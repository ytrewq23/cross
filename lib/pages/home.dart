import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/pages/apply_job_screen.dart';
import 'notification.dart';
import 'profile.dart';
import 'search.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconly/iconly.dart';
import '../localizations.dart';
import '../orientation_support.dart';
import 'login_page.dart';
import 'role_selection_dialog.dart';
import 'offline_service.dart';

// Utility class for shared methods
class JobCardUtils {
  static Widget buildJobCard(
    BuildContext context,
    Map<String, dynamic> job,
    String jobId,
    AppLocalizations localizations,
    bool isGuest,
  ) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            job['title'] ?? localizations.translate('untitled'),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${localizations.translate('company')}: ${job['company'] ?? localizations.translate('unknown')}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${localizations.translate('location')}: ${job['city'] ?? localizations.translate('unknown')}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${localizations.translate('salary')}: ${job['salary'] ?? localizations.translate('notSpecified')}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${localizations.translate('schedule')}: ${job['schedule'] ?? localizations.translate('notSpecified')}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          trailing: Icon(
            IconlyLight.arrow_right_2,
            color: theme.colorScheme.secondary,
          ),
          onTap: () {
            if (isGuest) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    localizations.translate('pleaseLogin'),
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                  backgroundColor: theme.colorScheme.error,
                  action: SnackBarAction(
                    label: localizations.translate('login'),
                    textColor: theme.colorScheme.secondary,
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                    },
                  ),
                ),
              );
              return;
            }
            RecentJobsManager.saveJob({
              'title': job['title'] ?? localizations.translate('untitled'),
              'company': job['company'] ?? localizations.translate('unknown'),
              'location': job['city'] ?? localizations.translate('unknown'),
              'id': jobId,
            });
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => JobDetailsScreen(job: {...job, 'id': jobId})),
            );
          },
        ),
      ),
    );
  }
}

class RecentJobsManager {
  static Future<void> saveJob(Map<String, dynamic> job) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentJobs = prefs.getStringList('recentJobs') ?? [];
    recentJobs.insert(0, jsonEncode(job));
    if (recentJobs.length > 5) recentJobs = recentJobs.sublist(0, 5);
    await prefs.setStringList('recentJobs', recentJobs);
  }

  static Future<List<Map<String, dynamic>>> getRecentJobs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentJobs = prefs.getStringList('recentJobs') ?? [];
    return recentJobs.map((job) => Map<String, dynamic>.from(jsonDecode(job))).toList();
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
  late final OfflineService _offlineService;

  final List<Widget> _screens = [
    const HomeContent(),
    const SearchPage(),
    NotificationsPage(),
    ProfilePage(),
  ];

  bool get _isGuest => widget.userName == 'Guest' || FirebaseAuth.instance.currentUser?.isAnonymous == true;

  @override
  void initState() {
    super.initState();
    _offlineService = OfflineService();
    _initialize();
  }

  Future<void> _initialize() async {
    await _offlineService.init();
    if (_offlineService.isOnline && mounted) {
      await _offlineService.syncPendingActions(context);
    }
    await _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    if (!mounted || _isGuest || _isRoleDialogShown) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        if (_offlineService.isOnline) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          final role = userDoc.data()?['role'] as String?;
          if (role == null || role.isEmpty) {
            setState(() => _isRoleDialogShown = true);
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => RoleSelectionDialog(userId: user.uid),
            );
            setState(() => _isRoleDialogShown = false);
          }
        } else {
          final prefs = await SharedPreferences.getInstance();
          final role = prefs.getString('userRole');
          if (role == null || role.isEmpty) {
            _offlineService.showOfflineSnackBar(context);
          }
        }
      } catch (e) {
        print('Error checking user role: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error checking role: $e',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
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
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localizations.translate('pleaseLogin'),
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: theme.colorScheme.error,
        action: SnackBarAction(
          label: localizations.translate('login'),
          textColor: theme.colorScheme.secondary,
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
    final theme = Theme.of(context);
    final isOffline = !_offlineService.isOnline;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _isGuest
          ? AppBar(
              title: FadeInDown(
                duration: Duration(milliseconds: 600),
                child: Text(
                  localizations.translate('jobSeekerDashboard'),
                  style: theme.appBarTheme.titleTextStyle,
                ),
              ),
              centerTitle: true,
              backgroundColor: isOffline ? theme.colorScheme.error : theme.colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
              elevation: 4,
              flexibleSpace: isOffline
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.error.withOpacity(0.3), theme.colorScheme.error.withOpacity(0.1)],
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
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
              actions: [
                if (!isOffline)
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                    },
                    child: Text(
                      localizations.translate('login'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            )
          : null,
      body: _isGuest ? const HomeContent() : _currentScreen,
      bottomNavigationBar: _isGuest
          ? null
          : BottomNavigationBar(
              items: [
                BottomNavigationBarItem(
                  icon: Icon(IconlyLight.home),
                  label: localizations.translate('home'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(IconlyLight.search),
                  label: localizations.translate('search'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(IconlyLight.notification),
                  label: localizations.translate('notifications'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(IconlyLight.profile),
                  label: localizations.translate('profile'),
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              elevation: 8,
              backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
              selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
              unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
            ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String? _selectedCategory;

  List<Map<String, String>> getCategories(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return [
      {'display': localizations.translate('categoryIT'), 'firestore': 'categoryIT'},
      {'display': localizations.translate('categoryMarketing'), 'firestore': 'categoryMarketing'},
      {'display': localizations.translate('categorySales'), 'firestore': 'categorySales'},
      {'display': localizations.translate('categoryDesign'), 'firestore': 'categoryDesign'},
      {'display': localizations.translate('categoryHR'), 'firestore': 'categoryHR'},
      {'display': localizations.translate('categoryFinance'), 'firestore': 'categoryFinance'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final categories = getCategories(context);

    return withOrientationSupport(
      context: context,
      portrait: _buildPortraitLayout(context, localizations, categories),
      landscape: _buildLandscapeLayout(context, localizations, categories),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, AppLocalizations localizations, List<Map<String, String>> categories) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    final isGuest = homeState?._isGuest ?? false;
    final isOffline = !homeState!._offlineService.isOnline;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isGuest
          ? null
          : AppBar(
              title: FadeInDown(
                duration: Duration(milliseconds: 600),
                child: Text(
                  localizations.translate('jobSeekerDashboard'),
                  style: theme.appBarTheme.titleTextStyle,
                ),
              ),
              centerTitle: true,
              backgroundColor: isOffline ? theme.colorScheme.error : theme.colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
              elevation: 4,
              flexibleSpace: isOffline
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.error.withOpacity(0.3), theme.colorScheme.error.withOpacity(0.1)],
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
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
              actions: [
                if (!isOffline)
                  IconButton(
                    icon: Icon(IconlyLight.search, color: theme.colorScheme.onPrimary),
                    onPressed: () {
                      if (isGuest) {
                        homeState._showLoginPrompt();
                      } else {
                        homeState._onItemTapped(1);
                      }
                    },
                  ),
              ],
            ),
      body: isOffline
          ? Center(
              child: FadeInDown(
                duration: Duration(milliseconds: 800),
                child: Text(
                  localizations.translate('connectToInternet'),
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(
                      duration: Duration(milliseconds: 800),
                      child: Text(
                        localizations.translate('jobCategories'),
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: FadeInLeft(
                        duration: Duration(milliseconds: 900),
                        child: _buildCategoryList(context, localizations, categories, isGuest),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInDown(
                      duration: Duration(milliseconds: 1000),
                      child: Text(
                        _selectedCategory == null ? localizations.translate('allJobs') : '${localizations.translate('jobCategories')}: $_selectedCategory',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildJobList(context, localizations, isGuest),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, AppLocalizations localizations, List<Map<String, String>> categories) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    final isGuest = homeState?._isGuest ?? false;
    final isOffline = !homeState!._offlineService.isOnline;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isGuest
          ? null
          : AppBar(
              title: FadeInDown(
                duration: Duration(milliseconds: 600),
                child: Text(
                  localizations.translate('jobSeekerDashboard'),
                  style: theme.appBarTheme.titleTextStyle,
                ),
              ),
              centerTitle: true,
              backgroundColor: isOffline ? theme.colorScheme.error : theme.colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
              elevation: 4,
              flexibleSpace: isOffline
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.error.withOpacity(0.3), theme.colorScheme.error.withOpacity(0.1)],
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
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
              actions: [
                if (!isOffline)
                  IconButton(
                    icon: Icon(IconlyLight.search, color: theme.colorScheme.onPrimary),
                    onPressed: () {
                      if (isGuest) {
                        homeState._showLoginPrompt();
                      } else {
                        homeState._onItemTapped(1);
                      }
                    },
                  ),
              ],
            ),
      body: isOffline
          ? Center(
              child: FadeInDown(
                duration: Duration(milliseconds: 800),
                child: Text(
                  localizations.translate('connectToInternet'),
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(
                      duration: Duration(milliseconds: 800),
                      child: Text(
                        localizations.translate('jobCategories'),
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: FadeInLeft(
                        duration: Duration(milliseconds: 900),
                        child: _buildCategoryList(context, localizations, categories, isGuest),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInDown(
                      duration: Duration(milliseconds: 1000),
                      child: Text(
                        _selectedCategory == null ? localizations.translate('allJobs') : '${localizations.translate('jobCategories')}: $_selectedCategory',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildJobList(context, localizations, isGuest),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategoryList(BuildContext context, AppLocalizations localizations, List<Map<String, String>> categories, bool isGuest) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    final theme = Theme.of(context);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: categories.length + 1,
      itemBuilder: (context, index) {
        final isAll = index == 0;
        final category = isAll ? null : categories[index - 1];
        final isSelected = _selectedCategory == (isAll ? null : category!['display']);

        return ZoomIn(
          duration: Duration(milliseconds: 1000 + index * 100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () {
                if (isGuest && !isAll) {
                  homeState?._showLoginPrompt();
                  return;
                }
                setState(() {
                  _selectedCategory = isAll ? null : category!['display'];
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  isAll ? localizations.translate('all') : category!['display']!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.secondary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJobList(BuildContext context, AppLocalizations localizations, bool isGuest) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    final isOffline = !homeState!._offlineService.isOnline;
    final theme = Theme.of(context);
    final categories = getCategories(context);
    final selectedCategoryFirestore = _selectedCategory == null
        ? null
        : categories.firstWhere((cat) => cat['display'] == _selectedCategory, orElse: () => {'firestore': ''})['firestore'];

    if (isOffline) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: homeState._offlineService.getJobsListOffline(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
          }
          var jobs = snapshot.data ?? [];
          if (_selectedCategory != null && selectedCategoryFirestore!.isNotEmpty) {
            jobs = jobs.where((job) => job['category'] == selectedCategoryFirestore).toList();
          }
          if (jobs.isEmpty) {
            return Center(
              child: Text(
                localizations.translate(_selectedCategory == null ? 'connectToInternet' : 'noJobsAvailable'),
                style: theme.textTheme.bodyMedium,
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return FadeInLeft(
                duration: Duration(milliseconds: 900 + index * 100),
                child: JobCardUtils.buildJobCard(context, job, job['id'], localizations, isGuest),
              );
            },
          );
        },
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: selectedCategoryFirestore == null || selectedCategoryFirestore.isEmpty
          ? FirebaseFirestore.instance.collection('jobs').snapshots()
          : FirebaseFirestore.instance.collection('jobs').where('category', isEqualTo: selectedCategoryFirestore).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: theme.textTheme.bodyMedium));
        }
        final jobs = snapshot.data?.docs ?? [];
        if (jobs.isEmpty) {
          return Center(
            child: Text(
              localizations.translate('noJobsAvailable'),
              style: theme.textTheme.bodyMedium,
            ),
          );
        }
        final jobList = jobs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList();
        homeState._offlineService.saveJobsListOffline(jobList);

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index].data() as Map<String, dynamic>;
            final jobId = jobs[index].id;
            return FadeInLeft(
              duration: Duration(milliseconds: 900 + index * 100),
              child: JobCardUtils.buildJobCard(context, job, jobId, localizations, isGuest),
            );
          },
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
      localizations.translate('categoryIT'): 'categoryIT',
      localizations.translate('categoryMarketing'): 'categoryMarketing',
      localizations.translate('categorySales'): 'categorySales',
      localizations.translate('categoryDesign'): 'categoryDesign',
      localizations.translate('categoryHR'): 'categoryHR',
      localizations.translate('categoryFinance'): 'categoryFinance',
    };
    return categoryMap[category] ?? category;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final categoryKey = _getCategoryKey(context);
    final isGuest = FirebaseAuth.instance.currentUser?.isAnonymous == true;
    final offlineService = OfflineService();

    return withOrientationSupport(
      context: context,
      portrait: _buildPortraitLayout(context, localizations, categoryKey, isGuest, offlineService),
      landscape: _buildLandscapeLayout(context, localizations, categoryKey, isGuest, offlineService),
    );
  }

  Widget _buildPortraitLayout(
      BuildContext context, AppLocalizations localizations, String categoryKey, bool isGuest, OfflineService offlineService) {
    final isOffline = !offlineService.isOnline;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: FadeInDown(
          duration: Duration(milliseconds: 600),
          child: Text(
            '${localizations.translate('jobCategories')}: $category',
            style: theme.appBarTheme.titleTextStyle,
          ),
        ),
        centerTitle: true,
        backgroundColor: isOffline ? theme.colorScheme.error : theme.colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
        elevation: 4,
        flexibleSpace: isOffline
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.error.withOpacity(0.3), theme.colorScheme.error.withOpacity(0.1)],
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: isOffline
          ? FutureBuilder<List<Map<String, dynamic>>>(
              future: offlineService.getJobsListOffline(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                }
                var jobs = snapshot.data ?? [];
                jobs = jobs.where((job) => job['category'] == categoryKey).toList();
                if (jobs.isEmpty) {
                  return Center(
                    child: Text(
                      localizations.translate('noJobsAvailable'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return FadeInLeft(
                      duration: Duration(milliseconds: 900 + index * 100),
                      child: JobCardUtils.buildJobCard(context, job, job['id'], localizations, isGuest),
                    );
                  },
                );
              },
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('jobs').where('category', isEqualTo: categoryKey).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: theme.textTheme.bodyMedium));
                }
                final jobs = snapshot.data?.docs ?? [];
                if (jobs.isEmpty) {
                  return Center(
                    child: Text(
                      localizations.translate('noJobsAvailable'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }
                final jobList = jobs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList();
                offlineService.saveJobsListOffline(jobList);

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index].data() as Map<String, dynamic>;
                    final jobId = jobs[index].id;
                    return FadeInLeft(
                      duration: Duration(milliseconds: 900 + index * 100),
                      child: JobCardUtils.buildJobCard(context, job, jobId, localizations, isGuest),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildLandscapeLayout(
      BuildContext context, AppLocalizations localizations, String categoryKey, bool isGuest, OfflineService offlineService) {
    final isOffline = !offlineService.isOnline;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: FadeInDown(
          duration: Duration(milliseconds: 600),
          child: Text(
            '${localizations.translate('jobCategories')}: $category',
            style: theme.appBarTheme.titleTextStyle,
          ),
        ),
        centerTitle: true,
        backgroundColor: isOffline ? theme.colorScheme.error : theme.colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
        elevation: 4,
        flexibleSpace: isOffline
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.error.withOpacity(0.3), theme.colorScheme.error.withOpacity(0.1)],
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: isOffline
          ? FutureBuilder<List<Map<String, dynamic>>>(
              future: offlineService.getJobsListOffline(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                }
                var jobs = snapshot.data ?? [];
                jobs = jobs.where((job) => job['category'] == categoryKey).toList();
                if (jobs.isEmpty) {
                  return Center(
                    child: Text(
                      localizations.translate('noJobsAvailable'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3 / 2,
                  ),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return FadeInLeft(
                      duration: Duration(milliseconds: 900 + index * 100),
                      child: JobCardUtils.buildJobCard(context, job, job['id'], localizations, isGuest),
                    );
                  },
                );
              },
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('jobs').where('category', isEqualTo: categoryKey).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: theme.textTheme.bodyMedium));
                }
                final jobs = snapshot.data?.docs ?? [];
                if (jobs.isEmpty) {
                  return Center(
                    child: Text(
                      localizations.translate('noJobsAvailable'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }
                final jobList = jobs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList();
                offlineService.saveJobsListOffline(jobList);

                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3 / 2,
                  ),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index].data() as Map<String, dynamic>;
                    final jobId = jobs[index].id;
                    return FadeInLeft(
                      duration: Duration(milliseconds: 900 + index * 100),
                      child: JobCardUtils.buildJobCard(context, job, jobId, localizations, isGuest),
                    );
                  },
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
    final offlineService = OfflineService();
    if (!offlineService.isOnline) return;
    try {
      final jobRef = FirebaseFirestore.instance.collection('jobs').doc(job['id']);
      await jobRef.update({'views': FieldValue.increment(1)});
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    _incrementViewCount();

    final localizations = AppLocalizations.of(context);
    final offlineService = OfflineService();

    return withOrientationSupport(
      context: context,
      portrait: _buildPortraitLayout(context, localizations, offlineService),
      landscape: _buildLandscapeLayout(context, localizations, offlineService),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, AppLocalizations localizations, OfflineService offlineService) {
    final isOwnJob = job['employerId'] == FirebaseAuth.instance.currentUser?.uid;
    final isOffline = !offlineService.isOnline;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: FadeInDown(
          duration: Duration(milliseconds: 600),
          child: Text(
            job['title'] ?? localizations.translate('untitled'),
            style: theme.appBarTheme.titleTextStyle,
          ),
        ),
        centerTitle: true,
        backgroundColor: isOffline ? theme.colorScheme.error : theme.colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
        elevation: 4,
        flexibleSpace: isOffline
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.error.withOpacity(0.3), theme.colorScheme.error.withOpacity(0.1)],
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInLeft(
                  duration: Duration(milliseconds: 800),
                  child: Text(
                    '${localizations.translate('company')}: ${job['company'] ?? localizations.translate('unknown')}',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 8),
                FadeInLeft(
                  duration: Duration(milliseconds: 900),
                  child: Text(
                    '${localizations.translate('location')}: ${job['city'] ?? localizations.translate('unknown')}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 8),
                FadeInLeft(
                  duration: Duration(milliseconds: 1000),
                  child: Text(
                    '${localizations.translate('salary')}: ${job['salary'] ?? localizations.translate('notSpecified')}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 8),
                FadeInLeft(
                  duration: Duration(milliseconds: 1100),
                  child: Text(
                    '${localizations.translate('schedule')}: ${job['schedule'] ?? localizations.translate('notSpecified')}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 8),
                FadeInLeft(
                  duration: Duration(milliseconds: 1200),
                  child: Text(
                    '${localizations.translate('employmentType')}: ${job['employmentType'] ?? localizations.translate('notSpecified')}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),
                FadeInLeft(
                  duration: Duration(milliseconds: 1300),
                  child: Text(
                    localizations.translate('description'),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInLeft(
                  duration: Duration(milliseconds: 1400),
                  child: Text(
                    job['description'] ?? localizations.translate('noDescription'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),
                FadeInLeft(
                  duration: Duration(milliseconds: 1500),
                  child: Text(
                    localizations.translate('requirements'),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInLeft(
                  duration: Duration(milliseconds: 1600),
                  child: Text(
                    job['requirements'] ?? localizations.translate('noRequirements'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),
                FadeInLeft(
                  duration: Duration(milliseconds: 1700),
                  child: Text(
                    localizations.translate('contactInfo'),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInLeft(
                  duration: Duration(milliseconds: 1800),
                  child: Text(
                    job['contactInfo'] ?? localizations.translate('noContactInfo'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 24),
                isOwnJob
                    ? FadeInLeft(
                        duration: Duration(milliseconds: 1900),
                        child: Text(
                          localizations.translate('yourVacancy'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : ZoomIn(
                        duration: Duration(milliseconds: 2000),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ApplyJobScreen(jobId: job['id'], jobTitle: job['title'] ?? localizations.translate('untitled')),
                              ),
                            );
                          },
                          child: Text(localizations.translate('apply')),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, AppLocalizations localizations, OfflineService offlineService) {
    final isOwnJob = job['employerId'] == FirebaseAuth.instance.currentUser?.uid;
    final isOffline = !offlineService.isOnline;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: FadeInDown(
          duration: Duration(milliseconds: 600),
          child: Text(
            job['title'] ?? localizations.translate('untitled'),
            style: theme.appBarTheme.titleTextStyle,
          ),
        ),
        centerTitle: true,
        backgroundColor: isOffline ? theme.colorScheme.error : theme.colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
        elevation: 4,
        flexibleSpace: isOffline
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.error.withOpacity(0.3), theme.colorScheme.error.withOpacity(0.1)],
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
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
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInLeft(
                        duration: Duration(milliseconds: 800),
                        child: Text(
                          '${localizations.translate('company')}: ${job['company'] ?? localizations.translate('unknown')}',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInLeft(
                        duration: Duration(milliseconds: 900),
                        child: Text(
                          '${localizations.translate('location')}: ${job['city'] ?? localizations.translate('unknown')}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInLeft(
                        duration: Duration(milliseconds: 1000),
                        child: Text(
                          '${localizations.translate('salary')}: ${job['salary'] ?? localizations.translate('notSpecified')}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInLeft(
                        duration: Duration(milliseconds: 1100),
                        child: Text(
                          '${localizations.translate('schedule')}: ${job['schedule'] ?? localizations.translate('notSpecified')}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInLeft(
                        duration: Duration(milliseconds: 1200),
                        child: Text(
                          '${localizations.translate('employmentType')}: ${job['employmentType'] ?? localizations.translate('notSpecified')}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInLeft(
                        duration: Duration(milliseconds: 1300),
                        child: Text(
                          localizations.translate('description'),
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInLeft(
                        duration: Duration(milliseconds: 1400),
                        child: Text(
                          job['description'] ?? localizations.translate('noDescription'),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeInLeft(
                        duration: Duration(milliseconds: 1500),
                        child: Text(
                          localizations.translate('requirements'),
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInLeft(
                        duration: Duration(milliseconds: 1600),
                        child: Text(
                          job['requirements'] ?? localizations.translate('noRequirements'),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeInLeft(
                        duration: Duration(milliseconds: 1700),
                        child: Text(
                          localizations.translate('contactInfo'),
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInLeft(
                        duration: Duration(milliseconds: 1800),
                        child: Text(
                          job['contactInfo'] ?? localizations.translate('noContactInfo'),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      isOwnJob
                          ? FadeInLeft(
                              duration: Duration(milliseconds: 1900),
                              child: Text(
                                localizations.translate('yourVacancy'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : ZoomIn(
                              duration: Duration(milliseconds: 2000),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ApplyJobScreen(jobId: job['id'], jobTitle: job['title'] ?? localizations.translate('untitled')),
                                    ),
                                  );
                                },
                                child: Text(localizations.translate('apply')),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}