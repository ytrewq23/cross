import 'package:flutter/material.dart';
import 'notification.dart';
import 'profile.dart';
import 'search.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../localizations.dart';

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

  final List<Widget> _screens = [
    HomeContent(),
    SearchPage(),
    NotificationsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: localizations.translate('home')),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), label: localizations.translate('search')),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: localizations.translate('notifications')),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: localizations.translate('profile')),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('jobSeekerDashboard')),
        centerTitle: true,
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
                child: FutureBuilder<List<Map<String, String>>>(
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Container(
                              width: 150,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
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
                ),
              ),
              const SizedBox(height: 20),
              Text(
                localizations.translate('jobCategories'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CategoryJobsScreen(category: categories[index]),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        categories[index],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
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
        'location': 'Remote'
      },
      {
        'title': 'Backend Engineer',
        'company': 'Data Inc',
        'location': 'San Francisco'
      },
    ],
    'Маркетинг': [
      {
        'title': 'Digital Marketer',
        'company': 'Grow Easy',
        'location': 'New York'
      },
      {
        'title': 'Content Strategist',
        'company': 'Brand Boost',
        'location': 'London'
      },
    ],
    'Продажи': [
      {
        'title': 'Sales Manager',
        'company': 'Sell Well',
        'location': 'Chicago'
      },
    ],
    'Дизайн': [
      {
        'title': 'UI/UX Designer',
        'company': 'Creative Studio',
        'location': 'Berlin'
      },
    ],
    'HR': [
      {
        'title': 'HR Specialist',
        'company': 'People First',
        'location': 'Toronto'
      },
    ],
    'Финансы': [
      {
        'title': 'Financial Analyst',
        'company': 'Money Wise',
        'location': 'Singapore'
      },
    ],
  };

  const CategoryJobsScreen({required this.category});

  String _getCategoryKey(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (category == localizations.translate('categoryIT')) return 'ИТ';
    if (category == localizations.translate('categoryMarketing')) return 'Маркетинг';
    if (category == localizations.translate('categorySales')) return 'Продажи';
    if (category == localizations.translate('categoryDesign')) return 'Дизайн';
    if (category == localizations.translate('categoryHR')) return 'HR';
    if (category == localizations.translate('categoryFinance')) return 'Финансы';
    return category;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final categoryKey = _getCategoryKey(context);
    final jobs = categoryJobs[categoryKey] ?? [];

    return Scaffold(
      appBar: AppBar(
          title: Text('${localizations.translate('jobCategories')}: $category'),
          centerTitle: true),
      body: jobs.isEmpty
          ? Center(child: Text(localizations.translate('noJobsAvailable')))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      job['title']!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${localizations.translate('company')}: ${job['company']}'),
                        Text(
                            '${localizations.translate('location')}: ${job['location']}'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      RecentJobsManager.saveJob(job);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobDetailsScreen(job: job),
                        ),
                      );
                    },
                  ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(job['title']!),
        centerTitle: true,
      ),
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
}