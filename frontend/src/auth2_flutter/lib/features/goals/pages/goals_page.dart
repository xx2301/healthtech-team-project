import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class GoalsPage extends StatefulWidget {
  const GoalsPage({Key? key}) : super(key: key);

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  List<dynamic> _goals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchGoals();
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

  Future<void> _fetchGoals() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      if (token == null) return;
      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/api/health-goals'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _goals = json['data'] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      print('Error fetching goals: $e');
    }
  }

  Future<void> _deleteGoal(String id) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final response = await http.delete(
        Uri.parse('${_getBaseUrl()}/api/goals/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        _fetchGoals();
      }
    } catch (e) {
      print('Error deleting goal: $e');
    }
  }

  void _showAddEditDialog({Map? goal}) {
    final titleController = TextEditingController(text: goal?['title'] ?? '');
    final targetValueController = TextEditingController(text: goal?['targetValue']?.toString() ?? '');
    final currentValueController = TextEditingController(text: goal?['currentValue']?.toString() ?? '0');
    final targetDateController = TextEditingController(text: goal?['targetDate']?.substring(0,10) ?? '');
    String goalType = goal?['goalType'] ?? 'steps';
    String frequency = goal?['frequency'] ?? 'daily';
    String priority = goal?['priority'] ?? 'medium';
    final descriptionController = TextEditingController(text: goal?['description'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text(goal == null ? 'Add Goal' : 'Edit Goal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: goalType,
                      items: const [
                        DropdownMenuItem(value: 'steps', child: Text('Steps')),
                        DropdownMenuItem(value: 'calories_burned', child: Text('Calories')),
                        DropdownMenuItem(value: 'heart_rate', child: Text('Heart Rate')),
                        DropdownMenuItem(value: 'sleep_duration', child: Text('Sleep')),
                      ],
                      onChanged: (val) => setState(() => goalType = val!),
                      decoration: const InputDecoration(labelText: 'Goal Type'),
                    ),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    TextField(
                      controller: targetValueController,
                      decoration: const InputDecoration(labelText: 'Target Value'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: currentValueController,
                      decoration: const InputDecoration(labelText: 'Current Value'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: targetDateController,
                      decoration: const InputDecoration(labelText: 'Target Date (YYYY-MM-DD)'),
                    ),
                    DropdownButtonFormField<String>(
                      value: frequency,
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('Daily')),
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      ],
                      onChanged: (val) => setState(() => frequency = val!),
                      decoration: const InputDecoration(labelText: 'Frequency'),
                    ),
                    DropdownButtonFormField<String>(
                      value: priority,
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                      ],
                      onChanged: (val) => setState(() => priority = val!),
                      decoration: const InputDecoration(labelText: 'Priority'),
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
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Title is required')),
                      );
                      return;
                    }
                    if (targetDateController.text.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Target date is required')),
                      );
                      return;
                    }
                    if (double.tryParse(targetValueController.text) == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Valid target value is required')),
                      );
                      return;
                    }

                    final token = await _getToken();
                    if (token == null) return;

                    final data = {
                      'goalType': goalType,
                      'title': titleController.text,
                      'description': descriptionController.text,
                      'targetValue': double.tryParse(targetValueController.text) ?? 0,
                      'currentValue': double.tryParse(currentValueController.text) ?? 0,
                      'targetDate': targetDateController.text,
                      'frequency': frequency,
                      'priority': priority,
                    };

                    final url = goal == null
                        ? Uri.parse('${_getBaseUrl()}/api/health-goals')
                        : Uri.parse('${_getBaseUrl()}/api/health-goals/${goal['_id']}');

                    final client = http.Client();
                    http.Response response;

                    try {
                      if (goal == null) {
                        response = await client.post(
                          url,
                          headers: {
                            'Authorization': 'Bearer $token',
                            'Content-Type': 'application/json',
                          },
                          body: jsonEncode(data),
                        );
                      } else {
                        response = await client.put(
                          url,
                          headers: {
                            'Authorization': 'Bearer $token',
                            'Content-Type': 'application/json',
                          },
                          body: jsonEncode(data),
                        );
                      }

                      if (response.statusCode == 200 || response.statusCode == 201) {
                        Navigator.pop(ctx);
                        _fetchGoals();
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Error: ${response.statusCode}')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    } finally {
                      client.close();
                    }
                  },
                  child: Text(goal == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? const Center(child: Text('No goals yet. Tap + to add.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _goals.length,
                  itemBuilder: (ctx, index) {
                    final goal = _goals[index];
                    final progress = (goal['progressPercentage'] ?? 0).toDouble();
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(goal['title']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Target: ${goal['targetValue']} (${goal['frequency']})'),
                            Text('Progress: ${progress.toStringAsFixed(1)}%'),
                            Text('Target date: ${_formatDate(goal['targetDate'])}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showAddEditDialog(goal: goal),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteGoal(goal['_id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}