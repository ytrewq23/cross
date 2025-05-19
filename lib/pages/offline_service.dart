import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import '../localizations.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  bool _isOnline = false;
  bool get isOnline => _isOnline;
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  DateTime? _lastSync;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
    }

    await _checkConnectivity();

    if (kIsWeb) {
      html.window.addEventListener('online', (_) {
        if (!_isInitialized) return;
        _isOnline = true;
        print('Web: Went online');
        _scheduleSync();
      });
      html.window.addEventListener('offline', (_) {
        if (!_isInitialized) return;
        _isOnline = false;
        print('Web: Went offline');
      });
    } else {
      try {
        Connectivity().onConnectivityChanged.listen((
          List<ConnectivityResult> results,
        ) {
          if (!_isInitialized) return;
          final wasOnline = _isOnline;
          _isOnline = results.any(
            (result) => result != ConnectivityResult.none,
          );
          print(
            'Mobile: Connectivity changed to $_isOnline (Results: $results)',
          );
          if (_isOnline && !wasOnline) {
            _scheduleSync();
          }
        });
      } catch (e) {
        print('Error setting up connectivity listener: $e');
        _isOnline = false;
      }
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      if (kIsWeb) {
        _isOnline = html.window.navigator.onLine ?? false;
        print('Web connectivity check: $_isOnline');
      } else {
        final results = await Connectivity().checkConnectivity();
        _isOnline = results.any((result) => result != ConnectivityResult.none);
        print('Mobile connectivity check: $_isOnline (Results: $results)');
      }
    } catch (e) {
      print('Error checking connectivity: $e');
      _isOnline = false;
    }
  }

  Future<bool> checkConnection() async {
    try {
      if (kIsWeb) {
        final online = html.window.navigator.onLine ?? false;
        print('Web connection check: $online');
        return online;
      } else {
        final results = await Connectivity().checkConnectivity();
        final online = results.any(
          (result) => result != ConnectivityResult.none,
        );
        print('Mobile connection check: $online (Results: $results)');
        return online;
      }
    } catch (e) {
      print('Error checking connection: $e');
      return false;
    }
  }

  void showOfflineSnackBar(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).translate('connectToInternet'),
        ),
      ),
    );
  }

  Future<void> saveJobOffline(Map<String, dynamic> job, String action) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      List<String> offlineJobs = prefs.getStringList('offline_jobs') ?? [];
      offlineJobs.add(jsonEncode({'job': job, 'action': action}));
      await prefs.setStringList('offline_jobs', offlineJobs);
      print('Saved job offline: $job, action: $action');
    } catch (e) {
      print('Error saving job offline: $e');
    }
  }

  Future<void> saveJobsListOffline(List<Map<String, dynamic>> jobs) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString('offline_jobs_list', jsonEncode(jobs));
      print('Saved jobs list offline: $jobs');
    } catch (e) {
      print('Error saving jobs list offline: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getJobsListOffline() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final jobsString = prefs.getString('offline_jobs_list');
      if (jobsString != null) {
        final jobs = List<Map<String, dynamic>>.from(jsonDecode(jobsString));
        print('Retrieved offline jobs list: $jobs');
        return jobs;
      }
      print('No offline jobs list found');
      return [];
    } catch (e) {
      print('Error decoding offline jobs list: $e');
      return [];
    }
  }

  Future<void> _syncOfflineData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in, skipping sync');
      return;
    }

    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      List<String> offlineJobs = prefs.getStringList('offline_jobs') ?? [];
      List<String> syncedJobs = [];

      const batchSize = 5;
      for (var i = 0; i < offlineJobs.length; i += batchSize) {
        final batch = offlineJobs.skip(i).take(batchSize).toList();
        for (String jobData in batch) {
          try {
            final data = jsonDecode(jobData);
            if (data is! Map ||
                !data.containsKey('job') ||
                !data.containsKey('action')) {
              print('Invalid job data format: $jobData');
              continue;
            }
            final job = Map<String, dynamic>.from(data['job']);
            final action = data['action'];

            if (action == 'create') {
              final docRef = await FirebaseFirestore.instance
                  .collection('jobs')
                  .add(job);
              syncedJobs.add(jobData);
              print('Synced job creation: $job, id: ${docRef.id}');
            }
          } catch (e) {
            print('Error syncing job: $e, data: $jobData');
          }
        }
      }

      await prefs.setStringList(
        'offline_jobs',
        offlineJobs.where((job) => !syncedJobs.contains(job)).toList(),
      );
      print('Cleared synced offline jobs');

      final jobs =
          await FirebaseFirestore.instance
              .collection('jobs')
              .where('employerId', isEqualTo: user.uid)
              .get();
      await saveJobsListOffline(
        jobs.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList(),
      );

      _lastSync = DateTime.now();
    } catch (e) {
      print('Error during sync: $e');
    }
  }

  Future<void> syncAndNotify(
    BuildContext context,
    VoidCallback onSuccess,
  ) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final hasPending = prefs.getStringList('offline_jobs')?.isNotEmpty ?? false;
    if (hasPending) {
      await _syncOfflineData();
      onSuccess();
    }
  }

  void _scheduleSync() {
    if (_lastSync != null &&
        DateTime.now().difference(_lastSync!).inSeconds < 30) {
      print('Sync throttled, last sync: $_lastSync');
      return;
    }
    Future.microtask(_syncOfflineData);
  }
}
