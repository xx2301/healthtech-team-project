import 'package:auth2_flutter/features/data/domain/entities/patient.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';
import 'package:auth2_flutter/features/patient/presentation/pSearchBar.dart';
import 'package:auth2_flutter/features/patient/presentation/pTable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    /*allPatients = [
      Patient(
        pid: 'P001',
        fname: 'Adam Lee',
        dateOfBirth: DateTime(1974, 5, 12),
        gender: 'Male',
        height: 175,
        weight: 78,
        bloodType: 'O+',
        allergies: ['Peanuts'],
        chronicConditions: ['Hypertension'],
        emergencyContactID: 101,
      ),
      Patient(
        pid: 'P002',
        fname: 'Noor Aisyah',
        dateOfBirth: DateTime(1961, 8, 21),
        gender: 'Female',
        height: 160,
        weight: 65,
        bloodType: 'A+',
        allergies: ['Penicillin'],
        chronicConditions: ['Diabetes'],
        emergencyContactID: 102,
      ),
      Patient(
        pid: 'P003',
        fname: 'Ivan Tan',
        dateOfBirth: DateTime(1965, 3, 2),
        gender: 'Male',
        height: 180,
        weight: 85,
        bloodType: 'B+',
        allergies: [],
        chronicConditions: ['Asthma'],
        emergencyContactID: 103,
      ),
    ];

    filteredPatients = List.of(allPatients);
  }*/
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
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

    final canAccess = (user.role == 'doctor' || user.role == 'admin' || user.role == 'super_admin');
    if (!canAccess) {
      _handleNoPermission('You do not have permission to view patients.');
      return;
    }

    await _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:3001/api/patients/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> patientsJson = jsonData['data'];
        final List<Patient> patients = patientsJson.map((json) {
          final userInfo = json['userId'] ?? {};
          return Patient(
            pid: json['_id'] ?? json['patientCode'] ?? 'Unknown',
            fname: userInfo['fullName'] ?? 'Unknown',
            dateOfBirth: userInfo['dateOfBirth'] != null
                ? DateTime.parse(userInfo['dateOfBirth'])
                : DateTime.now(),
            gender: userInfo['gender'] ?? 'Unknown',
            height: (json['height'] as num?)?.toDouble() ?? 0,
            weight: (json['weight'] as num?)?.toDouble() ?? 0,
            bloodType: json['bloodType'] ?? 'Unknown',
            allergies: (json['allergies'] as List?)?.cast<String>() ?? [],
            chronicConditions: (json['chronicConditions'] as List?)?.cast<String>() ?? [],
            emergencyContactID: json['emergencyContactId'] ?? 0,
          );
        }).toList();

        setState(() {
          _allPatients = patients;
          filteredPatients = List.of(_allPatients);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load patients: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
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
    final idQ = pIDController.text.trim().toLowerCase();

    setState(() {
      filteredPatients = _allPatients.where((p) {  // 原来是 allPatients
        final matchesName = nameQ.isEmpty || p.fname.toLowerCase().contains(nameQ);
        final matchesId = idQ.isEmpty || p.pid.toLowerCase().contains(idQ);

        // status: you currently don't have p.status, so we only filter if you add it later.
        // For now, this will always be true.
        final matchesStatus = true;

        // date of visit: you also don't have visit dates in Patient model, so can't filter yet.
        final matchesDate = true;

        return matchesName && matchesId && matchesStatus && matchesDate;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                color: const Color(0xFFEAF4EC),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Patient Search",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Patient Name",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pNameController,
                    decoration: InputDecoration(hintText: "Enter Patient Name"),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    "Patient ID",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pIDController,
                    decoration: InputDecoration(hintText: "Enter Patient ID"),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    "Date of Visit",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
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
                  onPressed: () {},
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                  ),
                  child: Text("Export Data"),
                  onPressed: () {},
                ),
              ],
            ),

            const SizedBox(height: 10),

            PatientSearchTable(patients: filteredPatients),
          ],
        ),
      ),
    );
  }
}