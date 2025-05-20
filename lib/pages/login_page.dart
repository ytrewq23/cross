import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconly/iconly.dart';
import '../localizations.dart';
import 'home.dart';
import 'register_page.dart';
import 'offline_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _emailError;
  bool _isOnline = true;
  int _currentPage = 0;

  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    bool isOnline = await OfflineService().checkConnection();
    if (mounted) {
      setState(() => _isOnline = isOnline);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      if (value.isEmpty) {
        _emailError = AppLocalizations.of(context).translate('enterEmail');
      } else if (!_emailRegex.hasMatch(value)) {
        _emailError = AppLocalizations.of(context).translate('invalidEmail');
      } else {
        _emailError = null;
      }
    });
  }

  void _login() async {
    if (!mounted) return;

    final localizations = AppLocalizations.of(context);
    if (_formKey.currentState!.validate() && _emailError == null) {
      setState(() => _isLoading = true);

      if (!_isOnline) {
        if (mounted) {
          OfflineService().showOfflineSnackBar(context);
        }
        setState(() => _isLoading = false);
        return;
      }

      try {
        print('Attempting to sign in with email: ${_emailController.text}');
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
        print('User signed in with UID: ${userCredential.user!.uid}');

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => HomeScreen(
                    userName:
                        userCredential.user?.displayName ??
                        userCredential.user?.email ??
                        '',
                  ),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        print('Login error: $e');
        if (!mounted) return;

        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = localizations.translate('userNotFound');
            break;
          case 'wrong-password':
            errorMessage = localizations.translate('wrongPassword');
            break;
          default:
            errorMessage = localizations.translate('invalidCredentials');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isLoading = false);
      } catch (e) {
        print('Unexpected error during login: $e');
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate('invalidCredentials'),
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToRegister() {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  void _continueAsGuest() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(userName: 'Guest')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    // Onboarding pages for the carousel
    List<Widget> onboardingPages = [
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work, size: 100, color: Color(0xFF2A9D8F)),
            SizedBox(height: 16),
            Text(
              localizations.translate('startYourJobSearch'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF264653),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              localizations.translate('beginJourney'),
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 100, color: Color(0xFF2A9D8F)),
            SizedBox(height: 16),
            Text(
              localizations.translate('createProfile'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF264653),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              localizations.translate('standOut'),
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 100, color: Color(0xFF2A9D8F)),
            SizedBox(height: 16),
            Text(
              localizations.translate('findOpportunities'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF264653),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              localizations.translate('matchSkills'),
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ];

    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF2A9D8F),
          secondary: Color(0xFFF4A261),
          surface: Color(0xFFF8FAFC),
          onSurface: Color(0xFF264653),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2A9D8F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            minimumSize: Size(double.infinity, 48),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: Color(0xFF2A9D8F)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF6B7280)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF6B7280)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF2A9D8F), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.redAccent, width: 2),
          ),
          labelStyle: TextStyle(color: Color(0xFF6B7280)),
          prefixIconColor: Color(0xFF2A9D8F),
          suffixIconColor: Color(0xFF2A9D8F),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
      child: Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        appBar: AppBar(
          title: FadeInDown(
            duration: Duration(milliseconds: 600),
            child: Text(
              localizations.translate('login'),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: _isOnline ? Color(0xFF2A9D8F) : Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          elevation: 4,
          flexibleSpace:
              !_isOnline
                  ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withOpacity(0.3),
                          Colors.red.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: FadeInDown(
                        duration: Duration(milliseconds: 700),
                        child: Text(
                          localizations.translate('connectToInternet'),
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  )
                  : null,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Card(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Onboarding carousel
                      SizedBox(
                        height: 200,
                        child: Stack(
                          children: [
                            PageView(
                              controller: _pageController,
                              onPageChanged: (int page) {
                                setState(() => _currentPage = page);
                              },
                              children: onboardingPages,
                            ),
                            Positioned(
                              bottom: 10,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  onboardingPages.length,
                                  (index) => AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    margin: EdgeInsets.symmetric(horizontal: 4),
                                    height: 8,
                                    width: _currentPage == index ? 24 : 8,
                                    decoration: BoxDecoration(
                                      color:
                                          _currentPage == index
                                              ? Color(0xFF2A9D8F)
                                              : Color(0xFF6B7280),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32),
                      FadeInDown(
                        duration: Duration(milliseconds: 800),
                        child: Text(
                          localizations.translate('welcomeBack'),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF264653),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_emailError != null)
                            FadeInLeft(
                              duration: Duration(milliseconds: 900),
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  _emailError!,
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          FadeInLeft(
                            duration: Duration(milliseconds: 1000),
                            child: TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: localizations.translate('email'),
                                prefixIcon: Icon(IconlyLight.message),
                                hintText: 'example@domain.com',
                                hintStyle: TextStyle(color: Color(0xFF6B7280)),
                              ),
                              onChanged: _validateEmail,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? localizations.translate(
                                            'enterEmail',
                                          )
                                          : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      FadeInLeft(
                        duration: Duration(milliseconds: 1100),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: localizations.translate('password'),
                            prefixIcon: Icon(IconlyLight.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? IconlyLight.show
                                    : IconlyLight.hide,
                                color: Color(0xFF2A9D8F),
                              ),
                              onPressed:
                                  () => setState(
                                    () =>
                                        _isPasswordVisible =
                                            !_isPasswordVisible,
                                  ),
                            ),
                            hintText: '••••••••',
                            hintStyle: TextStyle(color: Color(0xFF6B7280)),
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? localizations.translate('enterPassword')
                                      : null,
                        ),
                      ),
                      SizedBox(height: 24),
                      _isLoading
                          ? Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2A9D8F),
                            ),
                          )
                          : Column(
                            children: [
                              ZoomIn(
                                duration: Duration(milliseconds: 1300),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  child: Text(localizations.translate('login')),
                                ),
                              ),
                              SizedBox(height: 16),
                              FadeInLeft(
                                duration: Duration(milliseconds: 1400),
                                child: TextButton(
                                  onPressed: _navigateToRegister,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Color(0xFFF4A261),
                                  ),
                                  child: Text(
                                    localizations.translate('dontHaveAccount'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              ZoomIn(
                                duration: Duration(milliseconds: 1500),
                                child: OutlinedButton(
                                  onPressed: _continueAsGuest,
                                  child: Text(
                                    localizations.translate('continueAsGuest'),
                                    style: TextStyle(color: Color(0xFF2A9D8F)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
