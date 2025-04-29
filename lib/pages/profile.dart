import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_page.dart';
import 'about_page.dart';
import 'help_page.dart';
import '../localizations.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = '';
  String _email = '';
  List<Map<String, String>> _resumes = [];
  String _status = 'statusActive'; // Храним ключ перевода
  final List<String> _statuses = [
    'statusActive',
    'statusFound',
    'statusNotLooking',
  ]; // Ключи переводов для статусов
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
    final resumesJson = prefs.getString('resumes');
    final avatar = prefs.getString('avatar');
    final savedStatus = prefs.getString('status');

    // Load user data from FirebaseAuth
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _name = user.displayName ?? 'No Name';
        _email = user.email ?? 'No Email';
      });
    }

    if (resumesJson != null) {
      _resumes = List<Map<String, String>>.from(jsonDecode(resumesJson));
    }
    if (savedStatus != null && _statuses.contains(savedStatus)) {
      _status = savedStatus;
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

  Future<void> _saveStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('status', status);
  }

  Future<void> _pickImage() async {
    try {
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': true,
      });
      if (stream == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось получить доступ к камере')),
        );
        return;
      }

      final videoElement =
          html.VideoElement()
            ..autoplay = true
            ..srcObject = stream;

      await videoElement.play();

      await showDialog(
        context: context,
        builder:
            (dialogCtx) => AlertDialog(
              title: Text('Сделать фото'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Камера активна. Нажмите, чтобы сделать снимок.'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final canvas = html.CanvasElement(
                        width: videoElement.videoWidth,
                        height: videoElement.videoHeight,
                      );
                      final ctx = canvas.context2D;
                      ctx.drawImage(videoElement, 0, 0);

                      final base64Image = canvas.toDataUrl('image/png');
                      await _saveAvatar(base64Image);

                      setState(() {
                        _avatarBase64 = base64Image;
                        _isVerified = true;
                      });

                      stream.getTracks().forEach((track) => track.stop());
                      Navigator.of(
                        dialogCtx,
                        rootNavigator: true,
                      ).pop(); // Закрываем правильно
                    },
                    child: Text('Снять'),
                    style: _buttonStyle(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    stream.getTracks().forEach((track) => track.stop());
                    Navigator.of(dialogCtx, rootNavigator: true).pop();
                  },
                  child: Text('Отмена'),
                ),
              ],
            ),
      );
    } catch (e) {
      print("Ошибка доступа к камере: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка доступа к камере: $e')));
    }
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
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('profile')),
        centerTitle: true,
      ),
      endDrawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Text(localizations.translate('aboutTheApp')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AboutPage()),
                );
              },
            ),
            ListTile(
              title: Text(localizations.translate('settings')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsPage()),
                );
              },
            ),
            ListTile(
              title: Text(localizations.translate('help')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HelpPage()),
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
                  ClipOval(
                    child:
                        _avatarBase64 != null
                            ? Image.memory(
                              base64Decode(_avatarBase64!.split(',').last),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            )
                            : Image.asset(
                              _placeholderAvatar,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _isVerified ? null : _pickImage,
                    child: Text(
                      _isVerified
                          ? localizations.translate('verified')
                          : localizations.translate('verifyYourself'),
                    ),
                    style: _buttonStyle(),
                  ),
                  if (_isVerified)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ElevatedButton(
                        onPressed: _deleteAvatar,
                        child: Text(localizations.translate('deletePhoto')),
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
                    isExpanded: true,
                    items:
                        _statuses.map((String statusKey) {
                          return DropdownMenuItem<String>(
                            value: statusKey,
                            child: Text(localizations.translate(statusKey)),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _status = newValue;
                        });
                        _saveStatus(newValue);
                      }
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
                    localizations.translate('myResume'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 10),
                  if (_resumes.isEmpty)
                    Text(localizations.translate('noResumes'))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _resumes.length,
                      itemBuilder: (context, index) {
                        final resume = _resumes[index];
                        return ListTile(
                          title: Text(resume['profession']!),
                          subtitle: Text(
                            '${localizations.translate('created')}: ${resume['date']}',
                          ),
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
                    onPressed: () {
                      // Логика для создания резюме
                    },
                    child: Text(localizations.translate('createResume')),
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
