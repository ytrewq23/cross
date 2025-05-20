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

  Map<String, dynamic> _makeJsonSerializable(Map<String, dynamic> data) {
    final serializableData = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is Timestamp) {
        serializableData[key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        serializableData[key] = _makeJsonSerializable(
          Map<String, dynamic>.from(value),
        );
      } else if (value is List) {
        serializableData[key] =
            value.map((item) {
              if (item is Map) {
                return _makeJsonSerializable(Map<String, dynamic>.from(item));
              } else if (item is Timestamp) {
                return item.toDate().toIso8601String();
              }
              return item;
            }).toList();
      } else {
        serializableData[key] = value;
      }
    });
    return serializableData;
  }

  Future<void> saveJobOffline(Map<String, dynamic> job, String action) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      List<String> offlineJobs = prefs.getStringList('offline_jobs') ?? [];

      final newJobTitle = job['title'].toString().toLowerCase();
      offlineJobs =
          offlineJobs.where((jobData) {
            final data = jsonDecode(jobData);
            final existingTitle = data['job']['title'].toString().toLowerCase();
            return existingTitle != newJobTitle;
          }).toList();

      final serializableJob = _makeJsonSerializable(job);
      offlineJobs.add(jsonEncode({'job': serializableJob, 'action': action}));
      await prefs.setStringList('offline_jobs', offlineJobs);
      print('Saved job offline: $job, action: $action');
    } catch (e) {
      print('Error saving job offline: $e');
    }
  }

  Future<void> saveJobsListOffline(List<Map<String, dynamic>> jobs) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final uniqueJobs = <String, Map<String, dynamic>>{};
      for (var job in jobs) {
        final title = job['title'].toString().toLowerCase();
        uniqueJobs[title] = _makeJsonSerializable(job);
      }
      final filteredJobs = uniqueJobs.values.toList();
      await prefs.setString('offline_jobs_list', jsonEncode(filteredJobs));
      print('Saved jobs list offline: ${filteredJobs.length} jobs');
    } catch (e) {
      print('Error saving jobs list offline: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getJobsListOffline() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final jobsString = prefs.getString('offline_jobs_list');
      if (jobsString != null) {
        final decoded = jsonDecode(jobsString);
        if (decoded is List) {
          final jobs =
              decoded.map((item) {
                if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              }).toList();
          print('Retrieved offline jobs list: ${jobs.length} jobs');
          return jobs;
        }
      }
      print('No offline jobs list found');
      return [];
    } catch (e) {
      print('Error decoding offline jobs list: $e');
      return [];
    }
  }

  Future<void> clearOfflineStorage() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.remove('offline_jobs');
      await prefs.remove('offline_jobs_list');
      print('Cleared offline storage');
    } catch (e) {
      print('Error clearing offline storage: $e');
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
      if (offlineJobs.isEmpty) {
        print('No offline jobs to sync');
        return;
      }

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
            final jobTitle = job['title'].toString().toLowerCase();

            if (job['createdAt'] is String) {
              job['createdAt'] = Timestamp.fromDate(
                DateTime.parse(job['createdAt'] as String),
              );
            }
            if (job['updatedAt'] is String) {
              job['updatedAt'] = Timestamp.fromDate(
                DateTime.parse(job['updatedAt'] as String),
              );
            }

            final existingJobs =
                await FirebaseFirestore.instance
                    .collection('jobs')
                    .where('employerId', isEqualTo: user.uid)
                    .where('title', isEqualTo: job['title'])
                    .get();

            if (action == 'create') {
              if (existingJobs.docs.isEmpty) {
                final docRef = await FirebaseFirestore.instance
                    .collection('jobs')
                    .add(job);
                syncedJobs.add(jobData);
                print('Synced job creation: $job, id: ${docRef.id}');
              } else {
                print(
                  'Job with title $jobTitle already exists, skipping creation',
                );
                syncedJobs.add(jobData);
              }
            } else if (action == 'update') {
              final jobId = job['id'];
              if (jobId != null) {
                if (existingJobs.docs.isNotEmpty &&
                    existingJobs.docs.any((doc) => doc.id == jobId)) {
                  await FirebaseFirestore.instance
                      .collection('jobs')
                      .doc(jobId)
                      .update(job);
                  syncedJobs.add(jobData);
                  print('Synced job update: $job, id: $jobId');
                } else {
                  print('Job with id $jobId not found for update, skipping');
                  syncedJobs.add(jobData);
                }
              } else {
                print('Invalid job ID for update: $jobData');
              }
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
        jobs.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList(),
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
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final hasPending =
          prefs.getStringList('offline_jobs')?.isNotEmpty ?? false;
      if (hasPending) {
        await _syncOfflineData();
        if (context.mounted) {
          onSuccess();
        }
      } else {
        print('No pending offline jobs to sync');
        if (context.mounted) {
          onSuccess();
        }
      }
    } catch (e) {
      print('Error during syncAndNotify: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('error')),
          ),
        );
      }
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
