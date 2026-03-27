import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Getting Started',
              content: '''
• Add health data: Click the "+" button on the Home or Report page to manually log steps, heart rate, sleep, water intake, etc.
• Connect devices: Go to Settings → Health Devices to sync wearables.
• View reports: Navigate to Report page to see weekly summaries, charts, and insights.
''',
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Setting Goals',
              content: '''
• Set daily goals for steps, calories, sleep, and water from Settings → Health Goals.
• Your progress will be shown on the dashboard and in the weekly report.
''',
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Understanding Your Data',
              content: '''
• Steps: Total steps this week.
• Heart Rate: Average BPM (normal 60-100).
• Calories: Active calories burned.
• Sleep: Total hours of sleep.
• Glucose & Blood Pressure: Latest readings and trends.
''',
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'FAQs',
              content: '''
Q: How do I edit a goal?
A: Go to Settings → Health Goals, tap on a goal, and adjust the target value.

Q: Can I export my data?
A: Yes! Go to Settings → Export My Data and choose JSON or CSV format.

Q: How to delete my account?
A: Scroll to the bottom of Settings and tap "Delete Account".

Q: Why is some data missing?
A: Make sure you have added data manually or synced devices. The report covers the selected date range.
''',
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Contact Support',
              content: 'If you need further assistance, please email us at support@healthtech.com',
              isDark: isDark,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
