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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected ? Colors.green : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: _isHovered
                ? [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))]
                : null,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: _isHovered ? FontWeight.w700 : FontWeight.bold,
                color: widget.isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (widget.isSelected) return const Color.fromARGB(255, 92, 173, 94);
    if (_isHovered) return Colors.green.shade50;
    return Colors.grey.shade200;
  }
}