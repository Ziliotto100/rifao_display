import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/brand_colors.dart';

class ThemeStorage {
  static const _bgKey = 'theme_background_color';
  static const _numberKey = 'theme_number_color';
  static const _historyTextKey = 'theme_history_text_color';
  static const _typingKey = 'theme_typing_color';

  static const Color defaultBackground = BrandColors.darkGreen;
  static const Color defaultNumberColor = BrandColors.gold;
  static const Color defaultHistoryTextColor = BrandColors.cream;
  static const Color defaultTypingColor = BrandColors.olive;

  static Future<Color> loadBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_bgKey);
    return value != null ? Color(value) : defaultBackground;
  }

  static Future<void> saveBackground(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bgKey, color.value);
  }

  static Future<Color> loadNumberColor() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_numberKey);
    return value != null ? Color(value) : defaultNumberColor;
  }

  static Future<void> saveNumberColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_numberKey, color.value);
  }

  static Future<Color> loadHistoryTextColor() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_historyTextKey);
    return value != null ? Color(value) : defaultHistoryTextColor;
  }

  static Future<void> saveHistoryTextColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_historyTextKey, color.value);
  }

  static Future<Color> loadTypingColor() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_typingKey);
    return value != null ? Color(value) : defaultTypingColor;
  }

  static Future<void> saveTypingColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_typingKey, color.value);
  }

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bgKey);
    await prefs.remove(_numberKey);
    await prefs.remove(_historyTextKey);
    await prefs.remove(_typingKey);
  }
}
