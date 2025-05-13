import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/pages/apply_job_screen.dart';
import 'notification.dart';
import 'profile.dart';
import 'search.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../localizations.dart';
import '../orientation_support.dart';
import 'login_page.dart';
import 'role_selection_dialog.dart';
import 'offline_service.dart';

class RecentJobsManager {
  static Future<void> saveJob(Map<String, String> job) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentJobs = prefs.getStringList('recentJobs') ?? [];
    recentJobs.insert(0, jsonEncode(job));
    if (recentJobs.length > 5) recentJobs = recentJobs.sublist(0, 5);
    await prefs.setStringList('recentJobs', recentJobs);
  }

  static Future<List<Map<String, String>>> getRecentJobs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentJobs = prefs.getStringList('recentJobs') ?? [];
    return recentJobs
        .map((job) => Map<String, String>.from(jsonDecode(job)))
        .toList();
  }
}

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({required this.userName, super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Widget _currentScreen = const HomeContent();
  bool _isRoleDialogShown = false;

  final List<Widget> _screens = [
    const HomeContent(),
    const SearchPage(),
    NotificationsPage(),
    ProfilePage(),
  ];

  bool get _isGuest =>
      widget.userName == 'Guest' || FirebaseAuth.instance.currentUser == null;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    if (!mounted || _isGuest || _isRoleDialogShown) return;

    if (!await OfflineService().checkConnection()) {
      OfflineService().showOfflineSnackBar(context);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        final role = userDoc.data()?['role'] as String?;

        if (role == null || role.isEmpty && mounted) {
          setState(() => _isRoleDialogShown = true);
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => RoleSelectionDialog(userId: user.uid),
          );
          if (mounted) {
            setState(() => _isRoleDialogShown = false);
          }
        }
      } catch (e) {
        print('Error checking user role: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error checking role: $e')));
        }
      }
    }
  }

  void _onItemTapped(int index) {
    if (_isGuest && index != 0) {
      _showLoginPrompt();
      return;
    }
    setState(() {
      _selectedIndex = index;
      _currentScreen = _screens[index];
    });
  }

  void _showLoginPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).translate('pleaseLogin')),
        action: SnackBarAction(
          label: AppLocalizations.of(context).translate('login'),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isOffline = !OfflineService().isOnline;

    return Scaffold(
      appBar:
          _isGuest
              ? AppBar(
                title: Text(localizations.translate('jobSeekerDashboard')),
                centerTitle: true,
                backgroundColor: isOffline ? Colors.red : null,
                flexibleSpace:
                    isOffline
                        ? Container(
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
                        )
                        : null,
                actions: [
                  if (!isOffline)
                    TextButton(
                      onPressed: () async {
                        if (!await OfflineService().checkConnection()) {
                          OfflineService().showOfflineSnackBar(context);
                          return;
                        }
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: Text(
                        localizations.translate('login'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              )
              : null,
      body: _isGuest ? const HomeContent() : _currentScreen,
      bottomNavigationBar:
          _isGuest
              ? null
              : BottomNavigationBar(
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home),
                    label: localizations.translate('home'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.search),
                    label: localizations.translate('search'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.notifications),
                    label: localizations.translate('notifications'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person),
                    label: localizations.translate('profile'),
                  ),
                ],
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                selectedItemColor: Theme.of(context).colorScheme.secondary,
                unselectedItemColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.6),
                backgroundColor: Theme.of(context).colorScheme.surface,
              ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  List<String> getCategories(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return [
      localizations.translate('categoryIT'),
      localizations.translate('categoryMarketing'),
      localizations.translate('categorySales'),
      localizations.translate('categoryDesign'),
      localizations.translate('categoryHR'),
      localizations.translate('categoryFinance'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final categories = getCategories(context);

    return withOrientationSupport(
      context: context,
      portrait: _buildPortraitLayout(context, localizations, categories),
      landscape: _buildLandscapeLayout(context, localizations, categories),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    AppLocalizations localizations,
    List<String> categories,
  ) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    final isGuest = homeState?._isGuest ?? false;
    final isOffline = !OfflineService().isOnline;

    return Scaffold(
      appBar:
          isGuest
              ? null
              : AppBar(
                title: Text(localizations.translate('jobSeekerDashboard')),
                centerTitle: true,
                backgroundColor: isOffline ? Colors.red : null,
                flexibleSpace:
                    isOffline
                        ? Container(
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
                        )
                        : null,
                actions: [
                  if (!isOffline)
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () async {
                        if (!await OfflineService().checkConnection()) {
                          OfflineService().showOfflineSnackBar(context);
                          return;
                        }
                        if (isGuest) {
                          homeState?._showLoginPrompt();
                        } else {
                          homeState?._onItemTapped(1);
                        }
                      },
                    ),
                ],
              ),
      body:
          isOffline
              ? Center(
                child: Text(localizations.translate('connectToInternet')),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        localizations.translate('recentJobs'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(
                        height: 200,
                        child: _buildRecentJobs(
                          context,
                          localizations,
                          isGuest,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        localizations.translate('jobCategories'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      _buildCategoryGrid(
                        context,
                        categories,
                        crossAxisCount: 2,
                        isGuest: isGuest,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    AppLocalizations localizations,
    List<String> categories,
  ) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    final isGuest = homeState?._isGuest ?? false;
    final isOffline = !OfflineService().isOnline;

    return Scaffold(
      appBar:
          isGuest
              ? null
              : AppBar(
                title: Text(localizations.translate('jobSeekerDashboard')),
                centerTitle: true,
                backgroundColor: isOffline ? Colors.red : null,
                flexibleSpace:
                    isOffline
                        ? Container(
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
                        )
                        : null,
                actions: [
                  if (!isOffline)
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () async {
                        if (!await OfflineService().checkConnection()) {
                          OfflineService().showOfflineSnackBar(context);
                          return;
                        }
                        if (isGuest) {
                          homeState?._showLoginPrompt();
                        } else {
                          homeState?._onItemTapped(1);
                        }
                      },
                    ),
                ],
              ),
      body:
          isOffline
              ? Center(
                child: Text(localizations.translate('connectToInternet')),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.translate('recentJobs'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            SizedBox(
                              height: 200,
                              child: _buildRecentJobs(
                                context,
                                localizations,
                                isGuest,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.translate('jobCategories'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            _buildCategoryGrid(
                              context,
                              categories,
                              crossAxisCount: 3,
                              isGuest: isGuest,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildRecentJobs(
    BuildContext context,
    AppLocalizations localizations,
    bool isGuest,
  ) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    final isOffline = !OfflineService().isOnline;

    if (isOffline) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: OfflineService().getJobsListOffline(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final jobs = snapshot.data ?? [];
          if (jobs.isEmpty) {
            return Center(
              child: Text(
                localizations.translate('connectToInternet'),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return GestureDetector(
                onTap: () {
                  if (isGuest) {
                    homeState?._showLoginPrompt();
                    return;
                  }
                  RecentJobsManager.saveJob({
                    'title': job['title'] ?? '',
                    'company': job['company'] ?? 'Unknown',
                    'location': job['city'] ?? 'Unknown',
                    'id': job['id'] ?? '',
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobDetailsScreen(job: job),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.all(8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work,
                          size: 40,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          job['title'] ?? '',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          job['company'] ?? 'Unknown',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final jobs = snapshot.data?.docs ?? [];
        if (jobs.isEmpty) {
          return Center(
            child: Text(
              localizations.translate('noRecentJobs'),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        final jobList =
            jobs
                .map(
                  (doc) => {
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  },
                )
                .toList();
        OfflineService().saveJobsListOffline(jobList);

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index].data() as Map<String, dynamic>;
            final jobId = jobs[index].id;
            return GestureDetector(
              onTap: () async {
                if (!await OfflineService().checkConnection()) {
                  OfflineService().showOfflineSnackBar(context);
                  return;
                }
                if (isGuest) {
                  homeState?._showLoginPrompt();
                  return;
                }
                RecentJobsManager.saveJob({
                  'title': job['title'] ?? '',
                  'company': job['company'] ?? 'Unknown',
                  'location': job['city'] ?? 'Unknown',
                  'id': jobId,
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            JobDetailsScreen(job: {...job, 'id': jobId}),
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.all(8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.work,
                        size: 40,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        job['title'] ?? '',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        job['company'] ?? 'Unknown',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryGrid(
    BuildContext context,
    List<String> categories, {
    required int crossAxisCount,
    required bool isGuest,
  }) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () async {
            if (!await OfflineService().checkConnection()) {
              OfflineService().showOfflineSnackBar(context);
              return;
            }
            if (isGuest) {
              homeState?._showLoginPrompt();
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        CategoryJobsScreen(category: categories[index]),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              categories[index],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class CategoryJobsScreen extends StatelessWidget {
  final String category;

  const CategoryJobsScreen({required this.category, super.key});

  String _getCategoryKey(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final categoryMap = {
      localizations.translate('categoryIT'): 'ИТ',
      localizations.translate('categoryMarketing'): 'Маркетинг',
      localizations.translate('categorySales'): 'Продажи',
      localizations.translate('categoryDesign'): 'Дизайн',
      localizations.translate('categoryHR'): 'HR',
      localizations.translate('categoryFinance'): 'Финансы',
    };
    return categoryMap[category] ?? category;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final categoryKey = _getCategoryKey(context);
    final isGuest = FirebaseAuth.instance.currentUser == null;
    final isOffline = !OfflineService().isOnline;

    return withOrientationSupport(
      context: context,
      portrait: _buildPortraitLayout(
        context,
        localizations,
        categoryKey,
        isGuest,
      ),
      landscape: _buildLandscapeLayout(
        context,
        localizations,
        categoryKey,
        isGuest,
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    AppLocalizations localizations,
    String categoryKey,
    bool isGuest,
  ) {
    final isOffline = !OfflineService().isOnline;

    return Scaffold(
      appBar: AppBar(
        title: Text('${localizations.translate('jobCategories')}: $category'),
        centerTitle: true,
        backgroundColor: isOffline ? Colors.red : null,
        flexibleSpace:
            isOffline
                ? Container(
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
                )
                : null,
      ),
      body:
          isOffline
              ? Center(
                child: Text(localizations.translate('connectToInternet')),
              )
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('jobs')
                        .where('category', isEqualTo: categoryKey)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final jobs = snapshot.data?.docs ?? [];
                  if (jobs.isEmpty) {
                    return Center(
                      child: Text(localizations.translate('noJobsAvailable')),
                    );
                  }
                  final jobList =
                      jobs
                          .map(
                            (doc) => {
                              ...doc.data() as Map<String, dynamic>,
                              'id': doc.id,
                            },
                          )
                          .toList();
                  OfflineService().saveJobsListOffline(jobList);

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index].data() as Map<String, dynamic>;
                      final jobId = jobs[index].id;
                      return _buildJobCard(
                        context,
                        job,
                        jobId,
                        localizations,
                        isGuest,
                      );
                    },
                  );
                },
              ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    AppLocalizations localizations,
    String categoryKey,
    bool isGuest,
  ) {
    final isOffline = !OfflineService().isOnline;

    return Scaffold(
      appBar: AppBar(
        title: Text('${localizations.translate('jobCategories')}: $category'),
        centerTitle: true,
        backgroundColor: isOffline ? Colors.red : null,
        flexibleSpace:
            isOffline
                ? Container(
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
                )
                : null,
      ),
      body:
          isOffline
              ? Center(
                child: Text(localizations.translate('connectToInternet')),
              )
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('jobs')
                        .where('category', isEqualTo: categoryKey)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final jobs = snapshot.data?.docs ?? [];
                  if (jobs.isEmpty) {
                    return Center(
                      child: Text(localizations.translate('noJobsAvailable')),
                    );
                  }
                  final jobList =
                      jobs
                          .map(
                            (doc) => {
                              ...doc.data() as Map<String, dynamic>,
                              'id': doc.id,
                            },
                          )
                          .toList();
                  OfflineService().saveJobsListOffline(jobList);

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 3 / 2,
                        ),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index].data() as Map<String, dynamic>;
                      final jobId = jobs[index].id;
                      return _buildJobCard(
                        context,
                        job,
                        jobId,
                        localizations,
                        isGuest,
                      );
                    },
                  );
                },
              ),
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    Map<String, dynamic> job,
    String jobId,
    AppLocalizations localizations,
    bool isGuest,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          job['title'] ?? '',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${localizations.translate('company')}: ${job['company'] ?? 'Unknown'}',
            ),
            Text(
              '${localizations.translate('location')}: ${job['city'] ?? 'Unknown'}',
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () async {
          if (!await OfflineService().checkConnection()) {
            OfflineService().showOfflineSnackBar(context);
            return;
          }
          if (isGuest) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.translate('pleaseLogin')),
                action: SnackBarAction(
                  label: localizations.translate('login'),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                ),
              ),
            );
            return;
          }
          RecentJobsManager.saveJob({
            'title': job['title'] ?? '',
            'company': job['company'] ?? 'Unknown',
            'location': job['city'] ?? 'Unknown',
            'id': jobId,
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => JobDetailsScreen(job: {...job, 'id': jobId}),
            ),
          );
        },
      ),
    );
  }
}

class JobDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobDetailsScreen({required this.job, super.key});

  Future<void> _incrementViewCount() async {
    if (!await OfflineService().checkConnection()) return;
    try {
      final jobRef = FirebaseFirestore.instance
          .collection('jobs')
          .doc(job['id']);
      await jobRef.update({'views': FieldValue.increment(1)});
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    _incrementViewCount();

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
    final isOwnJob =
        job['employerId'] == FirebaseAuth.instance.currentUser?.uid;
    final isOffline = !OfflineService().isOnline;

    return Scaffold(
      appBar: AppBar(
        title: Text(job['title'] ?? ''),
        centerTitle: true,
        backgroundColor: isOffline ? Colors.red : null,
        flexibleSpace:
            isOffline
                ? Container(
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
                )
                : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${localizations.translate('company')}: ${job['company'] ?? 'Unknown'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${localizations.translate('location')}: ${job['city'] ?? 'Unknown'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${localizations.translate('salary')}: ${job['salary'] ?? 'Not specified'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${localizations.translate('schedule')}: ${job['schedule'] ?? 'Not specified'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${localizations.translate('employmentType')}: ${job['employmentType'] ?? 'Not specified'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('description'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              job['description'] ?? 'No description available',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('requirements'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              job['requirements'] ?? 'No requirements specified',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('contactInfo'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              job['contactInfo'] ?? 'No contact information provided',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            isOwnJob
                ? Text(
                  localizations.translate('yourVacancy'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontStyle: FontStyle.italic,
                  ),
                )
                : ElevatedButton(
                  onPressed: () async {
                    if (!await OfflineService().checkConnection()) {
                      OfflineService().showOfflineSnackBar(context);
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ApplyJobScreen(
                              jobId: job['id'],
                              jobTitle: job['title'] ?? 'Untitled',
                            ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(localizations.translate('apply')),
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
    final isOwnJob =
        job['employerId'] == FirebaseAuth.instance.currentUser?.uid;
    final isOffline = !OfflineService().isOnline;

    return Scaffold(
      appBar: AppBar(
        title: Text(job['title'] ?? ''),
        centerTitle: true,
        backgroundColor: isOffline ? Colors.red : null,
        flexibleSpace:
            isOffline
                ? Container(
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
                )
                : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${localizations.translate('company')}: ${job['company'] ?? 'Unknown'}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('location')}: ${job['city'] ?? 'Unknown'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('salary')}: ${job['salary'] ?? 'Not specified'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('schedule')}: ${job['schedule'] ?? 'Not specified'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('employmentType')}: ${job['employmentType'] ?? 'Not specified'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('description'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job['description'] ?? 'No description available',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('requirements'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job['requirements'] ?? 'No requirements specified',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('contactInfo'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job['contactInfo'] ?? 'No contact information provided',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  isOwnJob
                      ? Text(
                        localizations.translate('yourVacancy'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                      : ElevatedButton(
                        onPressed: () async {
                          if (!await OfflineService().checkConnection()) {
                            OfflineService().showOfflineSnackBar(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ApplyJobScreen(
                                    jobId: job['id'],
                                    jobTitle: job['title'] ?? 'Untitled',
                                  ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: Text(localizations.translate('apply')),
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
