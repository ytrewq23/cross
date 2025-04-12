import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home.dart';
import 'dart:convert';

void main() {
  runApp(JobRecruitmentApp());
}

class JobRecruitmentApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Recruitment Platform',
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: TextTheme(
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
      home: FutureBuilder<String?>(
        future: checkLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          } else if (snapshot.hasData && snapshot.data != null) {
            return HomeScreen(
              userName: snapshot.data!,
            ); // Если авторизован, показываем главный экран
          } else {
            return LoginPage(); // Если не авторизован, показываем экран логина
          }
        },
      ),
    );
  }

  Future<String?> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user');

    if (userJson != null) {
      Map<String, dynamic> userMap = jsonDecode(userJson);
      User user = User.fromJson(userMap);
      return user.name;
    }
    return null;
  }
}
