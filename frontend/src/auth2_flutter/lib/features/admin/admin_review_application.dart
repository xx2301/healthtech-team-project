import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';

class AdminReviewApplications extends StatefulWidget {
  const AdminReviewApplications({Key? key}) : super(key: key);

  @override
  State<AdminReviewApplications> createState() => _AdminReviewApplicationsState();
}

class _AdminReviewApplicationsState extends State<AdminReviewApplications> {
  List<dynamic> _applications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  String _getBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    if (Platform.isIOS) return 'http://localhost:3001';
    return 'http://localhost:3001';
  }

  Future<void> _fetchApplications() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/api/admin/pending-doctor-applications'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _applications = json['data'] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load applications: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      print('Error: $e');
    }
  }

  Future<void> _handleApplication(String doctorId, bool approve) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final url = approve
          ? '${_getBaseUrl()}/api/admin/approve-doctor/$doctorId'
          : '${_getBaseUrl()}/api/admin/reject-doctor/$doctorId';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? 'Doctor approved' : 'Application rejected')),
        );
        _fetchApplications(); // 刷新列表
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Action failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DefaultAppBar(),
      drawer: DefaultDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? const Center(child: Text('No pending applications'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _applications.length,
                  itemBuilder: (ctx, index) {
                    final app = _applications[index];
                    final doctorId = app['_id'];
                    final userId = app['userId'] ?? {};
                    final name = userId['fullName'] ?? 'Unknown';
                    final email = userId['email'] ?? '';
                    final license = app['medicalLicenseNumber'] ?? 'N/A';
                    final spec = app['specialization'] ?? 'N/A';
                    final hospital = app['hospitalAffiliation'] ?? 'N/A';
                    final years = app['yearsOfExperience'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ExpansionTile(
                        leading: CircleAvatar(child: Text(name[0])),
                        title: Text('$name - $spec'),
                        subtitle: Text('License: $license'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Email: $email'),
                                Text('Hospital: $hospital'),
                                Text('Experience: $years years'),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _handleApplication(doctorId, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      child: const Text('Approve'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _handleApplication(doctorId, false),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('Reject'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}