import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ThresholdSettingsPage extends StatefulWidget {
  const ThresholdSettingsPage({Key? key}) : super(key: key);

  @override
  State<ThresholdSettingsPage> createState() => _ThresholdSettingsPageState();
}

class _ThresholdSettingsPageState extends State<ThresholdSettingsPage> {
  final List<String> _metricTypes = [
    'steps',
    'heart_rate',
    'blood_pressure_systolic',
    'blood_pressure_diastolic',
    'blood_glucose',
    'weight',
    'body_temperature',
    'oxygen_saturation',
    'sleep_duration',
    'calories_burned',
  ];

  final Map<String, Map<String, dynamic>> _thresholds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchThresholds();
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

  Future<void> _fetchThresholds() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      if (token == null) return;
      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/api/thresholds'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'];
        final Map<String, Map<String, dynamic>> thresholds = {};
        for (var t in data) {
          thresholds[t['metricType']] = {
            'min': t['minThreshold'],
            'max': t['maxThreshold'],
            'enabled': t['enabled'],
          };
        }
        setState(() {
          _thresholds.clear();
          _thresholds.addAll(thresholds);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      print('Error fetching thresholds: $e');
    }
  }

  Future<void> _saveThreshold(String metricType, double? min, double? max, bool enabled) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final response = await http.post(
        Uri.parse('${_getBaseUrl()}/api/thresholds'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'metricType': metricType,
          'minThreshold': min,
          'maxThreshold': max,
          'enabled': enabled,
        }),
      );
      if (response.statusCode == 200) {
        _fetchThresholds();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Threshold saved')),
        );
      } else {
        throw Exception('Failed to save');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showEditDialog(String metricType) {
    final current = _thresholds[metricType];
    final minController = TextEditingController(
      text: current?['min']?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: current?['max']?.toString() ?? '',
    );
    bool enabled = current?['enabled'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text('Set Threshold for $metricType'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: minController,
                      decoration: const InputDecoration(labelText: 'Min Threshold (leave empty for no limit)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: maxController,
                      decoration: const InputDecoration(labelText: 'Max Threshold (leave empty for no limit)'),
                      keyboardType: TextInputType.number,
                    ),
                    SwitchListTile(
                      title: const Text('Enabled'),
                      value: enabled,
                      onChanged: (val) => setState(() => enabled = val),
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
                  onPressed: () {
                    final min = minController.text.isEmpty
                        ? null
                        : double.tryParse(minController.text);
                    final max = maxController.text.isEmpty
                        ? null
                        : double.tryParse(maxController.text);
                    Navigator.pop(ctx);
                    _saveThreshold(metricType, min, max, enabled);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Alert Thresholds'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _metricTypes.length,
              itemBuilder: (ctx, index) {
                final metric = _metricTypes[index];
                final threshold = _thresholds[metric];
                final hasThreshold = threshold != null;
                final enabled = hasThreshold ? threshold['enabled'] : false;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(metric.replaceAll('_', ' ').toUpperCase()),
                    subtitle: hasThreshold
                        ? Text(
                            'Min: ${threshold['min']?.toString() ?? '--'}, Max: ${threshold['max']?.toString() ?? '--'}',
                          )
                        : const Text('No threshold set'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasThreshold && enabled)
                          const Icon(Icons.notifications_active, color: Colors.green),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditDialog(metric),
                        ),
                      ],
                    ),
                    onTap: () => _showEditDialog(metric),
                  ),
                );
              },
            ),
    );
  }
}