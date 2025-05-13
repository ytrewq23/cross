import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_page.dart';
import 'about_page.dart';
import 'help_page.dart';
import 'create_job_screen.dart';
import 'edit_job_screen.dart';
import 'role_selection_dialog.dart';
import 'apply_job_screen.dart';
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
  List<Map<String, String>> _resumes = [];
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

  static const String _placeholderAvatar = 'assets/avatar_placeholder.jpg';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final avatar = prefs.getString('avatar');
    final savedStatus = prefs.getString('status');
    final isOffline = !OfflineService().isOnline;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      if (isOffline) {
        final offlineResume = await OfflineService().getResumeOffline();
        if (mounted) {
          setState(() {
            _name = prefs.getString('user_name') ?? 'No Name';
            _email = prefs.getString('user_email') ?? 'No Email';
            _userRole = prefs.getString('user_role');
            _isLoading = false;
            if (offlineResume != null) {
              _resumes = [
                {
                  'profession': offlineResume['profession'] as String,
                  'date': offlineResume['date'] as String,
                  'name': offlineResume['name'] as String,
                  'email': offlineResume['email'] as String,
                },
              ];
            }
            if (savedStatus != null && _statuses.contains(savedStatus)) {
              _status = savedStatus;
            }
            _avatarBase64 = avatar;
            if (_avatarBase64 != null) {
              _isVerified = true;
            }
          });
        }
      } else {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        final resumeDoc =
            await FirebaseFirestore.instance
                .collection('resumes')
                .doc(user.uid)
                .get();
        if (mounted) {
          setState(() {
            _name = user.displayName ?? 'No Name';
            _email = user.email ?? 'No Email';
            _userRole = userDoc.data()?['role'] as String?;
            _isLoading = false;
            if (resumeDoc.exists) {
              final resumeData = resumeDoc.data()!;
              _resumes = [
                {
                  'profession': resumeData['profession'] as String,
                  'date': resumeData['date'] as String,
                  'name': resumeData['name'] as String,
                  'email': resumeData['email'] as String,
                },
              ];
              // Сохраняем резюме оффлайн
              OfflineService().saveResumeOffline(resumeData);
            }
            if (savedStatus != null && _statuses.contains(savedStatus)) {
              _status = savedStatus;
            }
            _avatarBase64 = avatar;
            if (_avatarBase64 != null) {
              _isVerified = true;
            }
          });
          // Сохраняем данные для оффлайн-доступа
          await prefs.setString('user_name', _name);
          await prefs.setString('user_email', _email);
          if (_userRole != null) {
            await prefs.setString('user_role', _userRole!);
          }
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _status = newStatus;
      });
      await prefs.setString('status', newStatus);
    }
  }

  Future<void> _uploadAvatar() async {
    if (!await OfflineService().checkConnection()) {
      OfflineService().showOfflineSnackBar(context);
      return;
    }

    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    input.onChange.listen((e) async {
      final files = input.files;
      if (files!.isEmpty) return;

      final reader = html.FileReader();
      reader.readAsDataUrl(files[0]);
      reader.onLoadEnd.listen((e) async {
        final base64String = reader.result as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('avatar', base64String);

        if (mounted) {
          setState(() {
            _avatarBase64 = base64String;
            _isVerified = true;
          });
        }
      });
    });
  }

  Future<void> _updateResume() async {
    if (!await OfflineService().checkConnection()) {
      OfflineService().showOfflineSnackBar(context);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final professionController = TextEditingController();
    final dateController = TextEditingController();
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    if (_resumes.isNotEmpty) {
      professionController.text = _resumes[0]['profession'] ?? '';
      dateController.text = _resumes[0]['date'] ?? '';
      nameController.text = _resumes[0]['name'] ?? '';
      emailController.text = _resumes[0]['email'] ?? '';
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).translate('updateResume')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: professionController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    ).translate('profession'),
                  ),
                ),
                TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).translate('date'),
                  ),
                ),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).translate('name'),
                  ),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).translate('email'),
                  ),
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
              onPressed: () {
                Navigator.pop(context, {
                  'profession': professionController.text,
                  'date': dateController.text,
                  'name': nameController.text,
                  'email': emailController.text,
                });
              },
              child: Text(AppLocalizations.of(context).translate('save')),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        await FirebaseFirestore.instance
            .collection('resumes')
            .doc(user.uid)
            .set(result);
        await OfflineService().saveResumeOffline(result);
        if (mounted) {
          setState(() {
            _resumes = [result];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('resumeUpdated'),
              ),
            ),
          );
        }
      } catch (e) {
        print('Error updating resume: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating resume: $e')));
        }
      }
    }
  }

  Future<void> _signOut() async {
    if (!await OfflineService().checkConnection()) {
      OfflineService().showOfflineSnackBar(context);
      return;
    }

    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    }
  }

  Future<void> _deleteJob(String jobId) async {
    if (!await OfflineService().checkConnection()) {
      await OfflineService().saveJobOffline({'id': jobId}, 'delete');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('jobDeletionSavedOffline'),
            ),
          ),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('jobDeleted')),
          ),
        );
      }
    } catch (e) {
      print('Error deleting job: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting job: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isOffline = !OfflineService().isOnline;

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
    final isOffline = !OfflineService().isOnline;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('profile')),
        centerTitle: true,
        backgroundColor: isOffline ? Colors.red : null,
        actions:
            isOffline
                ? [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Center(
                      child: Text(
                        localizations.translate('connectToInternet'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ]
                : null,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : isOffline && _resumes.isEmpty && _userRole == null
              ? Center(
                child: Text(localizations.translate('connectToInternet')),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage:
                                _avatarBase64 != null
                                    ? MemoryImage(
                                      base64Decode(
                                        _avatarBase64!.split(',').last,
                                      ),
                                    )
                                    : const AssetImage(_placeholderAvatar)
                                        as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                              onPressed: _uploadAvatar,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Center(
                      child: Text(
                        _email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Center(
                      child:
                          _isVerified
                              ? const Icon(
                                Icons.verified,
                                color: Colors.green,
                                size: 24,
                              )
                              : Text(localizations.translate('notVerified')),
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<String>(
                      value: _status,
                      onChanged:
                          (newStatus) => _updateStatus(newStatus ?? _status),
                      items:
                          _statuses
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(localizations.translate(status)),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.translate('resume'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _resumes.isEmpty
                        ? Text(localizations.translate('noResume'))
                        : Column(
                          children:
                              _resumes.map((resume) {
                                return Card(
                                  child: ListTile(
                                    title: Text(
                                      resume['profession'] ?? 'No Profession',
                                    ),
                                    subtitle: Text(
                                      '${resume['date']}\n${resume['name']}\n${resume['email']}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: _updateResume,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                    const SizedBox(height: 16),
                    if (_resumes.isEmpty)
                      ElevatedButton(
                        onPressed: _updateResume,
                        child: Text(localizations.translate('addResume')),
                      ),
                    const SizedBox(height: 16),
                    if (_userRole == 'employer') ...[
                      Text(
                        localizations.translate('myVacancies'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      isOffline
                          ? Center(
                            child: Text(
                              localizations.translate('connectToInternet'),
                            ),
                          )
                          : StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('jobs')
                                    .where(
                                      'employerId',
                                      isEqualTo:
                                          FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.uid,
                                    )
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final jobs = snapshot.data?.docs ?? [];
                              if (jobs.isEmpty) {
                                return Text(
                                  localizations.translate('noVacancies'),
                                );
                              }
                              return Column(
                                children:
                                    jobs.map((job) {
                                      final jobData =
                                          job.data() as Map<String, dynamic>;
                                      return Card(
                                        child: ListTile(
                                          title: Text(jobData['title'] ?? ''),
                                          subtitle: Text(
                                            '${jobData['company'] ?? ''}\n${jobData['city'] ?? ''}',
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                onPressed: () async {
                                                  if (!await OfflineService()
                                                      .checkConnection()) {
                                                    OfflineService()
                                                        .showOfflineSnackBar(
                                                          context,
                                                        );
                                                    return;
                                                  }
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              EditJobScreen(
                                                                jobId: job.id,
                                                                jobData:
                                                                    jobData,
                                                              ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                onPressed:
                                                    () => _deleteJob(job.id),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              );
                            },
                          ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (!await OfflineService().checkConnection()) {
                            OfflineService().showOfflineSnackBar(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateJobScreen(),
                            ),
                          );
                        },
                        child: Text(localizations.translate('createJob')),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      localizations.translate('applications'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    isOffline
                        ? Center(
                          child: Text(
                            localizations.translate('connectToInternet'),
                          ),
                        )
                        : StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('applications')
                                  .where(
                                    'userId',
                                    isEqualTo:
                                        FirebaseAuth.instance.currentUser?.uid,
                                  )
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final applications = snapshot.data?.docs ?? [];
                            if (applications.isEmpty) {
                              return Text(
                                localizations.translate('noApplications'),
                              );
                            }
                            return Column(
                              children:
                                  applications.map((app) {
                                    final appData =
                                        app.data() as Map<String, dynamic>;
                                    return Card(
                                      child: ListTile(
                                        title: Text(appData['jobTitle'] ?? ''),
                                        subtitle: Text(
                                          '${appData['status'] ?? 'Pending'}\n${appData['appliedAt']?.toDate() ?? ''}',
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            );
                          },
                        ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.translate('settings'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: Text(localizations.translate('settings')),
                      onTap: () async {
                        if (!await OfflineService().checkConnection()) {
                          OfflineService().showOfflineSnackBar(context);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: Text(localizations.translate('about')),
                      onTap: () async {
                        if (!await OfflineService().checkConnection()) {
                          OfflineService().showOfflineSnackBar(context);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AboutPage()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: Text(localizations.translate('help')),
                      onTap: () async {
                        if (!await OfflineService().checkConnection()) {
                          OfflineService().showOfflineSnackBar(context);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HelpPage()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.work),
                      title: Text(localizations.translate('changeRole')),
                      onTap: () async {
                        if (!await OfflineService().checkConnection()) {
                          OfflineService().showOfflineSnackBar(context);
                          return;
                        }
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          showDialog(
                            context: context,
                            builder:
                                (context) =>
                                    RoleSelectionDialog(userId: user.uid),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: _signOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text(localizations.translate('signOut')),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final isOffline = !OfflineService().isOnline;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('profile')),
        centerTitle: true,
        backgroundColor: isOffline ? Colors.red : null,
        actions:
            isOffline
                ? [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Center(
                      child: Text(
                        localizations.translate('connectToInternet'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ]
                : null,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : isOffline && _resumes.isEmpty && _userRole == null
              ? Center(
                child: Text(localizations.translate('connectToInternet')),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage:
                                      _avatarBase64 != null
                                          ? MemoryImage(
                                            base64Decode(
                                              _avatarBase64!.split(',').last,
                                            ),
                                          )
                                          : const AssetImage(_placeholderAvatar)
                                              as ImageProvider,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                    ),
                                    onPressed: _uploadAvatar,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              _name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Center(
                            child: Text(
                              _email,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Center(
                            child:
                                _isVerified
                                    ? const Icon(
                                      Icons.verified,
                                      color: Colors.green,
                                      size: 24,
                                    )
                                    : Text(
                                      localizations.translate('notVerified'),
                                    ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButton<String>(
                            value: _status,
                            onChanged:
                                (newStatus) =>
                                    _updateStatus(newStatus ?? _status),
                            items:
                                _statuses
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(
                                          localizations.translate(status),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            localizations.translate('resume'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          _resumes.isEmpty
                              ? Text(localizations.translate('noResume'))
                              : Column(
                                children:
                                    _resumes.map((resume) {
                                      return Card(
                                        child: ListTile(
                                          title: Text(
                                            resume['profession'] ??
                                                'No Profession',
                                          ),
                                          subtitle: Text(
                                            '${resume['date']}\n${resume['name']}\n${resume['email']}',
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: _updateResume,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                          const SizedBox(height: 16),
                          if (_resumes.isEmpty)
                            ElevatedButton(
                              onPressed: _updateResume,
                              child: Text(localizations.translate('addResume')),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_userRole == 'employer') ...[
                            Text(
                              localizations.translate('myVacancies'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            isOffline
                                ? Center(
                                  child: Text(
                                    localizations.translate(
                                      'connectToInternet',
                                    ),
                                  ),
                                )
                                : StreamBuilder<QuerySnapshot>(
                                  stream:
                                      FirebaseFirestore.instance
                                          .collection('jobs')
                                          .where(
                                            'employerId',
                                            isEqualTo:
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser
                                                    ?.uid,
                                          )
                                          .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    final jobs = snapshot.data?.docs ?? [];
                                    if (jobs.isEmpty) {
                                      return Text(
                                        localizations.translate('noVacancies'),
                                      );
                                    }
                                    return Column(
                                      children:
                                          jobs.map((job) {
                                            final jobData =
                                                job.data()
                                                    as Map<String, dynamic>;
                                            return Card(
                                              child: ListTile(
                                                title: Text(
                                                  jobData['title'] ?? '',
                                                ),
                                                subtitle: Text(
                                                  '${jobData['company'] ?? ''}\n${jobData['city'] ?? ''}',
                                                ),
                                                trailing: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                      ),
                                                      onPressed: () async {
                                                        if (!await OfflineService()
                                                            .checkConnection()) {
                                                          OfflineService()
                                                              .showOfflineSnackBar(
                                                                context,
                                                              );
                                                          return;
                                                        }
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  context,
                                                                ) => EditJobScreen(
                                                                  jobId: job.id,
                                                                  jobData:
                                                                      jobData,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                      ),
                                                      onPressed:
                                                          () => _deleteJob(
                                                            job.id,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    );
                                  },
                                ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                if (!await OfflineService().checkConnection()) {
                                  OfflineService().showOfflineSnackBar(context);
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const CreateJobScreen(),
                                  ),
                                );
                              },
                              child: Text(localizations.translate('createJob')),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            localizations.translate('applications'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          isOffline
                              ? Center(
                                child: Text(
                                  localizations.translate('connectToInternet'),
                                ),
                              )
                              : StreamBuilder<QuerySnapshot>(
                                stream:
                                    FirebaseFirestore.instance
                                        .collection('applications')
                                        .where(
                                          'userId',
                                          isEqualTo:
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser
                                                  ?.uid,
                                        )
                                        .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  final applications =
                                      snapshot.data?.docs ?? [];
                                  if (applications.isEmpty) {
                                    return Text(
                                      localizations.translate('noApplications'),
                                    );
                                  }
                                  return Column(
                                    children:
                                        applications.map((app) {
                                          final appData =
                                              app.data()
                                                  as Map<String, dynamic>;
                                          return Card(
                                            child: ListTile(
                                              title: Text(
                                                appData['jobTitle'] ?? '',
                                              ),
                                              subtitle: Text(
                                                '${appData['status'] ?? 'Pending'}\n${appData['appliedAt']?.toDate() ?? ''}',
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  );
                                },
                              ),
                          const SizedBox(height: 16),
                          Text(
                            localizations.translate('settings'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          ListTile(
                            leading: const Icon(Icons.settings),
                            title: Text(localizations.translate('settings')),
                            onTap: () async {
                              if (!await OfflineService().checkConnection()) {
                                OfflineService().showOfflineSnackBar(context);
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsPage(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.info),
                            title: Text(localizations.translate('about')),
                            onTap: () async {
                              if (!await OfflineService().checkConnection()) {
                                OfflineService().showOfflineSnackBar(context);
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AboutPage(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.help),
                            title: Text(localizations.translate('help')),
                            onTap: () async {
                              if (!await OfflineService().checkConnection()) {
                                OfflineService().showOfflineSnackBar(context);
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HelpPage(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.work),
                            title: Text(localizations.translate('changeRole')),
                            onTap: () async {
                              if (!await OfflineService().checkConnection()) {
                                OfflineService().showOfflineSnackBar(context);
                                return;
                              }
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) =>
                                          RoleSelectionDialog(userId: user.uid),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton(
                              onPressed: _signOut,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: Text(localizations.translate('signOut')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
