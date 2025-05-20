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

    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: const ColorScheme.light(
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
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6B7280)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6B7280)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A9D8F), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
          prefixIconColor: const Color(0xFF2A9D8F),
          suffixIconColor: const Color(0xFF2A9D8F),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A9D8F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Text(
              localizations.translate('settings'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF2A9D8F),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          elevation: 4,
        ),
        body: ListView(
          children: [
            FadeInLeft(
              duration: const Duration(milliseconds: 800),
              child: Card(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      localizations.translate('darkTheme'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF264653),
                      ),
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                    activeColor: const Color(0xFF2A9D8F),
                    secondary: const Icon(
                      IconlyLight.star,
                      color: Color(0xFFF4A261),
                    ),
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFFE6ECEF)),
            FadeInLeft(
              duration: const Duration(milliseconds: 900),
              child: Card(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      localizations.translate('userSettings'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF264653),
                      ),
                    ),
                    trailing: const Icon(
                      IconlyLight.arrow_right_2,
                      color: Color(0xFFF4A261),
                    ),
                    onTap: () {
                      print('Navigating to UserSettingsPage');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UserSettingsPage()),
                      );
                    },
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFFE6ECEF)),
            FadeInLeft(
              duration: const Duration(milliseconds: 1000),
              child: Card(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      localizations.translate('notificationSettings'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF264653),
                      ),
                    ),
                    trailing: const Icon(
                      IconlyLight.arrow_right_2,
                      color: Color(0xFFF4A261),
                    ),
                    onTap: () {
                      print('Navigating to NotificationSettingsPage');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationSettingsPage()),
                      );
                    },
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFFE6ECEF)),
            FadeInLeft(
              duration: const Duration(milliseconds: 1100),
              child: Card(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      localizations.translate('language'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF264653),
                      ),
                    ),
                    trailing: const Icon(
                      IconlyLight.arrow_right_2,
                      color: Color(0xFFF4A261),
                    ),
                    onTap: () {
                      print('Navigating to LanguageSettingsPage');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LanguageSettingsPage()),
                      );
                    },
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFFE6ECEF)),
            FadeInLeft(
              duration: const Duration(milliseconds: 1200),
              child: Card(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      localizations.translate('favourites'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF264653),
                      ),
                    ),
                    trailing: const Icon(
                      IconlyLight.arrow_right_2,
                      color: Color(0xFFF4A261),
                    ),
                    onTap: () {
                      print('Navigating to FavouritesPage');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FavouritesPage()),
                      );
                    },
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFFE6ECEF)),
            FadeInLeft(
              duration: const Duration(milliseconds: 1300),
              child: Card(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      localizations.translate('aboutTheApp'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF264653),
                      ),
                    ),
                    trailing: const Icon(
                      IconlyLight.arrow_right_2,
                      color: Color(0xFFF4A261),
                    ),
                    onTap: () {
                      print('Navigating to AboutPage');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AboutPage()),
                      ).catchError((e) {
                        print('Error navigating to AboutPage: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              localizations.translate('failedToOpenAbout'),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      });
                    },
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFFE6ECEF)),
            FadeInLeft(
              duration: const Duration(milliseconds: 1400),
              child: Card(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      localizations.translate('help'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF264653),
                      ),
                    ),
                    trailing: const Icon(
                      IconlyLight.arrow_right_2,
                      color: Color(0xFFF4A261),
                    ),
                    onTap: () {
                      print('Navigating to HelpPage');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HelpPage()),
                      ).catchError((e) {
                        print('Error navigating to HelpPage: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              localizations.translate('failedToOpenHelp'),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      });
                    },
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFFE6ECEF)),
            FadeInLeft(
              duration: const Duration(milliseconds: 1500),
              child: Card(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      localizations.translate('pinSettings'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF264653),
                      ),
                    ),
                    trailing: const Icon(
                      IconlyLight.arrow_right_2,
                      color: Color(0xFFF4A261),
                    ),
                    onTap: () {
                      print('Navigating to PinSettingsPage');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PinSettingsPage()),
                      );
                    },
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFFE6ECEF)),
            FadeInLeft(
              duration: const Duration(milliseconds: 1600),
              child: Card(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      localizations.translate('logout'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                    trailing: const Icon(
                      IconlyLight.logout,
                      color: Colors.redAccent,
                    ),
                    onTap: () {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: FadeInDown(
                            duration: const Duration(milliseconds: 600),
                            child: Text(
                              localizations.translate('confirmLogout'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF264653),
                              ),
                            ),
                          ),
                          content: FadeInLeft(
                            duration: const Duration(milliseconds: 700),
                            child: Text(
                              localizations.translate('confirmLogoutMessage'),
                              style: const TextStyle(color: Color(0xFF6B7280)),
                            ),
                          ),
                          actions: [
                            ZoomIn(
                              duration: const Duration(milliseconds: 800),
                              child: TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFF4A261),
                                ),
                                child: Text(
                                  localizations.translate('cancel'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                        MaterialPageRoute(builder: (context) => const LoginPage()),
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
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                ),
                                child: Text(
                                  localizations.translate('logout'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
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

  void _updateName() async {
    final localizations = AppLocalizations.of(context);
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.translate('enterName'),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user');
    if (userJson != null) {
      Map<String, dynamic> userMap = jsonDecode(userJson);
      userMap['name'] = _nameController.text;
      await prefs.setString('user', jsonEncode(userMap));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.translate('nameUpdated'),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2A9D8F),
        ),
      );
    }
  }

  void _updatePassword() async {
    final localizations = AppLocalizations.of(context);
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.translate('enterPassword'),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', _passwordController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localizations.translate('passwordUpdated'),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2A9D8F),
      ),
    );
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
    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2A9D8F),
          secondary: Color(0xFFF4A261),
          surface: Color(0xFFF8FAFC),
          onSurface: Color(0xFF264653),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6B7280)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6B7280)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A9D8F), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
          prefixIconColor: const Color(0xFF2A9D8F),
          suffixIconColor: const Color(0xFF2A9D8F),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A9D8F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Text(
              localizations.translate('userSettings'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF2A9D8F),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          elevation: 4,
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
                    prefixIcon: const Icon(IconlyLight.profile),
                    hintText: 'John Doe',
                    hintStyle: const TextStyle(color: Color(0xFF6B7280)),
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
                    prefixIcon: const Icon(IconlyLight.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? IconlyLight.show : IconlyLight.hide,
                        color: const Color(0xFF2A9D8F),
                      ),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    hintText: '••••••••',
                    hintStyle: const TextStyle(color: Color(0xFF6B7280)),
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
      ),
    );
  }
}

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  _NotificationSettingsPageState createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: const ColorScheme.light(
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
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Text(
              localizations.translate('notificationSettings'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF2A9D8F),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          elevation: 4,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: FadeInLeft(
            duration: const Duration(milliseconds: 800),
            child: Card(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text(
                    localizations.translate('enableSound'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF264653),
                    ),
                  ),
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                  },
                  activeColor: const Color(0xFF2A9D8F),
                  secondary: const Icon(
                    IconlyLight.notification,
                    color: Color(0xFFF4A261),
                  ),
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

    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: const ColorScheme.light(
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
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Text(
              localizations.translate('language'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF2A9D8F),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          elevation: 4,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF264653),
                        ),
                      ),
                      value: 'Қазақша',
                      groupValue: themeProvider.language,
                      onChanged: (value) {
                        if (value != null) {
                          themeProvider.setLanguage(value);
                        }
                      },
                      activeColor: const Color(0xFF2A9D8F),
                      secondary: const Icon(
                        IconlyLight.bookmark,
                        color: Color(0xFFF4A261),
                      ),
                    ),
                  ),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 900),
                    child: RadioListTile<String>(
                      title: Text(
                        localizations.translate('languageRussian'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF264653),
                        ),
                      ),
                      value: 'Русский',
                      groupValue: themeProvider.language,
                      onChanged: (value) {
                        if (value != null) {
                          themeProvider.setLanguage(value);
                        }
                      },
                      activeColor: const Color(0xFF2A9D8F),
                      secondary: const Icon(
                        IconlyLight.bookmark,
                        color: Color(0xFFF4A261),
                      ),
                    ),
                  ),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 1000),
                    child: RadioListTile<String>(
                      title: Text(
                        localizations.translate('languageEnglish'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF264653),
                        ),
                      ),
                      value: 'English',
                      groupValue: themeProvider.language,
                      onChanged: (value) {
                        if (value != null) {
                          themeProvider.setLanguage(value);
                        }
                      },
                      activeColor: const Color(0xFF2A9D8F),
                      secondary: const Icon(
                        IconlyLight.bookmark,
                        color: Color(0xFFF4A261),
                      ),
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

class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: const ColorScheme.light(
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
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Text(
              localizations.translate('favourites'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF2A9D8F),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          elevation: 4,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: FadeInLeft(
            duration: const Duration(milliseconds: 800),
            child: Card(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Text(
                  localizations.translate('favouritesPlaceholder'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}