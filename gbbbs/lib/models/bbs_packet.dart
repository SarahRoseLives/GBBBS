import 'dart:typed_data';

/// Represents a packet intended for the BBS client or server.
class BbsPacket {
  final String destination;
  final String source;
  final List<String> path;
  final String info;
  final DateTime timestamp;

  BbsPacket({
    required this.destination,
    required this.source,
    required this.path,
    required this.info,
    required this.timestamp,
  });

  /// Factory constructor to parse a raw AX.25 UI frame.
  factory BbsPacket.fromAX25Frame(Uint8List frame) {
    int offset = 0;

    String parseAddress() {
      final addressBytes = frame.sublist(offset, offset + 6);
      final ssidByte = frame[offset + 6];
      offset += 7;

      String callsign =
          String.fromCharCodes(addressBytes.map((b) => b >> 1)).trim();
      int ssid = (ssidByte >> 1) & 0x0F;

      return ssid > 0 ? '$callsign-$ssid' : callsign;
    }

    final dest = parseAddress();
    final source = parseAddress();

    List<String> path = [];
    while ((frame[offset - 1] & 0x01) == 0) {
      if (offset + 7 > frame.length) break;
      path.add(parseAddress());
    }

    offset += 2; // Skip Control (0x03) and PID (0xF0)

    final infoField = String.fromCharCodes(frame.sublist(offset));

    return BbsPacket(
      destination: dest,
      source: source,
      path: path,
      info: infoField,
      timestamp: DateTime.now(),
    );
  }
}