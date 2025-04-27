import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/theme_language_provider.dart';
import 'login_page.dart';
import 'about_page.dart';
import 'help_page.dart';
import '../localizations.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeLanguageProvider>(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.translate('settings'),
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(
              localizations.translate('darkTheme'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),
          Divider(),
          ListTile(
            title: Text(
              localizations.translate('userSettings'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              print('Navigating to UserSettingsPage'); // Debug log
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserSettingsPage()),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text(
              localizations.translate('notificationSettings'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              print('Navigating to NotificationSettingsPage'); // Debug log
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationSettingsPage(),
                ),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text(
              localizations.translate('language'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              print('Navigating to LanguageSettingsPage'); // Debug log
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LanguageSettingsPage()),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text(
              localizations.translate('favourites'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              print('Navigating to FavouritesPage'); // Debug log
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FavouritesPage()),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text(
              localizations.translate('aboutTheApp'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              print('Navigating to AboutPage'); // Debug log
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutPage()),
              ).catchError((e) {
                print('Error navigating to AboutPage: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localizations.translate('failedToOpenAbout')),
                  ),
                );
              });
            },
          ),
          Divider(),
          ListTile(
            title: Text(
              localizations.translate('help'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              print('Navigating to HelpPage'); // Debug log
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HelpPage()),
              ).catchError((e) {
                print('Error navigating to HelpPage: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localizations.translate('failedToOpenHelp')),
                  ),
                );
              });
            },
          ),
          Divider(),
          ListTile(
            title: Text(
              localizations.translate('logout'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            onTap: () async {
              print('Logging out'); // Debug log
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user');
              await prefs.remove('password');
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

// User Settings Page
class UserSettingsPage extends StatefulWidget {
  @override
  _UserSettingsPageState createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _updateName() async {
    final localizations = AppLocalizations.of(context);
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.translate('enterName'))),
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
        SnackBar(content: Text(localizations.translate('nameUpdated'))),
      );
    }
  }

  void _updatePassword() async {
    final localizations = AppLocalizations.of(context);
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.translate('enterPassword'))),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', _passwordController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.translate('passwordUpdated'))),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.translate('userSettings'),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: localizations.translate('newName'),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _updateName,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(localizations.translate('updateName')),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: localizations.translate('newPassword'),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _updatePassword,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(localizations.translate('updatePassword')),
            ),
          ],
        ),
      ),
    );
  }
}

// Notification Settings Page
class NotificationSettingsPage extends StatefulWidget {
  @override
  _NotificationSettingsPageState createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.translate('notificationSettings'),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SwitchListTile(
          title: Text(localizations.translate('enableSound')),
          value: _soundEnabled,
          onChanged: (value) {
            setState(() {
              _soundEnabled = value;
            });
          },
        ),
      ),
    );
  }
}

// Language Settings Page
class LanguageSettingsPage extends StatefulWidget {
  @override
  _LanguageSettingsPageState createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeLanguageProvider>(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.translate('language'),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RadioListTile<String>(
              title: Text(localizations.translate('languageKazakh')),
              value: localizations.translate('languageKazakh'),
              groupValue: themeProvider.language,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setLanguage(value);
                }
              },
            ),
            RadioListTile<String>(
              title: Text(localizations.translate('languageRussian')),
              value: localizations.translate('languageRussian'),
              groupValue: themeProvider.language,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setLanguage(value);
                }
              },
            ),
            RadioListTile<String>(
              title: Text(localizations.translate('languageEnglish')),
              value: localizations.translate('languageEnglish'),
              groupValue: themeProvider.language,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setLanguage(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Favourites Page
class FavouritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.translate('favourites'),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          localizations.translate('favouritesPlaceholder'),
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
