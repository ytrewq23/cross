import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconly/iconly.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _emailError;
  bool _isOnline = true;
  int _currentPage = 0;
  bool _usePinLogin = false;
  bool _hasPin = false;

  static const _emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initializeOfflineService();
    _checkPinAvailability();
  }

  Future<void> _initializeOfflineService() async {
    await OfflineService().init();
    if (mounted) {
      setState(() {
        _isOnline = OfflineService().isOnline;
      });
    }
    Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() {
          _isOnline = results.any(
            (result) =>
                result == ConnectivityResult.wifi ||
                result == ConnectivityResult.mobile,
          );
        });
      }
    });
  }

  Future<void> _checkPinAvailability() async {
    final hasPin = await OfflineService().hasPin();
    if (mounted) {
      setState(() {
        _hasPin = hasPin;
        _usePinLogin = hasPin;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      if (value.isEmpty) {
        _emailError = AppLocalizations.of(context).translate('enterEmail');
      } else if (!RegExp(_emailRegex).hasMatch(value)) {
        _emailError = AppLocalizations.of(context).translate('invalidEmail');
      } else {
        _emailError = null;
      }
    });
  }

  void _loginWithEmail() async {
    if (!mounted) return;

    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (_formKey.currentState!.validate() && _emailError == null) {
      if (_passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate('passwordTooShort'),
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        return;
      }

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
        final userCredential = await FirebaseAuth.instance
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
            content: Text(
              errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: theme.colorScheme.error,
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
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _loginWithPin() async {
    if (!mounted) return;

    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (_pinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.translate('enter4DigitPin'),
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isValidPin = await OfflineService().validatePin(
        _pinController.text,
      );
      if (!isValidPin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.translate('invalidPin'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final userId = await OfflineService().getPinUserId();
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.translate('pinNotAssociated'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      if (_isOnline) {
        final user = await FirebaseAuth.instance.authStateChanges().firstWhere(
          (user) => user != null && user.uid == userId,
          orElse: () => null,
        );
        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  localizations.translate('userNotFound'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => HomeScreen(
                    userName: user.displayName ?? user.email ?? '',
                  ),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(userName: 'Offline User'),
            ),
          );
        }
      }
    } catch (e) {
      print('Error during PIN login: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate('pinLoginFailed'),
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
      setState(() => _isLoading = false);
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
      MaterialPageRoute(
        builder: (context) => const HomeScreen(userName: 'Guest'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final onboardingPages = [
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work, size: 100, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              localizations.translate('startYourJobSearch'),
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('beginJourney'),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 100, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              localizations.translate('createProfile'),
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('standOut'),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 100, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              localizations.translate('findOpportunities'),
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('matchSkills'),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Text(
            localizations.translate('login'),
            style: theme.appBarTheme.titleTextStyle,
          ),
        ),
        centerTitle: true,
        backgroundColor:
            _isOnline ? theme.colorScheme.primary : theme.colorScheme.error,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        elevation: 4,
        flexibleSpace:
            !_isOnline
                ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.error.withOpacity(0.3),
                        theme.colorScheme.error.withOpacity(0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 700),
                      child: Text(
                        localizations.translate('connectToInternet'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                : null,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            color: theme.cardColor,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      theme.brightness == Brightness.dark
                          ? [theme.cardColor, theme.cardColor.darken(0.1)]
                          : [theme.cardColor, theme.cardColor.darken(0.05)],
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
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  height: 8,
                                  width: _currentPage == index ? 24 : 8,
                                  decoration: BoxDecoration(
                                    color:
                                        _currentPage == index
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface
                                                .withOpacity(0.5),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: Text(
                        localizations.translate('welcomeBack'),
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_hasPin)
                      FadeIn(
                        duration: const Duration(milliseconds: 900),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              localizations.translate('loginWith'),
                              style: theme.textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _usePinLogin = !_usePinLogin;
                                  _emailController.clear();
                                  _passwordController.clear();
                                  _pinController.clear();
                                  _emailError = null;
                                });
                              },
                              child: Text(
                                _usePinLogin
                                    ? localizations.translate('email')
                                    : localizations.translate('pin'),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (!_usePinLogin) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_emailError != null)
                            FadeIn(
                              duration: const Duration(milliseconds: 900),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  _emailError!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
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
                                prefixIcon: Icon(
                                  IconlyLight.message,
                                  color: theme.colorScheme.primary,
                                ),
                                hintText: 'example@domain.com',
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
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
                      const SizedBox(height: 16),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 1100),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: localizations.translate('password'),
                            prefixIcon: Icon(
                              IconlyLight.lock,
                              color: theme.colorScheme.primary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? IconlyLight.show
                                    : IconlyLight.hide,
                                color: theme.colorScheme.primary,
                              ),
                              onPressed:
                                  () => setState(
                                    () =>
                                        _isPasswordVisible =
                                            !_isPasswordVisible,
                                  ),
                            ),
                            hintText: '••••••••',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? localizations.translate('enterPassword')
                                      : null,
                        ),
                      ),
                    ] else ...[
                      FadeInLeft(
                        duration: const Duration(milliseconds: 1000),
                        child: TextFormField(
                          controller: _pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          decoration: InputDecoration(
                            labelText: localizations.translate('pinCode'),
                            prefixIcon: Icon(
                              IconlyLight.lock,
                              color: theme.colorScheme.primary,
                            ),
                            hintText: '1234',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          validator:
                              (value) =>
                                  value!.length != 4
                                      ? localizations.translate(
                                        'enter4DigitPin',
                                      )
                                      : null,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        )
                        : Column(
                          children: [
                            ZoomIn(
                              duration: const Duration(milliseconds: 1300),
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : _usePinLogin
                                        ? _loginWithPin
                                        : _loginWithEmail,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(localizations.translate('login')),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FadeInLeft(
                              duration: const Duration(milliseconds: 1400),
                              child: TextButton(
                                onPressed: _navigateToRegister,
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.secondary,
                                ),
                                child: Text(
                                  localizations.translate('dontHaveAccount'),
                                  style: theme.textTheme.labelLarge,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ZoomIn(
                              duration: const Duration(milliseconds: 1500),
                              child: OutlinedButton(
                                onPressed: _continueAsGuest,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: theme.colorScheme.primary,
                                  ),
                                  foregroundColor: theme.colorScheme.primary,
                                ),
                                child: Text(
                                  localizations.translate('continueAsGuest'),
                                  style: theme.textTheme.labelLarge,
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
    );
  }
}

extension ColorExtension on Color {
  Color darken([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
