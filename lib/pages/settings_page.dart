import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/theme_language_provider.dart';
import 'login_page.dart';
import 'about_page.dart';
import 'help_page.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeLanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(
              'Dark Theme',
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
              'User Settings',
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
              'Notification Settings',
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
              'Language',
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
              'Favourites',
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
              'About the App',
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
                  SnackBar(content: Text('Failed to open About page')),
                );
              });
            },
          ),
          Divider(),
          ListTile(
            title: Text(
              'Help',
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
                  SnackBar(content: Text('Failed to open Help page')),
                );
              });
            },
          ),
          Divider(),
          ListTile(
            title: Text(
              'Logout',
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
    final prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user');
    if (userJson != null) {
      Map<String, dynamic> userMap = jsonDecode(userJson);
      userMap['name'] = _nameController.text;
      await prefs.setString('user', jsonEncode(userMap));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Name updated successfully')));
    }
  }

  void _updatePassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', _passwordController.text);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Password updated successfully')));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Settings', style: TextStyle(color: Colors.white)),
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
                labelText: 'New Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _updateName,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
              ),
              child: Text('Update Name'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'New Password',
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
              ),
              child: Text('Update Password'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SwitchListTile(
          title: Text('Enable Sound'),
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
  String _selectedLanguage = 'Русский';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'Русский';
    });
  }

  Future<void> _saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
  }

  void _onLanguageChanged(String? language) {
    if (language != null) {
      setState(() {
        _selectedLanguage = language;
      });
      _saveLanguage(language);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Language Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RadioListTile<String>(
              title: Text('Қазақша'),
              value: 'Қазақша',
              groupValue: _selectedLanguage,
              onChanged: _onLanguageChanged,
            ),
            RadioListTile<String>(
              title: Text('Русский'),
              value: 'Русский',
              groupValue: _selectedLanguage,
              onChanged: _onLanguageChanged,
            ),
            RadioListTile<String>(
              title: Text('English'),
              value: 'English',
              groupValue: _selectedLanguage,
              onChanged: _onLanguageChanged,
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Favourites', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Favourites settings will be implemented here.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
