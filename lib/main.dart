import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'pages/login_page.dart';
import 'pages/home.dart';
import 'theme_language_provider.dart';
import 'localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
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
        if (!themeLanguageProvider.isInitialized) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        return MaterialApp(
          title: 'Job Recruitment Platform',
          debugShowCheckedModeBanner: false,
          locale: themeLanguageProvider.locale,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('ru', 'RU'),
            Locale('kk', 'KZ'),
          ],
          theme: themeLanguageProvider.isDarkMode
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
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasData && snapshot.data != null) {
                  return HomeScreen(
                    userName:
                        snapshot.data!.displayName ??
                        snapshot.data!.email ??
                        '',
                  );
                } else {
                  return const LoginPage();
                }
              },
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'JobSeeker',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  localizations.translate('findYourDreamJob'),
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}