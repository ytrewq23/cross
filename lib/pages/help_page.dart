import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import 'package:iconly/iconly.dart';
import '../localizations.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  _HelpPageState createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _userEmail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user');
    if (userJson != null) {
      Map<String, dynamic> userMap = jsonDecode(userJson);
      setState(() {
        _userEmail = userMap['email'];
      });
    }
  }

  Future<void> _sendEmail() async {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final serviceId = 'service_5073rm2';
      final templateId = 'template_iggr0om';
      final userId = 'NoInnSdze2Ouzhru9';

      final fullMessage = '''
${_messageController.text}

---
User Email: ${_userEmail ?? 'unknown'}
''';

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'service_id': serviceId,
            'template_id': templateId,
            'user_id': userId,
            'template_params': {
              'subject': _subjectController.text,
              'message': fullMessage,
            },
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.translate('messageSent'),
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
          _subjectController.clear();
          _messageController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.translate('messageFailed'),
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${localizations.translate('error')}: $e',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Text(
            localizations.translate('help'),
            style: theme.appBarTheme.titleTextStyle,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: theme.cardColor,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: theme.brightness == Brightness.dark
                    ? [const Color(0xFF2A2F33), const Color(0xFF1C2526)]
                    : [const Color(0xFFF8FAFC), const Color(0xFFE6ECEF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 700),
                    child: Text(
                      localizations.translate('contactSupportTitle'),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInDown(
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      localizations.translate('supportDescription'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 900),
                    child: TextFormField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('subject'),
                        prefixIcon: Icon(IconlyLight.paper, color: theme.colorScheme.secondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? localizations.translate('enterSubject') : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 1000),
                    child: TextFormField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('message'),
                        prefixIcon: Icon(IconlyLight.message, color: theme.colorScheme.secondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                        ),
                      ),
                      maxLines: 5,
                      validator: (value) =>
                          value!.isEmpty ? localizations.translate('enterMessage') : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_userEmail != null)
                    FadeInLeft(
                      duration: const Duration(milliseconds: 1100),
                      child: Text(
                        '${localizations.translate('yourEmail')}: $_userEmail',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : ZoomIn(
                          duration: const Duration(milliseconds: 1200),
                          child: ElevatedButton(
                            onPressed: _sendEmail,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(localizations.translate('sendMessage')),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}