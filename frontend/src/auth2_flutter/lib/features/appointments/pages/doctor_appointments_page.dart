import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  const DoctorAppointmentsPage({super.key});

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  List<dynamic> _appointments = [];
  bool _loading = true;
  String _filter = 'all'; // 'all', 'pending', 'confirmed', 'completed', 'cancelled'

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
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

  Future<void> _fetchAppointments() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/api/appointments/doctor'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _appointments = json['data'] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load appointments: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      print('Error: $e');
    }
  }

  Future<void> _updateAppointmentStatus(String id, String newStatus) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse('${_getBaseUrl()}/api/appointments/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': newStatus}),
      );
      if (response.statusCode == 200) {
        _fetchAppointments();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment ${newStatus == 'cancelled' ? 'cancelled' : 'updated'}.')),
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to update';
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

  List<dynamic> get _filteredAppointments {
    if (_filter == 'all') return _appointments;
    return _appointments.where((apt) => apt['status'] == _filter).toList();
  }

  Future<void> _editAppointment(Map<String, dynamic> apt) async {
    final dateController = TextEditingController(text: apt['date'].substring(0,10));
    final timeController = TextEditingController(text: apt['time'] ?? '');
    final reasonController = TextEditingController(text: apt['reason'] ?? '');
    String status = apt['status'] ?? 'pending';

    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text('Edit Appointment for ${apt['patientName']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(labelText: 'Time (e.g., 10:30)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(labelText: 'Reason'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: status,
                    items: ['pending', 'confirmed', 'completed', 'cancelled'].map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (val) => setState(() => status = val!),
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final data = {
                    if (dateController.text.isNotEmpty) 'date': dateController.text,
                    if (timeController.text.isNotEmpty) 'time': timeController.text,
                    if (reasonController.text.isNotEmpty) 'reason': reasonController.text,
                    'status': status,
                  };
                  await _updateAppointment(apt['_id'], data);
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateAppointment(String id, Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse('${_getBaseUrl()}/api/appointments/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        _fetchAppointments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment updated')),
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to update';
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _filter == 'all',
                        onSelected: (selected) => setState(() => _filter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Pending'),
                        selected: _filter == 'pending',
                        onSelected: (selected) => setState(() => _filter = 'pending'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Confirmed'),
                        selected: _filter == 'confirmed',
                        onSelected: (selected) => setState(() => _filter = 'confirmed'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Completed'),
                        selected: _filter == 'completed',
                        onSelected: (selected) => setState(() => _filter = 'completed'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Cancelled'),
                        selected: _filter == 'cancelled',
                        onSelected: (selected) => setState(() => _filter = 'cancelled'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredAppointments.isEmpty
                      ? const Center(child: Text('No appointments'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredAppointments.length,
                          itemBuilder: (ctx, index) {
                            final apt = _filteredAppointments[index];
                            final date = DateTime.parse(apt['date']);
                            final time = apt['time'] ?? '';
                            final patientName = apt['patientName'] ?? 'Unknown';
                            final status = apt['status'];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(
                                  '$patientName - ${date.year}-${date.month}-${date.day} ${time.isNotEmpty ? 'at $time' : ''}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('Reason: ${apt['reason'] ?? ''}\nStatus: $status'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (apt['status'] != 'completed' && apt['status'] != 'cancelled')
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Colors.blue[400]),
                                        onPressed: () => _editAppointment(apt),
                                      ),
                                    if (status == 'pending')
                                      IconButton(
                                        icon: const Icon(Icons.check_circle, color: Colors.green),
                                        onPressed: () => _updateAppointmentStatus(apt['_id'], 'confirmed'),
                                        tooltip: 'Confirm',
                                      ),
                                    if (status == 'confirmed')
                                      IconButton(
                                        icon: const Icon(Icons.done_all, color: Colors.blue),
                                        onPressed: () => _updateAppointmentStatus(apt['_id'], 'completed'),
                                        tooltip: 'Mark completed',
                                      ),
                                    if (status == 'pending' || status == 'confirmed')
                                      IconButton(
                                        icon: const Icon(Icons.cancel, color: Colors.red),
                                        onPressed: () => _updateAppointmentStatus(apt['_id'], 'cancelled'),
                                        tooltip: 'Cancel',
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}