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
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
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
      child: Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        appBar: AppBar(
          title: FadeInDown(
            duration: Duration(milliseconds: 600),
            child: Text(
              localizations.translate('createJob'),
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
        body: Padding(
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
                child: ListView(
                  children: [
                    FadeInLeft(
                      duration: Duration(milliseconds: 700),
                      child: TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: localizations.translate('jobTitle'),
                          prefixIcon: Icon(IconlyLight.bookmark, color: Color(0xFFF4A261)),
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
                      duration: Duration(milliseconds: 800),
                      child: TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: localizations.translate('description'),
                          prefixIcon: Icon(IconlyLight.document, color: Color(0xFFF4A261)),
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
                      duration: Duration(milliseconds: 900),
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          labelText: localizations.translate('category'),
                          prefixIcon: Icon(IconlyLight.category, color: Color(0xFFF4A261)),
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
                      duration: Duration(milliseconds: 1000),
                      child: TextFormField(
                        controller: _salaryController,
                        decoration: InputDecoration(
                          labelText: localizations.translate('salary'),
                          prefixIcon: Icon(IconlyLight.wallet, color: Color(0xFFF4A261)),
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
                      duration: Duration(milliseconds: 1100),
                      child: TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: localizations.translate('city'),
                          prefixIcon: Icon(IconlyLight.location, color: Color(0xFFF4A261)),
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
                      duration: Duration(milliseconds: 1200),
                      child: DropdownButtonFormField<String>(
                        value: _schedule,
                        decoration: InputDecoration(
                          labelText: localizations.translate('schedule'),
                          prefixIcon: Icon(IconlyLight.time_circle, color: Color(0xFFF4A261)),
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
                      duration: Duration(milliseconds: 1300),
                      child: DropdownButtonFormField<String>(
                        value: _employmentType,
                        decoration: InputDecoration(
                          labelText: localizations.translate('employmentType'),
                          prefixIcon: Icon(IconlyLight.work, color: Color(0xFFF4A261)),
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
                      duration: Duration(milliseconds: 1400),
                      child: TextFormField(
                        controller: _requirementsController,
                        decoration: InputDecoration(
                          labelText: localizations.translate('requirements'),
                          prefixIcon: Icon(IconlyLight.chart, color: Color(0xFFF4A261)),
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
                      duration: Duration(milliseconds: 1500),
                      child: TextFormField(
                        controller: _contactInfoController,
                        decoration: InputDecoration(
                          labelText: localizations.translate('contactInfo'),
                          prefixIcon: Icon(IconlyLight.call, color: Color(0xFFF4A261)),
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
                      duration: Duration(milliseconds: 1600),
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: Text(localizations.translate('save')),
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