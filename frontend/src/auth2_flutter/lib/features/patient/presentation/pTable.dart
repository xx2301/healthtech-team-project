import 'package:auth2_flutter/features/data/domain/entities/patient.dart';
import 'package:flutter/material.dart';

class PatientSearchTable extends StatelessWidget {
  final List<Patient> patients;
  final Function(Patient) onDelete;
  final Function(Patient) onEdit;
  final bool canDelete;
  final bool canEdit;

  const PatientSearchTable({
    super.key,
    required this.patients,
    required this.onDelete,
    required this.onEdit,
    this.canDelete = false,
    this.canEdit = false,
  });

  Widget _dataRow(BuildContext context, Patient p) {
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
                  "ID: ${p.patientCode}",
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
              p.age?.toString() ?? '-',
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(status),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canEdit)
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue[400], size: 20),
                      onPressed: () => onEdit(p),
                      constraints: BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    if (canDelete)
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
                      onPressed: () => _confirmDelete(context, p),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Patient patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text('Are you sure you want to delete ${patient.fname}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              onDelete(patient);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
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
          ...patients.map((p) => _dataRow(context, p)).toList(),
        ],
      ),
    );
  }
}