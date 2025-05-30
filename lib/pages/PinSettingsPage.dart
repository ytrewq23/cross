import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconly/iconly.dart';
import '../localizations.dart';
import 'offline_service.dart';

class PinSettingsPage extends StatefulWidget {
  const PinSettingsPage({super.key});

  @override
  _PinSettingsPageState createState() => _PinSettingsPageState();
}

class _PinSettingsPageState extends State<PinSettingsPage> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPinVisible = false;
  bool _isConfirmPinVisible = false;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    final hasPin = await OfflineService().hasPin();
    if (mounted) {
      setState(() {
        _hasPin = hasPin;
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _setPin() async {
    final localizations = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.translate('loginRequired'),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    try {
      await OfflineService().savePin(_pinController.text, user.uid);
      if (mounted) {
        setState(() => _hasPin = true);
        _pinController.clear();
        _confirmPinController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate('pinSetSuccess'),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF2A9D8F),
          ),
        );
      }
    } catch (e) {
      print('Error setting PIN: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate('failedToSetPin'),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removePin() async {
    final localizations = AppLocalizations.of(context);
    try {
      await OfflineService().removePin();
      if (mounted) {
        setState(() => _hasPin = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate('pinRemovedSuccessfully'),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF2A9D8F),
          ),
        );
      }
    } catch (e) {
      print('Error removing PIN: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate('failedToRemovePin'),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2A9D8F),
          secondary: Color(0xFFF4A261),
          surface: Color(0xFFF8FAFC),
          onSurface: Color(0xFF264653),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF6B7280)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF6B7280)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF2A9D8F), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.redAccent, width: 2),
          ),
          labelStyle: TextStyle(color: Color(0xFF6B7280)),
          prefixIconColor: Color(0xFF2A9D8F),
          suffixIconColor: Color(0xFF2A9D8F),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A9D8F),
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Text(
              localizations.translate('pinSettings'),
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
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_hasPin) ...[
                  FadeInLeft(
                    duration: const Duration(milliseconds: 800),
                    child: TextFormField(
                      controller: _pinController,
                      obscureText: !_isPinVisible,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: InputDecoration(
                        labelText: localizations.translate('newPin'),
                        prefixIcon: const Icon(IconlyLight.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPinVisible ? IconlyLight.show : IconlyLight.hide,
                            color: const Color(0xFF2A9D8F),
                          ),
                          onPressed: () => setState(() => _isPinVisible = !_isPinVisible),
                        ),
                        hintText: '1234',
                        hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                      validator: (value) {
                        if (value == null || value.length != 4) {
                          return localizations.translate('enter4DigitPin');
                        }
                        if (value != _confirmPinController.text) {
                          return localizations.translate('pinsDontMatch');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 900),
                    child: TextFormField(
                      controller: _confirmPinController,
                      obscureText: !_isConfirmPinVisible,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: InputDecoration(
                        labelText: localizations.translate('confirmPin'),
                        prefixIcon: const Icon(IconlyLight.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPinVisible ? IconlyLight.show : IconlyLight.hide,
                            color: const Color(0xFF2A9D8F),
                          ),
                          onPressed: () => setState(() => _isConfirmPinVisible = !_isConfirmPinVisible),
                        ),
                        hintText: '1234',
                        hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                      validator: (value) {
                        if (value == null || value.length != 4) {
                          return localizations.translate('enter4DigitPin');
                        }
                        if (value != _pinController.text) {
                          return localizations.translate('pinsDontMatch');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ZoomIn(
                    duration: const Duration(milliseconds: 1000),
                    child: ElevatedButton(
                      onPressed: _setPin,
                      child: Text(localizations.translate('setPin')),
                    ),
                  ),
                ] else ...[
                  FadeInLeft(
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      localizations.translate('pinIsSet'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF264653),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ZoomIn(
                    duration: const Duration(milliseconds: 900),
                    child: ElevatedButton(
                      onPressed: _removePin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(localizations.translate('removePin')),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
