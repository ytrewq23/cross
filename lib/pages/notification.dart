import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconly/iconly.dart';
import '../localizations.dart';
import 'offline_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<String> notifications = [
    'Welcome to the app!',
    'Your profile was updated.',
    'New message received.',
    'Reminder: Meeting at 5 PM.',
    'Your report is ready to view.',
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isOffline = !OfflineService().isOnline;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Text(
            localizations.translate('notifications'),
            style: theme.appBarTheme.titleTextStyle,
          ),
        ),
        centerTitle: true,
        backgroundColor: isOffline ? theme.colorScheme.error : theme.appBarTheme.backgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        flexibleSpace: isOffline
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.error.withOpacity(0.3),
                      theme.colorScheme.error.withOpacity(0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Center(
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 700),
                    child: Text(
                      localizations.translate('connectToInternet'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return FadeInLeft(
            duration: Duration(milliseconds: 800 + index * 100),
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
                child: ListTile(
                  leading: Icon(
                    IconlyLight.notification,
                    color: theme.colorScheme.secondary,
                    size: 30,
                  ),
                  title: Text(
                    notifications[index],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    // Add interaction logic if needed (e.g., navigate to details)
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}