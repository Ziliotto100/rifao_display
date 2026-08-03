import 'package:shared_preferences/shared_preferences.dart';

class SponsorStorage {
  static const _pathsKey = 'sponsor_paths';
  static const _intervalKey = 'sponsor_interval_seconds';
  static const _perScreenKey = 'sponsor_per_screen';
  static const _historySizeKey = 'history_font_size';
  static const _numberSizeKey = 'number_display_font_size';

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
  /// 3 = Grande (padrão), 4 = Gigante, 5 = Extra grande, 6 = Enorme, 7 = Colossal
  static Future<int> loadHistorySize() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_historySizeKey) ?? 3;
    return value.clamp(3, 7);
  }

  static Future<void> saveHistorySize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_historySizeKey, size.clamp(3, 7));
  }

  /// Tamanho da fonte do número grande em destaque (o sorteio atual).
  /// 3 = Grande (padrão), 4 = Gigante, 5 = Extra grande, 6 = Enorme, 7 = Colossal
  static Future<int> loadNumberSize() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_numberSizeKey) ?? 3;
    return value.clamp(3, 7);
  }

  static Future<void> saveNumberSize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_numberSizeKey, size.clamp(3, 7));
  }
}
