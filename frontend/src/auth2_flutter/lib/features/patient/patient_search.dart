import 'package:auth2_flutter/features/data/domain/entities/patient.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';
import 'package:auth2_flutter/features/patient/presentation/pSearchBar.dart';
import 'package:auth2_flutter/features/patient/presentation/pTable.dart';
import 'package:flutter/material.dart';

class PatientSearch extends StatefulWidget {
  const PatientSearch({super.key});

  @override
  State<PatientSearch> createState() => _PatientSearchState();
}

class _PatientSearchState extends State<PatientSearch> {
  final pNameController = TextEditingController();
  final pIDController = TextEditingController();
  final dateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
                color: const Color.fromARGB(255, 203, 231, 204),
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
                  DropdownMenu<String>(
                    initialSelection: "Avaliable",
                    textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    dropdownMenuEntries: [
                      DropdownMenuEntry(value: "Avaliable", label: "Available"),
                      DropdownMenuEntry(value: "Healthy", label: "Healthy"),
                      DropdownMenuEntry(value: "Critical", label: "Critical"),
                    ],
                    onSelected: (value) {
                      print(value);
                    },
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(child: Text("Reset"), onPressed: () {}),

                      const SizedBox(width: 20),

                      ElevatedButton(child: Text("Search"), onPressed: () {}),
                    ],
                  ),
                ],
              ),
            ),

            Text(
              "Patients",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(child: Text("+ Add Patient"), onPressed: () {}),

                ElevatedButton(child: Text("Export Data"), onPressed: () {}),
              ],
            ),

            const SizedBox(height: 10),

            PatientSearchTable(
              patients: [
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
