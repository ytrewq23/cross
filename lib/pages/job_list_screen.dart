import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../localizations.dart';
import 'offline_service.dart';
import 'edit_job_screen.dart';
import 'create_job_screen.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  _JobListScreenState createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  final OfflineService _offlineService = OfflineService();
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    try {
      if (await _offlineService.checkConnection()) {
        await _offlineService.syncAndNotify(context, () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('jobsSynced'),
              ),
            ),
          );
        });
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final jobs = await FirebaseFirestore.instance
              .collection('jobs')
              .where('employerId', isEqualTo: user.uid)
              .get();
          _jobs = jobs.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
          await _offlineService.saveJobsListOffline(_jobs);
          print('Loaded ${_jobs.length} jobs from Firestore');
        }
      } else {
        _jobs = await _offlineService.getJobsListOffline();
        _offlineService.showOfflineSnackBar(context);
        print('Loaded ${_jobs.length} jobs from offline storage');
      }
    } catch (e) {
      print('Error loading jobs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading jobs: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('jobList')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadJobs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              await _offlineService.clearOfflineStorage();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Offline storage cleared'),
                ),
              );
              _loadJobs();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _jobs.isEmpty
              ? Center(child: Text(localizations.translate('noJobs')))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _jobs.length,
                  itemBuilder: (context, index) {
                    final job = _jobs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(job['title'] ?? 'No Title'),
                        subtitle: Text(
                          '${job['city'] ?? 'No City'} • ${job['salary'] ?? 'No Salary'} • isOnline: ${job['isOnline'] ?? 'Unknown'}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditJobScreen(
                                  jobId: job['id'],
                                  jobData: job,
                                ),
                              ),
                            ).then((_) => _loadJobs());
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateJobScreen()),
          ).then((_) => _loadJobs());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}