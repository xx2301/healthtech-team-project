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

  Map<String, double> _progressMap = {};

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
        final goals = json['data'] ?? [];
        setState(() {
          _goals = goals;
        });
        await _calculateProgressForGoals(token);
        setState(() {
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

  Future<void> _calculateProgressForGoals(String token) async {
    try {
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day - 6);
      final weekEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final url = Uri.parse('${_getBaseUrl()}/api/health-metrics').replace(
        queryParameters: {
          'startDate': weekStart.toIso8601String(),
          'endDate': weekEnd.toIso8601String(),
          'limit': '5000',
        },
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body)['data'] as List;
      Map<String, double> weeklyValues = {
        'steps': 0.0,
        'calories_burned': 0.0,
        'sleep_duration': 0.0,
        'water_intake': 0.0,
      };
      for (var item in data) {
        final type = item['metricType'] as String;
        if (weeklyValues.containsKey(type)) {
          final value = (item['value'] as num).toDouble();
          weeklyValues[type] = weeklyValues[type]! + value;
        }
      }

      final progressMap = <String, double>{};
      for (var goal in _goals) {
        final type = goal['goalType'] as String;
        final target = (goal['targetValue'] as num).toDouble();
        final frequency = goal['frequency'] ?? 'daily';
        double progress = 0.0;

        int multiplier = 1;
        if (frequency == 'daily') multiplier = 7;
        else if (frequency == 'weekly') multiplier = 1;
        else if (frequency == 'monthly') multiplier = 30;

        if (type == 'steps') {
          final weekTarget = target * multiplier;
          if (weekTarget > 0) {
            progress = (weeklyValues['steps']! / weekTarget).clamp(0.0, 1.0) * 100;
          }
        } else if (type == 'calories_burned') {
          final weekTarget = target * multiplier;
          if (weekTarget > 0) {
            progress = (weeklyValues['calories_burned']! / weekTarget).clamp(0.0, 1.0) * 100;
          }
        } else if (type == 'sleep_duration') {
          final weekTarget = target * multiplier;
          if (weekTarget > 0) {
            progress = (weeklyValues['sleep_duration']! / weekTarget).clamp(0.0, 1.0) * 100;
          }
        } else if (type == 'water_intake') {
          final weekTarget = target * multiplier;
          if (weekTarget > 0) {
            progress = (weeklyValues['water_intake']! / weekTarget).clamp(0.0, 1.0) * 100;
          }
        } else {
          progress = 0.0;
        }
        progressMap[goal['_id']] = progress;
      }
      setState(() {
        _progressMap = progressMap;
      });
    } catch (e) {
      print('Error calculating progress: $e');
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

  IconData _goalIcon(String type) {
    switch (type) {
      case 'steps':
        return Icons.directions_walk;
      case 'calories_burned':
        return Icons.local_fire_department;
      case 'heart_rate':
        return Icons.favorite;
      case 'sleep_duration':
        return Icons.nightlight_round;
      default:
        return Icons.flag;
    }
  }

  Color _goalColor(String type) {
    switch (type) {
      case 'steps':
        return Colors.green;
      case 'calories_burned':
        return Colors.orange;
      case 'heart_rate':
        return Colors.red;
      case 'sleep_duration':
        return Colors.indigo;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.flag_outlined,
              size: 72,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No goals yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap "Add Goal" to start tracking your health targets.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(Map goal, double progress) {
    final goalType = goal['goalType'] ?? 'steps';
    final frequency = goal['frequency'] ?? 'daily';
    final priority = goal['priority'] ?? 'medium';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _goalColor(goalType).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _goalIcon(goalType),
                  color: _goalColor(goalType),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal['title'] ?? 'Untitled Goal',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goal['description']?.toString().isNotEmpty == true
                          ? goal['description']
                          : 'No description',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showAddEditDialog(goal: goal);
                  } else if (value == 'delete') {
                    _deleteGoal(goal['_id']);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                icon: Icons.track_changes,
                label: 'Target: ${goal['targetValue']}',
              ),
              _buildInfoChip(
                icon: Icons.repeat,
                label: frequency[0].toUpperCase() + frequency.substring(1),
              ),
              _buildInfoChip(
                icon: Icons.flag,
                label: priority[0].toUpperCase() + priority.substring(1),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Target date: ${_formatDate(goal['targetDate'] ?? '')}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${progress.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _goalColor(goalType),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.grey[200],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Health Goals',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Goal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _goals.length,
                  itemBuilder: (ctx, index) {
                    final goal = _goals[index];
                    final progress = _progressMap[goal['_id']] ??
                        (goal['progressPercentage'] ?? 0.0).toDouble();

                    return _buildGoalCard(goal, progress);
                  },
                ),
    );
  }
}