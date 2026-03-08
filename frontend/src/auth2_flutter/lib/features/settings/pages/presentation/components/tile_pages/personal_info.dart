import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_cubit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:auth2_flutter/features/data/domain/entities/app_user.dart';

class PersonalInfo extends StatefulWidget {
  const PersonalInfo({super.key});

  @override
  State<PersonalInfo> createState() => _PersonalInfoState();
}

String _formatDate(DateTime date) {
  return '${date.day} ${_monthAbbr(date.month)} ${date.year}';
}

String _monthAbbr(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return months[month - 1];
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

  Future<void> _showEditProfileDialog(BuildContext context, AppUser user) async {
    final nameController = TextEditingController(text: user.fullName);
    final ageController = TextEditingController(text: user.age?.toString() ?? '');
    final heightController = TextEditingController(text: user.height?.toString() ?? '');
    final weightController = TextEditingController(text: user.weight?.toString() ?? '');
    String selectedGender = user.gender ?? 'prefer_not_to_say';

    return showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                        DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
                      ],
                      onChanged: (value) => setState(() => selectedGender = value!),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: heightController,
                      decoration: const InputDecoration(labelText: 'Height (cm)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: weightController,
                      decoration: const InputDecoration(labelText: 'Weight (kg)'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updatedData = {
                      'fullName': nameController.text,
                      'gender': selectedGender,
                      'age': int.tryParse(ageController.text),
                      'height': double.tryParse(heightController.text),
                      'weight': double.tryParse(weightController.text),
                    };
                    await _updateUserProfile(updatedData);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  String _getBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    if (Platform.isIOS) return 'http://localhost:3001';
    return 'http://localhost:3001'; // Windows, Linux, macOS
    // return http://192.168.0.3:3001'; // Connect wifi ip
    // return 'http://172.20.10.2:3001'; // Connect hotspot ip
  }

  Future<void> _updateUserProfile(Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) return;

    final response = await http.put(
      Uri.parse('${_getBaseUrl()}/api/user/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      await context.read<AuthCubit>().refreshUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().currentUser;

    print('Current user: ${user?.toJson()}');

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
              onEdit: () => _showEditProfileDialog(context, user!),
              children: [
                infoRow(
                  icon: Icons.person_rounded,
                  title: "Name",
                  value: user?.fullName ?? 'Not set',
                ),
                infoRow(
                  icon: Icons.male_rounded,
                  title: "Gender",
                  value: user?.gender ?? 'Not set',
                ),
                infoRow(
                  icon: Icons.cake_rounded,
                  title: "Age",
                  value: user?.age != null ? '${user!.age} years old' : 'Not set',
                ),
                infoRow(
                  icon: Icons.food_bank,
                  title: "Weight",
                  value: user?.weight != null ? '${user!.weight} kg' : 'Not set',
                  subtitle: user?.weightUpdatedAt != null ? 'Last updated ${_formatDate(user!.weightUpdatedAt!)}': null,
                ),
                infoRow(
                  icon: Icons.straighten,
                  title: "Height",
                  value: user?.height != null ? '${user!.height} cm' : 'Not set',
                  subtitle: user?.heightUpdatedAt != null ? 'Last updated ${_formatDate(user!.heightUpdatedAt!)}': null,
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