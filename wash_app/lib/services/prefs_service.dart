import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const _excludedCodesKey = 'excluded_codes_key';
  static const _compactLayoutKey = 'compact_layout_key';

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
}
