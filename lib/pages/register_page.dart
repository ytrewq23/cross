import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Regular expression for email validation
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
    print('Register button pressed');
    // Validate email format before attempting Firebase registration
    _validateEmail(_emailController.text.trim());

    if (_formKey.currentState!.validate() && _emailError == null) {
      setState(() => _isLoading = true);
      try {
        print(
          'Attempting to register user with email: ${_emailController.text}',
        );
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
            });
        print(
          'User data saved to Firestore for UID: ${userCredential.user!.uid}',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } on FirebaseAuthException catch (e) {
        print('Registration error: $e');
        String errorMessage;
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = AppLocalizations.of(
              context,
            ).translate('emailAlreadyInUse');
            break;
          case 'weak-password':
            errorMessage = AppLocalizations.of(
              context,
            ).translate('weakPassword');
            break;
          case 'invalid-email':
            errorMessage = AppLocalizations.of(
              context,
            ).translate('invalidEmail');
            break;
          default:
            errorMessage = AppLocalizations.of(
              context,
            ).translate('registrationFailed');
        }
        setState(() {
          _emailError = errorMessage;
          _isLoading = false;
        });
      } catch (e) {
        print('Unexpected error during registration: $e');
        setState(() {
          _emailError = AppLocalizations.of(
            context,
          ).translate('registrationFailed');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localizations.translate('register'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  localizations.translate('signUp'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: localizations.translate('name'),
                    prefixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty
                              ? localizations.translate('enterName')
                              : null,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_emailError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          _emailError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('email'),
                        prefixIcon: const Icon(Icons.email),
                        border: const OutlineInputBorder(),
                        errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                      ),
                      onChanged: _validateEmail,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return localizations.translate('enterEmail');
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: localizations.translate('password'),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed:
                          () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty
                              ? localizations.translate('enterPassword')
                              : null,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(localizations.translate('register')),
                    ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: Text(localizations.translate('login')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
