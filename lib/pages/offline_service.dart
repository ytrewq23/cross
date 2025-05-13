import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_application_1/localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:flutter/material.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> init() async {
    await _checkConnectivity();
    if (kIsWeb) {
      // Listen to online/offline events on web
      html.window.addEventListener('online', (_) {
        _isOnline = true;
        print('Web: Went online');
        _syncOfflineData();
      });
      html.window.addEventListener('offline', (_) {
        _isOnline = false;
        print('Web: Went offline');
      });
    } else {
      // Use connectivity_plus for mobile
      try {
        Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
          _isOnline = results.any((result) => result != ConnectivityResult.none);
          print('Mobile: Connectivity changed to $_isOnline (Results: $results)');
          if (_isOnline) {
            _syncOfflineData();
          }
        });
      } catch (e) {
        print('Error setting up connectivity listener: $e');
        _isOnline = false;
      }
    }
  }

  Future<void> _checkConnectivity() async {
    if (kIsWeb) {
      _isOnline = html.window.navigator.onLine!;
      print('Web connectivity check: $_isOnline');
    } else {
      try {
        final results = await Connectivity().checkConnectivity();
        _isOnline = results.any((result) => result != ConnectivityResult.none);
        print('Mobile connectivity check: $_isOnline (Results: $results)');
      } catch (e) {
        print('Error checking connectivity: $e');
        _isOnline = false;
      }
    }
  }

  Future<bool?> checkConnection() async {
    if (kIsWeb) {
      final online = html.window.navigator.onLine;
      print('Web connection check: $online');
      return online;
    } else {
      try {
        final results = await Connectivity().checkConnectivity();
        final online = results.any((result) => result != ConnectivityResult.none);
        print('Mobile connection check: $online (Results: $results)');
        return online;
      } catch (e) {
        print('Error checking connection: $e');
        return false;
      }
    }
  }

  void showOfflineSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).translate('connectToInternet'),
        ),
      ),
    );
  }

  // Сохранение вакансий оффлайн
  Future<void> saveJobOffline(Map<String, dynamic> job, String action) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> offlineJobs = prefs.getStringList('offline_jobs') ?? [];
    offlineJobs.add(jsonEncode({'job': job, 'action': action}));
    await prefs.setStringList('offline_jobs', offlineJobs);
    print('Saved job offline: $job, action: $action');
  }

  // Сохранение резюме оффлайн
  Future<void> saveResumeOffline(Map<String, dynamic> resume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_resume', jsonEncode(resume));
    print('Saved resume offline: $resume');
  }

  // Сохранение списка вакансий для оффлайн-доступа
  Future<void> saveJobsListOffline(List<Map<String, dynamic>> jobs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_jobs_list', jsonEncode(jobs));
    print('Saved jobs list offline: $jobs');
  }

  // Получение списка вакансий оффлайн
  Future<List<Map<String, dynamic>>> getJobsListOffline() async {
    final prefs = await SharedPreferences.getInstance();
    final jobsString = prefs.getString('offline_jobs_list');
    if (jobsString != null) {
      final jobs = List<Map<String, dynamic>>.from(jsonDecode(jobsString));
      print('Retrieved offline jobs list: $jobs');
      return jobs;
    }
    print('No offline jobs list found');
    return [];
  }

  // Получение резюме оффлайн
  Future<Map<String, dynamic>?> getResumeOffline() async {
    final prefs = await SharedPreferences.getInstance();
    final resumeString = prefs.getString('offline_resume');
    if (resumeString != null) {
      final resume = Map<String, dynamic>.from(jsonDecode(resumeString));
      print('Retrieved offline resume: $resume');
      return resume;
    }
    print('No offline resume found');
    return null;
  }

  // Синхронизация оффлайн-данных с Firestore
  Future<void> _syncOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in, skipping sync');
      return;
    }

    // Синхронизация вакансий
    List<String> offlineJobs = prefs.getStringList('offline_jobs') ?? [];
    for (String jobData in offlineJobs) {
      final data = jsonDecode(jobData);
      final job = Map<String, dynamic>.from(data['job']);
      final action = data['action'];

      try {
        if (action == 'create') {
          await FirebaseFirestore.instance.collection('jobs').add(job);
          print('Synced job creation: $job');
        } else if (action == 'delete' && job['id'] != null) {
          await FirebaseFirestore.instance
              .collection('jobs')
              .doc(job['id'])
              .delete();
          print('Synced job deletion: ${job['id']}');
        }
      } catch (e) {
        print('Error syncing job: $e');
      }
    }
    await prefs.remove('offline_jobs');
    print('Cleared offline jobs queue');

    // Синхронизация резюме
    final resumeString = prefs.getString('offline_resume');
    if (resumeString != null) {
      final resume = Map<String, dynamic>.from(jsonDecode(resumeString));
      try {
        await FirebaseFirestore.instance
            .collection('resumes')
            .doc(user.uid)
            .set(resume);
        await prefs.remove('offline_resume');
        print('Synced resume: $resume');
      } catch (e) {
        print('Error syncing resume: $e');
      }
    }
  }
}