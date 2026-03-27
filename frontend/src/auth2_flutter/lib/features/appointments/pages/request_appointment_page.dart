import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class RequestAppointmentPage extends StatefulWidget {
  const RequestAppointmentPage({super.key});

  @override
  State<RequestAppointmentPage> createState() => _RequestAppointmentPageState();
}

class _RequestAppointmentPageState extends State<RequestAppointmentPage> {
  List<dynamic> _doctors = [];
  String? _selectedDoctorId;
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _loadingDoctors = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
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

  Future<void> _fetchDoctors() async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/api/patients/my-doctors'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _doctors = json['data'] ?? [];
          _loadingDoctors = false;
          if (_doctors.isNotEmpty) _selectedDoctorId = _doctors.first['id'];
        });
      } else {
        setState(() => _loadingDoctors = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load doctors')),
        );
      }
    } catch (e) {
      setState(() => _loadingDoctors = false);
      print('Error fetching doctors: $e');
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a doctor')),
      );
      return;
    }
    final date = _dateController.text.trim();
    final time = _timeController.text.trim();
    if (date.isEmpty || time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date and time are required')),
      );
      return;
    }

    setState(() => _submitting = true);
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${_getBaseUrl()}/api/appointments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'doctorId': _selectedDoctorId,
          'date': date,
          'time': time,
          'reason': _reasonController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment request sent')),
        );
        Navigator.pop(context);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to request';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Appointment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loadingDoctors
            ? const Center(child: CircularProgressIndicator())
            : _doctors.isEmpty
                ? const Center(child: Text('No doctors available'))
                : Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedDoctorId,
                        decoration: const InputDecoration(labelText: 'Select Doctor *'),
                        items: _doctors.map<DropdownMenuItem<String>>((doc) {
                          return DropdownMenuItem<String>(
                            value: doc['id'] as String?,
                            child: Text(doc['name'] as String? ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedDoctorId = value),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _dateController,
                        decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD) *'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _timeController,
                        decoration: const InputDecoration(labelText: 'Time (e.g., 10:30) *'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reasonController,
                        decoration: const InputDecoration(labelText: 'Reason'),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submitRequest,
                          child: _submitting ? const CircularProgressIndicator() : const Text('Submit Request'),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
