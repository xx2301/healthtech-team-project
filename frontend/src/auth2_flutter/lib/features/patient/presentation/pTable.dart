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
    final screenWidth = MediaQuery.of(context).size.width;

    double getFontSize() {
      if (screenWidth < 360) return 10;
      if (screenWidth < 400) return 11;
      if (screenWidth < 600) return 12;
      return 13;
    }

    final String status = "Available"; // change to p.status if exists
    final DateTime lastVisit = DateTime(2026, 3, 18);

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end
        ,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
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
          child: Align(
            alignment: Alignment.center,
            child: Text(
              '${lastVisit.day}/${lastVisit.month}/${lastVisit.year}' ?.toString() ?? '-',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
              ),
              Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              p.age?.toString() ?? '-',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: getFontSize(),
                color: Colors.black.withOpacity(0.75),
              ),
            ),
          ),
              ),
              Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              p.gender,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: getFontSize(),
                color: Colors.black.withOpacity(0.75),
              ),
            ),
          ),
              ),
              Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              (p.chronicConditions != null && p.chronicConditions!.isNotEmpty)
                  ? p.chronicConditions!.join(', ')
                  : '-',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: getFontSize(),
                color: Colors.black.withOpacity(0.75),
              ),
            ),
          ),
              ),
              Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              status,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: getFontSize(),
                color: Colors.black.withOpacity(0.75),
              ),
            ),
          ),
              ),
              
            ],
          ),
        
        SizedBox(height: 10),
        SizedBox(
      width: 72,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (canEdit)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue[400], size: 20),
              onPressed: () => onEdit(p),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          if (canDelete)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red[400],
                size: 20,
              ),
              onPressed: () => _confirmDelete(context, p),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    
          ),],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Patient patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text(
          'Are you sure you want to delete ${patient.fname}? This action cannot be undone.',
        ),
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
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: Colors.black.withOpacity(0.65),
    );

    return Container(
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
        children: [
          // Header Row
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color.fromARGB(255, 62, 99, 79)   // dark mode (muted green)
                  : const Color.fromARGB(255, 104, 167, 109),  // light mode (soft green)
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    "Patient Infos",
                    style: headerStyle.copyWith(color: Colors.white),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "Last Appt",
                    textAlign: TextAlign.center,
                    style: headerStyle.copyWith(color: Colors.white),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "Age",
                    textAlign: TextAlign.center,
                    style: headerStyle.copyWith(color: Colors.white),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "Sex",
                    textAlign: TextAlign.center,
                    style: headerStyle.copyWith(color: Colors.white),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Chronic Conditions",
                    textAlign: TextAlign.center,
                    style: headerStyle.copyWith(color: Colors.white),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "Status",
                    textAlign: TextAlign.center,
                    style: headerStyle.copyWith(color: Colors.white),
                  ),
                ),
               
              ],
            ),

            
          ),
          
          // Data Rows
          ...patients.map((p) => _dataRow(context, p)).toList(),
        ],
      ),
    );
  }
}
