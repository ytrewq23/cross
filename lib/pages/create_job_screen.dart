import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconly/iconly.dart';
import '../localizations.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  _CreateJobScreenState createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _cityController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _contactInfoController = TextEditingController();
  String? _category;
  String? _schedule;
  String? _employmentType;

  final List<String> _categories = [
    'categoryIT',
    'categoryMarketing',
    'categorySales',
    'categoryDesign',
    'categoryHR',
    'categoryFinance',
  ];
  final List<String> _schedules = [
    'scheduleFullTime',
    'schedulePartTime',
    'scheduleRemote',
    'scheduleFlexible',
  ];
  final List<String> _employmentTypes = [
    'employmentFull',
    'employmentPart',
    'employmentContract',
    'employmentTemporary',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    _cityController.dispose();
    _requirementsController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final jobData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'salary': _salaryController.text,
        'city': _cityController.text,
        'category': _category!,
        'schedule': _schedule!,
        'employmentType': _employmentType!,
        'requirements': _requirementsController.text,
        'contactInfo': _contactInfoController.text,
      };
      Navigator.pop(context, jobData);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('fillAllFields'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
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
            localizations.translate('createJob'),
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
      body: Padding(
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
              child: ListView(
                children: [
                  FadeInLeft(
                    duration: const Duration(milliseconds: 700),
                    child: TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('jobTitle'),
                        prefixIcon: Icon(IconlyLight.bookmark, color: theme.colorScheme.secondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('enterJobTitle');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 800),
                    child: TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('description'),
                        prefixIcon: Icon(IconlyLight.document, color: theme.colorScheme.secondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                        ),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('enterDescription');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 900),
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: InputDecoration(
                        labelText: localizations.translate('category'),
                        prefixIcon: Icon(IconlyLight.category, color: theme.colorScheme.secondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                        ),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(localizations.translate(category)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _category = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return localizations.translate('selectCategory');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 1000),
                    child: TextFormField(
                      controller: _salaryController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('salary'),
                        prefixIcon: Icon(IconlyLight.wallet, color: theme.colorScheme.secondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('enterSalary');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 1100),
                    child: TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('city'),
                        prefixIcon: Icon(IconlyLight.location, color: theme.colorScheme.secondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('enterCity');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 1200),
                    child: DropdownButtonFormField<String>(
                      value: _schedule,
                      decoration: InputDecoration(
                        labelText: localizations.translate('schedule'),
                        prefixIcon: Icon(IconlyLight.time_circle, color: theme.colorScheme.secondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                        ),
                      ),
                      items: _schedules.map((schedule) {
                        return DropdownMenuItem(
                          value: schedule,
                          child: Text(localizations.translate(schedule)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _schedule = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return localizations.translate('selectSchedule');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 1300),
                    child: DropdownButtonFormField<String>(
                      value: _employmentType,
                      decoration: InputDecoration(
                        labelText: localizations.translate('employmentType'),
                        prefixIcon: Icon(IconlyLight.work, color: theme.colorScheme.secondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                        ),
                      ),
                      items: _employmentTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(localizations.translate(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _employmentType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return localizations.translate('selectEmploymentType');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 1400),
                    child: TextFormField(
                      controller: _requirementsController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('requirements'),
                        prefixIcon: Icon(IconlyLight.chart, color: theme.colorScheme.secondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                        ),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('enterRequirements');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 1500),
                    child: TextFormField(
                      controller: _contactInfoController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('contactInfo'),
                        prefixIcon: Icon(IconlyLight.call, color: theme.colorScheme.secondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('enterContactInfo');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ZoomIn(
                    duration: const Duration(milliseconds: 1600),
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(localizations.translate('save')),
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