import 'package:shared_preferences/shared_preferences.dart';

class DeviceManager {
  static const _devicesKey = 'washer_devices_list';

  Future<List<String>> loadDeviceCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_devicesKey);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    return const [
      'GTYX2112210117',
      'GTYX2112210115',
      'GTYX2112210149',
      'GTYX2112210182',
      'GTYX2112210020',
      'GTYX2112210157',
      'GTYX2112210131',
    ];
  }

  Future<void> saveDeviceCodes(List<String> codes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_devicesKey, codes);
  }

  Future<void> addDevice(String code) async {
    final codes = await loadDeviceCodes();
    if (!codes.contains(code)) {
      codes.add(code);
      await saveDeviceCodes(codes);
    }
  }

  Future<void> removeDevice(String code) async {
    final codes = await loadDeviceCodes();
    codes.remove(code);
    await saveDeviceCodes(codes);
  }

  String? extractCodeFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }
    final name = uri.queryParameters['name'];
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final match = RegExp(r'name=([A-Za-z0-9]+)').firstMatch(url);
    return match?.group(1);
  }
}
