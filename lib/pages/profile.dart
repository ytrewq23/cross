import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = '';
  String _email = '';
  String _password = '';
  bool _showPassword = false;

  // Получаем данные из SharedPreferences
  void _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user');
    String? savedPassword = prefs.getString('password');

    if (userJson != null && savedPassword != null) {
      Map<String, dynamic> userMap = jsonDecode(userJson);
      User user = User.fromJson(userMap);
      setState(() {
        _name = user.name;
        _email = user.email;
        _password = savedPassword;
      });
    }
  }

  // Функция для выхода из аккаунта
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('password');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _getUserData(); // Загружаем данные пользователя при старте
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: $_name', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Email: $_email', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text(
              'Password: ${_showPassword ? _password : '*' * _password.length}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blue,
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.blue),
              ),
              child: Text(_showPassword ? 'Hide Password' : 'Show Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              onPressed: _logout,
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
