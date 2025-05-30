import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconly/iconly.dart';
import 'login_page.dart';
import 'about_page.dart';
import 'help_page.dart';
import 'PinSettingsPage.dart';
import '../localizations.dart';
import '../theme_language_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeLanguageProvider>(context);
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Text(
            localizations.translate('settings'),
            style: theme.appBarTheme.titleTextStyle,
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: ListView(
        children: [
          FadeInLeft(
            duration: const Duration(milliseconds: 800),
            child: _buildCard(
              child: SwitchListTile(
                title: Text(
                  localizations.translate('darkTheme'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
                activeColor: theme.colorScheme.primary,
                secondary: Icon(
                  IconlyLight.star,
                  color: theme.colorScheme.secondary,
                ),
              ),
              theme: theme,
            ),
          ),
          Divider(color: theme.dividerColor),
          FadeInLeft(
            duration: const Duration(milliseconds: 900),
            child: _buildCard(
              child: ListTile(
                title: Text(
                  localizations.translate('userSettings'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  IconlyLight.arrow_right_2,
                  color: theme.colorScheme.secondary,
                ),
                onTap:
                    () => _navigateTo(
                      context,
                      const UserSettingsPage(),
                      'UserSettingsPage',
                      localizations,
                      theme,
                    ),
              ),
              theme: theme,
            ),
          ),
          Divider(color: theme.dividerColor),
          FadeInLeft(
            duration: const Duration(milliseconds: 1000),
            child: _buildCard(
              child: ListTile(
                title: Text(
                  localizations.translate('notificationSettings'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  IconlyLight.arrow_right_2,
                  color: theme.colorScheme.secondary,
                ),
                onTap:
                    () => _navigateTo(
                      context,
                      const NotificationSettingsPage(),
                      'NotificationSettingsPage',
                      localizations,
                      theme,
                    ),
              ),
              theme: theme,
            ),
          ),
          Divider(color: theme.dividerColor),
          FadeInLeft(
            duration: const Duration(milliseconds: 1100),
            child: _buildCard(
              child: ListTile(
                title: Text(
                  localizations.translate('language'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  IconlyLight.arrow_right_2,
                  color: theme.colorScheme.secondary,
                ),
                onTap:
                    () => _navigateTo(
                      context,
                      const LanguageSettingsPage(),
                      'LanguageSettingsPage',
                      localizations,
                      theme,
                    ),
              ),
              theme: theme,
            ),
          ),
          Divider(color: theme.dividerColor),
          FadeInLeft(
            duration: const Duration(milliseconds: 1200),
            child: _buildCard(
              child: ListTile(
                title: Text(
                  localizations.translate('favourites'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  IconlyLight.arrow_right_2,
                  color: theme.colorScheme.secondary,
                ),
                onTap:
                    () => _navigateTo(
                      context,
                      const FavouritesPage(),
                      'FavouritesPage',
                      localizations,
                      theme,
                    ),
              ),
              theme: theme,
            ),
          ),
          Divider(color: theme.dividerColor),
          FadeInLeft(
            duration: const Duration(milliseconds: 1300),
            child: _buildCard(
              child: ListTile(
                title: Text(
                  localizations.translate('aboutTheApp'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  IconlyLight.arrow_right_2,
                  color: theme.colorScheme.secondary,
                ),
                onTap:
                    () => _navigateTo(
                      context,
                      const AboutPage(),
                      'AboutPage',
                      localizations,
                      theme,
                    ),
              ),
              theme: theme,
            ),
          ),
          Divider(color: theme.dividerColor),
          FadeInLeft(
            duration: const Duration(milliseconds: 1400),
            child: _buildCard(
              child: ListTile(
                title: Text(
                  localizations.translate('help'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  IconlyLight.arrow_right_2,
                  color: theme.colorScheme.secondary,
                ),
                onTap:
                    () => _navigateTo(
                      context,
                      const HelpPage(),
                      'HelpPage',
                      localizations,
                      theme,
                    ),
              ),
              theme: theme,
            ),
          ),
          Divider(color: theme.dividerColor),
          FadeInLeft(
            duration: const Duration(milliseconds: 1500),
            child: _buildCard(
              child: ListTile(
                title: Text(
                  localizations.translate('pinSettings'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  IconlyLight.arrow_right_2,
                  color: theme.colorScheme.secondary,
                ),
                onTap:
                    () => _navigateTo(
                      context,
                      const PinSettingsPage(),
                      'PinSettingsPage',
                      localizations,
                      theme,
                    ),
              ),
              theme: theme,
            ),
          ),
          Divider(color: theme.dividerColor),
          FadeInLeft(
            duration: const Duration(milliseconds: 1600),
            child: _buildCard(
              child: ListTile(
                title: Text(
                  localizations.translate('logout'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
                trailing: Icon(
                  IconlyLight.logout,
                  color: theme.colorScheme.error,
                ),
                onTap: () => _showLogoutDialog(context, localizations, theme),
              ),
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, required ThemeData theme}) {
    return Card(
      color: theme.cardColor,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                theme.brightness == Brightness.dark
                    ? [const Color(0xFF2A2F33), const Color(0xFF1C2526)]
                    : [const Color(0xFFF8FAFC), const Color(0xFFE6ECEF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }

  void _navigateTo(
    BuildContext context,
    Widget page,
    String pageName,
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    print('Navigating to $pageName');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    ).catchError((e) {
      print('Error navigating to $pageName: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.translate('failedToOpen$pageName') ??
                'Failed to open $pageName',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    });
  }

  void _showLogoutDialog(
    BuildContext context,
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Text(
                localizations.translate('confirmLogout'),
                style: theme.textTheme.titleLarge,
              ),
            ),
            content: FadeInLeft(
              duration: const Duration(milliseconds: 700),
              child: Text(
                localizations.translate('confirmLogoutMessage'),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            actions: [
              ZoomIn(
                duration: const Duration(milliseconds: 800),
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.secondary,
                  ),
                  child: Text(
                    localizations.translate('cancel'),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ),
              ZoomIn(
                duration: const Duration(milliseconds: 900),
                child: TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    print('Logging out');
                    try {
                      await FirebaseAuth.instance.signOut();
                      print('Firebase sign out successful');
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('user');
                      await prefs.remove('password');
                      await prefs.remove('resumes');
                      await prefs.remove('avatar');
                      await prefs.remove('status');
                      await prefs.remove('offline_pin');
                      await prefs.remove('offline_user_id');
                      print('SharedPreferences cleared');
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      print('Error during logout: $e');
                      if (context.mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              localizations.translate('logoutFailed') ??
                                  'Failed to log out',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: theme.colorScheme.error,
                          ),
                        );
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  child: Text(
                    localizations.translate('logout'),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({super.key});

  @override
  _UserSettingsPageState createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      setState(() {
        _nameController.text = user.displayName ?? '';
      });
    }
  }

  Future<void> _updateName() async {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.translate('enterName'),
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(_nameController.text);
        final prefs = await SharedPreferences.getInstance();
        String? userJson = prefs.getString('user');
        Map<String, dynamic> userMap =
            userJson != null ? jsonDecode(userJson) : {};
        userMap['name'] = _nameController.text;
        await prefs.setString('user', jsonEncode(userMap));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.translate('nameUpdated'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      print('Error updating name: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate('failedToUpdateName'),
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _updatePassword() async {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.translate('passwordTooShort'),
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(_passwordController.text);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('password', _passwordController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.translate('passwordUpdated'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      print('Error updating password: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate('failedToUpdatePassword'),
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
            localizations.translate('userSettings'),
            style: theme.appBarTheme.titleTextStyle,
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInLeft(
              duration: const Duration(milliseconds: 800),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: localizations.translate('newName'),
                  prefixIcon: Icon(
                    IconlyLight.profile,
                    color: theme.colorScheme.primary,
                  ),
                  hintText: 'John Doe',
                  hintStyle: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  border: theme.inputDecorationTheme.border,
                  enabledBorder: theme.inputDecorationTheme.enabledBorder,
                  focusedBorder: theme.inputDecorationTheme.focusedBorder,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ZoomIn(
              duration: const Duration(milliseconds: 900),
              child: ElevatedButton(
                onPressed: _updateName,
                child: Text(localizations.translate('updateName')),
              ),
            ),
            const SizedBox(height: 20),
            FadeInLeft(
              duration: const Duration(milliseconds: 1000),
              child: TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: localizations.translate('newPassword'),
                  prefixIcon: Icon(
                    IconlyLight.lock,
                    color: theme.colorScheme.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? IconlyLight.show : IconlyLight.hide,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed:
                        () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        ),
                  ),
                  hintText: '••••••••',
                  hintStyle: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  border: theme.inputDecorationTheme.border,
                  enabledBorder: theme.inputDecorationTheme.enabledBorder,
                  focusedBorder: theme.inputDecorationTheme.focusedBorder,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ZoomIn(
              duration: const Duration(milliseconds: 1100),
              child: ElevatedButton(
                onPressed: _updatePassword,
                child: Text(localizations.translate('updatePassword')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  _NotificationSettingsPageState createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _soundEnabled = true;

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
            localizations.translate('notificationSettings'),
            style: theme.appBarTheme.titleTextStyle,
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FadeInLeft(
          duration: const Duration(milliseconds: 800),
          child: Card(
            color: theme.cardColor,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      theme.brightness == Brightness.dark
                          ? [const Color(0xFF2A2F33), const Color(0xFF1C2526)]
                          : [const Color(0xFFF8FAFC), const Color(0xFFE6ECEF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: Text(
                  localizations.translate('enableSound'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() {
                    _soundEnabled = value;
                  });
                },
                activeColor: theme.colorScheme.primary,
                secondary: Icon(
                  IconlyLight.notification,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  _LanguageSettingsPageState createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeLanguageProvider>(context);
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Text(
            localizations.translate('language'),
            style: theme.appBarTheme.titleTextStyle,
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: theme.cardColor,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    theme.brightness == Brightness.dark
                        ? [const Color(0xFF2A2F33), const Color(0xFF1C2526)]
                        : [const Color(0xFFF8FAFC), const Color(0xFFE6ECEF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeInLeft(
                  duration: const Duration(milliseconds: 800),
                  child: RadioListTile<String>(
                    title: Text(
                      localizations.translate('languageKazakh'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: 'kk',
                    groupValue: themeProvider.language,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setLanguage(value);
                      }
                    },
                    activeColor: theme.colorScheme.primary,
                    secondary: Icon(
                      IconlyLight.bookmark,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                FadeInLeft(
                  duration: const Duration(milliseconds: 900),
                  child: RadioListTile<String>(
                    title: Text(
                      localizations.translate('languageRussian'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: 'ru',
                    groupValue: themeProvider.language,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setLanguage(value);
                      }
                    },
                    activeColor: theme.colorScheme.primary,
                    secondary: Icon(
                      IconlyLight.bookmark,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                FadeInLeft(
                  duration: const Duration(milliseconds: 1000),
                  child: RadioListTile<String>(
                    title: Text(
                      localizations.translate('languageEnglish'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: 'en',
                    groupValue: themeProvider.language,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setLanguage(value);
                      }
                    },
                    activeColor: theme.colorScheme.primary,
                    secondary: Icon(
                      IconlyLight.bookmark,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

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
            localizations.translate('favourites'),
            style: theme.appBarTheme.titleTextStyle,
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FadeInLeft(
          duration: const Duration(milliseconds: 800),
          child: Card(
            color: theme.cardColor,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      theme.brightness == Brightness.dark
                          ? [const Color(0xFF2A2F33), const Color(0xFF1C2526)]
                          : [const Color(0xFFF8FAFC), const Color(0xFFE6ECEF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Text(
                localizations.translate('favouritesPlaceholder'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
