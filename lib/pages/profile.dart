import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconly/iconly.dart';
import 'settings_page.dart';
import 'about_page.dart';
import 'help_page.dart';
import 'create_job_screen.dart';
import 'edit_job_screen.dart';
import 'role_selection_dialog.dart';
import '../localizations.dart';
import '../orientation_support.dart';
import 'offline_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = '';
  String _email = '';
  List<Map<String, dynamic>> _jobs = [];
  String _status = 'statusActive';
  final List<String> _statuses = [
    'statusActive',
    'statusFound',
    'statusNotLooking',
  ];
  String? _avatarBase64;
  bool _isVerified = false;
  String? _userRole;
  bool _isLoading = true;
  bool _isOnline = true;
  bool _hasPendingRequests = false;

  static const String _placeholderAvatar = 'assets/avatar_placeholder.jpg';

  @override
  void initState() {
    super.initState();
    _initializeOfflineService();
    _loadUserData();
  }

  Future<void> _initializeOfflineService() async {
    await OfflineService().init();
    setState(() {
      _isOnline = OfflineService().isOnline;
    });
    if (kIsWeb) {
      html.window.addEventListener('online', (_) {
        if (mounted) {
          setState(() => _isOnline = true);
          _handleReconnect();
        }
      });
      html.window.addEventListener('offline', (_) {
        if (mounted) {
          setState(() => _isOnline = false);
        }
      });
    } else {
      Connectivity().onConnectivityChanged.listen((results) {
        if (mounted) {
          final newOnline = results.any((result) => result != ConnectivityResult.none);
          setState(() => _isOnline = newOnline);
          if (newOnline && !_isOnline) {
            _handleReconnect();
          }
        }
      });
    }
  }

  Future<void> _handleReconnect() async {
    await OfflineService().syncAndNotify(context, () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('requestsProcessedSuccess'),
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF2A9D8F),
          ),
        );
        setState(() => _hasPendingRequests = false);
        _loadUserData();
      }
    });
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final avatar = prefs.getString('avatar');
    final savedStatus = prefs.getString('status');
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _name = 'No Name';
          _email = 'No Email';
          _userRole = '';
          _jobs = [];
          _avatarBase64 = avatar;
          _isVerified = avatar != null;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      if (_isOnline) {
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          final jobsSnapshot = await FirebaseFirestore.instance
              .collection('jobs')
              .where('employerId', isEqualTo: user.uid)
              .get();

          if (mounted) {
            setState(() {
              _name = user.displayName ?? prefs.getString('name') ?? 'No Name';
              _email = user.email ?? prefs.getString('email') ?? 'No Email';
              _userRole = userDoc.data()?['role'] as String? ?? prefs.getString('userRole') ?? '';
              _jobs = jobsSnapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
              if (savedStatus != null && _statuses.contains(savedStatus)) {
                _status = savedStatus;
              }
              _avatarBase64 = avatar;
              _isVerified = avatar != null;
              _isLoading = false;
            });
            await prefs.setString('name', _name);
            await prefs.setString('email', _email);
            await prefs.setString('userRole', _userRole ?? '');
            await OfflineService().saveJobsListOffline(_jobs);
          }
        } catch (e) {
          print('Firestore error: $e');
          final offlineJobs = await OfflineService().getJobsListOffline();
          if (mounted) {
            setState(() {
              _name = prefs.getString('name') ?? user.displayName ?? 'No Name';
              _email = prefs.getString('email') ?? user.email ?? 'No Email';
              _userRole = prefs.getString('userRole') ?? '';
              _jobs = offlineJobs;
              if (savedStatus != null && _statuses.contains(savedStatus)) {
                _status = savedStatus;
              }
              _avatarBase64 = avatar;
              _isVerified = avatar != null;
              _isLoading = false;
            });
          }
        }
      } else {
        final offlineJobs = await OfflineService().getJobsListOffline();
        if (mounted) {
          setState(() {
            _name = prefs.getString('name') ?? user.displayName ?? 'No Name';
            _email = prefs.getString('email') ?? user.email ?? 'No Email';
            _userRole = prefs.getString('userRole') ?? '';
            _jobs = offlineJobs;
            if (savedStatus != null && _statuses.contains(savedStatus)) {
              _status = savedStatus;
            }
            _avatarBase64 = avatar;
            _isVerified = avatar != null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _name = prefs.getString('name') ?? user.displayName ?? 'No Name';
          _email = prefs.getString('email') ?? user.email ?? 'No Email';
          _userRole = prefs.getString('userRole') ?? '';
          _jobs = [];
          _avatarBase64 = avatar;
          _isVerified = avatar != null;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('connectToInternet'),
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({'video': true});
      if (stream == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('cameraError'),
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final videoElement = html.VideoElement()
        ..autoplay = true
        ..srcObject = stream;

      await videoElement.play();

      await showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: FadeInDown(
            duration: Duration(milliseconds: 600),
            child: Text(
              AppLocalizations.of(context).translate('takePhoto'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF264653),
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeInLeft(
                duration: Duration(milliseconds: 700),
                child: Text(
                  AppLocalizations.of(context).translate('cameraActive'),
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
              SizedBox(height: 20),
              ZoomIn(
                duration: Duration(milliseconds: 800),
                child: ElevatedButton(
                  onPressed: () async {
                    final canvas = html.CanvasElement(width: videoElement.videoWidth, height: videoElement.videoHeight);
                    final ctx = canvas.context2D;
                    ctx.drawImage(videoElement, 0, 0);

                    final base64Image = canvas.toDataUrl('image/png');
                    await _saveAvatar(base64Image);

                    setState(() {
                      _avatarBase64 = base64Image;
                      _isVerified = true;
                    });

                    stream.getTracks().forEach((track) => track.stop());
                    Navigator.of(dialogCtx, rootNavigator: true).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2A9D8F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: Size(double.infinity, 48),
                  ),
                  child: Text(
                    AppLocalizations.of(context).translate('capture'),
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            FadeInLeft(
              duration: Duration(milliseconds: 900),
              child: TextButton(
                onPressed: () {
                  stream.getTracks().forEach((track) => track.stop());
                  Navigator.of(dialogCtx, rootNavigator: true).pop();
                },
                style: TextButton.styleFrom(foregroundColor: Color(0xFFF4A261)),
                child: Text(
                  AppLocalizations.of(context).translate('cancel'),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print("Error accessing camera: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).translate('cameraError')}: $e',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _deleteAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('avatar');
    setState(() {
      _avatarBase64 = null;
      _isVerified = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF2A9D8F),
          secondary: Color(0xFFF4A261),
          surface: Color(0xFFF8FAFC),
          onSurface: Color(0xFF264653),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2A9D8F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            minimumSize: Size(double.infinity, 48),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF6B7280)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF6B7280)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF2A9D8F), width: 2),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2A9D8F),
          foregroundColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      ),
      child: withOrientationSupport(
        context: context,
        portrait: _buildPortraitLayout(context, localizations),
        landscape: _buildLandscapeLayout(context, localizations),
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, AppLocalizations localizations) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: FadeInDown(
          duration: Duration(milliseconds: 600),
          child: Text(
            localizations.translate('profile'),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: _isOnline ? Color(0xFF2A9D8F) : Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        elevation: 4,
        flexibleSpace: _isOnline
            ? null
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.withOpacity(0.3), Colors.red.withOpacity(0.1)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Center(
                  child: FadeInDown(
                    duration: Duration(milliseconds: 700),
                    child: Text(
                      localizations.translate('connectToInternet'),
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
      ),
      endDrawer: Drawer(
        child: Container(
          color: Color(0xFFF8FAFC),
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2A9D8F), Color(0xFFF4A261)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    localizations.translate('menu'),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              FadeInLeft(
                duration: Duration(milliseconds: 800),
                child: ListTile(
                  leading: Icon(IconlyLight.info_circle, color: Color(0xFF2A9D8F)),
                  title: Text(
                    localizations.translate('aboutTheApp'),
                    style: TextStyle(
                      color: Color(0xFF264653),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AboutPage()));
                  },
                ),
              ),
              FadeInLeft(
                duration: Duration(milliseconds: 900),
                child: ListTile(
                  leading: Icon(IconlyLight.setting, color: Color(0xFF2A9D8F)),
                  title: Text(
                    localizations.translate('settings'),
                    style: TextStyle(
                      color: Color(0xFF264653),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage()));
                  },
                ),
              ),
              FadeInLeft(
                duration: Duration(milliseconds: 1000),
                child: ListTile(
                  leading: Icon(IconlyLight.chat, color: Color(0xFF2A9D8F)),
                  title: Text(
                    localizations.translate('help'),
                    style: TextStyle(
                      color: Color(0xFF264653),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => HelpPage()));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF2A9D8F)))
          : _userRole == null || _userRole!.isEmpty
              ? _buildNoRoleContent(context, localizations)
              : _userRole == 'jobSeeker'
                  ? _buildJobSeekerContent(context, localizations)
                  : _buildEmployerContent(context, localizations),
      floatingActionButton: _userRole == 'employer'
          ? ZoomIn(
              duration: Duration(milliseconds: 1100),
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateJobScreen()),
                  );
                  if (result != null && result is Map<String, dynamic>) {
                    final jobData = {
                      ...result,
                      'employerId': FirebaseAuth.instance.currentUser?.uid,
                      'createdAt': DateTime.now().toIso8601String(),
                    };
                    try {
                      if (_isOnline) {
                        final docRef = await FirebaseFirestore.instance.collection('jobs').add(jobData);
                        setState(() {
                          _jobs.add({...jobData, 'id': docRef.id});
                        });
                        await OfflineService().saveJobsListOffline(_jobs);
                      } else {
                        await OfflineService().saveJobOffline(jobData, 'create');
                        setState(() {
                          _jobs.add({...jobData, 'id': 'offline_${_jobs.length}'});
                          _hasPendingRequests = true;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations.translate('offlineModeWarning'),
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      print('Error creating job: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              localizations.translate('offlineModeWarning'),
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  }
                },
                tooltip: localizations.translate('createJob'),
                child: Icon(IconlyLight.work),
              ),
            )
          : null,
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, AppLocalizations localizations) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: FadeInDown(
          duration: Duration(milliseconds: 600),
          child: Text(
            localizations.translate('profile'),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: _isOnline ? Color(0xFF2A9D8F) : Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        elevation: 4,
        flexibleSpace: _isOnline
            ? null
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.withOpacity(0.3), Colors.red.withOpacity(0.1)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Center(
                  child: FadeInDown(
                    duration: Duration(milliseconds: 700),
                    child: Text(
                      localizations.translate('connectToInternet'),
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
      ),
      endDrawer: Drawer(
        child: Container(
          color: Color(0xFFF8FAFC),
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2A9D8F), Color(0xFFF4A261)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    localizations.translate('menu'),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              FadeInLeft(
                duration: Duration(milliseconds: 800),
                child: ListTile(
                  leading: Icon(IconlyLight.info_circle, color: Color(0xFF2A9D8F)),
                  title: Text(
                    localizations.translate('aboutTheApp'),
                    style: TextStyle(
                      color: Color(0xFF264653),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AboutPage()));
                  },
                ),
              ),
              FadeInLeft(
                duration: Duration(milliseconds: 900),
                child: ListTile(
                  leading: Icon(IconlyLight.setting, color: Color(0xFF2A9D8F)),
                  title: Text(
                    localizations.translate('settings'),
                    style: TextStyle(
                      color: Color(0xFF264653),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage()));
                  },
                ),
              ),
              FadeInLeft(
                duration: Duration(milliseconds: 1000),
                child: ListTile(
                  leading: Icon(IconlyLight.chat, color: Color(0xFF2A9D8F)),
                  title: Text(
                    localizations.translate('help'),
                    style: TextStyle(
                      color: Color(0xFF264653),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => HelpPage()));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF2A9D8F)))
          : Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeInDown(
                          duration: Duration(milliseconds: 800),
                          child: ClipOval(
                            child: _avatarBase64 != null
                                ? Image.memory(
                                    base64Decode(_avatarBase64!.split(',').last),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    _placeholderAvatar,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        SizedBox(height: 8),
                        FadeInLeft(
                          duration: Duration(milliseconds: 900),
                          child: Text(
                            _name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF264653),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        FadeInLeft(
                          duration: Duration(milliseconds: 1000),
                          child: Text(
                            _email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _userRole == null || _userRole!.isEmpty
                      ? _buildNoRoleContent(context, localizations)
                      : _userRole == 'jobSeeker'
                          ? _buildJobSeekerContent(context, localizations)
                          : _buildEmployerContent(context, localizations),
                ),
              ],
            ),
      floatingActionButton: _userRole == 'employer'
          ? ZoomIn(
              duration: Duration(milliseconds: 1100),
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateJobScreen()),
                  );
                  if (result != null && result is Map<String, dynamic>) {
                    final jobData = {
                      ...result,
                      'employerId': FirebaseAuth.instance.currentUser?.uid,
                      'createdAt': DateTime.now().toIso8601String(),
                    };
                    try {
                      if (_isOnline) {
                        final docRef = await FirebaseFirestore.instance.collection('jobs').add(jobData);
                        setState(() {
                          _jobs.add({...jobData, 'id': docRef.id});
                        });
                        await OfflineService().saveJobsListOffline(_jobs);
                      } else {
                        await OfflineService().saveJobOffline(jobData, 'create');
                        setState(() {
                          _jobs.add({...jobData, 'id': 'offline_${_jobs.length}'});
                          _hasPendingRequests = true;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations.translate('offlineModeWarning'),
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      print('Error creating job: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              localizations.translate('offlineModeWarning'),
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  }
                },
                tooltip: localizations.translate('createJob'),
                child: Icon(IconlyLight.work),
              ),
            )
          : null,
    );
  }

  Widget _buildNoRoleContent(BuildContext context, AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInDown(
            duration: Duration(milliseconds: 800),
            child: Text(
              localizations.translate('pleaseSelectRole'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF264653),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 20),
          ZoomIn(
            duration: Duration(milliseconds: 900),
            child: ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  if (_isOnline) {
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogContext) => RoleSelectionDialog(userId: user.uid),
                    );
                    await _loadUserData();
                  } else {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('userRole', 'jobSeeker');
                    setState(() {
                      _userRole = 'jobSeeker';
                      _hasPendingRequests = true;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            localizations.translate('offlineModeWarning'),
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                }
              },
              child: Text(localizations.translate('selectRole')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobSeekerContent(BuildContext context, AppLocalizations localizations) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Center(
            child: Column(
              children: [
                FadeInDown(
                  duration: Duration(milliseconds: 800),
                  child: ClipOval(
                    child: _avatarBase64 != null
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
                ),
                SizedBox(height: 10),
                ZoomIn(
                  duration: Duration(milliseconds: 900),
                  child: ElevatedButton(
                    onPressed: _isVerified ? null : _pickImage,
                    child: Text(
                      _isVerified
                          ? localizations.translate('verified')
                          : localizations.translate('verifyYourself'),
                    ),
                  ),
                ),
                if (_isVerified)
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: ZoomIn(
                      duration: Duration(milliseconds: 1000),
                      child: ElevatedButton(
                        onPressed: _deleteAvatar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: Size(double.infinity, 48),
                        ),
                        child: Text(
                          localizations.translate('deletePhoto'),
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 20),
          FadeInLeft(
            duration: Duration(milliseconds: 1100),
            child: _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF264653),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFF4A261),
                    ),
                  ),
                  SizedBox(height: 20),
                  DropdownButton<String>(
                    value: _status,
                    icon: Icon(IconlyLight.arrow_down_2, color: Color(0xFF2A9D8F)),
                    isExpanded: true,
                    items: _statuses.map((String statusKey) {
                      return DropdownMenuItem<String>(
                        value: statusKey,
                        child: Text(
                          localizations.translate(statusKey),
                          style: TextStyle(color: Color(0xFF264653)),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _status = newValue);
                        _saveStatus(newValue);
                      }
                    },
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF264653),
                    ),
                    dropdownColor: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployerContent(BuildContext context, AppLocalizations localizations) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Center(
            child: Column(
              children: [
                FadeInDown(
                  duration: Duration(milliseconds: 800),
                  child: ClipOval(
                    child: _avatarBase64 != null
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
                ),
                SizedBox(height: 10),
                FadeInLeft(
                  duration: Duration(milliseconds: 900),
                  child: Text(
                    _name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF264653),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                FadeInLeft(
                  duration: Duration(milliseconds: 1000),
                  child: Text(
                    _email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFF4A261),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          FadeInLeft(
            duration: Duration(milliseconds: 1100),
            child: Text(
              localizations.translate('yourJobs'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF264653),
              ),
            ),
          ),
          SizedBox(height: 16),
          _jobs.isEmpty
              ? Center(
                  child: FadeInLeft(
                    duration: Duration(milliseconds: 1200),
                    child: Text(
                      _isOnline
                          ? localizations.translate('noJobsCreated')
                          : localizations.translate('connectToInternet'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _jobs.length,
                  itemBuilder: (context, index) {
                    final job = _jobs[index];
                    final jobId = job['id'] ?? 'offline_${index}';
                    return FadeInLeft(
                      duration: Duration(milliseconds: 1300 + index * 100),
                      child: _buildJobCard(context, job, jobId, localizations),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job, String jobId, AppLocalizations localizations) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          title: Text(
            job['title'] ?? 'Untitled',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A9D8F),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${localizations.translate('category')}: ${job['category']}',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              Text(
                '${localizations.translate('city')}: ${job['city']}',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              Text(
                '${localizations.translate('salary')}: ${job['salary']}',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              IconlyLight.edit,
              color: Color(0xFFF4A261),
            ),
            onPressed: () {
              if (_isOnline) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditJobScreen(jobId: jobId, jobData: job),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      localizations.translate('offlineModeWarning'),
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}