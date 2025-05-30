import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconly/iconly.dart';
import '../localizations.dart';
import 'offline_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isOffline = !OfflineService().isOnline;
    final categories = [
      {
        'name': localizations.translate('categoryIT'),
        'icon': IconlyLight.activity,
      },
      {
        'name': localizations.translate('categoryMarketing'),
        'icon': IconlyLight.graph,
      },
      {
        'name': localizations.translate('categorySales'),
        'icon': IconlyLight.bag,
      },
      {
        'name': localizations.translate('categoryDesign'),
        'icon': IconlyLight.edit,
      },
      {
        'name': localizations.translate('categoryHR'),
        'icon': IconlyLight.profile,
      },
      {
        'name': localizations.translate('categoryFinance'),
        'icon': IconlyLight.paper,
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Text(
            isOffline
                ? localizations.translate('connectToInternet')
                : localizations.translate('search'),
            style: theme.appBarTheme.titleTextStyle,
          ),
        ),
        centerTitle: true,
        backgroundColor:
            isOffline
                ? theme.colorScheme.error
                : theme.appBarTheme.backgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        flexibleSpace:
            isOffline
                ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.error.withOpacity(0.3),
                        theme.colorScheme.error.withOpacity(0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 700),
                      child: Text(
                        localizations.translate('connectToInternet'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: TextField(
                decoration: InputDecoration(
                  hintText: localizations.translate('jobSearch'),
                  prefixIcon: Icon(
                    IconlyLight.search,
                    color: theme.colorScheme.primary,
                  ),
                  border: theme.inputDecorationTheme.border,
                  enabledBorder: theme.inputDecorationTheme.enabledBorder,
                  focusedBorder: theme.inputDecorationTheme.focusedBorder,
                  filled: true,
                  fillColor: theme.inputDecorationTheme.fillColor,
                ),
                onChanged: (value) {
                  // TODO: Implement search functionality
                },
              ),
            ),
            const SizedBox(height: 20),
            FadeInLeft(
              duration: const Duration(milliseconds: 900),
              child: Text(
                localizations.translate('jobCategories'),
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return FadeInLeft(
                    duration: Duration(milliseconds: 1000 + index * 100),
                    child: Card(
                      color: theme.cardColor,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                theme.brightness == Brightness.dark
                                    ? [
                                      const Color(0xFF2A2F33),
                                      const Color(0xFF1C2526),
                                    ]
                                    : [
                                      const Color(0xFFF8FAFC),
                                      const Color(0xFFE6ECEF),
                                    ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            // TODO: Navigate to category-specific job list
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                categories[index]['icon'] as IconData,
                                size: 40,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                categories[index]['name'] as String,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
