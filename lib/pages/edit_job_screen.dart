import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconly/iconly.dart';
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
    'categoryIT',
    'categoryMarketing',
    'categorySales',
    'categoryDesign',
    'categoryHR',
    'categoryFinance',
  ];
  final List<String> _cities = [
    'cityAlmaty',
    'cityAstana',
    'cityShymkent',
    'cityKaraganda',
    'cityAktobe',
    'cityOther',
  ];
  final List<String> _schedules = [
    'scheduleFullTime',
    'scheduleRemote',
    'scheduleFlexible',
  ];
  final List<String> _employmentTypes = [
    'employmentFull',
    'employmentPart',
    'employmentProject',
    'employmentInternship',
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
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF2A9D8F),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error updating job: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating job: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      child: withOrientationSupport(
        context: context,
        portrait: _buildPortraitLayout(context, localizations),
        landscape: _buildLandscapeLayout(context, localizations),
      ),
    );
  }

  Widget _buildPortraitLayout(
      BuildContext context,
      AppLocalizations localizations,
      ) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: FadeInDown(
          duration: Duration(milliseconds: 600),
          child: Text(
            localizations.translate('editJob'),
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF2A9D8F)))
          : SingleChildScrollView(
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
                  FadeInLeft(
                    duration: Duration(milliseconds: 700),
                    child: TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('jobTitle'),
                        prefixIcon: Icon(IconlyLight.bookmark, color: Color(0xFFF4A261)),
                      ),
                      validator: (value) =>
                      value!.isEmpty
                          ? localizations.translate('enterJobTitle')
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInLeft(
                    duration: Duration(milliseconds: 800),
                    child: TextFormField(
                      controller: _companyController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('company'),
                        prefixIcon: Icon(IconlyLight.work, color: Color(0xFFF4A261)),
                      ),
                      validator: (value) =>
                      value!.isEmpty
                          ? localizations.translate('enterCompany')
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInLeft(
                    duration: Duration(milliseconds: 900),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: localizations.translate('category'),
                        prefixIcon: Icon(IconlyLight.category, color: Color(0xFFF4A261)),
                      ),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                          value: category,
                          child: Text(localizations.translate(category)),
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
                  ),
                  const SizedBox(height: 16),
                  FadeInLeft(
                    duration: Duration(milliseconds: 1000),
                    child: TextFormField(
                      controller: _salaryController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('salary'),
                        prefixIcon: Icon(IconlyLight.wallet, color: Color(0xFFF4A261)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                      value!.isEmpty
                          ? localizations.translate('enterSalary')
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInLeft(
                    duration: Duration(milliseconds: 1100),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: InputDecoration(
                        labelText: localizations.translate('city'),
                        prefixIcon: Icon(IconlyLight.location, color: Color(0xFFF4A261)),
                      ),
                      items: _cities
                          .map(
                            (city) => DropdownMenuItem(
                          value: city,
                          child: Text(localizations.translate(city)),
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
                  ),
                  const SizedBox(height: 16),
                  FadeInLeft(
                    duration: Duration(milliseconds: 1200),
                    child: DropdownButtonFormField<String>(
                      value: _selectedSchedule,
                      decoration: InputDecoration(
                        labelText: localizations.translate('schedule'),
                        prefixIcon: Icon(IconlyLight.time_circle, color: Color(0xFFF4A261)),
                      ),
                      items: _schedules
                          .map(
                            (schedule) => DropdownMenuItem(
                          value: schedule,
                          child: Text(localizations.translate(schedule)),
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
                  ),
                  const SizedBox(height: 16),
                  FadeInLeft(
                    duration: Duration(milliseconds: 1300),
                    child: DropdownButtonFormField<String>(
                      value: _selectedEmploymentType,
                      decoration: InputDecoration(
                        labelText: localizations.translate('employmentType'),
                        prefixIcon: Icon(IconlyLight.work, color: Color(0xFFF4A261)),
                      ),
                      items: _employmentTypes
                          .map(
                            (type) => DropdownMenuItem(
                          value: type,
                          child: Text(localizations.translate(type)),
                        ),
                      )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedEmploymentType = value),
                      validator: (value) =>
                      value == null
                          ? localizations.translate('selectEmploymentType')
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInLeft(
                    duration: Duration(milliseconds: 1400),
                    child: TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('description'),
                        prefixIcon: Icon(IconlyLight.document, color: Color(0xFFF4A261)),
                      ),
                      maxLines: 4,
                      validator: (value) =>
                      value!.isEmpty
                          ? localizations.translate('enterDescription')
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInLeft(
                    duration: Duration(milliseconds: 1500),
                    child: TextFormField(
                      controller: _requirementsController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('requirements'),
                        prefixIcon: Icon(IconlyLight.chart, color: Color(0xFFF4A261)),
                      ),
                      maxLines: 4,
                      validator: (value) =>
                      value!.isEmpty
                          ? localizations.translate('enterRequirements')
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInLeft(
                    duration: Duration(milliseconds: 1600),
                    child: TextFormField(
                      controller: _contactInfoController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('contactInfo'),
                        prefixIcon: Icon(IconlyLight.call, color: Color(0xFFF4A261)),
                      ),
                      validator: (value) =>
                      value!.isEmpty
                          ? localizations.translate('enterContactInfo')
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ZoomIn(
                    duration: Duration(milliseconds: 1700),
                    child: ElevatedButton(
                      onPressed: _updateJob,
                      child: Text(localizations.translate('saveChanges')),
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

  Widget _buildLandscapeLayout(
      BuildContext context,
      AppLocalizations localizations,
      ) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: FadeInDown(
          duration: Duration(milliseconds: 600),
          child: Text(
            localizations.translate('editJob'),
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF2A9D8F)))
          : SingleChildScrollView(
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInLeft(
                          duration: Duration(milliseconds: 700),
                          child: TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: localizations.translate('jobTitle'),
                              prefixIcon: Icon(IconlyLight.bookmark, color: Color(0xFFF4A261)),
                            ),
                            validator: (value) =>
                            value!.isEmpty
                                ? localizations.translate('enterJobTitle')
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInLeft(
                          duration: Duration(milliseconds: 800),
                          child: TextFormField(
                            controller: _companyController,
                            decoration: InputDecoration(
                              labelText: localizations.translate('company'),
                              prefixIcon: Icon(IconlyLight.work, color: Color(0xFFF4A261)),
                            ),
                            validator: (value) =>
                            value!.isEmpty
                                ? localizations.translate('enterCompany')
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInLeft(
                          duration: Duration(milliseconds: 900),
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: localizations.translate('category'),
                              prefixIcon: Icon(IconlyLight.category, color: Color(0xFFF4A261)),
                            ),
                            items: _categories
                                .map(
                                  (category) => DropdownMenuItem(
                                value: category,
                                child: Text(localizations.translate(category)),
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
                        ),
                        const SizedBox(height: 16),
                        FadeInLeft(
                          duration: Duration(milliseconds: 1000),
                          child: TextFormField(
                            controller: _salaryController,
                            decoration: InputDecoration(
                              labelText: localizations.translate('salary'),
                              prefixIcon: Icon(IconlyLight.wallet, color: Color(0xFFF4A261)),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                            value!.isEmpty
                                ? localizations.translate('enterSalary')
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInLeft(
                          duration: Duration(milliseconds: 1100),
                          child: DropdownButtonFormField<String>(
                            value: _selectedCity,
                            decoration: InputDecoration(
                              labelText: localizations.translate('city'),
                              prefixIcon: Icon(IconlyLight.location, color: Color(0xFFF4A261)),
                            ),
                            items: _cities
                                .map(
                                  (city) => DropdownMenuItem(
                                value: city,
                                child: Text(localizations.translate(city)),
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
                        ),
                        const SizedBox(height: 16),
                        FadeInLeft(
                          duration: Duration(milliseconds: 1200),
                          child: DropdownButtonFormField<String>(
                            value: _selectedSchedule,
                            decoration: InputDecoration(
                              labelText: localizations.translate('schedule'),
                              prefixIcon: Icon(IconlyLight.time_circle, color: Color(0xFFF4A261)),
                            ),
                            items: _schedules
                                .map(
                                  (schedule) => DropdownMenuItem(
                                value: schedule,
                                child: Text(localizations.translate(schedule)),
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
                          duration: Duration(milliseconds: 1300),
                          child: DropdownButtonFormField<String>(
                            value: _selectedEmploymentType,
                            decoration: InputDecoration(
                              labelText: localizations.translate('employmentType'),
                              prefixIcon: Icon(IconlyLight.work, color: Color(0xFFF4A261)),
                            ),
                            items: _employmentTypes
                                .map(
                                  (type) => DropdownMenuItem(
                                value: type,
                                child: Text(localizations.translate(type)),
                              ),
                            )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedEmploymentType = value),
                            validator: (value) =>
                            value == null
                                ? localizations.translate('selectEmploymentType')
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInLeft(
                          duration: Duration(milliseconds: 1400),
                          child: TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: localizations.translate('description'),
                              prefixIcon: Icon(IconlyLight.document, color: Color(0xFFF4A261)),
                            ),
                            maxLines: 4,
                            validator: (value) =>
                            value!.isEmpty
                                ? localizations.translate('enterDescription')
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInLeft(
                          duration: Duration(milliseconds: 1500),
                          child: TextFormField(
                            controller: _requirementsController,
                            decoration: InputDecoration(
                              labelText: localizations.translate('requirements'),
                              prefixIcon: Icon(IconlyLight.chart, color: Color(0xFFF4A261)),
                            ),
                            maxLines: 4,
                            validator: (value) =>
                            value!.isEmpty
                                ? localizations.translate('enterRequirements')
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInLeft(
                          duration: Duration(milliseconds: 1600),
                          child: TextFormField(
                            controller: _contactInfoController,
                            decoration: InputDecoration(
                              labelText: localizations.translate('contactInfo'),
                              prefixIcon: Icon(IconlyLight.call, color: Color(0xFFF4A261)),
                            ),
                            validator: (value) =>
                            value!.isEmpty
                                ? localizations.translate('enterContactInfo')
                                : null,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ZoomIn(
                          duration: Duration(milliseconds: 1700),
                          child: ElevatedButton(
                            onPressed: _updateJob,
                            child: Text(localizations.translate('saveChanges')),
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