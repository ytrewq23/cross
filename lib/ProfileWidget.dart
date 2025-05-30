import 'package:flutter/material.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({Key? key}) : super(key: key);

  @override
  _ProfileWidgetState createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  bool isDarkMode = false;
  String language = 'en';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Toggle Theme'),
              value: isDarkMode,
              onChanged: (value) {
                setState(() {
                  isDarkMode = value;
                });
              },
            ),
            DropdownButton<String>(
              key: const Key('language_dropdown'), // Add key for reliable testing
              value: language,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ru', child: Text('Русский')),
                DropdownMenuItem(value: 'kk', child: Text('Қазақша')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    language = value;
                  });
                }
              },
              hint: const Text('Select Language'),
            ),
            Text('Selected Language: $language'), // Display selected language
          ],
        ),
      ),
    );
  }
}