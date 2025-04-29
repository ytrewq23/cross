import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'pages/login_page.dart';
import 'pages/home.dart';
import 'theme_language_provider.dart';
import 'localizations.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (!kIsWeb) {
      // Инициализация только для не-веб платформ
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAKmQxpHTGgCyDFngNfw_WdEn1MW3lcxhM",
          authDomain: "flutter-4e118.firebaseapp.com",
          projectId: "flutter-4e118",
          storageBucket: "flutter-4e118.firebasestorage.app",
          messagingSenderId: "866137879876",
          appId: "1:866137879876:web:8022c25ccfcb62c4055311",
          measurementId: "G-1ZDP0HQVRW",
        ),
      );
      print('Firebase initialized successfully');
    } else {
      print('Firebase already initialized in web/index.html');
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeLanguageProvider(),
      child: const JobRecruitmentApp(),
    ),
  );
}

class JobRecruitmentApp extends StatelessWidget {
  const JobRecruitmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeLanguageProvider>(
      builder: (context, themeLanguageProvider, child) {
        return MaterialApp(
          title: 'Job Recruitment Platform',
          debugShowCheckedModeBanner: false,
          locale: themeLanguageProvider.locale,
          localizationsDelegates: [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ru'), Locale('kk')],
          theme:
              themeLanguageProvider.isDarkMode
                  ? ThemeData(
                    brightness: Brightness.dark,
                    primaryColor: const Color(0xFF1E2A47),
                    scaffoldBackgroundColor: const Color(0xFF1C2526),
                    cardColor: const Color(0xFF2A2F33),
                    colorScheme: const ColorScheme.dark(
                      primary: Color(0xFF1E2A47),
                      secondary: Color(0xFF40C4FF),
                      surface: Color(0xFF2A2F33),
                      onPrimary: Colors.white,
                      onSecondary: Colors.black,
                      onSurface: Color(0xFFE0E0E0),
                    ),
                    textTheme: const TextTheme(
                      titleLarge: TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      bodyMedium: TextStyle(
                        color: Color(0xFFB0B0B0),
                        fontSize: 16,
                      ),
                      labelLarge: TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF40C4FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    appBarTheme: const AppBarTheme(
                      backgroundColor: Color(0xFF1E2A47),
                      titleTextStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  : ThemeData(
                    brightness: Brightness.light,
                    primaryColor: Colors.blue,
                    scaffoldBackgroundColor: Colors.white,
                    cardColor: Colors.white,
                    colorScheme: const ColorScheme.light(
                      primary: Colors.blue,
                      secondary: Colors.blueAccent,
                      surface: Colors.white,
                      onPrimary: Colors.white,
                      onSecondary: Colors.black,
                      onSurface: Colors.black87,
                    ),
                    textTheme: const TextTheme(
                      titleLarge: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      bodyMedium: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                      labelLarge: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    appBarTheme: const AppBarTheme(
                      backgroundColor: Colors.blue,
                      titleTextStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasData && snapshot.data != null) {
                return HomeScreen(
                  userName:
                      snapshot.data!.displayName ?? snapshot.data!.email ?? '',
                );
              } else {
                return LoginPage();
              }
            },
          ),
        );
      },
    );
  }
}

// Делегат для локализации
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  @override
  bool isSupported(Locale locale) =>
      ['en', 'ru', 'kk'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
