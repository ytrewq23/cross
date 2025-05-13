import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/pages/offline_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'settings_page.dart';
import 'about_page.dart';
import 'help_page.dart';
import 'create_job_screen.dart';
import 'edit_job_screen.dart';
import 'role_selection_dialog.dart';
import '../localizations.dart';
import '../orientation_support.dart';

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
          setState(() {
            _isOnline = true;
          });
          _handleReconnect();
        }
      });
      html.window.addEventListener('offline', (_) {
        if (mounted) {
          setState(() {
            _isOnline = false;
          });
        }
      });
    } else {
      Connectivity().onConnectivityChanged.listen((results) {
        if (mounted) {
          final newOnline = results.any(
            (result) => result != ConnectivityResult.none,
          );
          setState(() {
            _isOnline = newOnline;
          });
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
              AppLocalizations.of(
                context,
              ).translate('requestsProcessedSuccess'),
            ),
          ),
        );
        setState(() {
          _hasPendingRequests = false;
        });
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
        // Try Firestore first
        try {
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();
          final jobsSnapshot =
              await FirebaseFirestore.instance
                  .collection('jobs')
                  .where('employerId', isEqualTo: user.uid)
                  .get();

          if (mounted) {
            setState(() {
              _name = user.displayName ?? prefs.getString('name') ?? 'No Name';
              _email = user.email ?? prefs.getString('email') ?? 'No Email';
              _userRole =
                  userDoc.data()?['role'] as String? ??
                  prefs.getString('userRole') ??
                  '';
              _jobs =
                  jobsSnapshot.docs
                      .map((doc) => {...doc.data(), 'id': doc.id})
                      .toList();
              if (savedStatus != null && _statuses.contains(savedStatus)) {
                _status = savedStatus;
              }
              _avatarBase64 = avatar;
              _isVerified = avatar != null;
              _isLoading = false;
            });
            // Cache to SharedPreferences
            await prefs.setString('name', _name);
            await prefs.setString('email', _email);
            await prefs.setString('userRole', _userRole ?? '');
            await OfflineService().saveJobsListOffline(_jobs);
          }
        } catch (e) {
          print('Firestore error: $e');
          // Fall back to SharedPreferences
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
        // Load from SharedPreferences offline
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
            ),
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
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': true,
      });
      if (stream == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('cameraError'),
              ),
            ),
          );
        }
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
              title: Text(AppLocalizations.of(context).translate('takePhoto')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context).translate('cameraActive')),
                  const SizedBox(height: 20),
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
                      Navigator.of(dialogCtx, rootNavigator: true).pop();
                    },
                    child: Text(
                      AppLocalizations.of(context).translate('capture'),
                    ),
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
                  child: Text(AppLocalizations.of(context).translate('cancel')),
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
            ),
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
    return withOrientationSupport(
      context: context,
      portrait: _buildPortraitLayout(context, localizations),
      landscape: _buildLandscapeLayout(context, localizations),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('profile')),
        centerTitle: true,
        flexibleSpace:
            _isOnline
                ? null
                : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0.3),
                        Colors.red.withOpacity(0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      localizations.translate('connectToInternet'),
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
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
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _userRole == null || _userRole!.isEmpty
              ? _buildNoRoleContent(context, localizations)
              : _userRole == 'jobSeeker'
              ? _buildJobSeekerContent(context, localizations)
              : _buildEmployerContent(context, localizations),
      floatingActionButton:
          _userRole == 'employer'
              ? FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateJobScreen(),
                    ),
                  );
                  if (result != null && result is Map<String, dynamic>) {
                    final jobData = {
                      ...result,
                      'employerId': FirebaseAuth.instance.currentUser?.uid,
                      'createdAt': DateTime.now().toIso8601String(),
                    };
                    try {
                      if (_isOnline) {
                        final docRef = await FirebaseFirestore.instance
                            .collection('jobs')
                            .add(jobData);
                        setState(() {
                          _jobs.add({...jobData, 'id': docRef.id});
                        });
                        await OfflineService().saveJobsListOffline(_jobs);
                      } else {
                        await OfflineService().saveJobOffline(
                          jobData,
                          'create',
                        );
                        setState(() {
                          _jobs.add({
                            ...jobData,
                            'id': 'offline_${_jobs.length}',
                          });
                          _hasPendingRequests = true;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations.translate('offlineModeWarning'),
                              ),
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
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: const Icon(Icons.add),
                tooltip: localizations.translate('createJob'),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              )
              : null,
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('profile')),
        centerTitle: true,
        flexibleSpace:
            _isOnline
                ? null
                : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0.3),
                        Colors.red.withOpacity(0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      localizations.translate('connectToInternet'),
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
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
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipOval(
                            child:
                                _avatarBase64 != null
                                    ? Image.memory(
                                      base64Decode(
                                        _avatarBase64!.split(',').last,
                                      ),
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
                          const SizedBox(height: 8),
                          Text(
                            _name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _email,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child:
                        _userRole == null || _userRole!.isEmpty
                            ? _buildNoRoleContent(context, localizations)
                            : _userRole == 'jobSeeker'
                            ? _buildJobSeekerContent(context, localizations)
                            : _buildEmployerContent(context, localizations),
                  ),
                ],
              ),
      floatingActionButton:
          _userRole == 'employer'
              ? FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateJobScreen(),
                    ),
                  );
                  if (result != null && result is Map<String, dynamic>) {
                    final jobData = {
                      ...result,
                      'employerId': FirebaseAuth.instance.currentUser?.uid,
                      'createdAt': DateTime.now().toIso8601String(),
                    };
                    try {
                      if (_isOnline) {
                        final docRef = await FirebaseFirestore.instance
                            .collection('jobs')
                            .add(jobData);
                        setState(() {
                          _jobs.add({...jobData, 'id': docRef.id});
                        });
                        await OfflineService().saveJobsListOffline(_jobs);
                      } else {
                        await OfflineService().saveJobOffline(
                          jobData,
                          'create',
                        );
                        setState(() {
                          _jobs.add({
                            ...jobData,
                            'id': 'offline_${_jobs.length}',
                          });
                          _hasPendingRequests = true;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations.translate('offlineModeWarning'),
                              ),
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
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: const Icon(Icons.add),
                tooltip: localizations.translate('createJob'),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              )
              : null,
    );
  }

  Widget _buildNoRoleContent(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            localizations.translate('pleaseSelectRole'),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                if (_isOnline) {
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (dialogContext) =>
                            RoleSelectionDialog(userId: user.uid),
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
                        ),
                      ),
                    );
                  }
                }
              }
            },
            style: _buttonStyle(),
            child: Text(localizations.translate('selectRole')),
          ),
        ],
      ),
    );
  }

  Widget _buildJobSeekerContent(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isVerified ? null : _pickImage,
                  style: _buttonStyle(),
                  child: Text(
                    _isVerified
                        ? localizations.translate('verified')
                        : localizations.translate('verifyYourself'),
                  ),
                ),
                if (_isVerified)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ElevatedButton(
                      onPressed: _deleteAvatar,
                      style: ElevatedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(localizations.translate('deletePhoto')),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  _email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButton<String>(
                  value: _status,
                  icon: const Icon(Icons.arrow_drop_down),
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
        ],
      ),
    );
  }

  Widget _buildEmployerContent(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
                const SizedBox(height: 10),
                Text(_name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  _email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            localizations.translate('yourJobs'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _jobs.isEmpty
              ? Center(
                child: Text(
                  _isOnline
                      ? localizations.translate('noJobsCreated')
                      : localizations.translate('connectToInternet'),
                ),
              )
              : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _jobs.length,
                itemBuilder: (context, index) {
                  final job = _jobs[index];
                  final jobId = job['id'] ?? 'offline_${index}';
                  return _buildJobCard(context, job, jobId, localizations);
                },
              ),
        ],
      ),
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    Map<String, dynamic> job,
    String jobId,
    AppLocalizations localizations,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          job['title'] ?? 'Untitled',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${localizations.translate('category')}: ${job['category']}'),
            Text('${localizations.translate('city')}: ${job['city']}'),
            Text('${localizations.translate('salary')}: ${job['salary']}'),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.edit,
            color: Theme.of(context).colorScheme.secondary,
          ),
          onPressed: () {
            if (_isOnline) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => EditJobScreen(jobId: jobId, jobData: job),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizations.translate('offlineModeWarning')),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
