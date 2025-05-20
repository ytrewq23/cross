import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconly/iconly.dart';
import '../localizations.dart';

class AboutPage extends StatelessWidget {
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
              localizations.translate('aboutTheApp'),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                duration: Duration(milliseconds: 800),
                child: Text(
                  localizations.translate('appTitle'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF264653),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 16),
              FadeInDown(
                duration: Duration(milliseconds: 900),
                child: Text(
                  localizations.translate('version'),
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24),
              FadeInLeft(
                duration: Duration(milliseconds: 1000),
                child: Text(
                  localizations.translate('aboutUs'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF264653),
                  ),
                ),
              ),
              SizedBox(height: 8),
              FadeInLeft(
                duration: Duration(milliseconds: 1100),
                child: Text(
                  localizations.translate('aboutDescription'),
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              SizedBox(height: 24),
              FadeInLeft(
                duration: Duration(milliseconds: 1200),
                child: Text(
                  localizations.translate('features'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF264653),
                  ),
                ),
              ),
              SizedBox(height: 8),
              ZoomIn(
                duration: Duration(milliseconds: 1300),
                child: _buildFeatureItem(
                  context,
                  icon: IconlyLight.search,
                  title: localizations.translate('jobSearch'),
                  description: localizations.translate('jobSearchDescription'),
                ),
              ),
              ZoomIn(
                duration: Duration(milliseconds: 1400),
                child: _buildFeatureItem(
                  context,
                  icon: IconlyLight.profile,
                  title: localizations.translate('profileManagement'),
                  description: localizations.translate('profileManagementDescription'),
                ),
              ),
              ZoomIn(
                duration: Duration(milliseconds: 1500),
                child: _buildFeatureItem(
                  context,
                  icon: IconlyLight.notification,
                  title: localizations.translate('notificationsFeature'),
                  description: localizations.translate('notificationsDescription'),
                ),
              ),
              SizedBox(height: 24),
              FadeInUp(
                duration: Duration(milliseconds: 1600),
                child: Center(
                  child: Text(
                    localizations.translate('copyright'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
      }) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ZoomIn(
                duration: Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  size: 30,
                  color: Color(0xFFF4A261),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF264653),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
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