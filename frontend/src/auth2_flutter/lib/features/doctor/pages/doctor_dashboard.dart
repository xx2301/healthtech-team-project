import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({Key? key}) : super(key: key);

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  List<dynamic> _patients = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPatients();
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

  Future<void> _fetchPatients() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/api/doctor/patients-with-summary'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _patients = json['data'] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load patients: ${response.statusCode}')),
        );
      }      
    } catch (e) {
      setState(() => _loading = false);
      print('Error fetching patients: $e');
    }
  }

  void _showAddPatientDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Patient'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Patient Email',
              hintText: 'Enter patient email',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter an email')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await _addPatient(email);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addPatient(String email) async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse('${_getBaseUrl()}/api/doctor/add-patient'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'patientEmail': email}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient added successfully')),
        );
        _fetchPatients();
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to add patient';
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Patients'),
        backgroundColor: Colors.green[500],
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddPatientDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPatients,
          ),
        ],
      ),
      drawer: DefaultDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _patients.isEmpty
                    ? const Center(child: Text('No patients assigned'))
                    : RefreshIndicator(
                        onRefresh: _fetchPatients,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _patients.length,
                          itemBuilder: (ctx, index) {
                            final patient = _patients[index];
                            final name = patient['fullName'] ?? 'Unknown';
                            if (_searchQuery.isNotEmpty &&
                                !name.toLowerCase().contains(_searchQuery)) {
                              return const SizedBox.shrink();
                            }
                            final patientCode = patient['patientCode'] ?? 'N/A';
                            final gender = patient['gender'] ?? 'unknown';
                            final userId = patient['userId'];
                            final summary = patient['healthSummary'] ?? {};

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green[100],
                                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Code: $patientCode  |  Gender: $gender'),
                                    const SizedBox(height: 4),
                                    // Text(
                                    //   'Steps (7d): ${summary['steps7Days'] ?? 0} | '
                                    //   'Heart: ${summary['latestHeartRate'] ?? '--'} bpm | '
                                    //   'Sleep: ${summary['latestSleep'] ?? '--'} hrs',
                                    //   style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    // ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  if (userId != null) {
                                    Navigator.pushNamed(
                                      context,
                                      '/reportpage',
                                      arguments: {
                                        'userId': userId,
                                        'userName': name,
                                        'fromDoctorDashboard': true,
                                      },
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
