import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconly/iconly.dart';
import '../localizations.dart';

class HelpPage extends StatefulWidget {
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
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF2A9D8F),
            ),
          );
          _subjectController.clear();
          _messageController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.translate('messageFailed'),
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${localizations.translate('error')}: $e',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
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
    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
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
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF6B7280)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFF4A261), width: 2),
          ),
          labelStyle: TextStyle(color: Color(0xFF6B7280)),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.redAccent, width: 2),
          ),
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
              localizations.translate('help'),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          backgroundColor: Color(0xFF2A9D8F),
          centerTitle: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          elevation: 4,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
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
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(
                      duration: Duration(milliseconds: 700),
                      child: Text(
                        localizations.translate('contactSupportTitle'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF264653),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInDown(
                      duration: Duration(milliseconds: 800),
                      child: Text(
                        localizations.translate('supportDescription'),
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInLeft(
                      duration: Duration(milliseconds: 900),
                      child: TextFormField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          labelText: localizations.translate('subject'),
                          prefixIcon: Icon(IconlyLight.paper, color: Color(0xFFF4A261)),
                        ),
                        validator: (value) =>
                        value!.isEmpty ? localizations.translate('enterSubject') : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInLeft(
                      duration: Duration(milliseconds: 1000),
                      child: TextFormField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          labelText: localizations.translate('message'),
                          prefixIcon: Icon(IconlyLight.message, color: Color(0xFFF4A261)),
                        ),
                        maxLines: 5,
                        validator: (value) =>
                        value!.isEmpty ? localizations.translate('enterMessage') : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_userEmail != null)
                      FadeInLeft(
                        duration: Duration(milliseconds: 1100),
                        child: Text(
                          '${localizations.translate('yourEmail')}: $_userEmail',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2A9D8F),
                      ),
                    )
                        : ZoomIn(
                      duration: Duration(milliseconds: 1200),
                      child: ElevatedButton(
                        onPressed: _sendEmail,
                        child: Text(localizations.translate('sendMessage')),
                      ),
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