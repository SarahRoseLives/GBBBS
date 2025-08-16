// tnc/mobilinkd/mobilinkd_controller.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/aprs_packet.dart';
import '../../models/bbs_packet.dart';

/// Helper to peek at the AX.25 destination without a full parse.
String? _peekAx25Destination(Uint8List frame) {
  if (frame.length < 7) return null;
  final addressBytes = frame.sublist(0, 6);
  return String.fromCharCodes(addressBytes.map((b) => b >> 1)).trim();
}

class MobilinkdController extends ChangeNotifier {
  final BluetoothDevice device;
  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _streamSubscription;
  Uint8List _rxBuffer = Uint8List(0);

  // --- BBS Stream ---
  final StreamController<BbsPacket> _bbsPacketController =
      StreamController<BbsPacket>.broadcast();
  Stream<BbsPacket> get bbsPacketStream => _bbsPacketController.stream;

  // --- State Properties ---
  String userCallsign = 'NOCALL';

  // --- UI Notifiers ---
  final ValueNotifier<List<AprsPacket>> aprsPackets = ValueNotifier([]);

  // --- Internal State ---
  final List<AprsPacket> _internalPacketList = [];

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  MobilinkdController({required this.device});

  /// Sends a KISS configuration command to the TNC.
  Future<void> _sendKissCommand(int command, int value) async {
    if (_connection == null || !_isConnected) return;
    final builder = BytesBuilder();
    builder.addByte(0xC0); // FEND
    builder.addByte(command);
    builder.addByte(value);
    builder.addByte(0xC0); // FEND
    _connection!.output.add(builder.toBytes());
    await _connection!.output.allSent;
    await Future.delayed(
        const Duration(milliseconds: 50)); // Small delay between commands
  }

  Future<void> connect() async {
    if (_isConnected) return;
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      _isConnected = true;

      // This is crucial for preparing the TNC for transmission.
      // Set TX Delay to 300ms (value 30 * 10ms) to allow the radio to key up.
      await _sendKissCommand(0x01, 30);
      // Set Persistence parameter (standard value).
      await _sendKissCommand(0x02, 64);
      // Set Slot Time (standard value).
      await _sendKissCommand(0x03, 10);
      // Exit KISS mode to set hardware-specific commands (Mobilinkd feature)
      await _sendKissCommand(0xFF, 0xFF);
      // Set the audio output level to a sensible default (Mobilinkd specific)
      _connection!.output.add(Uint8List.fromList([0x20, 128]));
      await _connection!.output.allSent;
      await Future.delayed(const Duration(milliseconds: 50));
      // Re-enter KISS mode
      await _sendKissCommand(0xFF, 0x00);

      _streamSubscription =
          _connection!.input!.listen(_onDataReceived, onDone: dispose);
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      notifyListeners();
      rethrow;
    }
  }

  void _onDataReceived(Uint8List data) {
    _rxBuffer = Uint8List.fromList([..._rxBuffer, ...data]);
    _processKISSFrames();
  }

  void _processKISSFrames() async {
    const int fend = 0xC0;
    const int fesc = 0xDB;
    const int tfend = 0xDC;
    const int tfesc = 0xDD;

    while (true) {
      int frameStart = _rxBuffer.indexOf(fend);
      if (frameStart == -1) return;
      if (frameStart > 0) _rxBuffer = _rxBuffer.sublist(frameStart);

      int frameEnd = _rxBuffer.indexOf(fend, 1);
      if (frameEnd == -1) return;

      final frameWithCmd = _rxBuffer.sublist(1, frameEnd);
      _rxBuffer = _rxBuffer.sublist(frameEnd + 1);

      if (frameWithCmd.isEmpty || (frameWithCmd[0] & 0x0F) != 0) continue;

      final rawAx25 = frameWithCmd.sublist(1);
      final builder = BytesBuilder();
      for (int i = 0; i < rawAx25.length; i++) {
        if (rawAx25[i] == fesc) {
          i++;
          if (i < rawAx25.length) {
            if (rawAx25[i] == tfend)
              builder.addByte(fend);
            else if (rawAx25[i] == tfesc) builder.addByte(fesc);
          }
        } else {
          builder.addByte(rawAx25[i]);
        }
      }

      final fullPacketBytes = builder.toBytes();

      // ROUTE PACKET
      String? dest = _peekAx25Destination(fullPacketBytes);
      if (dest != null &&
          (dest == userCallsign ||
              (userCallsign.contains('-') &&
                  dest == userCallsign.split('-')[0]))) {
        try {
          final bbsPacket = BbsPacket.fromAX25Frame(fullPacketBytes);
          _bbsPacketController.add(bbsPacket);
        } catch (e) {
          if (kDebugMode) print("Could not parse incoming BBS packet: $e");
        }
      } else {
        // Assume APRS
        try {
          final newPacket = AprsPacket.fromAX25Frame(fullPacketBytes);

          if (newPacket.latitude != null && newPacket.longitude != null) {
            final existingIndex = _internalPacketList
                .indexWhere((p) => p.source == newPacket.source);
            if (existingIndex != -1) {
              _internalPacketList[existingIndex] = newPacket;
            } else {
              _internalPacketList.add(newPacket);
            }
            if (_internalPacketList.length > 200)
              _internalPacketList.removeAt(0);
            aprsPackets.value = List.from(_internalPacketList);
          }
        } catch (e) {
          if (kDebugMode)
            print("[MobilinkdController] Failed to parse AX.25 frame: $e");
        }
      }
    }
  }

  Future<void> sendBbsPacket(String destination, String info) async {
    // For direct communication, the path is empty.
    await _sendPacket(userCallsign, destination, [], info);
  }

  Future<void> _sendPacket(
      String source, String destination, List<String> path, String info) async {
    if (_connection == null || !_isConnected)
      throw Exception("TNC not connected.");
    final ax25Frame = _buildAX25Frame(source, destination, path, info);
    final kissFrame = _buildKISSFrame(ax25Frame);
    _connection!.output.add(kissFrame);
    await _connection!.output.allSent;
  }

  Uint8List _buildKISSFrame(Uint8List ax25Frame) {
    const int fend = 0xC0;
    const int fesc = 0xDB;
    const int tfend = 0xDC;
    const int tfesc = 0xDD;
    const int cmdData = 0x00;
    final builder = BytesBuilder();
    builder.addByte(fend);
    builder.addByte(cmdData);
    for (final byte in ax25Frame) {
      if (byte == fend) {
        builder.addByte(fesc);
        builder.addByte(tfend);
      } else if (byte == fesc) {
        builder.addByte(fesc);
        builder.addByte(tfesc);
      } else {
        builder.addByte(byte);
      }
    }
    builder.addByte(fend);
    return builder.toBytes();
  }

  Uint8List _buildAX25Frame(
      String source, String destination, List<String> path, String info) {
    final builder = BytesBuilder();

    Uint8List buildAddress(String call, bool isLast) {
      final parts = call.split('-');
      final callsign = parts[0].toUpperCase().padRight(6, ' ');
      final ssid = (parts.length > 1) ? int.tryParse(parts[1]) ?? 0 : 0;
      final address = Uint8List(7);
      for (int i = 0; i < 6; i++) {
        address[i] = callsign.codeUnitAt(i) << 1;
      }
      address[6] = 0xE0 | ((ssid & 0x0F) << 1) | (isLast ? 1 : 0);
      return address;
    }

    final List<String> allAddresses = [destination, source, ...path];

    for (int i = 0; i < allAddresses.length; i++) {
      builder.add(buildAddress(allAddresses[i], i == allAddresses.length - 1));
    }

    builder.addByte(0x03);
    builder.addByte(0xF0);
    builder.add(utf8.encode(info));

    return builder.toBytes();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _connection?.dispose();
    _bbsPacketController.close();
    aprsPackets.dispose();
    super.dispose();
  }
}