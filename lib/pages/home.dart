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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error checking role: $e',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localizations.translate('pleaseLogin'),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        action: SnackBarAction(
          label: localizations.translate('login'),
          textColor: Color(0xFFF4A261),
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

    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            minimumSize: Size(double.infinity, 48),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.symmetric(vertical: 8),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xFFF8FAFC),
          selectedItemColor: Color(0xFF2A9D8F),
          unselectedItemColor: Color(0xFF6B7280),
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
          showUnselectedLabels: true,
        ),
      ),
      child: Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        appBar: _isGuest
            ? AppBar(
          title: FadeInDown(
            duration: Duration(milliseconds: 600),
            child: Text(
              localizations.translate('jobSeekerDashboard'),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: isOffline ? Colors.red : Color(0xFF2A9D8F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          elevation: 4,
          flexibleSpace: isOffline
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
              borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(16)),
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
                    color: Colors.white,
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
          backgroundColor: Color(0xFFF8FAFC),
          selectedItemColor: Color(0xFF2A9D8F),
          unselectedItemColor: Color(0xFF6B7280),
        ),
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
      backgroundColor: Color(0xFFF8FAFC),
      appBar: isGuest
          ? null
          : AppBar(
        title: FadeInDown(
          duration: Duration(milliseconds: 600),
          child: Text(
            localizations.translate('jobSeekerDashboard'),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: isOffline ? Colors.red : Color(0xFF2A9D8F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        elevation: 4,
        flexibleSpace: isOffline
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
            borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(16)),
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
        )
            : null,
        actions: [
          if (!isOffline)
            IconButton(
              icon: Icon(IconlyLight.search, color: Colors.white),
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
      body: isOffline
          ? Center(
        child: FadeInDown(
          duration: Duration(milliseconds: 800),
          child: Text(
            localizations.translate('connectToInternet'),
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
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
                  localizations.translate('recentJobs'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF264653),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 200,
                    child: FadeInLeft(
                      duration: Duration(milliseconds: 900),
                      child: _buildRecentJobs(context, localizations, isGuest),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeInDown(
                duration: Duration(milliseconds: 1000),
                child: Text(
                  localizations.translate('jobCategories'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF264653),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: FadeInLeft(
                    duration: Duration(milliseconds: 1100),
                    child: _buildCategoryGrid(
                      context,
                      categories,
                      crossAxisCount: 2,
                      isGuest: isGuest,
                    ),
                  ),
                ),
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
      backgroundColor: Color(0xFFF8FAFC),
      appBar: isGuest
          ? null
          : AppBar(
        title: FadeInDown(
          duration: Duration(milliseconds: 600),
          child: Text(
            localizations.translate('jobSeekerDashboard'),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: isOffline ? Colors.red : Color(0xFF2A9D8F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        elevation: 4,
        flexibleSpace: isOffline
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
            borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(16)),
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
        )
            : null,
        actions: [
          if (!isOffline)
            IconButton(
              icon: Icon(IconlyLight.search, color: Colors.white),
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
      body: isOffline
          ? Center(
        child: FadeInDown(
          duration: Duration(milliseconds: 800),
          child: Text(
            localizations.translate('connectToInternet'),
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(
                      duration: Duration(milliseconds: 800),
                      child: Text(
                        localizations.translate('recentJobs'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF264653),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: 200,
                          child: FadeInLeft(
                            duration: Duration(milliseconds: 900),
                            child: _buildRecentJobs(context, localizations, isGuest),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(
                      duration: Duration(milliseconds: 1000),
                      child: Text(
                        localizations.translate('jobCategories'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF264653),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: FadeInLeft(
                          duration: Duration(milliseconds: 1100),
                          child: _buildCategoryGrid(
                            context,
                            categories,
                            crossAxisCount: 3,
                            isGuest: isGuest,
                          ),
                        ),
                      ),
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
            return Center(child: CircularProgressIndicator(color: Color(0xFF2A9D8F)));
          }
          final jobs = snapshot.data ?? [];
          if (jobs.isEmpty) {
            return Center(
              child: Text(
                localizations.translate('connectToInternet'),
                style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
              ),
            );
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return ZoomIn(
                duration: Duration(milliseconds: 1000 + index * 100),
                child: GestureDetector(
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
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Color(0xFF6B7280).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Container(
                      width: 150,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            IconlyLight.work,
                            size: 40,
                            color: Color(0xFFF4A261),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            job['title'] ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF264653),
                            ),
                          ),
                          Text(
                            job['company'] ?? 'Unknown',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
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
          return Center(child: CircularProgressIndicator(color: Color(0xFF2A9D8F)));
        }
        final jobs = snapshot.data?.docs ?? [];
        if (jobs.isEmpty) {
          return Center(
            child: Text(
              localizations.translate('noRecentJobs'),
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
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
            return ZoomIn(
              duration: Duration(milliseconds: 1000 + index * 100),
              child: GestureDetector(
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
                      builder: (context) => JobDetailsScreen(job: {...job, 'id': jobId}),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.all(8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Color(0xFF6B7280).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          IconlyLight.work,
                          size: 40,
                          color: Color(0xFFF4A261),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          job['title'] ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF264653),
                          ),
                        ),
                        Text(
                          job['company'] ?? 'Unknown',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
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
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        return ZoomIn(
          duration: Duration(milliseconds: 1200 + index * 100),
          child: GestureDetector(
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
                  builder: (context) => CategoryJobsScreen(category: categories[index]),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFF6B7280).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF264653).withOpacity(0.1),
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
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF4A261),
                ),
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
      portrait: _buildPortraitLayout(context, localizations, categoryKey, isGuest),
      landscape: _buildLandscapeLayout(context, localizations, categoryKey, isGuest),
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
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: FadeInDown(
          duration: Duration(milliseconds: 600),
          child: Text(
            '${localizations.translate('jobCategories')}: $category',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: isOffline ? Colors.red : Color(0xFF2A9D8F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        elevation: 4,
        flexibleSpace: isOffline
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
        )
            : null,
      ),
      body: isOffline
          ? Center(
        child: FadeInDown(
          duration: Duration(milliseconds: 800),
          child: Text(
            localizations.translate('connectToInternet'),
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('category', isEqualTo: categoryKey)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xFF2A9D8F)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            );
          }
          final jobs = snapshot.data?.docs ?? [];
          if (jobs.isEmpty) {
            return Center(
              child: Text(
                localizations.translate('noJobsAvailable'),
                style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
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
            padding: const EdgeInsets.all(16.0),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index].data() as Map<String, dynamic>;
              final jobId = jobs[index].id;
              return FadeInLeft(
                duration: Duration(milliseconds: 900 + index * 100),
                child: _buildJobCard(context, job, jobId, localizations, isGuest),
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
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: FadeInDown(
          duration: Duration(milliseconds: 600),
          child: Text(
            '${localizations.translate('jobCategories')}: $category',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: isOffline ? Colors.red : Color(0xFF2A9D8F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        elevation: 4,
        flexibleSpace: isOffline
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
        )
            : null,
      ),
      body: isOffline
          ? Center(
        child: FadeInDown(
          duration: Duration(milliseconds: 800),
          child: Text(
            localizations.translate('connectToInternet'),
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('category', isEqualTo: categoryKey)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xFF2A9D8F)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            );
          }
          final jobs = snapshot.data?.docs ?? [];
          if (jobs.isEmpty) {
            return Center(
              child: Text(
                localizations.translate('noJobsAvailable'),
                style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
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
                child: _buildJobCard(context, job, jobId, localizations, isGuest),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            job['title'] ?? '',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF264653),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${localizations.translate('company')}: ${job['company'] ?? 'Unknown'}',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              Text(
                '${localizations.translate('location')}: ${job['city'] ?? 'Unknown'}',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
          trailing: Icon(
            IconlyLight.arrow_right_2,
            color: Color(0xFFF4A261),
          ),
          onTap: () async {
            if (!await OfflineService().checkConnection()) {
              OfflineService().showOfflineSnackBar(context);
              return;
            }
            if (isGuest) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    localizations.translate('pleaseLogin'),
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.redAccent,
                  action: SnackBarAction(
                    label: localizations.translate('login'),
                    textColor: Color(0xFFF4A261),
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
                builder: (context) => JobDetailsScreen(job: {...job, 'id': jobId}),
              ),
            );
          },
        ),
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
    final isOwnJob = job['employerId'] == FirebaseAuth.instance.currentUser?.uid;
    final isOffline = !OfflineService().isOnline;

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: FadeInDown(
          duration: Duration(milliseconds: 600),
          child: Text(
            job['title'] ?? '',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: isOffline ? Colors.red : Color(0xFF2A9D8F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        elevation: 4,
        flexibleSpace: isOffline
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
        )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
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
                    '${localizations.translate('company')}: ${job['company'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF264653),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInLeft(
                  duration: Duration(milliseconds: 900),
                  child: Text(
                    '${localizations.translate('location')}: ${job['city'] ?? 'Unknown'}',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInLeft(
                  duration: Duration(milliseconds: 1000),
                  child: Text(
                    '${localizations.translate('salary')}: ${job['salary'] ?? 'Not specified'}',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInLeft(
                  duration: Duration(milliseconds: 1100),
                  child: Text(
                    '${localizations.translate('schedule')}: ${job['schedule'] ?? 'Not specified'}',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInLeft(
                  duration: Duration(milliseconds: 1200),
                  child: Text(
                    '${localizations.translate('employmentType')}: ${job['employmentType'] ?? 'Not specified'}',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  ),
                ),
                const SizedBox(height: 16),
                FadeInLeft(
                  duration: Duration(milliseconds: 1300),
                  child: Text(
                    localizations.translate('description'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF264653),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInLeft(
                  duration: Duration(milliseconds: 1400),
                  child: Text(
                    job['description'] ?? 'No description available',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  ),
                ),
                const SizedBox(height: 16),
                FadeInLeft(
                  duration: Duration(milliseconds: 1500),
                  child: Text(
                    localizations.translate('requirements'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF264653),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInLeft(
                  duration: Duration(milliseconds: 1600),
                  child: Text(
                    job['requirements'] ?? 'No requirements specified',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  ),
                ),
                const SizedBox(height: 16),
                FadeInLeft(
                  duration: Duration(milliseconds: 1700),
                  child: Text(
                    localizations.translate('contactInfo'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF264653),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInLeft(
                  duration: Duration(milliseconds: 1800),
                  child: Text(
                    job['contactInfo'] ?? 'No contact information provided',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  ),
                ),
                const SizedBox(height: 24),
                isOwnJob
                    ? FadeInLeft(
                  duration: Duration(milliseconds: 1900),
                  child: Text(
                    localizations.translate('yourVacancy'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFF4A261),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
                    : ZoomIn(
                  duration: Duration(milliseconds: 2000),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!await OfflineService().checkConnection()) {
                        OfflineService().showOfflineSnackBar(context);
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ApplyJobScreen(
                            jobId: job['id'],
                            jobTitle: job['title'] ?? 'Untitled',
                          ),
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

  Widget _buildLandscapeLayout(
      BuildContext context,
      AppLocalizations localizations,
      ) {
    final isOwnJob = job['employerId'] == FirebaseAuth.instance.currentUser?.uid;
    final isOffline = !OfflineService().isOnline;

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: FadeInDown(
          duration: Duration(milliseconds: 600),
          child: Text(
            job['title'] ?? '',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: isOffline ? Colors.red : Color(0xFF2A9D8F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        elevation: 4,
        flexibleSpace: isOffline
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
        )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFE6ECEF)],
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
                          '${localizations.translate('company')}: ${job['company'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF264653),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInLeft(
                        duration: Duration(milliseconds: 900),
                        child: Text(
                          '${localizations.translate('location')}: ${job['city'] ?? 'Unknown'}',
                          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInLeft(
                        duration: Duration(milliseconds: 1000),
                        child: Text(
                          '${localizations.translate('salary')}: ${job['salary'] ?? 'Not specified'}',
                          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInLeft(
                        duration: Duration(milliseconds: 1100),
                        child: Text(
                          '${localizations.translate('schedule')}: ${job['schedule'] ?? 'Not specified'}',
                          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInLeft(
                        duration: Duration(milliseconds: 1200),
                        child: Text(
                          '${localizations.translate('employmentType')}: ${job['employmentType'] ?? 'Not specified'}',
                          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF264653),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInLeft(
                        duration: Duration(milliseconds: 1400),
                        child: Text(
                          job['description'] ?? 'No description available',
                          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeInLeft(
                        duration: Duration(milliseconds: 1500),
                        child: Text(
                          localizations.translate('requirements'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF264653),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInLeft(
                        duration: Duration(milliseconds: 1600),
                        child: Text(
                          job['requirements'] ?? 'No requirements specified',
                          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeInLeft(
                        duration: Duration(milliseconds: 1700),
                        child: Text(
                          localizations.translate('contactInfo'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF264653),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInLeft(
                        duration: Duration(milliseconds: 1800),
                        child: Text(
                          job['contactInfo'] ?? 'No contact information provided',
                          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      isOwnJob
                          ? FadeInLeft(
                        duration: Duration(milliseconds: 1900),
                        child: Text(
                          localizations.translate('yourVacancy'),
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFF4A261),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                          : ZoomIn(
                        duration: Duration(milliseconds: 2000),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!await OfflineService().checkConnection()) {
                              OfflineService().showOfflineSnackBar(context);
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ApplyJobScreen(
                                  jobId: job['id'],
                                  jobTitle: job['title'] ?? 'Untitled',
                                ),
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