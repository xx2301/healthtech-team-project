import 'package:auth2_flutter/features/data/domain/entities/patient.dart';
import 'package:flutter/material.dart';

class PatientSearchTable extends StatelessWidget {
  final List<Patient> patients;

  const PatientSearchTable({
    super.key,
    required this.patients,
  });

  Widget _dataRow(Patient p) {
    final String status = "Available"; // change to p.status if exists

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.fname,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  "ID: ${p.pid}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              (p.age ?? 0).toString(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              p.gender,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              status,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    TextStyle headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: Colors.black.withOpacity(0.65),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              Expanded(flex: 2, child: Text("Patient Infos", style: headerStyle)),
              Expanded(flex: 1, child: Text("Age", style: headerStyle)),
              Expanded(flex: 1, child: Text("Sex", style: headerStyle)),
              Expanded(flex: 1, child: Text("Status", style: headerStyle)),
            ],
          ),
          const SizedBox(height: 8),

          // Data Rows
          ...patients.map((p) => _dataRow(p)).toList(),
        ],
      ),
    );
  }
}
