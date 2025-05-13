import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../localizations.dart';
import '../orientation_support.dart';

class EditJobScreen extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic> jobData;

  const EditJobScreen({super.key, required this.jobId, required this.jobData});

  @override
  _EditJobScreenState createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _salaryController;
  late TextEditingController _descriptionController;
  late TextEditingController _requirementsController;
  late TextEditingController _contactInfoController;
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.jobData['title'] ?? '');
    _companyController = TextEditingController(text: widget.jobData['company'] ?? '');
    _salaryController = TextEditingController(text: widget.jobData['salary'] ?? '');
    _descriptionController = TextEditingController(text: widget.jobData['description'] ?? '');
    _requirementsController = TextEditingController(text: widget.jobData['requirements'] ?? '');
    _contactInfoController = TextEditingController(text: widget.jobData['contactInfo'] ?? '');
    _selectedCategory = widget.jobData['category'];
    _selectedCity = widget.jobData['city'];
    _selectedSchedule = widget.jobData['schedule'];
    _selectedEmploymentType = widget.jobData['employmentType'];
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

  Future<void> _updateJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .update({
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
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('jobUpdatedSuccess'),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error updating job: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating job: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      minimumSize: const Size(double.infinity, 48),
    );
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
        title: Text(localizations.translate('editJob')),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                    const SizedBox(height: 16),
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
                    ElevatedButton(
                      onPressed: _updateJob,
                      style: _buttonStyle(),
                      child: Text(localizations.translate('saveChanges')),
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
        title: Text(localizations.translate('editJob')),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                                  (city) => DropdownMenuItem(
                                    value: city,
                                    child: Text(city),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedCity = value),
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
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedEmploymentType = value),
                            validator: (value) =>
                                value == null
                                    ? localizations.translate(
                                        'selectEmploymentType')
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
                          ElevatedButton(
                            onPressed: _updateJob,
                            style: _buttonStyle(),
                            child: Text(localizations.translate('saveChanges')),
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