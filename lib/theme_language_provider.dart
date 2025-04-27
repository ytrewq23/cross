import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeLanguageProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _language = 'Русский';

  bool get isDarkMode => _isDarkMode;
  String get language => _language;

  ThemeLanguageProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkTheme') ?? false;
    _language = prefs.getString('language') ?? 'Русский';
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', value);
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    notifyListeners();
  }
}
