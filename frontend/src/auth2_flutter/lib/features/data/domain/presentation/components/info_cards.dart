import 'package:flutter/material.dart';

class InfoCards extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color? backgroundColor;

  const InfoCards({
    super.key,
    required this.title,
    required this.subtitle,
    this.backgroundColor,
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
        color: (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F2E1F)
            : const Color(0xFFE6F2E6)),
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
              color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[200]
                    : Colors.grey[700],
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
