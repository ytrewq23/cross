import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconly/iconly.dart';
import 'login_page.dart';
import '../localizations.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _emailError;

  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

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

  void _register() async {
    if (!mounted) return;

    print('Register button pressed');
    _validateEmail(_emailController.text.trim());

    if (_formKey.currentState!.validate() && _emailError == null) {
      setState(() => _isLoading = true);
      try {
        print('Attempting to register user with email: ${_emailController.text}');
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        print('User registered with UID: ${userCredential.user!.uid}');

        await userCredential.user?.updateDisplayName(_nameController.text);
        print('User display name updated: ${_nameController.text}');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name': _nameController.text,
          'email': _emailController.text.trim(),
          'id': DateTime.now().millisecondsSinceEpoch,
          'role': '', // Empty role, selection in HomeScreen
        });
        print('User data saved to Firestore for UID: ${userCredential.user!.uid}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('registrationSuccess'),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF2A9D8F),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } on FirebaseAuthException catch (e) {
        print('Registration error: $e');
        String errorMessage;
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage =
                AppLocalizations.of(context).translate('emailAlreadyInUse');
            break;
          case 'weak-password':
            errorMessage = AppLocalizations.of(context).translate('weakPassword');
            break;
          case 'invalid-email':
            errorMessage = AppLocalizations.of(context).translate('invalidEmail');
            break;
          default:
            errorMessage =
                AppLocalizations.of(context).translate('registrationFailed');
        }
        if (mounted) {
          setState(() {
            _emailError = errorMessage;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Unexpected error during registration: $e');
        if (mounted) {
          setState(() {
            _emailError =
                AppLocalizations.of(context).translate('registrationFailed');
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
              localizations.translate('register'),
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
                          localizations.translate('signUp'),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF264653),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 900),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: localizations.translate('name'),
                            prefixIcon: const Icon(IconlyLight.profile),
                            hintText: 'John Doe',
                            hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                          validator: (value) => value!.isEmpty
                              ? localizations.translate('enterName')
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_emailError != null)
                            FadeInLeft(
                              duration: const Duration(milliseconds: 1000),
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
                            duration: const Duration(milliseconds: 1100),
                            child: TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: localizations.translate('email'),
                                prefixIcon: const Icon(IconlyLight.message),
                                hintText: 'example@domain.com',
                                hintStyle:
                                const TextStyle(color: Color(0xFF6B7280)),
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
                        duration: const Duration(milliseconds: 1200),
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
                                      () => _isPasswordVisible = !_isPasswordVisible),
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
                            duration: const Duration(milliseconds: 1300),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              child:
                              Text(localizations.translate('register')),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInLeft(
                            duration: const Duration(milliseconds: 1400),
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                    const LoginPage(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFF4A261),
                              ),
                              child: Text(
                                localizations.translate('login'),
                                style: const TextStyle(
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