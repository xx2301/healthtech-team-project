import 'package:flutter/material.dart';

class HealthCards extends StatefulWidget {
  final String title; // card title
  final IconData icon; // card icon
  final bool hasProgressCircle; // needs progress circle
  final int value; // value of biometric
  final String unit; // type of biometric

  final double? progress; // 0.0 -1.0 for progress circle  

  const HealthCards({
    super.key,
    required this.title,
    required this.icon,
    required this.hasProgressCircle,
    required this.value,
    required this.unit,
    this.progress,
  });

  @override
  State<HealthCards> createState() => _HealthCardsState();
}

class _HealthCardsState extends State<HealthCards> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title row
          Row(
            children: [
              Icon(widget.icon, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // progress circle (only if enabled)
         Center(
  child: Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        width: 100,
        height: 100,
        child: widget.hasProgressCircle
            ? CircularProgressIndicator(
                value: widget.progress ?? 0.0,
                strokeWidth: 6,
                backgroundColor: Colors.grey[200],
                valueColor:
                    const AlwaysStoppedAnimation(Colors.green),
              )
            : null, // 👈 no circle when false
      ),
      Text(
        '${widget.value} ${widget.unit}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
)


        ],
      ),
    );
  }
}
