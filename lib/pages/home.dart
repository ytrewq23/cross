import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification.dart';
import 'profile.dart';
import 'search.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../localizations.dart';
import '../orientation_support.dart';
import 'login_page.dart';

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

  HomeScreen({required this.userName});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Widget _currentScreen = HomeContent();

  final List<Widget> _screens = [
    HomeContent(),
    SearchPage(),
    NotificationsPage(),
    ProfilePage(),
  ];

  bool get _isGuest =>
      widget.userName == 'Guest' || FirebaseAuth.instance.currentUser == null;

  void _onItemTapped(int index) {
    if (_isGuest && index != 0) {
      _showLoginPrompt();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToSearch() {
    if (_isGuest) {
      _showLoginPrompt();
      return;
    }
    setState(() {
      _currentScreen = SearchPage();
    });
  }

  void _navigateToHome() {
    setState(() {
      _currentScreen = HomeContent();
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

    return Scaffold(
      appBar:
          _isGuest
              ? AppBar(
                title: Text(localizations.translate('jobSeekerDashboard')),
                centerTitle: true,
                actions: [
                  TextButton(
                    onPressed: () {
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
      body: _isGuest ? HomeContent() : _screens[_selectedIndex],
      bottomNavigationBar:
          _isGuest
              ? null
              : BottomNavigationBar(
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: localizations.translate('home'),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search),
                    label: localizations.translate('search'),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.notifications),
                    label: localizations.translate('notifications'),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
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

    return Scaffold(
      appBar:
          isGuest
              ? null
              : AppBar(
                title: Text(localizations.translate('jobSeekerDashboard')),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      if (isGuest) {
                        homeState?._showLoginPrompt();
                      } else {
                        homeState?._onItemTapped(1);
                      }
                    },
                  ),
                ],
              ),
      body: SingleChildScrollView(
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
                child: _buildRecentJobs(context, localizations, isGuest),
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

    return Scaffold(
      appBar:
          isGuest
              ? null
              : AppBar(
                title: Text(localizations.translate('jobSeekerDashboard')),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      if (isGuest) {
                        homeState?._showLoginPrompt();
                      } else {
                        homeState?._onItemTapped(1);
                      }
                    },
                  ),
                ],
              ),
      body: SingleChildScrollView(
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
                      child: _buildRecentJobs(context, localizations, isGuest),
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

    return FutureBuilder<List<Map<String, String>>>(
      future: RecentJobsManager.getRecentJobs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final jobs = snapshot.data ?? [];
        if (jobs.isEmpty) {
          return Center(
            child: Text(
              localizations.translate('noRecentJobs'),
              style: TextStyle(fontSize: 16, color: Colors.grey),
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
                RecentJobsManager.saveJob(job);
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
                        job['title']!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        job['company']!,
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
          onTap: () {
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

  static const Map<String, List<Map<String, String>>> categoryJobs = {
    'ИТ': [
      {
        'title': 'Flutter Developer',
        'company': 'Tech Corp',
        'location': 'Remote',
      },
      {
        'title': 'Backend Engineer',
        'company': 'Data Inc',
        'location': 'San Francisco',
      },
    ],
    'Маркетинг': [
      {
        'title': 'Digital Marketer',
        'company': 'Grow Easy',
        'location': 'New York',
      },
      {
        'title': 'Content Strategist',
        'company': 'Brand Boost',
        'location': 'London',
      },
    ],
    'Продажи': [
      {'title': 'Sales Manager', 'company': 'Sell Well', 'location': 'Chicago'},
    ],
    'Дизайн': [
      {
        'title': 'UI/UX Designer',
        'company': 'Creative Studio',
        'location': 'Berlin',
      },
    ],
    'HR': [
      {
        'title': 'HR Specialist',
        'company': 'People First',
        'location': 'Toronto',
      },
    ],
    'Финансы': [
      {
        'title': 'Financial Analyst',
        'company': 'Money Wise',
        'location': 'Singapore',
      },
    ],
  };

  const CategoryJobsScreen({required this.category});

  String _getCategoryKey(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (category == localizations.translate('categoryIT')) return 'ИТ';
    if (category == localizations.translate('categoryMarketing'))
      return 'Маркетинг';
    if (category == localizations.translate('categorySales')) return 'Продажи';
    if (category == localizations.translate('categoryDesign')) return 'Дизайн';
    if (category == localizations.translate('categoryHR')) return 'HR';
    if (category == localizations.translate('categoryFinance'))
      return 'Финансы';
    return category;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final categoryKey = _getCategoryKey(context);
    final jobs = categoryJobs[categoryKey] ?? [];

    return withOrientationSupport(
      context: context,
      portrait: _buildPortraitLayout(context, localizations, jobs),
      landscape: _buildLandscapeLayout(context, localizations, jobs),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    AppLocalizations localizations,
    List<Map<String, String>> jobs,
  ) {
    final isGuest = FirebaseAuth.instance.currentUser == null;

    return Scaffold(
      appBar: AppBar(
        title: Text('${localizations.translate('jobCategories')}: $category'),
        centerTitle: true,
      ),
      body:
          jobs.isEmpty
              ? Center(child: Text(localizations.translate('noJobsAvailable')))
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: jobs.length,
                itemBuilder:
                    (context, index) => _buildJobCard(
                      context,
                      jobs[index],
                      localizations,
                      isGuest,
                    ),
              ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    AppLocalizations localizations,
    List<Map<String, String>> jobs,
  ) {
    final isGuest = FirebaseAuth.instance.currentUser == null;

    return Scaffold(
      appBar: AppBar(
        title: Text('${localizations.translate('jobCategories')}: $category'),
        centerTitle: true,
      ),
      body:
          jobs.isEmpty
              ? Center(child: Text(localizations.translate('noJobsAvailable')))
              : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3 / 2,
                ),
                itemCount: jobs.length,
                itemBuilder:
                    (context, index) => _buildJobCard(
                      context,
                      jobs[index],
                      localizations,
                      isGuest,
                    ),
              ),
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    Map<String, String> job,
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
          job['title']!,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${localizations.translate('company')}: ${job['company']}'),
            Text('${localizations.translate('location')}: ${job['location']}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
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
          RecentJobsManager.saveJob(job);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => JobDetailsScreen(job: job)),
          );
        },
      ),
    );
  }
}

class JobDetailsScreen extends StatelessWidget {
  final Map<String, String> job;

  const JobDetailsScreen({required this.job});

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
    final isGuest = FirebaseAuth.instance.currentUser == null;

    return Scaffold(
      appBar: AppBar(title: Text(job['title']!), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${localizations.translate('company')}: ${job['company']}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              '${localizations.translate('location')}: ${job['location']}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            Text(
              localizations.translate('jobSeekerDashboard'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
              style: Theme.of(context).textTheme.bodyMedium,
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
    final isGuest = FirebaseAuth.instance.currentUser == null;

    return Scaffold(
      appBar: AppBar(title: Text(job['title']!), centerTitle: true),
      body: Padding(
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
                    '${localizations.translate('company')}: ${job['company']}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${localizations.translate('location')}: ${job['location']}',
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
                    localizations.translate('jobSeekerDashboard'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                    style: Theme.of(context).textTheme.bodyMedium,
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
