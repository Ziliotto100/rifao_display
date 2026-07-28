import 'package:shared_preferences/shared_preferences.dart';

class SponsorStorage {
  static const _pathsKey = 'sponsor_paths';
  static const _intervalKey = 'sponsor_interval_seconds';
  static const _perScreenKey = 'sponsor_per_screen';
  static const _historySizeKey = 'history_font_size';

  static Future<List<String>> loadPaths() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_pathsKey) ?? [];
  }

  static Future<void> savePaths(List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_pathsKey, paths);
  }

  static Future<int> loadInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_intervalKey) ?? 6;
  }

  static Future<void> saveInterval(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_intervalKey, seconds);
  }

  static Future<int> loadPerScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_perScreenKey) ?? 1;
    return value.clamp(1, 6);
  }

  static Future<void> savePerScreen(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_perScreenKey, count.clamp(1, 6));
  }

  /// Tamanho da fonte dos números no histórico embaixo.
  /// 1 = Pequeno, 2 = Médio (padrão), 3 = Grande
  static Future<int> loadHistorySize() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_historySizeKey) ?? 2;
    return value.clamp(1, 3);
  }

  static Future<void> saveHistorySize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_historySizeKey, size.clamp(1, 3));
  }
}
