import 'package:auth2_flutter/features/data/domain/entities/patient.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';
import 'package:auth2_flutter/features/patient/presentation/pTable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:open_file/open_file.dart';
import 'package:csv/csv.dart';

class PatientSearch extends StatefulWidget {
  const PatientSearch({super.key});

  @override
  State<PatientSearch> createState() => _PatientSearchState();
}

class _PatientSearchState extends State<PatientSearch> {
  final pNameController = TextEditingController();
  final pIDController = TextEditingController();
  final dateController = TextEditingController();
  String selectedStatus = 'Available';
  DateTime? selectedDate;

  late final List<Patient> allPatients; //not used anymore
  List<Patient> filteredPatients = [];

  bool _isLoading = true;
  String? _error;
  bool _hasPermission = true;
  List<Patient> _allPatients = [];

  @override
  void initState() {
    super.initState();
    _checkPermissionAndFetch();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  void _handleNoPermission(String message) {
    setState(() {
      _hasPermission = false;
      _error = message;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pushReplacementNamed(context, '/homepage');
    });
  }

  Future<void> _checkPermissionAndFetch() async {
    final authCubit = context.read<AuthCubit>();
    final user = authCubit.currentUser;

    if (user == null) {
      _handleNoPermission('Not logged in');
      return;
    }

    final canAccess =
        (user.role == 'doctor' ||
        user.role == 'admin' ||
        user.role == 'super_admin');
    if (!canAccess) {
      _handleNoPermission('You do not have permission to view patients.');
      return;
    }

    await _fetchPatients();
  }

  String _getBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    if (Platform.isIOS) return 'http://localhost:3001';
    return 'http://localhost:3001'; // Windows, Linux, macOS
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/api/patients/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          final List<dynamic> patientsJson = jsonData['data'];
          final List<Patient> patients = patientsJson.map((json) {
            return Patient.fromJson(json);
          }).toList();
          setState(() {
            _allPatients = patients;
            filteredPatients = List.of(_allPatients);
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Failed to load patients: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAddPatientDialog() async {
    bool isNewUser = true;

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final ageController = TextEditingController();
    final heightController = TextEditingController();
    final weightController = TextEditingController();
    final genderController = TextEditingController(text: 'other');

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add New Patient'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.all(0),
                        title: Text('Create new user'),
                        value: isNewUser,
                        onChanged: (value) {
                          setState(() => isNewUser = value);
                        },
                      ),
                      const Divider(),
                  
                      if (isNewUser) ...[
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(labelText: 'Full Name *'),
                        ),

                        SizedBox(height: 5), 
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(labelText: 'Email *'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                          SizedBox(height: 5), 
                        TextField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password (min 6 chars) *',
                          ),
                          obscureText: true,
                        ),
                         SizedBox(height: 5), 
                        TextField(
                          controller: ageController,
                          decoration: InputDecoration(labelText: 'Age'),
                          keyboardType: TextInputType.number,
                        ),
                         SizedBox(height: 5), 
                        TextField(
                          controller: heightController,
                          decoration: InputDecoration(labelText: 'Height (cm)'),
                          keyboardType: TextInputType.number,
                        ),
                         SizedBox(height: 5), 
                        TextField(
                          controller: weightController,
                          decoration: InputDecoration(labelText: 'Weight (kg)'),
                          keyboardType: TextInputType.number,
                        ),
                         SizedBox(height: 5), 
                        DropdownButtonFormField<String>(
                          value: genderController.text,
                          decoration: InputDecoration(labelText: 'Gender'),
                          items: ['male', 'female', 'other', 'prefer_not_to_say']
                              .map(
                                (gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => genderController.text = value!,
                        ),
                      ] else ...[
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Existing User Email *',
                            hintText: 'Enter user email',
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'User will be linked as patient.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final email = emailController.text.trim();
                    if (email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Email is required')),
                      );
                      return;
                    }
                    if (isNewUser) {
                      final name = nameController.text.trim();
                      final password = passwordController.text.trim();
                      if (name.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Name and password are required for new user',
                            ),
                          ),
                        );
                        return;
                      }
                    }

                    Navigator.pop(context);

                    if (isNewUser) {
                      await _addNewUserPatient(
                        name: nameController.text.trim(),
                        email: email,
                        password: passwordController.text.trim(),
                        age: ageController.text.trim(),
                        height: heightController.text.trim(),
                        weight: weightController.text.trim(),
                        gender: genderController.text.trim(),
                      );
                    } else {
                      await _linkExistingUserAsPatient(email);
                    }
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditPatientDialog(Patient patient) async {
    final ageController = TextEditingController(
      text: patient.age?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: patient.height?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: patient.weight?.toString() ?? '',
    );
    String selectedBloodType = patient.bloodType ?? 'unknown';

    final allergiesText = patient.allergies.join(', ');
    final chronicConditionsText = patient.chronicConditions.join(', ');

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String tempAllergies = allergiesText;
            String tempChronic = chronicConditionsText;

            return AlertDialog(
              title: Text('Edit Patient: ${patient.fname}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: heightController,
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedBloodType,
                      decoration: const InputDecoration(
                        labelText: 'Blood Type',
                      ),
                      items:
                          const [
                                'A+',
                                'A-',
                                'B+',
                                'B-',
                                'AB+',
                                'AB-',
                                'O+',
                                'O-',
                                'unknown',
                              ]
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (value) =>
                          setState(() => selectedBloodType = value!),
                    ),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Allergies (comma separated)',
                      ),
                      onChanged: (value) => tempAllergies = value,
                    ),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Chronic Conditions (comma separated)',
                      ),
                      onChanged: (value) => tempChronic = value,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    List<String> allergiesList = tempAllergies
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                    List<String> chronicList = tempChronic
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();

                    final updatedData = {
                      'age': int.tryParse(ageController.text),
                      'height': double.tryParse(heightController.text),
                      'weight': double.tryParse(weightController.text),
                      'bloodType': selectedBloodType,
                      'allergies': allergiesList,
                      'chronicConditions': chronicList,
                    };
                    await _updatePatient(patient.pid, updatedData);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addNewUserPatient({
    required String name,
    required String email,
    required String password,
    required String age,
    required String height,
    required String weight,
    required String gender,
  }) async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final registerBody = {
        'fullName': name,
        'email': email,
        'password': password,
        'age': age,
        'height': height,
        'weight': weight,
        'gender': gender,
      };

      final registerResponse = await http.post(
        Uri.parse('${_getBaseUrl()}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(registerBody),
      );

      if (registerResponse.statusCode != 201) {
        final errorData = jsonDecode(registerResponse.body);
        throw Exception(errorData['error'] ?? 'Registration failed');
      }

      final registerData = jsonDecode(registerResponse.body);
      final userId = registerData['user']['_id'];

      await _createPatientProfile(userId, weight, height, age: age);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePatient(
    String patientId,
    Map<String, dynamic> data,
  ) async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('${_getBaseUrl()}/api/admin/patients/$patientId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        await _fetchPatients();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patient updated successfully')),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error'] ?? errorData['message'] ?? 'Update failed',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _linkExistingUserAsPatient(String email) async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final lookupResponse = await http.get(
        Uri.parse(
          '${_getBaseUrl()}/api/admin/users?search=${Uri.encodeComponent(email)}',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (lookupResponse.statusCode != 200) {
        throw Exception('Failed to lookup user');
      }

      final lookupData = jsonDecode(lookupResponse.body);
      final List<dynamic> users = lookupData['data'];
      if (users.isEmpty) {
        throw Exception('User not found');
      }

      final user = users.first;
      final userId = user['_id'];

      if (user['patientProfileId'] != null) {
        throw Exception('User already has a patient profile');
      }

      await _createPatientProfile(
        userId,
        null,
        null,
      ); //weight and height can be null
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createPatientProfile(
    String userId,
    String? weight,
    String? height, {
    String? age,
  }) async {
    final token = await _getToken();
    final patientBody = {
      'userId': userId,
      if (weight != null && weight.isNotEmpty)
        'weight': double.tryParse(weight),
      if (height != null && height.isNotEmpty)
        'height': double.tryParse(height),
      if (age != null && age.isNotEmpty) 'age': int.tryParse(age),
      'bloodType': 'unknown',
    };

    final patientResponse = await http.post(
      Uri.parse('${_getBaseUrl()}/api/admin/create-patient'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(patientBody),
    );

    if (patientResponse.statusCode != 201) {
      String errorMsg = 'Failed to create patient profile';
      try {
        final errorData = jsonDecode(patientResponse.body);
        errorMsg = errorData['error'] ?? errorMsg;
      } catch (_) {}
      throw Exception(errorMsg);
    }

    await _fetchPatients();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Patient added successfully')));
    }
  }

  Future<void> _deletePatient(Patient patient) async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('${_getBaseUrl()}/api/admin/patients/${patient.pid}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _allPatients.removeWhere((p) => p.pid == patient.pid);
          filteredPatients.removeWhere((p) => p.pid == patient.pid);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient deleted successfully')),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Delete failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetFilters() {
    pNameController.clear();
    pIDController.clear();
    dateController.clear();
    selectedDate = null;
    selectedStatus = 'Available';

    setState(() {
      filteredPatients = List.of(_allPatients);
    });
  }

  void _applySearch() {
    final nameQ = pNameController.text.trim().toLowerCase();
    final codeQ = pIDController.text.trim().toLowerCase();

    setState(() {
      filteredPatients = _allPatients.where((p) {
        final matchesName = nameQ.isEmpty || p.fname.toLowerCase().contains(nameQ);
        final matchesCode = codeQ.isEmpty || p.patientCode.toLowerCase().contains(codeQ);
        return matchesName && matchesCode;
      }).toList();
    });
  }

  Future<void> _showExportDialog() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Choose format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'json'),
            child: const Text('JSON'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'csv'),
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (choice != null) {
      await _exportData(format: choice);
    }
  }

  Future<void> _exportData({required String format}) async {
    if (_allPatients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No patients to export')),
      );
      return;
    }

    final List<Map<String, dynamic>> exportList = _allPatients.map((p) {
      return {
        'Patient Code': p.patientCode,
        'Name': p.fname,
        'Gender': p.gender,
        'Age': p.age,
        'Height': p.height,
        'Weight': p.weight,
        'Blood Type': p.bloodType,
        'Allergies': p.allergies.join(', '),
        'Chronic Conditions': p.chronicConditions.join(', '),
      };
    }).toList();

    String content;
    String fileName;
    if (format == 'json') {
      content = JsonEncoder.withIndent('  ').convert(exportList);
      fileName = 'patients_export.json';
    } else {
      content = _listToCsv(exportList);
      fileName = 'patients_export.csv';
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);

    if (kIsWeb) {
      await SharePlus.instance.share(
        ShareParams(
          text: 'Patient list',
          files: [XFile(file.path)],
          downloadFallbackEnabled: true,
        ),
      );
    } else {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        await OpenFile.open(file.path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File opened: $fileName')),
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            text: 'Patient list',
            files: [XFile(file.path)],
          ),
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported ${_allPatients.length} patients as $format')),
    );
  }

  String _listToCsv(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';
    final headers = data.first.keys.toList();
    final rows = <List<dynamic>>[headers];
    for (var item in data) {
      final row = headers.map((h) => item[h]?.toString() ?? '').toList();
      rows.add(row);
    }
    return ListToCsvConverter().convert(rows);
  }

  Future<void> _createAppointment(Patient patient) async {
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final reasonController = TextEditingController();

    print('Patient Code: ${patient.patientCode}');

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Create Appointment for ${patient.fname}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration: InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
            ),
            TextField(
              controller: timeController,
              decoration: InputDecoration(labelText: 'Time (e.g., 10:30)'),
            ),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final token = await _getToken();
              if (token == null) return;

              final response = await http.post(
                Uri.parse('${_getBaseUrl()}/api/appointments'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({
                  'patientCode': patient.patientCode, // 改为 patientCode
                  'date': dateController.text,
                  'time': timeController.text,
                  'reason': reasonController.text,
                }),
              );

              if (response.statusCode == 201) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Appointment created')),
                );
                _fetchPatients(); // 刷新列表以更新 lastAppt
              } else {
                final error = jsonDecode(response.body)['error'] ?? 'Failed to create';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $error')),
                );
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().currentUser;
    final canEdit =
        user?.role == 'doctor' ||
        user?.role == 'admin' ||
        user?.role == 'super_admin';
    final canDelete = user?.role == 'admin' || user?.role == 'super_admin';

    if (!_hasPermission) {
      return Scaffold(
        appBar: DefaultAppBar(),
        drawer: DefaultDrawer(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: DefaultAppBar(),
        drawer: DefaultDrawer(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: DefaultAppBar(),
        drawer: DefaultDrawer(),
        body: Center(child: Text('Error: $_error')),
      );
    }

    return Scaffold(
      appBar: DefaultAppBar(),
      drawer: DefaultDrawer(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color.fromARGB(255, 36, 36, 36)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: Theme.of(context).brightness == Brightness.dark
                        ? 20
                        : 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medical_information, size: 30),
                        const SizedBox(width: 5),
                      Text(
                        "Patient Search",
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                    
                      Text(
                        "Patient Name",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  TextField(
                    controller: pNameController,
                    decoration: InputDecoration(hintText: "Enter Patient Name"),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    "Patient ID",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: pIDController,
                    decoration: InputDecoration(hintText: "Enter Patient ID"),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    "Date of Visit",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
           
                  TextField(
                    controller: dateController,
                    decoration: InputDecoration(hintText: "mm/dd/yyyy"),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    "Status",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: DropdownMenu<String>(
                      initialSelection: selectedStatus,
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(
                          value: "Available",
                          label: "Available",
                        ),
                        DropdownMenuEntry(value: "Healthy", label: "Healthy"),
                        DropdownMenuEntry(value: "Critical", label: "Critical"),
                      ],
                      onSelected: (value) {
                        if (value == null) return;
                        setState(() => selectedStatus = value);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("Reset"),
                        onPressed: _resetFilters,
                      ),

                      const SizedBox(width: 10),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("Search"),
                        onPressed: _applySearch,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Patients",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                  ),
                  child: Text("+ Add Patient"),
                  onPressed: _showAddPatientDialog,
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                  ),
                  child: Text("Export Data"),
                  onPressed: _showExportDialog,
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (filteredPatients.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Icon(Icons.search_off, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No patients found',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try a different name or patient code.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              PatientSearchTable(
                patients: filteredPatients,
                onDelete: _deletePatient,
                onEdit: _showEditPatientDialog,
                canDelete: canDelete,
                canEdit: canEdit,
                onCreateAppointment: _createAppointment,
              ),
          ],
        ),
      ),
    );
  }
}