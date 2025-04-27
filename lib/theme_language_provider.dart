import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeLanguageProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _language = 'Русский';
  Locale _locale = Locale('ru');

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  Locale get locale => _locale;

  ThemeLanguageProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkTheme') ?? false;
    _language = prefs.getString('language') ?? 'Русский';
    _updateLocale(_language);
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
    _updateLocale(language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    notifyListeners();
  }

  void _updateLocale(String language) {
    switch (language) {
      case 'Русский':
        _locale = Locale('ru');
        break;
      case 'Қазақша':
        _locale = Locale('kk');
        break;
      case 'English':
        _locale = Locale('en');
        break;
      default:
        _locale = Locale('ru');
    }
  }
}
