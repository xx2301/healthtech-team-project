import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';
import 'package:auth2_flutter/features/settings/pages/presentation/components/setting_tiles.dart';
import 'package:auth2_flutter/themes/main_theme.dart';
import 'package:provider/provider.dart';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_cubit.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:csv/csv.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = false;

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

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? '
          'All your health data, devices, and personal information will be lost. '
          'This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    final token = await _getToken();
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('${_getBaseUrl()}/api/user/account'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );
        context.read<AuthCubit>().logout();
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to delete account';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showExportDialog() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Choose format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'json'),
            child: const Text('JSON'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'csv'),
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    
    if (choice != null) {
      await _exportData(format: choice);
    }
  }

  Future<void> _exportData({String format = 'json'}) async {
    final token = await _getToken();
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/api/user/export-data'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content;
        String fileName;

        if (format == 'json') {
          content = JsonEncoder.withIndent('  ').convert(data);
          fileName = 'health_data.json';
        } else {
          content = _jsonToCsv(data);
          fileName = 'health_data.csv';
        }

        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(content);

        if (kIsWeb) {
          await SharePlus.instance.share(
            ShareParams(
              text: 'My health data',
              files: [XFile(file.path)],
              downloadFallbackEnabled: true,
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File ready to download')),
          );
        } else {
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
            await OpenFile.open(file.path);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('File opened: $fileName')),
            );
          } else {
            await SharePlus.instance.share(
              ShareParams(
                text: 'My health data',
                files: [XFile(file.path)],
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _jsonToCsv(Map<String, dynamic> jsonData) {
    final List<List<dynamic>> rows = [];

    final user = jsonData['user'] ?? {};
    if (user.isNotEmpty) {
      rows.add(['User Info']);
      user.forEach((key, value) {
        rows.add([key, value?.toString() ?? '']);
      });
      rows.add([]);
    }

    final metrics = jsonData['metrics'] as List? ?? [];

    if (metrics.isNotEmpty) {
      final Set<String> headersSet = {};
      for (var m in metrics) {
        if (m is Map<String, dynamic>) {
          headersSet.addAll(m.keys);
        }
      }

      final headers = headersSet.toList()..sort();
      rows.add(headers);

      for (var m in metrics) {
        if (m is Map<String, dynamic>) {
          final row = headers.map((key) {
            final value = m[key];
            if (value == null) return '';
            if (value is Map || value is List) {
              return jsonEncode(value);
            }
            return value.toString();
          }).toList();
          rows.add(row);
        }
      }
    }

    return ListToCsvConverter().convert(rows);
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final user = context.watch<AuthCubit>().currentUser;

    return Scaffold(
      appBar: DefaultAppBar(),
      drawer: DefaultDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: const Color(0xFFB6D9B6),
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF4F7F4F),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user?.fullName ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  '🌿',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user != null
                                  ? '${user.height ?? '?'} cm · ${user.weight ?? '?'} kg'
                                  : 'Login to see details',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "Account",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.grey,
                      ),
                    ),

                    SettingsTile(
                      icon: Icons.person,
                      title: 'Personal Information',
                      isLinkTile: true,
                      routeName: '/personalinfopage',
                    ),

                    SettingsTile(
                      icon: Icons.flag,
                      title: 'Health Goals',
                      isLinkTile: true,
                      routeName: '/goals',
                    ),

                    SettingsTile(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      isLinkTile: false,
                      initialSwitchValue: true,
                      onSwitchChanged: (val) {
                        // handle toggle
                      },
                    ),
                    SettingsTile(
                      icon: Icons.lock,
                      title: 'Change Password',
                      isLinkTile: true,
                      routeName: '/change-password',
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Preferences",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.grey,
                      ),
                    ),

                    SettingsTile(
                      icon: Icons.dark_mode,
                      title: 'Dark Mode',
                      isLinkTile: false,
                      initialSwitchValue: Theme.of(context).brightness == Brightness.dark,
                      onSwitchChanged: (val) {
                        themeNotifier.toggleTheme(val);
                      },
                    ),

                    SettingsTile(
                      icon: Icons.health_and_safety,
                      title: 'Health Devices',
                      isLinkTile: true,
                      routeName: '/devicepage',
                    ),

                    SettingsTile(
                      icon: Icons.warning,
                      title: 'Health Alerts',
                      isLinkTile: true,
                      routeName: '/thresholds',
                    ),

                    // SettingsTile(
                    //   icon: Icons.scale,
                    //   title: 'Measurement Unit',
                    //   isLinkTile: true,
                    //   routeName: '/homepage',
                    // ),

                    // SettingsTile(
                    //   icon: Icons.language,
                    //   title: 'Language',
                    //   isLinkTile: true,
                    //   routeName: '/homepage',
                    // ),

                    const SizedBox(height: 10),

                    const Text(
                      "Support",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.grey,
                      ),
                    ),

                    SettingsTile(
                      icon: Icons.medical_services,
                      title: 'Apply as Doctor',
                      isLinkTile: true,
                      routeName: '/apply-doctor',
                    ),

                    SettingsTile(
                      icon: Icons.question_mark,
                      title: 'Help',
                      isLinkTile: true,
                      routeName: '/help',
                    ),

                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade400, width: 0.7),
                        ),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.download),
                        title: const Text(
                          'Export My Data',
                          style: TextStyle(fontSize: 15),
                        ),
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        onTap: _showExportDialog,
                      ),
                    ),
                    
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade400, width: 0.7),
                        ),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.red),
                        title: const Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.red, fontSize: 15),
                        ),
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        onTap: () => _showDeleteAccountDialog(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
