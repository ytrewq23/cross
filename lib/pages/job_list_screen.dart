import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineService {
  static const String _pendingActionsKey = 'pending_actions';
  static const String _cachedJobsKey = 'cached_jobs';
  static const String _cachedResumeKey = 'cached_resume';
  bool isOnline = true;

  OfflineService._privateConstructor();
  static final OfflineService _instance = OfflineService._privateConstructor();
  factory OfflineService() => _instance;

  Future<void> init() async {
    await _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((results) {
      final newOnline = results.any((result) => result != ConnectivityResult.none);
      if (newOnline != isOnline) {
        isOnline = newOnline;
        if (isOnline) {
          syncPendingActions(null);
        }
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    isOnline = result.any((r) => r != ConnectivityResult.none);
  }

  Future<void> saveJobOffline(Map<String, dynamic> jobData, String actionType) async {
    final prefs = await SharedPreferences.getInstance();
    final action = {
      'type': 'job',
      'action': actionType, // 'create' or 'delete'
      'data': jobData,
      'timestamp': DateTime.now().toIso8601String(),
    };
    List<String> pendingActions = prefs.getStringList(_pendingActionsKey) ?? [];
    pendingActions.add(jsonEncode(action));
    await prefs.setStringList(_pendingActionsKey, pendingActions);

    List<Map<String, dynamic>> cachedJobs = await getJobsListOffline();
    if (actionType == 'create') {
      cachedJobs.add(jobData);
    } else if (actionType == 'delete') {
      cachedJobs.removeWhere((j) => j['id'] == jobData['id']);
    }
    await prefs.setString(_cachedJobsKey, jsonEncode(cachedJobs));
  }

  Future<void> saveResumeOffline(Map<String, dynamic> resumeData) async {
    final prefs = await SharedPreferences.getInstance();
    final action = {
      'type': 'resume',
      'action': 'set',
      'data': resumeData,
      'timestamp': DateTime.now().toIso8601String(),
    };
    List<String> pendingActions = prefs.getStringList(_pendingActionsKey) ?? [];
    pendingActions.add(jsonEncode(action));
    await prefs.setStringList(_pendingActionsKey, pendingActions);
    await prefs.setString(_cachedResumeKey, jsonEncode(resumeData));
  }

  Future<List<Map<String, dynamic>>> getJobsListOffline() async {
    final prefs = await SharedPreferences.getInstance();
    final jobsJson = prefs.getString(_cachedJobsKey);
    if (jobsJson != null) {
      final List<dynamic> decoded = jsonDecode(jobsJson);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>?> getResumeOffline() async {
    final prefs = await SharedPreferences.getInstance();
    final resumeJson = prefs.getString(_cachedResumeKey);
    if (resumeJson != null) {
      return jsonDecode(resumeJson) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> syncPendingActions(BuildContext? context) async {
    if (!isOnline) return;

    final prefs = await SharedPreferences.getInstance();
    final pendingActions = prefs.getStringList(_pendingActionsKey) ?? [];
    if (pendingActions.isEmpty) return;

    bool success = true;
    List<String> remainingActions = [];

    for (var actionJson in pendingActions) {
      try {
        final action = jsonDecode(actionJson);
        final type = action['type'];
        final actionType = action['action'];
        final data = action['data'];

        if (type == 'job') {
          if (actionType == 'create') {
            final docRef = await FirebaseFirestore.instance.collection('jobs').add(data);
            data['id'] = docRef.id;
          } else if (actionType == 'delete') {
            await FirebaseFirestore.instance.collection('jobs').doc(data['id']).delete();
          }
        } else if (type == 'resume') {
          final userId = data['userId'];
          await FirebaseFirestore.instance.collection('resumes').doc(userId).set(data);
        }
      } catch (e) {
        print('Sync error: $e');
        success = false;
        remainingActions.add(actionJson);
      }
    }

    if (success) {
      await prefs.remove(_pendingActionsKey);
      await prefs.remove(_cachedJobsKey);
      await prefs.remove(_cachedResumeKey);
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data synced successfully', style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFF2A9D8F),
          ),
        );
      }
    } else {
      await prefs.setStringList(_pendingActionsKey, remainingActions);
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed, will retry later', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}