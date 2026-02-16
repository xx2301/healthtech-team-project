import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';
import 'package:flutter/material.dart';

class PersonalInfo extends StatefulWidget {
  const PersonalInfo({super.key});

  @override
  State<PersonalInfo> createState() => _PersonalInfoState();
}

class _PersonalInfoState extends State<PersonalInfo> {
  Widget infoRow({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.black.withOpacity(0.55)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.45),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionCard({
    required String title,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 20),
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Divider(height: 1, color: Colors.black.withOpacity(0.06)),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DefaultAppBar(),
      drawer: DefaultDrawer(),
      backgroundColor: const Color(0xFFF5F6F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Personal Information",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
            ),
            const SizedBox(height: 14),

            // ===== Card 1: Personal =====
            sectionCard(
              title: "Profile",
              onEdit: () {},
              children: [
                infoRow(
                  icon: Icons.person_rounded,
                  title: "Name",
                  value: "Joseph Wong",
                ),
                infoRow(
                  icon: Icons.male_rounded,
                  title: "Gender",
                  value: "Male",
                ),
                infoRow(
                  icon: Icons.cake_rounded,
                  title: "Age",
                  value: "19 years old",
                ),
                infoRow(
                  icon: Icons.food_bank,
                  title: "Weight",
                  value: "62 kg",
                  subtitle: "Last updated 1 Mar",
                ),
                infoRow(
                  icon: Icons.straighten,
                  title: "Height",
                  value: "170 cm",
                  subtitle: "Last updated 1 Mar",
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ===== Card 2: Medical Record =====
            sectionCard(
              title: "Medical Record",
              onEdit: () {},
              children: [
                infoRow(
                  icon: Icons.local_hospital_rounded,
                  title: "Doctor",
                  value: "Guru Priya",
                ),
                infoRow(
                  icon: Icons.event_rounded,
                  title: "Last doctor visit",
                  value: "19/11/2022",
                ),
                infoRow(
                  icon: Icons.favorite_rounded,
                  title: "Average heart rate",
                  value: "70 bpm",
                  subtitle: "Last updated 1 Mar",
                ),
                infoRow(
                  icon: Icons.directions_walk_rounded,
                  title: "Average daily steps",
                  value: "8,000",
                  subtitle: "Last updated 1 Mar",
                ),
                infoRow(
                  icon: Icons.nightlight_round,
                  title: "Average sleep duration",
                  value: "7 hours",
                  subtitle: "Last updated 1 Mar",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
