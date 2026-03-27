import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';

class ApplyDoctorPage extends StatefulWidget {
  const ApplyDoctorPage({Key? key}) : super(key: key);

  @override
  State<ApplyDoctorPage> createState() => _ApplyDoctorPageState();
}

class _ApplyDoctorPageState extends State<ApplyDoctorPage> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _specializationController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _departmentController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();
  String _selectedSpecialization = 'general_practice';
  bool _isLoading = false;

  final List<String> _specializations = [
    'cardiology', 'dermatology', 'endocrinology', 'gastroenterology',
    'neurology', 'pediatrics', 'psychiatry', 'radiology',
    'surgery', 'general_practice', 'orthopedics', 'ophthalmology'
  ];

  @override
  void dispose() {
    _licenseController.dispose();
    _specializationController.dispose();
    _hospitalController.dispose();
    _departmentController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    super.dispose();
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

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final data = {
        'medicalLicenseNumber': _licenseController.text.trim(),
        'specialization': _selectedSpecialization,
        'hospitalAffiliation': _hospitalController.text.trim(),
        'department': _departmentController.text.trim(),
        'yearsOfExperience': int.tryParse(_experienceController.text) ?? 0,
        'consultationFee': double.tryParse(_feeController.text) ?? 0,
      };

      final response = await http.post(
        Uri.parse('${_getBaseUrl()}/api/user/apply-for-doctor'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully! Pending approval.')),
        );
        Navigator.pop(context);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Application failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DefaultAppBar(),
      drawer: DefaultDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apply as Doctor',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fill in your professional details. Your application will be reviewed by an admin.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(
                  labelText: 'Medical License Number *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedSpecialization,
                decoration: const InputDecoration(
                  labelText: 'Specialization *',
                  border: OutlineInputBorder(),
                ),
                items: _specializations.map((spec) {
                  return DropdownMenuItem(
                    value: spec,
                    child: Text(spec.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedSpecialization = value!),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _hospitalController,
                decoration: const InputDecoration(
                  labelText: 'Hospital Affiliation (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(
                  labelText: 'Years of Experience *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _feeController,
                decoration: const InputDecoration(
                  labelText: 'Consultation Fee (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitApplication,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Application', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
