import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconly/iconly.dart';
import '../localizations.dart';
import 'home.dart';
import 'register_page.dart';

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

  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

    if (_formKey.currentState!.validate() && _emailError == null) {
      setState(() => _isLoading = true);
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
              builder: (context) => HomeScreen(
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
            errorMessage = AppLocalizations.of(context).translate('userNotFound');
            break;
          case 'wrong-password':
            errorMessage = AppLocalizations.of(context).translate('wrongPassword');
            break;
          default:
            errorMessage = AppLocalizations.of(context).translate('invalidCredentials');
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
              AppLocalizations.of(context).translate('invalidCredentials'),
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
    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2A9D8F),
          secondary: Color(0xFFF4A261),
          surface: Color(0xFFF8FAFC),
          onSurface: Color(0xFF264653),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A9D8F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6B7280)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6B7280)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A9D8F), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
          prefixIconColor: const Color(0xFF2A9D8F),
          suffixIconColor: const Color(0xFF2A9D8F),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Text(
              localizations.translate('login'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF2A9D8F),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          elevation: 4,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        child: Text(
                          localizations.translate('welcomeBack'),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF264653),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_emailError != null)
                            FadeInLeft(
                              duration: const Duration(milliseconds: 900),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  _emailError!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          FadeInLeft(
                            duration: const Duration(milliseconds: 1000),
                            child: TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: localizations.translate('email'),
                                prefixIcon: const Icon(IconlyLight.message),
                                hintText: 'example@domain.com',
                                hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                              ),
                              onChanged: _validateEmail,
                              validator: (value) => value!.isEmpty
                                  ? localizations.translate('enterEmail')
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 1100),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: localizations.translate('password'),
                            prefixIcon: const Icon(IconlyLight.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? IconlyLight.show
                                    : IconlyLight.hide,
                                color: const Color(0xFF2A9D8F),
                              ),
                              onPressed: () => setState(
                                    () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                            ),
                            hintText: '••••••••',
                            hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                          validator: (value) => value!.isEmpty
                              ? localizations.translate('enterPassword')
                              : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2A9D8F),
                        ),
                      )
                          : Column(
                        children: [
                          ZoomIn(
                            duration: const Duration(milliseconds: 1200),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              child: Text(localizations.translate('login')),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInLeft(
                            duration: const Duration(milliseconds: 1300),
                            child: TextButton(
                              onPressed: _navigateToRegister,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFF4A261),
                              ),
                              child: Text(
                                localizations.translate('dontHaveAccount'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ZoomIn(
                            duration: const Duration(milliseconds: 1400),
                            child: OutlinedButton(
                              onPressed: _continueAsGuest,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(
                                  color: Color(0xFF2A9D8F),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                localizations.translate('continueAsGuest'),
                                style: const TextStyle(
                                  color: Color(0xFF2A9D8F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
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