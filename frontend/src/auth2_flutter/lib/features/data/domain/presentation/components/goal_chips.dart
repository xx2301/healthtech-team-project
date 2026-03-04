import 'package:flutter/material.dart';

class GoalChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const GoalChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<GoalChip> createState() => _GoalChipState();
}

class _GoalChipState extends State<GoalChip> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? const Color.fromARGB(255, 92, 173, 94)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              
            ),
          ),
        ),
      ),
    );
  }
}