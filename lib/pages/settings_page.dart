import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import 'about_page.dart';
import 'help_page.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.translate('settings'),
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(
              localizations.translate('darkTheme'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),
          const Divider(),
          ListTile(
            title: Text(
              localizations.translate('userSettings'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              print('Navigating to UserSettingsPage');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserSettingsPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: Text(
              localizations.translate('notificationSettings'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              print('Navigating to NotificationSettingsPage');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: Text(
              localizations.translate('language'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              print('Navigating to LanguageSettingsPage');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LanguageSettingsPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: Text(
              localizations.translate('favourites'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              print('Navigating to FavouritesPage');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavouritesPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: Text(
              localizations.translate('aboutTheApp'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              print('Navigating to AboutPage');
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
          const Divider(),
          ListTile(
            title: Text(
              localizations.translate('help'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              print('Navigating to HelpPage');
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
          const Divider(),
          ListTile(
            title: Text(
              localizations.translate('logout'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            onTap: () {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(localizations.translate('confirmLogout')),
                  content: Text(localizations.translate('confirmLogoutMessage')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(localizations.translate('cancel')),
                    ),
                    TextButton(
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
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(localizations.translate('logout')),
                    ),
                  ],
                ),
              );
            },
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
          style: const TextStyle(color: Colors.white),
        ),
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
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _updateName,
              child: Text(localizations.translate('updateName')),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: localizations.translate('newPassword'),
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _updatePassword,
              child: Text(localizations.translate('updatePassword')),
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
  _NotificationSettingsPageState createState() => _NotificationSettingsPageState();
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
          style: const TextStyle(color: Colors.white),
        ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.translate('language'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RadioListTile<String>(
              title: Text(localizations.translate('languageKazakh')),
              value: 'Қазақша',
              groupValue: themeProvider.language,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setLanguage(value);
                }
              },
            ),
            RadioListTile<String>(
              title: Text(localizations.translate('languageRussian')),
              value: 'Русский',
              groupValue: themeProvider.language,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setLanguage(value);
                }
              },
            ),
            RadioListTile<String>(
              title: Text(localizations.translate('languageEnglish')),
              value: 'English',
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

class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.translate('favourites'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          localizations.translate('favouritesPlaceholder'),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}