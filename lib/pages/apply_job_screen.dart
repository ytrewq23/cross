import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconly/iconly.dart';
import '../localizations.dart';
import '../orientation_support.dart';

class ApplyJobScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const ApplyJobScreen({super.key, required this.jobId, required this.jobTitle});

  @override
  _ApplyJobScreenState createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  final _resumeLinkController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await FirebaseFirestore.instance.collection('applications').add({
        'jobId': widget.jobId,
        'jobTitle': widget.jobTitle,
        'applicantId': user.uid,
        'applicantEmail': user.email,
        'coverLetter': _coverLetterController.text.trim(),
        'resumeLink': _resumeLinkController.text.trim(),
        'submittedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('applicationSubmitted'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error submitting application: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error submitting application: $e',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    _resumeLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return withOrientationSupport(
      context: context,
      portrait: _buildPortraitLayout(context, localizations),
      landscape: _buildLandscapeLayout(context, localizations),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, AppLocalizations localizations) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Text(
            localizations.translate('applyForJob'),
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
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      '${localizations.translate('jobTitle')}: ${widget.jobTitle}',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 900),
                    child: TextFormField(
                      controller: _coverLetterController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('coverLetter'),
                        prefixIcon: Icon(IconlyLight.document, color: theme.colorScheme.secondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                        ),
                      ),
                      maxLines: 5,
                      validator: (value) =>
                          value!.isEmpty ? localizations.translate('enterCoverLetter') : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 1000),
                    child: TextFormField(
                      controller: _resumeLinkController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('resumeLink'),
                        prefixIcon: Icon(IconlyLight.upload, color: theme.colorScheme.secondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value!.isNotEmpty && !Uri.tryParse(value)!.hasAbsolutePath) {
                          return localizations.translate('invalidUrl');
                        }
                        return null;
                      },
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
                          duration: const Duration(milliseconds: 1100),
                          child: ElevatedButton(
                            onPressed: _submitApplication,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(localizations.translate('submitApplication')),
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

  Widget _buildLandscapeLayout(BuildContext context, AppLocalizations localizations) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Text(
            localizations.translate('applyForJob'),
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
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInDown(
                          duration: const Duration(milliseconds: 800),
                          child: Text(
                            '${localizations.translate('jobTitle')}: ${widget.jobTitle}',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInLeft(
                          duration: const Duration(milliseconds: 900),
                          child: TextFormField(
                            controller: _coverLetterController,
                            decoration: InputDecoration(
                              labelText: localizations.translate('coverLetter'),
                              prefixIcon: Icon(IconlyLight.document, color: theme.colorScheme.secondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                              ),
                            ),
                            maxLines: 5,
                            validator: (value) =>
                                value!.isEmpty ? localizations.translate('enterCoverLetter') : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInLeft(
                          duration: const Duration(milliseconds: 1000),
                          child: TextFormField(
                            controller: _resumeLinkController,
                            decoration: InputDecoration(
                              labelText: localizations.translate('resumeLink'),
                              prefixIcon: Icon(IconlyLight.upload, color: theme.colorScheme.secondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                              ),
                            ),
                            keyboardType: TextInputType.url,
                            validator: (value) {
                              if (value!.isNotEmpty && !Uri.tryParse(value)!.hasAbsolutePath) {
                                return localizations.translate('invalidUrl');
                              }
                              return null;
                            },
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
                                duration: const Duration(milliseconds: 1100),
                                child: ElevatedButton(
                                  onPressed: _submitApplication,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 48),
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(localizations.translate('submitApplication')),
                                ),
                              ),
                      ],
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