import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeLanguageProvider with ChangeNotifier {
  bool _isDarkMode = false;
  String _language = 'ru';
  Locale _locale = const Locale('ru');
  bool _isInitialized = false;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ThemeLanguageProvider({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _loadPreferences();
  }

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;

  Future<void> _loadPreferences() async {
    try {
      if (_auth.currentUser != null) {
        final doc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            _isDarkMode = data['isDarkMode'] ?? false;
            _language = data['language'] ?? 'ru';
            _locale = Locale(_language);
          }
        }
      }
    } catch (e) {
      _isDarkMode = false;
      _language = 'ru';
      _locale = const Locale('ru');
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    if (_auth.currentUser != null) {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
        'isDarkMode': _isDarkMode,
        'language': _language,
      }, SetOptions(merge: true));
    }
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    _locale = Locale(lang);
    notifyListeners();
    if (_auth.currentUser != null) {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
        'isDarkMode': _isDarkMode,
        'language': _language,
      }, SetOptions(merge: true));
    }
  }

  void resetPreferences() {
    _isDarkMode = false;
    _language = 'ru';
    _locale = const Locale('ru');
    _isInitialized = false;
    notifyListeners();
  }
}