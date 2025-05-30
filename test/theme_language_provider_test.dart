import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_application_1/theme_language_provider.dart';
import 'theme_language_provider_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseAuth>(),
  MockSpec<User>(),
])
void main() {
  group('ThemeLanguageProvider Tests', () {
    late ThemeLanguageProvider provider;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() async {
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      fakeFirestore = FakeFirebaseFirestore();
      reset(mockFirebaseAuth);
      reset(mockUser);
    });

    test('Initial state is correct', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);
      provider = ThemeLanguageProvider(auth: mockFirebaseAuth, firestore: fakeFirestore);
      print('isDarkMode before delay: ${provider.isDarkMode}');
      await Future.delayed(const Duration(milliseconds: 100));
      print('isDarkMode after delay: ${provider.isDarkMode}');
      expect(provider.isDarkMode, false);
      expect(provider.language, 'ru');
      expect(provider.locale, const Locale('ru'));
      expect(provider.isInitialized, true);
    });

    test('Constructor initializes with no user', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);
      provider = ThemeLanguageProvider(auth: mockFirebaseAuth, firestore: fakeFirestore);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.isDarkMode, false);
      expect(provider.language, 'ru');
      expect(provider.locale, const Locale('ru'));
      expect(provider.isInitialized, true);
    });

    test('Constructor loads preferences from Firestore', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_uid');
      await fakeFirestore.collection('users').doc('test_uid').set({
        'isDarkMode': true,
        'language': 'en',
      });

      provider = ThemeLanguageProvider(auth: mockFirebaseAuth, firestore: fakeFirestore);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.isDarkMode, true);
      expect(provider.language, 'en');
      expect(provider.locale, const Locale('en'));
      expect(provider.isInitialized, true);
    });

    test('Constructor sets defaults on Firestore error', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_uid');

      provider = ThemeLanguageProvider(auth: mockFirebaseAuth, firestore: fakeFirestore);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.isDarkMode, false);
      expect(provider.language, 'ru');
      expect(provider.locale, const Locale('ru'));
      expect(provider.isInitialized, true);
    });

    test('toggleTheme updates isDarkMode and saves to Firestore', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_uid');

      provider = ThemeLanguageProvider(auth: mockFirebaseAuth, firestore: fakeFirestore);
      await Future.delayed(const Duration(milliseconds: 100));
      await provider.toggleTheme(true);

      expect(provider.isDarkMode, true);
      final doc = await fakeFirestore.collection('users').doc('test_uid').get();
      expect(doc.data(), {'isDarkMode': true, 'language': 'ru'});
    });

    test('setLanguage updates language and locale', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_uid');

      provider = ThemeLanguageProvider(auth: mockFirebaseAuth, firestore: fakeFirestore);
      await Future.delayed(const Duration(milliseconds: 100));
      await provider.setLanguage('kk');

      expect(provider.language, 'kk');
      expect(provider.locale, const Locale('kk'));
      final doc = await fakeFirestore.collection('users').doc('test_uid').get();
      expect(doc.data(), {'isDarkMode': false, 'language': 'kk'});
    });

    test('resetPreferences resets to defaults', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_uid');

      provider = ThemeLanguageProvider(auth: mockFirebaseAuth, firestore: fakeFirestore);
      await Future.delayed(const Duration(milliseconds: 100));
      await provider.toggleTheme(true);
      await provider.setLanguage('en');
      provider.resetPreferences();

      expect(provider.isDarkMode, false);
      expect(provider.language, 'ru');
      expect(provider.locale, const Locale('ru'));
      expect(provider.isInitialized, false);
    });
  });
}
