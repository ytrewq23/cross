import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_page.dart';
import 'about_page.dart';
import 'help_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = '';
  String _email = '';
  List<Map<String, String>> _resumes = [];
  String _status = 'Активно ищу работу';
  final List<String> _statuses = [
    'Активно ищу работу',
    'Нашел работу',
    'Не ищу работу',
  ];
  String? _avatarBase64;
  bool _isVerified = false;

  static const String _placeholderAvatar = 'assets/avatar_placeholder.jpg';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    final resumesJson = prefs.getString('resumes');
    final avatar = prefs.getString('avatar');

    if (userJson != null) {
      final user = User.fromJson(jsonDecode(userJson));
      _name = user.name;
      _email = user.email;
    }
    if (resumesJson != null) {
      _resumes = List<Map<String, String>>.from(jsonDecode(resumesJson));
    }
    _avatarBase64 = avatar;
    setState(() {
      if (_avatarBase64 != null) {
        _isVerified = true;
      }
    });
  }

  Future<void> _saveAvatar(String base64Image) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar', base64Image);
  }

  void _pickImage() {
    html.window.navigator.mediaDevices
        ?.getUserMedia({'video': true})
        .then((stream) {
          final videoTrack = stream.getVideoTracks().first;
          final videoElement =
              html.VideoElement()
                ..autoplay = true
                ..srcObject = stream;

          videoElement.play();

          videoElement.onLoadedData.listen((event) {
            final canvas = html.CanvasElement(width: 640, height: 480);
            final context = canvas.context2D;
            context.drawImage(videoElement, 0, 0);

            final base64Image = canvas.toDataUrl('image/png');
            _saveAvatar(base64Image);
            setState(() {
              _avatarBase64 = base64Image;
              _isVerified = true;
            });

            videoTrack.stop();
          });
        })
        .catchError((e) {
          print("Ошибка доступа к камере: $e");
        });
  }

  void _deleteAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('avatar');
    setState(() {
      _avatarBase64 = null;
      _isVerified = false;
    });
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Профиль'), centerTitle: true),
      endDrawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Text('About the App'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutPage()),
                );
              },
            ),
            ListTile(
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
            ListTile(
              title: Text('Help'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HelpPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        _avatarBase64 != null
                            ? NetworkImage(_avatarBase64!)
                            : AssetImage(_placeholderAvatar) as ImageProvider,
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _isVerified ? null : _pickImage,
                    child: Text(
                      _isVerified ? 'Верифицировано' : 'Верифицировать себя',
                    ),
                    style: _buttonStyle(),
                  ),
                  if (_isVerified)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ElevatedButton(
                        onPressed: _deleteAvatar,
                        child: Text('Удалить фото'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_name, style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 8),
                  Text(
                    _email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  SizedBox(height: 20),
                  DropdownButton<String>(
                    value: _status,
                    icon: Icon(Icons.arrow_drop_down),
                    items:
                        _statuses.map((String status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _status = newValue!;
                      });
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Мое резюме:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 10),
                  if (_resumes.isEmpty)
                    Text('Нет добавленных резюме.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _resumes.length,
                      itemBuilder: (context, index) {
                        final resume = _resumes[index];
                        return ListTile(
                          title: Text(resume['profession']!),
                          subtitle: Text('Создано: ${resume['date']}'),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () => _deleteResume(index),
                          ),
                        );
                      },
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('Создать новое резюме'),
                    style: _buttonStyle(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteResume(int index) {
    setState(() => _resumes.removeAt(index));
    _saveResumes();
  }

  Future<void> _saveResumes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('resumes', jsonEncode(_resumes));
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
