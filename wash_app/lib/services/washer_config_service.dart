import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/washer_config.dart';

class WasherConfigService {
  static const _configKey = 'washer_config_json';

  Future<WasherConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_configKey);
    if (jsonString == null) {
      return WasherConfig.defaultConfig();
    }
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return WasherConfig.fromJson(decoded);
    } catch (_) {
      return WasherConfig.defaultConfig();
    }
  }

  Future<void> saveConfig(WasherConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(config.toJson());
    await prefs.setString(_configKey, encoded);
  }

  WasherConfig parseConfig(String content) {
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('配置文件格式错误');
    }
    return WasherConfig.fromJson(decoded);
  }

  Future<File> exportConfig(WasherConfig config) async {
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/washer_config_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    final encoded = const JsonEncoder.withIndent('  ').convert(config.toJson());
    await file.writeAsString(encoded);
    return file;
  }

  Future<WasherConfig> importConfigFromFile(File file) async {
    final content = await file.readAsString();
    final config = parseConfig(content);
    await saveConfig(config);
    return config;
  }
}
