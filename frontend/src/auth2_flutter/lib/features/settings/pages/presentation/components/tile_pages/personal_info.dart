import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_cubit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:auth2_flutter/features/data/domain/entities/app_user.dart';
import 'dart:async';

class PersonalInfo extends StatefulWidget {
  const PersonalInfo({super.key});

  @override
  State<PersonalInfo> createState() => _PersonalInfoState();
}

String _formatDate(DateTime date) {
  return '${date.day} ${_monthAbbr(date.month)} ${date.year}';
}

String _monthAbbr(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}

class _PersonalInfoState extends State<PersonalInfo> {
  Map<String, dynamic>? _fullProfile;
  bool _isLoadingMedical = false;
  String? _medicalError;
  List<dynamic> _sessions = [];
  bool _loadingSessions = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchFullProfile();
    _fetchSessions();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _fetchSessions(silent: true);
      }
    });
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  String _getBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    if (Platform.isIOS) return 'http://localhost:3001';
    return 'http://localhost:3001';
  }

  Future<void> _fetchFullProfile() async {
    setState(() {
      _isLoadingMedical = true;
    });

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _isLoadingMedical = false;
        _medicalError = 'Not authenticated';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/api/user/full-profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _fullProfile = json['data'];
          _isLoadingMedical = false;
        });
      } else {
        throw Exception('Failed to load full profile: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _medicalError = e.toString();
        _isLoadingMedical = false;
      });
    }
  }

  Future<void> _fetchSessions({bool silent = false}) async {
    if (!silent) setState(() => _loadingSessions = true);
    try {
      final token = await _getToken();
      if (token == null) {
        if (!silent) setState(() => _loadingSessions = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/api/sessions'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _sessions = json['data'] ?? [];
          if (!silent) _loadingSessions = false;
        });
      } else {
        if (!silent) setState(() => _loadingSessions = false);
        print('Failed to load sessions: ${response.body}');
      }
    } catch (e) {
      if (!silent) setState(() => _loadingSessions = false);
      print('Error fetching sessions: $e');
    }
  }

  Future<void> _terminateSession(String sessionId) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${_getBaseUrl()}/api/sessions/$sessionId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchSessions();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Session terminated')));
      } else {
        final error =
            jsonDecode(response.body)['error'] ?? 'Failed to terminate';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $error')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

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
          Icon(icon, size: 20),
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
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
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
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
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
              const SizedBox(width: 4),
              IconButton(
                onPressed: _showColorPickerDialog,
                icon: const Icon(Icons.color_lens, size: 20),
                splashRadius: 18,
                tooltip: 'Change avatar color',
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

  Future<void> _showEditProfileDialog(
    BuildContext context,
    AppUser user,
  ) async {
    final nameController = TextEditingController(text: user.fullName);
    final ageController = TextEditingController(
      text: user.age?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: user.height?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: user.weight?.toString() ?? '',
    );
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
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                        DropdownMenuItem(
                          value: 'prefer_not_to_say',
                          child: Text('Prefer not to say'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => selectedGender = value!),
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
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color:Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,)
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final currentUser = context.read<AuthCubit>().currentUser;
                    final Map<String, dynamic> updatedData = {};

                    if (nameController.text != currentUser?.fullName) {
                      updatedData['fullName'] = nameController.text;
                    }
                    if (selectedGender != currentUser?.gender) {
                      updatedData['gender'] = selectedGender;
                    }
                    final newAge = int.tryParse(ageController.text);
                    if (newAge != null &&
                        newAge.toString() != currentUser?.age) {
                      updatedData['age'] = newAge;
                    }
                    final newHeight = double.tryParse(heightController.text);
                    if (newHeight != null &&
                        newHeight.toString() != currentUser?.height) {
                      updatedData['height'] = newHeight;
                    }
                    final newWeight = double.tryParse(weightController.text);
                    if (newWeight != null &&
                        newWeight.toString() != currentUser?.weight) {
                      updatedData['weight'] = newWeight;
                    }

                    if (updatedData.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No changes detected')),
                      );
                      return;
                    }

                    await _updateUserProfile(updatedData);
                    Navigator.pop(ctx);
                  },
                  child:  Text('Save', style: TextStyle(color:Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,)
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateUserProfile(Map<String, dynamic> data) async {
    if (data.isEmpty) return;

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

  Future<void> _showColorPickerDialog() async {
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Avatar Color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () async {
                final colorInt = color.value;
                await _updateAvatarColor(colorInt);
                Navigator.pop(ctx);
              },
              child: CircleAvatar(backgroundColor: color, radius: 24),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _updateAvatarColor(int colorInt) async {
    final token = await _getToken();
    if (token == null) return;
    final response = await http.put(
      Uri.parse('${_getBaseUrl()}/api/user/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'avatarColor': colorInt}),
    );
    if (response.statusCode == 200) {
      await context.read<AuthCubit>().refreshUser();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Avatar color updated')));
    }
  }

  Widget? _buildMedicalRecordCard() {
    if (_isLoadingMedical) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_medicalError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text('Error loading medical data: $_medicalError'),
        ),
      );
    }
    if (_fullProfile == null) return null;

    final patient = _fullProfile!['patient'];
    final assignedDoctors = _fullProfile!['assignedDoctors'] as List? ?? [];
    final hasDoctor = assignedDoctors.isNotEmpty && assignedDoctors[0] != null;

    if (!hasDoctor) return null;

    // fetch first doctor
    final doctor = assignedDoctors[0]['doctorId'] ?? {};
    final lastVisit = patient?['lastVisit'] ?? 'Not available';
    final avgHeartRate = patient?['avgHeartRate'] ?? '70';
    final avgSteps = patient?['avgSteps'] ?? '8,000';
    final avgSleep = patient?['avgSleep'] ?? '7';

    return Column(
      children: [
        const SizedBox(height: 12),
        sectionCard(
          title: "Medical Record",
          onEdit: () {},
          children: [
            infoRow(
              icon: Icons.local_hospital_rounded,
              title: "Doctor",
              value: doctor['fullName'] ?? 'Unknown',
              subtitle: doctor['specialization'] ?? '',
            ),
            infoRow(
              icon: Icons.event_rounded,
              title: "Last doctor visit",
              value: lastVisit,
            ),
            infoRow(
              icon: Icons.favorite_rounded,
              title: "Average heart rate",
              value: "$avgHeartRate bpm",
              subtitle: "Last updated 1 Mar",
            ),
            infoRow(
              icon: Icons.directions_walk_rounded,
              title: "Average daily steps",
              value: avgSteps,
              subtitle: "Last updated 1 Mar",
            ),
            infoRow(
              icon: Icons.nightlight_round,
              title: "Average sleep duration",
              value: "$avgSleep hours",
              subtitle: "Last updated 1 Mar",
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Personal Information",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0E0E10)
            : const Color(0xFFF5F6F8),
        elevation: 0,
      ),
     backgroundColor: Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF0E0E10)
    : const Color(0xFFF5F6F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  value: user?.age != null
                      ? '${user!.age} years old'
                      : 'Not set',
                ),
                infoRow(
                  icon: Icons.food_bank,
                  title: "Weight",
                  value: user?.weight != null
                      ? '${user!.weight} kg'
                      : 'Not set',
                  subtitle: user?.weightUpdatedAt != null
                      ? 'Last updated ${_formatDate(user!.weightUpdatedAt!)}'
                      : null,
                ),
                infoRow(
                  icon: Icons.straighten,
                  title: "Height",
                  value: user?.height != null
                      ? '${user!.height} cm'
                      : 'Not set',
                  subtitle: user?.heightUpdatedAt != null
                      ? 'Last updated ${_formatDate(user!.heightUpdatedAt!)}'
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ===== Card 2: Medical Record =====
            if (_buildMedicalRecordCard() != null) _buildMedicalRecordCard()!,

            const SizedBox(height: 12),

            // ===== Card 3: Active Sessions =====
            sectionCard(
              title: "Active Sessions",
              onEdit:
                  () {}, // No editing function, can be left blank or add a refresh action
              children: [
                if (_loadingSessions)
                  const Center(child: CircularProgressIndicator())
                else if (_sessions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('No other sessions')),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sessions.length,
                    itemBuilder: (ctx, i) {
                      final s = _sessions[i];
                      final isCurrent = s['isCurrent'] ?? false;
                      final deviceName = s['deviceName'] ?? 'Unknown device';
                      final lastActive = s['lastActiveAt'] != null
                          ? DateTime.parse(s['lastActiveAt'])
                          : DateTime.now();
                      final deviceType = s['deviceType'] ?? 'unknown';

                      IconData icon;
                      if (deviceType == 'mobile')
                        icon = Icons.phone_android;
                      else if (deviceType == 'tablet')
                        icon = Icons.tablet;
                      else if (deviceType == 'desktop')
                        icon = Icons.computer;
                      else
                        icon = Icons.device_unknown;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Icon(icon),
                          title: Text(deviceName),
                          subtitle: Text(
                            'Last active: ${_formatDateTime(lastActive)}',
                          ),
                          trailing: isCurrent
                              ? const Chip(
                                  label: Text('Current'),
                                  backgroundColor: Colors.green,
                                  labelStyle: TextStyle(color: Colors.white),
                                )
                              : TextButton(
                                  onPressed: () => _terminateSession(s['_id']),
                                  child: const Text(
                                    'Terminate',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
