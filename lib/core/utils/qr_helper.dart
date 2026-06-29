import 'dart:convert';

class QrHelper {
  static Map<String, String> parseQr(String qrValue) {
    try {
      final decoded = jsonDecode(qrValue);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('bikeCode')) {
          return {
            'bikeCode': decoded['bikeCode'].toString(),
          };
        }
        
        final dockCode = decoded['dockCode']?.toString() ?? _extractDockCode(qrValue) ?? 'A1';
        final stationName = decoded['stationName']?.toString().trim() ?? 'Stasiun Gedung Teknik Informatika';
        return {
          'dockCode': _normalizeDockCode(dockCode),
          'dockLabel': _dockLabelFromCode(_normalizeDockCode(dockCode)),
          'stationName': stationName,
        };
      }
    } catch (_) {}

    final dockCode = _extractDockCode(qrValue) ?? 'A1';
    return {
      'dockCode': _normalizeDockCode(dockCode),
      'dockLabel': _dockLabelFromCode(_normalizeDockCode(dockCode)),
      'stationName': 'Stasiun Gedung Teknik Informatika',
    };
  }

  static String? _extractDockCode(String qrValue) {
    final match = RegExp(r'\b([A-Z]?\d{1,2})\b', caseSensitive: false).firstMatch(qrValue);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }

  static String _normalizeDockCode(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.startsWith('D')) {
      return normalized.substring(1);
    }
    if (normalized.startsWith('DOCK')) {
      return normalized.replaceFirst('DOCK', '');
    }
    return normalized;
  }

  static String _dockLabelFromCode(String code) {
    // Basic extraction
    final match = RegExp(r'\d+').firstMatch(code);
    if (match != null) {
      return 'Dok ${match.group(0)}';
    }
    return 'Dok';
  }
}
