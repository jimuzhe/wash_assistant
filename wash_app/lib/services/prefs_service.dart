import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const _excludedCodesKey = 'excluded_codes_key';
  static const _compactLayoutKey = 'compact_layout_key';
  static const _ownedDevicesKey = 'owned_devices_key';

  Future<Set<String>> loadExcludedCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_excludedCodesKey) ?? <String>[];
    return list.toSet();
  }

  Future<void> saveExcludedCodes(Set<String> codes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_excludedCodesKey, codes.toList());
  }

  Future<bool> loadCompactLayout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_compactLayoutKey) ?? false;
  }

  Future<void> saveCompactLayout(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_compactLayoutKey, value);
  }

  Future<Map<String, OwnedDeviceRecord>> loadOwnedDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_ownedDevicesKey);
    if (stored == null || stored.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(stored);
    if (decoded is! Map<String, dynamic>) {
      return {};
    }
    final result = <String, OwnedDeviceRecord>{};
    decoded.forEach((key, value) {
      if (key is String && value is Map<String, dynamic>) {
        final end = value['end'] as String?;
        final name = value['name'] as String? ?? '';
        final idRaw = value['id'];
        if (end == null || idRaw == null) {
          return;
        }
        final parsed = DateTime.tryParse(end);
        final deviceId = idRaw is num ? idRaw.toInt() : int.tryParse('$idRaw');
        if (parsed != null && deviceId != null) {
          result[key] = OwnedDeviceRecord(
            name: name,
            finishAt: parsed,
            deviceId: deviceId,
          );
        }
      }
    });
    return result;
  }

  Future<void> saveOwnedDevices(Map<String, OwnedDeviceRecord> devices) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      devices.map(
        (key, value) => MapEntry(
          key,
          {
            'end': value.finishAt.toIso8601String(),
            'name': value.name,
            'id': value.deviceId,
          },
        ),
      ),
    );
    await prefs.setString(_ownedDevicesKey, encoded);
  }
}

class OwnedDeviceRecord {
  OwnedDeviceRecord({
    required this.name,
    required this.finishAt,
    required this.deviceId,
  });

  final String name;
  final DateTime finishAt;
  final int deviceId;

  OwnedDeviceRecord copyWith({String? name, DateTime? finishAt, int? deviceId}) {
    return OwnedDeviceRecord(
      name: name ?? this.name,
      finishAt: finishAt ?? this.finishAt,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}
