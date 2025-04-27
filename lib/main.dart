import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'models/user.dart';
import 'pages/login_page.dart';
import 'pages/home.dart';
import 'theme_language_provider.dart';
import 'localizations.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeLanguageProvider(),
      child: JobRecruitmentApp(),
    ),
  );
}

class JobRecruitmentApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeLanguageProvider>(
      builder: (context, themeLanguageProvider, child) {
        return MaterialApp(
          title: 'Job Recruitment Platform',
          debugShowCheckedModeBanner: false,
          locale: themeLanguageProvider.locale,
          localizationsDelegates: [
            // Делегируем локализацию нашему классу
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('ru'), Locale('kk')],
          theme:
              themeLanguageProvider.isDarkMode
                  ? ThemeData(
                    brightness: Brightness.dark,
                    primaryColor: Color(0xFF1E2A47),
                    scaffoldBackgroundColor: Color(0xFF1C2526),
                    cardColor: Color(0xFF2A2F33),
                    colorScheme: ColorScheme.dark(
                      primary: Color(0xFF1E2A47),
                      secondary: Color(0xFF40C4FF),
                      surface: Color(0xFF2A2F33),
                      onPrimary: Colors.white,
                      onSecondary: Colors.black,
                      onSurface: Color(0xFFE0E0E0),
                    ),
                    textTheme: TextTheme(
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
                        backgroundColor: Color(0xFF40C4FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    appBarTheme: AppBarTheme(
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
                    colorScheme: ColorScheme.light(
                      primary: Colors.blue,
                      secondary: Colors.blueAccent,
                      surface: Colors.white,
                      onPrimary: Colors.white,
                      onSecondary: Colors.black,
                      onSurface: Colors.black87,
                    ),
                    textTheme: TextTheme(
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
                    appBarTheme: AppBarTheme(
                      backgroundColor: Colors.blue,
                      titleTextStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          home: FutureBuilder<String?>(
            future: checkLogin(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasData && snapshot.data != null) {
                return HomeScreen(userName: snapshot.data!);
              } else {
                return LoginPage();
              }
            },
          ),
        );
      },
    );
  }

  Future<String?> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user');

    if (userJson != null) {
      Map<String, dynamic> userMap = jsonDecode(userJson);
      User user = User.fromJson(userMap);
      return user.name;
    }
    return null;
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
