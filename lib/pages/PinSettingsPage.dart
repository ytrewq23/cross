import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PinSettingsPage extends StatefulWidget {
  const PinSettingsPage({super.key});

  @override
  _PinSettingsPageState createState() => _PinSettingsPageState();
}

class _PinSettingsPageState extends State<PinSettingsPage> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String? _currentPin;

  @override
  void initState() {
    super.initState();
    _loadCurrentPin();
  }

  Future<void> _loadCurrentPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentPin = prefs.getString('offline_pin');
    });
  }

  Future<void> _setPin() async {
    final localizations = AppLocalizations.of(context);
    if (_pinController.text.length != 4 || !_pinController.text.isValidPin()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate('invalidPin')),
        ),
      );
      return;
    }
    if (_pinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate('pinsDoNotMatch')),
        ),
      );
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('offline_pin', _pinController.text);
      await prefs.setString('offline_user_id', FirebaseAuth.instance.currentUser!.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _currentPin == null
                  ? localizations.translate('pinSetSuccess')
                  : localizations.translate('pinUpdatedSuccess'),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error setting PIN: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('pinSetFailed')),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentPin == null
              ? localizations.translate('setPin')
              : localizations.translate('updatePin'),
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('enterNewPin'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pinController,
              decoration: InputDecoration(
                labelText: localizations.translate('pin'),
                border: const OutlineInputBorder(),
                counterText: '',
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPinController,
              decoration: InputDecoration(
                labelText: localizations.translate('confirmPin'),
                border: const OutlineInputBorder(),
                counterText: '',
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _setPin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _currentPin == null
                    ? localizations.translate('setPin')
                    : localizations.translate('updatePin'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension PinValidation on String {
  bool isValidPin() => RegExp(r'^\d{4}$').hasMatch(this);
}