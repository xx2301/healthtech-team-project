import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  List<dynamic> _appointments = [];
  bool _loading = true;

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
        Uri.parse('${_getBaseUrl()}/api/appointments/my'),
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
      print('Error loading appointments: $e');
    }
  }

  Future<void> _cancelAppointment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${_getBaseUrl()}/api/appointments/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled')),
        );
        _fetchAppointments();
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to cancel';
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _editAppointment(Map<String, dynamic> apt) async {
    final reasonController = TextEditingController(text: apt['reason'] ?? '');
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Appointment Reason'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newReason = reasonController.text.trim();
              if (newReason == (apt['reason'] ?? '')) {
                Navigator.pop(ctx);
                return;
              }
              await _updateAppointment(apt['_id'], {'reason': newReason});
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
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
          : _appointments.isEmpty
              ? const Center(child: Text('No appointments'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _appointments.length,
                  itemBuilder: (ctx, index) {
                    final apt = _appointments[index];
                    final date = DateTime.parse(apt['date']);
                    final time = apt['time'] ?? '';
                    final reason = apt['reason'] ?? '';
                    final status = apt['status'] ?? 'pending';
                    final isCancellable = status == 'pending' || status == 'confirmed';
                    final isEditable = status != 'cancelled' && status != 'completed'; // 允许编辑未取消/未完成的预约

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          '${_formatDate(date)} ${time.isNotEmpty ? 'at $time' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (reason.isNotEmpty) Text('Reason: $reason'),
                            const SizedBox(height: 4),
                            Text('Status: $status'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isEditable)
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue[400]),
                                onPressed: () => _editAppointment(apt),
                              ),
                            if (isCancellable)
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _cancelAppointment(apt['_id']),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
