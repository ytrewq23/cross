import 'package:flutter/material.dart';
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
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('createJob')),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: localizations.translate('jobTitle'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.translate('enterJobTitle');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: localizations.translate('description'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.translate('enterDescription');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: localizations.translate('category'),
                  border: const OutlineInputBorder(),
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
              const SizedBox(height: 10),
              TextFormField(
                controller: _salaryController,
                decoration: InputDecoration(
                  labelText: localizations.translate('salary'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.translate('enterSalary');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: localizations.translate('city'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.translate('enterCity');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _schedule,
                decoration: InputDecoration(
                  labelText: localizations.translate('schedule'),
                  border: const OutlineInputBorder(),
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
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _employmentType,
                decoration: InputDecoration(
                  labelText: localizations.translate('employmentType'),
                  border: const OutlineInputBorder(),
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
              const SizedBox(height: 10),
              TextFormField(
                controller: _requirementsController,
                decoration: InputDecoration(
                  labelText: localizations.translate('requirements'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.translate('enterRequirements');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _contactInfoController,
                decoration: InputDecoration(
                  labelText: localizations.translate('contactInfo'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.translate('enterContactInfo');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(localizations.translate('save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}