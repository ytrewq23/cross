import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../localizations.dart';
import '../orientation_support.dart';
import 'offline_service.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  _CreateJobScreenState createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _salaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _contactInfoController = TextEditingController();
  String? _selectedCategory;
  String? _selectedCity;
  String? _selectedSchedule;
  String? _selectedEmploymentType;
  bool _isLoading = false;

  final List<String> _categories = [
    'ИТ',
    'Маркетинг',
    'Продажи',
    'Дизайн',
    'HR',
    'Финансы',
  ];
  final List<String> _cities = [
    'Алматы',
    'Астана',
    'Шымкент',
    'Караганда',
    'Актобе',
    'Другое',
  ];
  final List<String> _schedules = [
    'Полный день',
    'Удаленная работа',
    'Гибкий график',
  ];
  final List<String> _employmentTypes = [
    'Полная занятость',
    'Частичная занятость',
    'Проектная работа',
    'Стажировка',
  ];

  Future<void> _createJob() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('userNotAuthenticated'),
          ),
        ),
      );
      return;
    }

    final jobData = {
      'title': _titleController.text.trim(),
      'company': _companyController.text.trim(),
      'category': _selectedCategory,
      'salary': _salaryController.text.trim(),
      'city': _selectedCity,
      'schedule': _selectedSchedule,
      'employmentType': _selectedEmploymentType,
      'description': _descriptionController.text.trim(),
      'requirements': _requirementsController.text.trim(),
      'contactInfo': _contactInfoController.text.trim(),
      'employerId': user.uid,
      'views': 0,
      'createdAt': FieldValue.serverTimestamp(),
    };

    setState(() => _isLoading = true);
    try {
      if (!await OfflineService().checkConnection()) {
        await OfflineService().saveJobOffline(jobData, 'create');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('jobSavedOffline'),
              ),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final docRef = await FirebaseFirestore.instance.collection('jobs').add(jobData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('jobCreatedSuccess'),
              ),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error creating job: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating job: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isOffline = !OfflineService().isOnline;

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
    final isOffline = !OfflineService().isOnline;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('createJob')),
        centerTitle: true,
        backgroundColor: isOffline ? Colors.red : null,
        actions: isOffline
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Text(
                      localizations.translate('connectToInternet'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: localizations.translate('jobTitle'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty
                        ? localizations.translate('enterJobTitle')
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: InputDecoration(
                  labelText: localizations.translate('company'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty
                        ? localizations.translate('enterCompany')
                        : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: localizations.translate('category'),
                  border: const OutlineInputBorder(),
                ),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) =>
                    value == null
                        ? localizations.translate('selectCategory')
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salaryController,
                decoration: InputDecoration(
                  labelText: localizations.translate('salary'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty
                        ? localizations.translate('enterSalary')
                        : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: InputDecoration(
                  labelText: localizations.translate('city'),
                  border: const OutlineInputBorder(),
                ),
                items: _cities
                    .map(
                      (city) => DropdownMenuItem(value: city, child: Text(city)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedCity = value),
                validator: (value) =>
                    value == null
                        ? localizations.translate('selectCity')
                        : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSchedule,
                decoration: InputDecoration(
                  labelText: localizations.translate('schedule'),
                  border: const OutlineInputBorder(),
                ),
                items: _schedules
                    .map(
                      (schedule) => DropdownMenuItem(
                        value: schedule,
                        child: Text(schedule),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedSchedule = value),
                validator: (value) =>
                    value == null
                        ? localizations.translate('selectSchedule')
                        : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedEmploymentType,
                decoration: InputDecoration(
                  labelText: localizations.translate('employmentType'),
                  border: const OutlineInputBorder(),
                ),
                items: _employmentTypes
                    .map(
                      (type) => DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedEmploymentType = value),
                validator: (value) =>
                    value == null
                        ? localizations.translate('selectEmploymentType')
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: localizations.translate('description'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) =>
                    value!.isEmpty
                        ? localizations.translate('enterDescription')
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _requirementsController,
                decoration: InputDecoration(
                  labelText: localizations.translate('requirements'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) =>
                    value!.isEmpty
                        ? localizations.translate('enterRequirements')
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactInfoController,
                decoration: InputDecoration(
                  labelText: localizations.translate('contactInfo'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty
                        ? localizations.translate('enterContactInfo')
                        : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _createJob,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Text(localizations.translate('createJob')),
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
    final isOffline = !OfflineService().isOnline;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('createJob')),
        centerTitle: true,
        backgroundColor: isOffline ? Colors.red : null,
        actions: isOffline
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Text(
                      localizations.translate('connectToInternet'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ]
            : null,
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
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('jobTitle'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty
                              ? localizations.translate('enterJobTitle')
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _companyController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('company'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty
                              ? localizations.translate('enterCompany')
                              : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: localizations.translate('category'),
                        border: const OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value),
                      validator: (value) =>
                          value == null
                              ? localizations.translate('selectCategory')
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _salaryController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('salary'),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty
                              ? localizations.translate('enterSalary')
                              : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: InputDecoration(
                        labelText: localizations.translate('city'),
                        border: const OutlineInputBorder(),
                      ),
                      items: _cities
                          .map(
                            (city) =>
                                DropdownMenuItem(value: city, child: Text(city)),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _selectedCity = value),
                      validator: (value) =>
                          value == null
                              ? localizations.translate('selectCity')
                              : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSchedule,
                      decoration: InputDecoration(
                        labelText: localizations.translate('schedule'),
                        border: const OutlineInputBorder(),
                      ),
                      items: _schedules
                          .map(
                            (schedule) => DropdownMenuItem(
                              value: schedule,
                              child: Text(schedule),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedSchedule = value),
                      validator: (value) =>
                          value == null
                              ? localizations.translate('selectSchedule')
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
                    DropdownButtonFormField<String>(
                      value: _selectedEmploymentType,
                      decoration: InputDecoration(
                        labelText: localizations.translate('employmentType'),
                        border: const OutlineInputBorder(),
                      ),
                      items: _employmentTypes
                          .map(
                            (type) =>
                                DropdownMenuItem(value: type, child: Text(type)),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedEmploymentType = value),
                      validator: (value) =>
                          value == null
                              ? localizations.translate('selectEmploymentType')
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('description'),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      validator: (value) =>
                          value!.isEmpty
                              ? localizations.translate('enterDescription')
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _requirementsController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('requirements'),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      validator: (value) =>
                          value!.isEmpty
                              ? localizations.translate('enterRequirements')
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactInfoController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('contactInfo'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty
                              ? localizations.translate('enterContactInfo')
                              : null,
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _createJob,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: Text(localizations.translate('createJob')),
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