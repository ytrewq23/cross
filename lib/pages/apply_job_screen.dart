import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error submitting application: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting application: $e')),
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
    return withOrientationSupport(
      context: context,
      portrait: _buildPortraitLayout(context, localizations),
      landscape: _buildLandscapeLayout(context, localizations),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('applyForJob')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${localizations.translate('jobTitle')}: ${widget.jobTitle}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _coverLetterController,
                decoration: InputDecoration(
                  labelText: localizations.translate('coverLetter'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) =>
                    value!.isEmpty
                        ? localizations.translate('enterCoverLetter')
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _resumeLinkController,
                decoration: InputDecoration(
                  labelText: localizations.translate('resumeLink'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value!.isNotEmpty &&
                      !Uri.tryParse(value)!.hasAbsolutePath) {
                    return localizations.translate('invalidUrl');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitApplication,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Text(localizations.translate('submitApplication')),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('applyForJob')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                    Text(
                      '${localizations.translate('jobTitle')}: ${widget.jobTitle}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _coverLetterController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('coverLetter'),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      validator: (value) =>
                          value!.isEmpty
                              ? localizations.translate('enterCoverLetter')
                              : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _resumeLinkController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('resumeLink'),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value!.isNotEmpty &&
                            !Uri.tryParse(value)!.hasAbsolutePath) {
                          return localizations.translate('invalidUrl');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _submitApplication,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child:
                                Text(localizations.translate('submitApplication')),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}