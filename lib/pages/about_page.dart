import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconly/iconly.dart';
import '../localizations.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
            localizations.translate('aboutTheApp'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: Text(
                localizations.translate('appTitle'),
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            FadeInDown(
              duration: const Duration(milliseconds: 900),
              child: Text(
                localizations.translate('version'),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            FadeInLeft(
              duration: const Duration(milliseconds: 1000),
              child: Text(
                localizations.translate('aboutUs'),
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            FadeInLeft(
              duration: const Duration(milliseconds: 1100),
              child: Text(
                localizations.translate('aboutDescription'),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            FadeInLeft(
              duration: const Duration(milliseconds: 1200),
              child: Text(
                localizations.translate('features'),
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            ZoomIn(
              duration: const Duration(milliseconds: 1300),
              child: _buildFeatureItem(
                context,
                icon: IconlyLight.search,
                title: localizations.translate('jobSearch'),
                description: localizations.translate('jobSearchDescription'),
              ),
            ),
            ZoomIn(
              duration: const Duration(milliseconds: 1400),
              child: _buildFeatureItem(
                context,
                icon: IconlyLight.profile,
                title: localizations.translate('profileManagement'),
                description: localizations.translate('profileManagementDescription'),
              ),
            ),
            ZoomIn(
              duration: const Duration(milliseconds: 1500),
              child: _buildFeatureItem(
                context,
                icon: IconlyLight.notification,
                title: localizations.translate('notificationsFeature'),
                description: localizations.translate('notificationsDescription'),
              ),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              duration: const Duration(milliseconds: 1600),
              child: Center(
                child: Text(
                  localizations.translate('copyright'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ],
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
    final theme = Theme.of(context);

    return Card(
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ZoomIn(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 30,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}