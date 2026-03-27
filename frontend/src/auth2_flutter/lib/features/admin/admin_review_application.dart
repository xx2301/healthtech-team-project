import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:auth2_flutter/features/data/domain/presentation/components/appbar_backarrow.dart';

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
    if (kIsWeb) return 'http://10.101.61.123:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    if (Platform.isIOS) return 'http://10.101.61.123:3001';
    return 'http://10.101.61.123:3001';
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
    if (approve) {
      _performAction(doctorId, approve, null);
    } else {
      _showRejectReasonDialog(doctorId);
    }
  }

  Future<void> _showRejectReasonDialog(String doctorId) {
    final TextEditingController reasonController = TextEditingController();
    return showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reject Application'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for rejection (optional):'),
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Enter reason...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _performAction(doctorId, false, reasonController.text.trim());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Confirm Reject'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performAction(String doctorId, bool approve, String? reason) async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      if (token == null) return;

      final url = approve
          ? '${_getBaseUrl()}/api/admin/approve-doctor/$doctorId'
          : '${_getBaseUrl()}/api/admin/reject-doctor/$doctorId';
      
      final Map<String, dynamic> body = {};
      if (!approve && reason != null && reason.isNotEmpty) {
        body['rejectionReason'] = reason;
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body.isNotEmpty ? jsonEncode(body) : null,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? 'Doctor approved' : 'Application rejected')),
        );
        _fetchApplications();
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Action failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
        setState(() => _loading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BackButtonAppBar(),
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
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Approve'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _handleApplication(doctorId, false),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
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
