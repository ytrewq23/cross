import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineService {
  static const String _pendingActionsKey = 'pending_actions';
  static const String _cachedJobsKey = 'cached_jobs';
  static const String _cachedResumeKey = 'cached_resume';
  static const String _pinKey = 'offline_pin';
  static const String _pinUserIdKey = 'offline_user_id';
  bool isOnline = true;

  OfflineService._privateConstructor();
  static final OfflineService _instance = OfflineService._privateConstructor();
  factory OfflineService() => _instance;

  Future<void> init() async {
    await _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final newOnline = results.any((result) => result == ConnectivityResult.wifi || result == ConnectivityResult.mobile);
      if (newOnline != isOnline) {
        isOnline = newOnline;
        if (isOnline) {
          syncPendingActions(null);
        }
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    isOnline = results.any((result) => result == ConnectivityResult.wifi || result == ConnectivityResult.mobile);
  }

  Future<void> saveJobOffline(Map<String, dynamic> jobData, String actionType) async {
    if (actionType != 'create' && actionType != 'delete') {
      throw ArgumentError('Invalid actionType: $actionType. Must be "create" or "delete".');
    }
    if (actionType == 'delete' && jobData['id'] == null) {
      throw ArgumentError('Job ID is required for delete action.');
    }

    final prefs = await SharedPreferences.getInstance();
    final action = {
      'type': 'job',
      'action': actionType,
      'data': jobData,
      'timestamp': DateTime.now().toIso8601String(),
    };
    List<String> pendingActions = prefs.getStringList(_pendingActionsKey) ?? [];
    pendingActions.add(jsonEncode(action));
    await prefs.setStringList(_pendingActionsKey, pendingActions);

    List<Map<String, dynamic>> cachedJobs = await getJobsListOffline();
    if (actionType == 'create') {
      cachedJobs.removeWhere((j) => j['id'] == jobData['id']);
      cachedJobs.add(jobData);
    } else if (actionType == 'delete') {
      cachedJobs.removeWhere((j) => j['id'] == jobData['id']);
    }
    await prefs.setString(_cachedJobsKey, jsonEncode(cachedJobs));
  }

  Future<void> saveJobsListOffline(List<Map<String, dynamic>> jobs) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_cachedJobsKey, jsonEncode(jobs));
    } catch (e) {
      print('Error saving jobs list offline: $e');
    }
  }

  Future<void> saveResumeOffline(Map<String, dynamic> resumeData) async {
    if (resumeData['userId'] == null) {
      throw ArgumentError('userId is required in resumeData.');
    }

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

  Future<void> saveRoleOffline(String userId, String role) async {
    final prefs = await SharedPreferences.getInstance();
    final action = {
      'type': 'role',
      'action': 'set',
      'data': {'userId': userId, 'role': role},
      'timestamp': DateTime.now().toIso8601String(),
    };
    List<String> pendingActions = prefs.getStringList(_pendingActionsKey) ?? [];
    pendingActions.add(jsonEncode(action));
    await prefs.setStringList(_pendingActionsKey, pendingActions);
    await prefs.setString('userRole', role);
  }

  Future<List<Map<String, dynamic>>> getJobsListOffline() async {
    final prefs = await SharedPreferences.getInstance();
    final jobsJson = prefs.getString(_cachedJobsKey);
    if (jobsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jobsJson) as List<dynamic>;
        return decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        print('Error decoding cached jobs: $e');
        return [];
      }
    }
    return [];
  }

  Future<Map<String, dynamic>?> getResumeOffline() async {
    final prefs = await SharedPreferences.getInstance();
    final resumeJson = prefs.getString(_cachedResumeKey);
    if (resumeJson != null) {
      try {
        return jsonDecode(resumeJson) as Map<String, dynamic>;
      } catch (e) {
        print('Error decoding cached resume: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> syncPendingActions(BuildContext? context) async {
    if (!isOnline) return;

    final prefs = await SharedPreferences.getInstance();
    final pendingActions = prefs.getStringList(_pendingActionsKey) ?? [];
    if (pendingActions.isEmpty) return;

    List<String> remainingActions = [];
    bool success = true;

    for (var actionJson in pendingActions) {
      try {
        final action = jsonDecode(actionJson) as Map<String, dynamic>;
        final type = action['type'] as String?;
        final actionType = action['action'] as String?;
        final data = action['data'] as Map<String, dynamic>?;

        if (type == null || actionType == null || data == null) {
          print('Invalid action format: $actionJson');
          continue;
        }

        if (type == 'job') {
          if (actionType == 'create') {
            final docRef = await FirebaseFirestore.instance.collection('jobs').add(data);
            data['id'] = docRef.id;
          } else if (actionType == 'delete') {
            final jobId = data['id'] as String?;
            if (jobId != null) {
              await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
            } else {
              print('Missing job ID for delete action: $actionJson');
              remainingActions.add(actionJson);
              success = false;
            }
          }
        } else if (type == 'resume') {
          final userId = data['userId'] as String? ?? prefs.getString('userId');
          if (userId != null) {
            await FirebaseFirestore.instance.collection('resumes').doc(userId).set(data);
          } else {
            print('Missing userId for resume action: $actionJson');
            remainingActions.add(actionJson);
            success = false;
          }
        } else if (type == 'role') {
          final userId = data['userId'] as String?;
          final role = data['role'] as String?;
          if (userId != null && role != null) {
            await FirebaseFirestore.instance.collection('users').doc(userId).set({'role': role}, SetOptions(merge: true));
          } else {
            print('Missing userId or role for role action: $actionJson');
            remainingActions.add(actionJson);
            success = false;
          }
        }
      } catch (e) {
        print('Sync error for action $actionJson: $e');
        remainingActions.add(actionJson);
        success = false;
      }
    }

    if (success) {
      await prefs.remove(_pendingActionsKey);
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data synced successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF2A9D8F),
          ),
        );
      }
    } else {
      await prefs.setStringList(_pendingActionsKey, remainingActions);
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Some actions failed to sync, will retry later',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> syncAndNotify(BuildContext context, VoidCallback onSuccess) async {
    await syncPendingActions(context);
    final prefs = await SharedPreferences.getInstance();
    final pendingActions = prefs.getStringList(_pendingActionsKey) ?? [];
    if (pendingActions.isEmpty) {
      onSuccess();
    }
  }

  void showOfflineSnackBar(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You are offline. Actions will sync when online.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> savePin(String pin, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    await prefs.setString(_pinUserIdKey, userId);
  }

  Future<bool> validatePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString(_pinKey);
    return storedPin != null && storedPin == pin;
  }

  Future<String?> getPinUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinUserIdKey);
  }

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey) && prefs.containsKey(_pinUserIdKey);
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.remove(_pinUserIdKey);
  }
}