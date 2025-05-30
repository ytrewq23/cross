import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/theme_language_provider.dart';
import 'package:flutter_application_1/pages/profile.dart';
import 'package:flutter_application_1/pages/offline_service.dart';
import 'package:flutter_application_1/localizations.dart';

// Mock AppLocalizations
class MockAppLocalizations extends Mock implements AppLocalizations {
  @override
  String translate(String key) {
    return AppLocalizations(const Locale('en')).translate(key);
  }
}

void main() {
  group('ThemeLanguageProvider Integration Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late ThemeLanguageProvider themeProvider;
    late SharedPreferences prefs;

    setUp(() async {
      // Initialize mocks
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser(
        uid: 'test_uid',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_uid');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.displayName).thenReturn('Test User');

      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      // Initialize ThemeLanguageProvider
      themeProvider = ThemeLanguageProvider(auth: mockAuth, firestore: fakeFirestore);

      // Mock OfflineService connectivity
      OfflineService().isOnline = true;
    });

    testWidgets('Toggle theme and create job as employer (online)', (WidgetTester tester) async {
      // Set up user role as employer
      await fakeFirestore.collection('users').doc('test_uid').set({
        'role': 'employer',
        'name': 'Test User',
        'email': 'test@example.com',
      });

      // Build the app
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => themeProvider,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ru'), Locale('kk')],
            locale: const Locale('en'),
            home: const ProfilePage(),
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.light,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify ProfilePage is displayed
      expect(find.text('Profile'), findsOneWidget);

      // Verify employer content (Create Job button)
      expect(find.byTooltip('Create Job'), findsOneWidget);

      // Toggle theme to dark
      await themeProvider.toggleTheme(true);
      await tester.pumpAndSettle();
      expect(themeProvider.isDarkMode, true);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, ThemeData.dark().scaffoldBackgroundColor);

      // Tap Create Job button
      await tester.tap(find.byTooltip('Create Job'));
      await tester.pumpAndSettle();

      // Verify CreateJobScreen
      expect(find.text('Create Job'), findsOneWidget);

      // Fill job form
      await tester.enterText(find.widgetWithText(TextFormField, 'Job Title'), 'Software Engineer');
      await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'Develop apps');
      await tester.enterText(find.widgetWithText(TextFormField, 'Salary'), '100000');
      await tester.enterText(find.widgetWithText(TextFormField, 'City'), 'Almaty');
      await tester.enterText(find.widgetWithText(TextFormField, 'Requirements'), '5 years experience');
      await tester.enterText(find.widgetWithText(TextFormField, 'Contact Info'), 'hr@example.com');

      // Select category
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('IT').last);
      await tester.pumpAndSettle();

      // Select schedule
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Schedule'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Full Time').last);
      await tester.pumpAndSettle();

      // Select employment type
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Employment Type'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Full Employment').last);
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify job in Firestore
      final jobsSnapshot = await fakeFirestore.collection('jobs').get();
      expect(jobsSnapshot.docs.length, 1);
      final jobData = jobsSnapshot.docs.first.data();
      expect(jobData['title'], 'Software Engineer');
      expect(jobData['employerId'], 'test_uid');

      // Verify job in ProfilePage
      expect(find.text('Software Engineer'), findsOneWidget);
    });

    testWidgets('Create job as employer (offline)', (WidgetTester tester) async {
      // Set up user role as employer
      await fakeFirestore.collection('users').doc('test_uid').set({
        'role': 'employer',
        'name': 'Test User',
        'email': 'test@example.com',
      });

      // Set OfflineService to offline
      OfflineService().isOnline = false;

      // Build the app
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => themeProvider,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ru'), Locale('kk')],
            locale: const Locale('en'),
            home: const ProfilePage(),
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.light,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify offline warning
      expect(find.text('Please connect to the internet'), findsOneWidget);

      // Tap Create Job button
      await tester.tap(find.byTooltip('Create Job'));
      await tester.pumpAndSettle();

      // Fill job form
      await tester.enterText(find.widgetWithText(TextFormField, 'Job Title'), 'Data Analyst');
      await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'Analyze data');
      await tester.enterText(find.widgetWithText(TextFormField, 'Salary'), '80000');
      await tester.enterText(find.widgetWithText(TextFormField, 'City'), 'Astana');
      await tester.enterText(find.widgetWithText(TextFormField, 'Requirements'), '3 years experience');
      await tester.enterText(find.widgetWithText(TextFormField, 'Contact Info'), 'hr2@example.com');

      // Select category
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('IT').last);
      await tester.pumpAndSettle();

      // Select schedule
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Schedule'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Full Time').last);
      await tester.pumpAndSettle();

      // Select employment type
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Employment Type'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Full Employment').last);
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify offline snackbar
      expect(find.text('Please connect to the internet'), findsWidgets);

      // Verify job in SharedPreferences
      final pendingActions = prefs.getStringList('pending_actions') ?? [];
      expect(pendingActions.length, 1);
      final action = jsonDecode(pendingActions.first) as Map<String, dynamic>;
      expect(action['type'], 'job');
      expect(action['action'], 'create');
      expect(action['data']['title'], 'Data Analyst');

      // Simulate going online and syncing
      OfflineService().isOnline = true;
      await OfflineService().syncPendingActions(null);
      await tester.pumpAndSettle();

      // Verify job in Firestore
      final jobsSnapshot = await fakeFirestore.collection('jobs').get();
      expect(jobsSnapshot.docs.length, 1);
      final jobData = jobsSnapshot.docs.first.data();
      expect(jobData['title'], 'Data Analyst');
      expect(jobData['employerId'], 'test_uid');
    });

    testWidgets('No role displays role selection prompt', (WidgetTester tester) async {
      // No role set in Firestore
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => themeProvider,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ru'), Locale('kk')],
            locale: const Locale('en'),
            home: const ProfilePage(),
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.light,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no role content
      expect(find.text('Please Select Role'), findsOneWidget);
      expect(find.text('Select Role'), findsOneWidget);

      // Tap Select Role button
      await tester.tap(find.text('Select Role'));
      await tester.pumpAndSettle();

      // Simulate selecting employer role (assuming RoleSelectionDialog structure)
      expect(find.text('Select Your Role'), findsOneWidget);
      await tester.tap(find.text('Employer'));
      await tester.pumpAndSettle();

      // Verify role updated in Firestore
      final userDoc = await fakeFirestore.collection('users').doc('test_uid').get();
      expect(userDoc.data()?['role'], 'employer');

      // Verify ProfilePage updated
      await tester.pumpAndSettle();
      expect(find.byTooltip('Create Job'), findsOneWidget);
    });
  });
}