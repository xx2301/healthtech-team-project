import 'package:flutter/material.dart';

class InfoCards extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color backgroundColor;

  const InfoCards({
    super.key,
    required this.title,
    required this.subtitle,
    this.backgroundColor = const Color(0xFFE6F2E6),
  });

  @override
  State<InfoCards> createState() => _InfoCardState();
}

class _InfoCardState extends State<InfoCards> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:  EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 3,
            offset:  Offset(0, 2),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.title,
            style:  TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.subtitle,
            style:  TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
