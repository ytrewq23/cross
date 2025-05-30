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
  List<Map<String, String>> _resumes = [];
  String _status = 'statusActive';
  final List<String> _statuses = ['statusActive', 'statusFound', 'statusNotLooking'];
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
    setState(() => _isOnline = OfflineService().isOnline);
    if (kIsWeb) {
      html.window.addEventListener('online', (_) {
        if (mounted) {
          setState(() => _isOnline = true);
          _handleReconnect();
        }
      });
      html.window.addEventListener('offline', (_) {
        if (mounted) setState(() => _isOnline = false);
      });
    } else {
      Connectivity().onConnectivityChanged.listen((results) {
        if (mounted) {
          final newOnline = results.any((result) => result == ConnectivityResult.wifi || result == ConnectivityResult.mobile);
          setState(() => _isOnline = newOnline);
          if (newOnline) _handleReconnect();
        }
      });
    }
  }

  Future<void> _handleReconnect() async {
    await OfflineService().syncAndNotify(context, () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('requestsProcessedSuccess')),
            backgroundColor: Theme.of(context).colorScheme.primary,
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
          _resumes = [];
          _avatarBase64 = avatar;
          _isVerified = avatar != null;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      if (_isOnline) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final jobsSnapshot = await FirebaseFirestore.instance
            .collection('jobs')
            .where('employerId', isEqualTo: user.uid)
            .get();
        final resumeDoc = await FirebaseFirestore.instance.collection('resumes').doc(user.uid).get();

        if (mounted) {
          setState(() {
            _name = user.displayName ?? prefs.getString('name') ?? 'No Name';
            _email = user.email ?? prefs.getString('email') ?? 'No Email';
            _userRole = userDoc.data()?['role'] ?? prefs.getString('userRole') ?? '';
            _jobs = jobsSnapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
            if (resumeDoc.exists) {
              final resumeData = resumeDoc.data()!;
              _resumes = [
                {
                  'profession': resumeData['profession'] ?? '',
                  'date': resumeData['date'] ?? '',
                  'name': resumeData['name'] ?? '',
                  'email': resumeData['email'] ?? '',
                }
              ];
              OfflineService().saveResumeOffline({...resumeData, 'userId': user.uid});
            }
            if (savedStatus != null && _statuses.contains(savedStatus)) _status = savedStatus;
            _avatarBase64 = avatar;
            _isVerified = avatar != null;
            _isLoading = false;
          });
          await prefs.setString('name', _name);
          await prefs.setString('email', _email);
          await prefs.setString('userRole', _userRole ?? '');
          await prefs.setString('user_name', _name);
          await prefs.setString('user_email', _email);
          if (_userRole != null) await prefs.setString('user_role', _userRole!);
          await OfflineService().saveJobsListOffline(_jobs);
        }
      } else {
        _loadOfflineData(prefs, user, savedStatus, avatar);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _name = prefs.getString('name') ?? user.displayName ?? 'No Name';
          _email = prefs.getString('email') ?? user.email ?? 'No Email';
          _userRole = prefs.getString('userRole') ?? '';
          _jobs = [];
          _resumes = [];
          _avatarBase64 = avatar;
          _isVerified = avatar != null;
          _isLoading = false;
        });
        OfflineService().showOfflineSnackBar(context);
      }
    }
  }

  Future<void> _loadOfflineData(SharedPreferences prefs, User user, String? savedStatus, String? avatar) async {
    final offlineJobs = await OfflineService().getJobsListOffline();
    final offlineResume = await OfflineService().getResumeOffline();
    if (mounted) {
      setState(() {
        _name = prefs.getString('name') ?? user.displayName ?? 'No Name';
        _email = prefs.getString('email') ?? user.email ?? 'No Email';
        _userRole = prefs.getString('userRole') ?? '';
        _jobs = offlineJobs.where((job) => job['employerId'] == user.uid).toList();
        if (offlineResume != null) {
          _resumes = [
            {
              'profession': offlineResume['profession'] ?? '',
              'date': offlineResume['date'] ?? '',
              'name': offlineResume['name'] ?? '',
              'email': offlineResume['email'] ?? '',
            }
          ];
        }
        if (savedStatus != null && _statuses.contains(savedStatus)) _status = savedStatus;
        _avatarBase64 = avatar;
        _isVerified = avatar != null;
        _isLoading = false;
      });
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
    if (!kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('cameraWebOnly')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    try {
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({'video': true});
      if (stream == null) throw Exception('Camera not available');
      final videoElement = html.VideoElement()..autoplay = true..srcObject = stream;
      await videoElement.play();
      await showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Text(
              AppLocalizations.of(context).translate('takePhoto'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeInLeft(
                duration: const Duration(milliseconds: 700),
                child: Text(
                  AppLocalizations.of(context).translate('cameraActive'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 20),
              ZoomIn(
                duration: const Duration(milliseconds: 800),
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
                  child: Text(AppLocalizations.of(context).translate('capture')),
                ),
              ),
            ],
          ),
          actions: [
            FadeInLeft(
              duration: const Duration(milliseconds: 900),
              child: TextButton(
                onPressed: () {
                  stream.getTracks().forEach((track) => track.stop());
                  Navigator.of(dialogCtx, rootNavigator: true).pop();
                },
                child: Text(AppLocalizations.of(context).translate('cancel')),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).translate('cameraError')}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
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

  Future<void> _updateResume() async {
    if (!_isOnline) {
      OfflineService().showOfflineSnackBar(context);
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final professionController = TextEditingController(text: _resumes.isNotEmpty ? _resumes[0]['profession'] : '');
    final dateController = TextEditingController(text: _resumes.isNotEmpty ? _resumes[0]['date'] : '');
    final nameController = TextEditingController(text: _resumes.isNotEmpty ? _resumes[0]['name'] : '');
    final emailController = TextEditingController(text: _resumes.isNotEmpty ? _resumes[0]['email'] : '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('updateResume')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: professionController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('profession')),
              ),
              TextField(
                controller: dateController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('date')),
              ),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('name')),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('email')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'profession': professionController.text,
              'date': dateController.text,
              'name': nameController.text,
              'email': emailController.text,
              'userId': user.uid,
            }),
            child: Text(AppLocalizations.of(context).translate('save')),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await FirebaseFirestore.instance.collection('resumes').doc(user.uid).set(result);
        await OfflineService().saveResumeOffline(result);
        if (mounted) {
          setState(() => _resumes = [result]);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).translate('resumeUpdated'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating resume: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return withOrientationSupport(
      context: context,
      portrait: _buildPortraitLayout(context, localizations, theme),
      landscape: _buildLandscapeLayout(context, localizations, theme),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, AppLocalizations localizations, ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Text(localizations.translate('profile'), style: theme.appBarTheme.titleTextStyle),
        ),
        centerTitle: true,
        backgroundColor: _isOnline ? theme.appBarTheme.backgroundColor : theme.colorScheme.error,
        flexibleSpace: _isOnline
            ? null
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.error.withOpacity(0.3), theme.colorScheme.error.withOpacity(0.1)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Center(
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 700),
                    child: Text(
                      localizations.translate('connectToInternet'),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ),
      ),
      endDrawer: Drawer(
        child: Container(
          color: theme.scaffoldBackgroundColor,
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
                ),
                child: Text(
                  localizations.translate('menu'),
                  style: GoogleFonts.poppins(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FadeInLeft(
                duration: const Duration(milliseconds: 800),
                child: ListTile(
                  leading: Icon(IconlyLight.info_circle, color: theme.colorScheme.primary),
                  title: Text(localizations.translate('aboutTheApp'), style: theme.textTheme.bodyMedium),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
                  },
                ),
              ),
              FadeInLeft(
                duration: const Duration(milliseconds: 900),
                child: ListTile(
                  leading: Icon(IconlyLight.setting, color: theme.colorScheme.primary),
                  title: Text(localizations.translate('settings'), style: theme.textTheme.bodyMedium),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                  },
                ),
              ),
              FadeInLeft(
                duration: const Duration(milliseconds: 1000),
                child: ListTile(
                  leading: Icon(IconlyLight.chat, color: theme.colorScheme.primary),
                  title: Text(localizations.translate('help'), style: theme.textTheme.bodyMedium),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpPage()));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _userRole == null || _userRole!.isEmpty
              ? _buildNoRoleContent(context, localizations, theme)
              : _userRole == 'jobSeeker'
                  ? _buildJobSeekerContent(context, localizations, theme)
                  : _buildEmployerContent(context, localizations, theme),
      floatingActionButton: _userRole == 'employer'
          ? ZoomIn(
              duration: const Duration(milliseconds: 1100),
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateJobScreen()));
                  if (result != null && result is Map<String, dynamic>) {
                    final jobData = {
                      ...result,
                      'employerId': FirebaseAuth.instance.currentUser?.uid,
                      'createdAt': DateTime.now().toIso8601String(),
                    };
                    try {
                      if (_isOnline) {
                        final docRef = await FirebaseFirestore.instance.collection('jobs').add(jobData);
                        setState(() => _jobs.add({...jobData, 'id': docRef.id}));
                        await OfflineService().saveJobsListOffline(_jobs);
                      } else {
                        final offlineId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
                        await OfflineService().saveJobOffline({...jobData, 'id': offlineId}, 'create');
                        setState(() {
                          _jobs.add({...jobData, 'id': offlineId});
                          _hasPendingRequests = true;
                        });
                        if (mounted) OfflineService().showOfflineSnackBar(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error creating job: $e')),
                        );
                      }
                    }
                  }
                },
                tooltip: localizations.translate('createJob'),
                child: const Icon(IconlyLight.work),
                backgroundColor: theme.floatingActionButtonTheme.backgroundColor,
              ),
            )
          : null,
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, AppLocalizations localizations, ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Text(localizations.translate('profile'), style: theme.appBarTheme.titleTextStyle),
        ),
        centerTitle: true,
        backgroundColor: _isOnline ? theme.appBarTheme.backgroundColor : theme.colorScheme.error,
        flexibleSpace: _isOnline
            ? null
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.error.withOpacity(0.3), theme.colorScheme.error.withOpacity(0.1)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Center(
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 700),
                    child: Text(
                      localizations.translate('connectToInternet'),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ),
      ),
      endDrawer: Drawer(
        child: Container(
          color: theme.scaffoldBackgroundColor,
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
                ),
                child: Text(
                  localizations.translate('menu'),
                  style: GoogleFonts.poppins(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FadeInLeft(
                duration: const Duration(milliseconds: 800),
                child: ListTile(
                  leading: Icon(IconlyLight.info_circle, color: theme.colorScheme.primary),
                  title: Text(localizations.translate('aboutTheApp'), style: theme.textTheme.bodyMedium),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
                  },
                ),
              ),
              FadeInLeft(
                duration: const Duration(milliseconds: 900),
                child: ListTile(
                  leading: Icon(IconlyLight.setting, color: theme.colorScheme.primary),
                  title: Text(localizations.translate('settings'), style: theme.textTheme.bodyMedium),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                  },
                ),
              ),
              FadeInLeft(
                duration: const Duration(milliseconds: 1000),
                child: ListTile(
                  leading: Icon(IconlyLight.chat, color: theme.colorScheme.primary),
                  title: Text(localizations.translate('help'), style: theme.textTheme.bodyMedium),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpPage()));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeInDown(
                          duration: const Duration(milliseconds: 800),
                          child: ClipOval(
                            child: _avatarBase64 != null
                                ? Image.memory(base64Decode(_avatarBase64!.split(',').last), width: 100, height: 100, fit: BoxFit.cover)
                                : Image.asset(_placeholderAvatar, width: 100, height: 100, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeInLeft(
                          duration: const Duration(milliseconds: 900),
                          child: Text(_name, style: theme.textTheme.titleLarge),
                        ),
                        const SizedBox(height: 8),
                        FadeInLeft(
                          duration: const Duration(milliseconds: 1000),
                          child: Text(_email, style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _userRole == null || _userRole!.isEmpty
                      ? _buildNoRoleContent(context, localizations, theme)
                      : _userRole == 'jobSeeker'
                          ? _buildJobSeekerContent(context, localizations, theme)
                          : _buildEmployerContent(context, localizations, theme),
                ),
              ],
            ),
      floatingActionButton: _userRole == 'employer'
          ? ZoomIn(
              duration: const Duration(milliseconds: 1100),
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateJobScreen()));
                  if (result != null && result is Map<String, dynamic>) {
                    final jobData = {
                      ...result,
                      'employerId': FirebaseAuth.instance.currentUser?.uid,
                      'createdAt': DateTime.now().toIso8601String(),
                    };
                    try {
                      if (_isOnline) {
                        final docRef = await FirebaseFirestore.instance.collection('jobs').add(jobData);
                        setState(() => _jobs.add({...jobData, 'id': docRef.id}));
                        await OfflineService().saveJobsListOffline(_jobs);
                      } else {
                        final offlineId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
                        await OfflineService().saveJobOffline({...jobData, 'id': offlineId}, 'create');
                        setState(() {
                          _jobs.add({...jobData, 'id': offlineId});
                          _hasPendingRequests = true;
                        });
                        if (mounted) OfflineService().showOfflineSnackBar(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error creating job: $e')),
                        );
                      }
                    }
                  }
                },
                tooltip: localizations.translate('createJob'),
                child: const Icon(IconlyLight.work),
                backgroundColor: theme.floatingActionButtonTheme.backgroundColor,
              ),
            )
          : null,
    );
  }

  Widget _buildNoRoleContent(BuildContext context, AppLocalizations localizations, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 800),
            child: Text(
              localizations.translate('pleaseSelectRole'),
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ZoomIn(
            duration: const Duration(milliseconds: 900),
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
                    await OfflineService().saveRoleOffline(user.uid, 'jobSeeker');
                    setState(() {
                      _userRole = 'jobSeeker';
                      _hasPendingRequests = true;
                    });
                    if (mounted) OfflineService().showOfflineSnackBar(context);
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

  Widget _buildJobSeekerContent(BuildContext context, AppLocalizations localizations, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Center(
            child: Column(
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: ClipOval(
                    child: _avatarBase64 != null
                        ? Image.memory(base64Decode(_avatarBase64!.split(',').last), width: 120, height: 120, fit: BoxFit.cover)
                        : Image.asset(_placeholderAvatar, width: 120, height: 120, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 10),
                ZoomIn(
                  duration: const Duration(milliseconds: 900),
                  child: ElevatedButton(
                    onPressed: _isVerified ? null : _pickImage,
                    child: Text(_isVerified ? localizations.translate('verified') : localizations.translate('verifyYourself')),
                  ),
                ),
                if (_isVerified)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ZoomIn(
                      duration: const Duration(milliseconds: 1000),
                      child: ElevatedButton(
                        onPressed: _deleteAvatar,
                        style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error),
                        child: Text(localizations.translate('deletePhoto')),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FadeInLeft(
            duration: const Duration(milliseconds: 1100),
            child: _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_name, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(_email, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  DropdownButton<String>(
                    value: _status,
                    icon: Icon(IconlyLight.arrow_down_2, color: theme.colorScheme.primary),
                    isExpanded: true,
                    items: _statuses
                        .map((statusKey) => DropdownMenuItem(
                              value: statusKey,
                              child: Text(localizations.translate(statusKey), style: theme.textTheme.bodyMedium),
                            ))
                        .toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() => _status = newValue);
                        _saveStatus(newValue);
                      }
                    },
                    style: theme.textTheme.bodyMedium,
                    dropdownColor: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
              theme: theme,
            ),
          ),
          const SizedBox(height: 20),
          FadeInLeft(
            duration: const Duration(milliseconds: 1200),
            child: Text(localizations.translate('resume'), style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: 16),
          _resumes.isEmpty
              ? Center(
                  child: FadeInLeft(
                    duration: const Duration(milliseconds: 1300),
                    child: Text(
                      _isOnline ? localizations.translate('noResume') : localizations.translate('connectToInternet'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              : Column(
                  children: _resumes
                      .map((resume) => FadeInLeft(
                            duration: const Duration(milliseconds: 1400),
                            child: _buildCard(
                              child: ListTile(
                                title: Text(resume['profession'] ?? 'No Profession', style: theme.textTheme.titleMedium),
                                subtitle: Text('${resume['date']}\n${resume['name']}\n${resume['email']}'),
                                trailing: IconButton(
                                  icon: Icon(IconlyLight.edit, color: theme.colorScheme.secondary),
                                  onPressed: _updateResume,
                                ),
                              ),
                              theme: theme,
                            ),
                          ))
                      .toList(),
                ),
          if (_resumes.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ZoomIn(
                duration: const Duration(milliseconds: 1500),
                child: ElevatedButton(
                  onPressed: _updateResume,
                  child: Text(localizations.translate('addResume')),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmployerContent(BuildContext context, AppLocalizations localizations, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Center(
            child: Column(
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: ClipOval(
                    child: _avatarBase64 != null
                        ? Image.memory(base64Decode(_avatarBase64!.split(',').last), width: 120, height: 120, fit: BoxFit.cover)
                        : Image.asset(_placeholderAvatar, width: 120, height: 120, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 10),
                FadeInLeft(
                  duration: const Duration(milliseconds: 900),
                  child: Text(_name, style: theme.textTheme.titleLarge),
                ),
                const SizedBox(height: 8),
                FadeInLeft(
                  duration: const Duration(milliseconds: 1000),
                  child: Text(_email, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FadeInLeft(
            duration: const Duration(milliseconds: 1100),
            child: Text(localizations.translate('yourJobs'), style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: 16),
          _jobs.isEmpty
              ? Center(
                  child: FadeInLeft(
                    duration: const Duration(milliseconds: 1200),
                    child: Text(
                      _isOnline ? localizations.translate('noJobsCreated') : localizations.translate('connectToInternet'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _jobs.length,
                  itemBuilder: (context, index) {
                    final job = _jobs[index];
                    final jobId = job['id'] ?? 'offline_$index';
                    return FadeInLeft(
                      duration: Duration(milliseconds: 1300 + index * 100),
                      child: _buildJobCard(context, job, jobId, localizations, theme),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job, String jobId, AppLocalizations localizations, ThemeData theme) {
    return Card(
      color: theme.cardColor,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.brightness == Brightness.dark
                ? [const Color(0xFF2A2F33), const Color(0xFF1C2526)]
                : [const Color(0xFFF8FAFC), const Color(0xFFE6ECEF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            job['title'] ?? 'Untitled',
            style: theme.textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${localizations.translate('category')}: ${job['category'] ?? 'Unknown'}'),
              Text('${localizations.translate('city')}: ${job['city'] ?? 'Unknown'}'),
              Text('${localizations.translate('salary')}: ${job['salary'] ?? 'Not specified'}'),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(IconlyLight.edit, color: theme.colorScheme.secondary),
                onPressed: () async {
                  if (!_isOnline) {
                    OfflineService().showOfflineSnackBar(context);
                    return;
                  }
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditJobScreen(jobId: jobId, jobData: job)),
                  );
                  if (result != null && result is Map<String, dynamic>) {
                    setState(() => _jobs[_jobs.indexWhere((j) => j['id'] == jobId)] = {...result, 'id': jobId});
                    await OfflineService().saveJobsListOffline(_jobs);
                  }
                },
              ),
              IconButton(
                icon: Icon(IconlyLight.delete, color: theme.colorScheme.error),
                onPressed: () async {
                  try {
                    if (_isOnline) {
                      await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
                      setState(() => _jobs.removeWhere((j) => j['id'] == jobId));
                      await OfflineService().saveJobsListOffline(_jobs);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(localizations.translate('jobDeleted'))),
                      );
                    } else {
                      await OfflineService().saveJobOffline({'id': jobId}, 'delete');
                      setState(() {
                        _jobs.removeWhere((j) => j['id'] == jobId);
                        _hasPendingRequests = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(localizations.translate('jobDeletionSavedOffline'))),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting job: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, required ThemeData theme}) {
    return Card(
      color: theme.cardColor,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.brightness == Brightness.dark
                ? [const Color(0xFF2A2F33), const Color(0xFF1C2526)]
                : [const Color(0xFFF8FAFC), const Color(0xFFE6ECEF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}