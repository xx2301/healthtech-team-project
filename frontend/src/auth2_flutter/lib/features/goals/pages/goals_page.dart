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

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBg => _isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FB);

  Color get _cardBg => _isDark ? const Color(0xFF1E293B) : Colors.white;

  Color get _cardBorder => _isDark ? const Color(0xFF334155) : Colors.transparent;

  Color get _textPrimary => _isDark ? Colors.white : Colors.black87;

  Color get _textSecondary => _isDark ? Colors.white70 : Colors.grey[600]!;

  Color get _chipBg => _isDark ? const Color(0xFF334155) : const Color(0xFFF4F6FA);

  Color get _dialogBg => _isDark ? const Color(0xFF1E293B) : Colors.white;

  Color get _progressBg => _isDark ? const Color(0xFF334155) : Colors.grey[200]!;

  Color get _completedCardBg => _isDark ? const Color(0xFF102A1C) : const Color(0xFFF1FFF3);

  Color get _completedBorder => _isDark ? const Color(0xFF22C55E) : Colors.green;

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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: _isDark ? Colors.white70 : Colors.grey[700],
      ),
      filled: true,
      fillColor: _isDark ? const Color(0xFF334155) : const Color(0xFFF7F8FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.4),
      ),
    );
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
              backgroundColor: _dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                goal == null ? 'Add Goal' : 'Edit Goal',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      dropdownColor: _dialogBg,
                      value: goalType,
                      style: TextStyle(color: _textPrimary),
                      items: const [
                        DropdownMenuItem(value: 'steps', child: Text('Steps')),
                        DropdownMenuItem(value: 'calories_burned', child: Text('Calories')),
                        DropdownMenuItem(value: 'heart_rate', child: Text('Heart Rate')),
                        DropdownMenuItem(value: 'sleep_duration', child: Text('Sleep')),
                      ],
                      onChanged: (val) => setState(() => goalType = val!),
                      decoration: _inputDecoration('Goal Type'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: _textPrimary),
                      decoration: _inputDecoration('Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      style: TextStyle(color: _textPrimary),
                      decoration: _inputDecoration('Description'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetValueController,
                      style: TextStyle(color: _textPrimary),
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Target Value'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetDateController,
                      style: TextStyle(color: _textPrimary),
                      decoration: _inputDecoration('Target Date (YYYY-MM-DD)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: _isDark ? Colors.white70 : Colors.grey[700]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // keep your original save logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
          children: [
            Icon(
              Icons.flag_outlined,
              size: 72,
              color: _isDark ? Colors.white38 : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No goals yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add Goal" to start tracking your health targets.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: _isDark ? Colors.white60 : Colors.grey,
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
    final bool isCompleted = progress >= 100;

    final Color cardBg = isCompleted ? _completedCardBg : _cardBg;
    final Color borderColor = isCompleted ? _completedBorder : _cardBorder;
    final Color shadowColor = isCompleted
        ? Colors.green.withOpacity(_isDark ? 0.18 : 0.08)
        : Colors.black.withOpacity(_isDark ? 0.22 : 0.05);

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: isCompleted ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
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
                      color: isCompleted
                          ? Colors.green.withOpacity(_isDark ? 0.22 : 0.15)
                          : _goalColor(goalType).withOpacity(_isDark ? 0.22 : 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle : _goalIcon(goalType),
                      color: isCompleted ? Colors.greenAccent : _goalColor(goalType),
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
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? (_isDark ? Colors.greenAccent[100] : Colors.green[800])
                                : _textPrimary,
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
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: _cardBg,
                    iconColor: _textPrimary,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddEditDialog(goal: goal);
                      } else if (value == 'delete') {
                        _deleteGoal(goal['_id']);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit', style: TextStyle(color: _textPrimary)),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: _textPrimary)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (isCompleted)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isDark
                        ? Colors.green.withOpacity(0.18)
                        : Colors.green.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Congratulations! Goal achieved',
                        style: TextStyle(
                          color: _isDark ? Colors.greenAccent[100] : Colors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

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
                  color: _textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isCompleted ? 'Completed' : 'Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  Text(
                    isCompleted ? '100%' : '${progress.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? (_isDark ? Colors.greenAccent : Colors.green)
                          : _goalColor(goalType),
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
                  backgroundColor: _progressBg,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted
                        ? (_isDark ? Colors.greenAccent : Colors.green)
                        : _goalColor(goalType),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (isCompleted)
          Positioned(
            top: 12,
            right: 52,
            child: Transform.rotate(
              angle: -0.22,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isDark ? Colors.greenAccent : Colors.green,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _isDark
                      ? Colors.black.withOpacity(0.35)
                      : Colors.white.withOpacity(0.85),
                ),
                child: Text(
                  'COMPLETED',
                  style: TextStyle(
                    color: _isDark ? Colors.greenAccent : Colors.green,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _chipBg,
        borderRadius: BorderRadius.circular(20),
        border: _isDark
            ? Border.all(color: const Color(0xFF475569), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: _isDark ? Colors.white70 : Colors.grey[700],
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _textPrimary,
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
      backgroundColor: _pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _cardBg,
        foregroundColor: _textPrimary,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Health Goals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
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