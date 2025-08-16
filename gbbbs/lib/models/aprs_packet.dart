import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // <-- ADDED THIS IMPORT

/// Represents a fully parsed APRS packet.
class AprsPacket {
  final String destination;
  final String source;
  final List<String> path;
  final String info; // The raw information field

  // Parsed information fields
  final double? latitude;
  final double? longitude;
  final String? comment;
  final String? symbol;
  final int? course;
  final int? speed;
  final DateTime timestamp;

  AprsPacket({
    required this.destination,
    required this.source,
    required this.path,
    required this.info,
    this.latitude,
    this.longitude,
    this.comment,
    this.symbol,
    this.course,
    this.speed,
    required this.timestamp,
  });

  /// Factory constructor to parse a raw AX.25 UI frame.
  factory AprsPacket.fromAX25Frame(Uint8List frame) {
    int offset = 0;

    // Helper to parse a single address field (7 bytes)
    String parseAddress() {
      final addressBytes = frame.sublist(offset, offset + 6);
      final ssidByte = frame[offset + 6];
      offset += 7;

      String callsign = String.fromCharCodes(addressBytes.map((b) => b >> 1)).trim();
      int ssid = (ssidByte >> 1) & 0x0F;

      return ssid > 0 ? '$callsign-$ssid' : callsign;
    }

    // 1. Destination Address
    final dest = parseAddress();

    // 2. Source Address
    final source = parseAddress();

    // 3. Digipeater Path
    List<String> path = [];
    // The last address in the header is marked with the LSB set to 1.
    while ((frame[offset - 1] & 0x01) == 0) {
      if (offset + 7 > frame.length) break; // Avoid overruns
      path.add(parseAddress());
    }

    // 4. Skip Control (0x03) and PID (0xF0) fields
    offset += 2;

    // 5. The rest is the info field
    final infoField = String.fromCharCodes(frame.sublist(offset));

    // 6. Parse the info field for APRS data
    return _parseInfoField(
      destination: dest,
      source: source,
      path: path,
      info: infoField,
    );
  }

  /// Internal helper to parse the APRS-specific information field.
  static AprsPacket _parseInfoField({
    required String destination,
    required String source,
    required List<String> path,
    required String info,
  }) {
    double? lat;
    double? lon;
    String? cmt;
    String? sym;
    int? crs;
    int? spd;

    try {
      final dataType = info[0];

      // Compressed Position Report (most common on 2m)
      if (dataType == '!' || dataType == '=' || dataType == '/' || dataType == '@') {
        // Basic parsing for compressed and uncompressed position
        if (info.length >= 19 && (dataType == '!' || dataType == '=')) { // Uncompressed
            final latStr = info.substring(1, 9); // e.g., 4903.50N
            final lonStr = info.substring(10, 19); // e.g., 07201.75W
            lat = _parseLat(latStr);
            lon = _parseLon(lonStr);
            sym = info.substring(9, 10);
            cmt = info.length > 19 ? info.substring(19) : null;
        } else if (info.length >= 14 && (dataType == '/' || dataType == '@')) { // Compressed
            final latComp = info.substring(1, 5);
            final lonComp = info.substring(5, 9);
            lat = 90.0 - _decodeBase91(latComp) / 380926.0;
            lon = -180.0 + _decodeBase91(lonComp) / 190463.0;
            sym = info.substring(9, 10);
            // Compressed course/speed/altitude
            if (info.length > 10) {
                final cs = _decodeBase91(info.substring(10, 11));
                final da = _decodeBase91(info.substring(11, 12));
                if (cs > 0) {
                    // --- MODIFIED THIS LINE ---
                    crs = ((cs-1) * 4).round();
                    if(crs == 0) crs = 360;
                }
                if (da > 0) {
                    spd = (pow(1.08, (da-1)) -1).round();
                }
            }
            cmt = info.length > 14 ? info.substring(14) : null;
        }
      }
    } catch (e) {
      // Could not parse, treat as a generic message/status
      if (kDebugMode) {
        print("Failed to parse APRS info field '$info': $e");
      }
    }

    return AprsPacket(
      destination: destination,
      source: source,
      path: path,
      info: info,
      latitude: lat,
      longitude: lon,
      comment: cmt,
      symbol: sym,
      course: crs,
      speed: spd,
      timestamp: DateTime.now(),
    );
  }

  // Helper for uncompressed latitude, e.g., "4903.50N"
  static double? _parseLat(String s) {
    try {
      final deg = double.parse(s.substring(0, 2));
      final min = double.parse(s.substring(2, 7));
      final mult = (s[7] == 'S') ? -1.0 : 1.0;
      return mult * (deg + min / 60.0);
    } catch (_) {
      return null;
    }
  }

  // Helper for uncompressed longitude, e.g., "07201.75W"
  static double? _parseLon(String s) {
    try {
      final deg = double.parse(s.substring(0, 3));
      final min = double.parse(s.substring(3, 8));
      final mult = (s[8] == 'W') ? -1.0 : 1.0;
      return mult * (deg + min / 60.0);
    } catch (_) {
      return null;
    }
  }

  // Helper for compressed position format
  static double _decodeBase91(String s) {
      double n = 0;
      for (int i = 0; i < s.length; i++) {
          n += (s.codeUnitAt(i) - 33) * pow(91, s.length-1-i);
      }
      return n;
  }
}