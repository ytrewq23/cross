import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeLanguageProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _language = 'Русский';
  Locale _locale = const Locale('ru');
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;

  ThemeLanguageProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    if (_isInitialized) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          _isDarkMode = doc.data()?['isDarkMode'] ?? false;
          _language = doc.data()?['language'] ?? 'Русский';
          _updateLocale(_language);
        }
      } catch (e) {
        print('Error loading preferences from Firestore: $e');
        _isDarkMode = false;
        _language = 'Русский';
        _updateLocale(_language);
      }
    } else {
      _isDarkMode = false;
      _language = 'Русский';
      _updateLocale(_language);
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'isDarkMode': value,
          'language': _language,
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error saving theme to Firestore: $e');
      }
    }
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    _updateLocale(language);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'isDarkMode': _isDarkMode,
          'language': language,
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error saving language to Firestore: $e');
      }
    }
    notifyListeners();
  }

  void _updateLocale(String language) {
    switch (language) {
      case 'Русский':
        _locale = const Locale('ru');
        break;
      case 'Қазақша':
        _locale = const Locale('kk');
        break;
      case 'English':
        _locale = const Locale('en');
        break;
      default:
        _locale = const Locale('ru');
    }
  }

  void resetPreferences() {
    _isDarkMode = false;
    _language = 'Русский';
    _locale = const Locale('ru');
    _isInitialized = false;
    notifyListeners();
  }
}
