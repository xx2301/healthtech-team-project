import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/bar_graph.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/info_cards.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/line_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_cubit.dart';
import 'package:auth2_flutter/features/data/domain/entities/health_metric.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  List<HealthMetric> _metrics = [];
  bool _isLoading = true;
  String? _error;
  List<double> _heartRatePoints = [];
  List<double> _sleepDataPoints = List.filled(7, 0.0);

  int _totalSteps = 0;
  double _avgHeartRate = 0;
  int _totalCalories = 0;
  double _totalSleepHours = 0;

  String _reportPeriod = '';
  String _generatedDate = '';

  String _searchName = '';
  bool _isAdmin = false;

  String _viewingUserName = ''; 
  bool _viewingAll = true;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchHealthData();
    _searchController.clear();
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

  Future<void> _fetchHealthData({String? specificUserId}) async {
    setState(() => _isLoading = true);

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final user = context.read<AuthCubit>().currentUser;
      _isAdmin = user?.role == 'admin' || user?.role == 'super_admin';

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day - 6);
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final queryParams = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'limit': '500',
      };

      if (specificUserId != null) {
        queryParams['userId'] = specificUserId;
        _viewingUserName = 'your own data'; //after will overwrite
        _viewingAll = false;
      } else if (_searchName.isNotEmpty) {
        queryParams['search'] = _searchName;
        _viewingUserName = _searchName;
        _viewingAll = false;
      } else {
        _viewingUserName = 'all users';
        _viewingAll = true;
      }

      final url = Uri.parse('${_getBaseUrl()}/api/health-metrics')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> data = jsonData['data'] ?? [];
        final metrics = data.map((e) => HealthMetric.fromJson(e)).toList();
        
        _calculateStats(metrics);
        _prepareChartData(metrics);

        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day - 6);
        _reportPeriod = '${_formatDate(start)} - ${_formatDate(now)}';
        _generatedDate = _formatDate(now);

        setState(() {
          _metrics = metrics;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load health data');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _calculateStats(List<HealthMetric> metrics) {
    final stepsMetrics = metrics.where((m) => m.metricType == 'steps').toList();
    _totalSteps = stepsMetrics.fold<int>(0, (sum, m) {
      if (m.value is num) {
        if (m.isAbnormal) return sum;
        return sum + (m.value as num).toInt();
      }
      return sum;
    });

    final heartMetrics = metrics.where((m) => m.metricType == 'heart_rate').toList();
    if (heartMetrics.isNotEmpty) {
      _avgHeartRate = heartMetrics
              .where((m) => !m.isAbnormal) //ignore abnormal
              .fold<double>(0, (sum, m) => sum + (m.value as num).toDouble()) /
          heartMetrics.length;
    } else {
      _avgHeartRate = 0;
    }

    final calorieMetrics = metrics.where((m) => m.metricType == 'calories_burned').toList();
    _totalCalories = calorieMetrics.fold<int>(0, (sum, m) {
      if (m.value is num) return sum + (m.value as num).toInt();
      return sum;
    });

    final sleepMetrics = metrics.where((m) => m.metricType == 'sleep_duration').toList();
    _totalSleepHours = sleepMetrics.fold<double>(
        0, (sum, m) => sum + (m.value as num).toDouble());
  }

  void _prepareChartData(List<HealthMetric> metrics) {
    final heartMetrics = metrics
        .where((m) => m.metricType == 'heart_rate' && !m.isAbnormal)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _heartRatePoints = heartMetrics.map((m) => (m.value as num).toDouble()).toList();

    _sleepDataPoints = List.filled(7, 0.0);
    final sleepMetrics = metrics.where((m) => m.metricType == 'sleep_duration').toList();
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day - (6 - i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
      final daySleep = sleepMetrics
          .where((m) => m.timestamp.isAfter(dayStart) && m.timestamp.isBefore(dayEnd))
          .fold<double>(0, (sum, m) => sum + (m.value as num).toDouble());
      _sleepDataPoints[i] = daySleep;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthAbbr(date.month)} ${date.year}';
  }

  String _monthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
  
  // to test only
  Future<void> _generateSimulatedData() async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final response = await http.post(
        Uri.parse('${_getBaseUrl()}/api/dev/simulate-health-data'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Simulated data generated')),
        );
        _fetchHealthData();
      } else {
        throw Exception('Failed to generate data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _showAddMetricDialog() async {
    final metricTypes = [
      'steps', 'heart_rate', 'blood_pressure', 'blood_glucose',
      'weight', 'height', 'body_temperature', 'oxygen_saturation',
      'sleep_duration', 'calories_burned', 'water_intake', 'respiratory_rate'
    ];
    String selectedMetric = metricTypes.first;

    final valueController = TextEditingController();
    final unitController = TextEditingController();
    DateTime selectedDateTime = DateTime.now();

    return showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Add Health Data'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedMetric,
                      items: metricTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.replaceAll('_', ' ').toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => selectedMetric = value!),
                      decoration: const InputDecoration(labelText: 'Metric Type'),
                    ),
                    TextField(
                      controller: valueController,
                      decoration: const InputDecoration(labelText: 'Value'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: unitController,
                      decoration: const InputDecoration(labelText: 'Unit (optional)'),
                    ),
                    ListTile(
                      title: Text('Date & Time'),
                      subtitle: Text('${selectedDateTime.toLocal()}'.split('.')[0]),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDateTime,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                          );
                          if (time != null) {
                            setState(() {
                              selectedDateTime = DateTime(
                                date.year, date.month, date.day,
                                time.hour, time.minute,
                              );
                            });
                          }
                        }
                      },
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
                    if (valueController.text.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Value is required')),
                      );
                      return;
                    }
                    final value = double.tryParse(valueController.text);
                    if (value == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Invalid number')),
                      );
                      return;
                    }

                    final data = {
                      'metricType': selectedMetric,
                      'value': value,
                      'unit': unitController.text.isEmpty ? null : unitController.text,
                      'timestamp': selectedDateTime.toIso8601String(),
                      'source': 'manual',
                    };

                    Navigator.pop(ctx);
                    await _addHealthMetric(data);
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

  Future<void> _addHealthMetric(Map<String, dynamic> data) async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('${_getBaseUrl()}/api/health-metrics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data added successfully')),
        );
        await _fetchHealthData();
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to add data';
        throw Exception(error);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildEmptyState() {
    String message = _isAdmin && _searchName.isNotEmpty
        ? 'No data found for "$_searchName".'
        : 'You haven\'t imported any health data.\nPlease add manually or sync from device.';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_chart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'No health data yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _showAddMetricDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Data'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.green[100],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: DefaultAppBar(),
        drawer: DefaultDrawer(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: DefaultAppBar(),
        drawer: DefaultDrawer(),
        body: Center(child: Text('Error: $_error')),
      );
    }

    return Scaffold(
      appBar: DefaultAppBar(),
      drawer: DefaultDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_metrics.isNotEmpty) ...[
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page Title
                    Text(
                      "Health Report", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25)
                    ),
                    Row(
                      children: [
                        if (_isAdmin) ...[
                          ElevatedButton(
                            onPressed: () {
                              final currentUser = context.read<AuthCubit>().currentUser;
                              if (currentUser != null) {
                                _searchName = '';
                                _fetchHealthData(specificUserId: currentUser.uid);
                              }
                            },
                            child: const Text('My Data'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        ElevatedButton.icon(
                          onPressed: _showAddMetricDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.green[100],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (kDebugMode)
                          ElevatedButton(
                            onPressed: _generateSimulatedData, // test only
                            child: const Text('Test'),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              if (_isAdmin) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by user name',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        //onChanged: (value) => _searchName = value,
                        onSubmitted: (_) {
                          setState(() {
                            _searchName = _searchController.text;
                          });
                          _fetchHealthData();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: (){
                        setState((){
                          _searchName = _searchController.text;
                        });
                        _fetchHealthData();
                      },
                      child: const Text('Search'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              if (_metrics.isEmpty)
                SizedBox(
                  height: MediaQuery.of(context).size.height - 150,
                  child: _buildEmptyState(),
                )
              else ...[
                // Page Subtitle
                Text(
                  _isAdmin
                      ? (_viewingAll
                          ? 'Your health data overview and analysis – All users'
                          : 'Your health data overview and analysis – $_viewingUserName')
                      : 'Your health data overview and analysis',
                  style: TextStyle(color: Colors.grey[700], fontSize: 15),
                ),
                const SizedBox(height: 10),

                /*Text(
                  "Your health data overview and analysis",
                  style: TextStyle(color: Colors.grey[700], fontSize: 15),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isAdmin
                        ? (_viewingAll
                            ? 'Showing data for all users'
                            : 'Showing data for: $_viewingUserName')
                        : 'Your health data',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),

                const SizedBox(height: 10),*/                

                SizedBox(
                  height: 120,
                  child: GridView.count(
                    crossAxisCount: 1,
                    scrollDirection: Axis.horizontal,
                    mainAxisSpacing: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    children: [
                      // Report Info Card Duration
                      InfoCards(
                        title: "Report Period",
                        subtitle: _reportPeriod,
                      ),

                      // Report Info Card Creation Date
                      InfoCards(
                        title: "Generated On", 
                        subtitle: _generatedDate,
                      ),

                      // Report Info Card Goals Achieved
                      InfoCards(
                        title: "Goals Acheived", 
                        subtitle: "3/7 Days"
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Steps Health Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Steps",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          // steps progress status
                          Container(
                            padding: EdgeInsets.only(left: 5, right: 5),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text("+5%"),
                          ),
                        ],
                      ),

                      // total value of steps this week
                      Text(
                        _totalSteps.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                      const Text("Total steps this week", style: TextStyle(fontSize: 10)),
                      const SizedBox(height: 10),

                      // steps progress bar
                      LinearProgressIndicator(
                        value: 0.75,
                        valueColor: const AlwaysStoppedAnimation(Colors.green),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              // daily average steps
                              Text(
                                (_totalSteps / 7).toStringAsFixed(0),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text("Daily Average", style: TextStyle(fontSize: 10)),
                            ],
                          ),
                          Column(
                            children: const [
                              // total steps last week
                              Text(
                                "N/A", 
                                style: TextStyle(fontWeight: FontWeight.bold)
                                ),
                              Text(
                                "Last Week", 
                                style: TextStyle(fontSize: 10)
                                ),
                            ],
                          ),
                          Column(
                            children: const [
                              // total steps goal
                              Text(
                                "6,700", // stay static
                                style: TextStyle(fontWeight: FontWeight.bold)
                                ),
                              Text(
                                "Goal", 
                                style: TextStyle(fontSize: 10)
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // heart rate health card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Heart Rate", style: TextStyle(fontWeight: FontWeight.bold)),

                          // steps progress status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text("+10%"),
                          ),
                        ],
                      ),

                      //heart rate value
                      Text(
                        '${_avgHeartRate.toStringAsFixed(0)} BPM',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                      const Text("Average heart rate", style: TextStyle(fontSize: 10)),

                      // heart rate line graph
                      SizedBox(height: 150, child: LineGraph(dataPoints: _heartRatePoints)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${_avgHeartRate.toStringAsFixed(0)} BPM',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text("Average", style: TextStyle(fontSize: 10)),
                            ],
                          ),
                          Column(
                            children: const [
                              Text("60–100", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text("Normal Range", style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                
                // calories health card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Calories", style: TextStyle(fontWeight: FontWeight.bold)),

                          // steps progress status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text("+10%"),
                          ),
                        ],
                      ),
                      Text(
                        _totalCalories.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                      const Text("Active calories burned this week", style: TextStyle(fontSize: 10)),
                      const SizedBox(height: 10),

                      // steps progress bar
                      LinearProgressIndicator(
                        value: 0.55,
                        valueColor: const AlwaysStoppedAnimation(Colors.green),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text(
                                (_totalCalories / 7).toStringAsFixed(0),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text("Daily Average", style: TextStyle(fontSize: 10)),
                            ],
                          ),
                          Column(
                            children: const [
                              Text("N/A", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text("Last Week", style: TextStyle(fontSize: 10)),
                            ],
                          ),
                          Column(
                            children: const [
                              Text(
                                "12,700", 
                                style: TextStyle(fontWeight: FontWeight.bold)
                                ),
                              Text(
                                "Goal", 
                                style: TextStyle(fontSize: 10)
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                // sleep card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Sleep", style: TextStyle(fontWeight: FontWeight.bold)),
                          
                          // steps progress status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text("-10%"),
                          ),
                        ],
                      ),
                      Text(
                        '${_totalSleepHours.toStringAsFixed(0)} hours',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                      const Text("Total sleep this week", style: TextStyle(fontSize: 10)),
                      const SizedBox(height: 10),
                      SizedBox(height: 130, child: BarGraph(dataPoints: _sleepDataPoints)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${(_totalSleepHours / 7).toStringAsFixed(1)} hours',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text("Daily Average", style: TextStyle(fontSize: 10)),
                            ],
                          ),
                          Column(
                            children: const [
                              Text("N/A", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text("Last Week", style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Weekly Progress Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Weekly Progress", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Text("3/7", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                          SizedBox(width: 10),
                          Text("Goals Achieved This Week", style: TextStyle(fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFFDFF2FA),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(20),
                          ),
                          border: const Border(left: BorderSide(width: 3, color: Colors.blue)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // Weekly Health Summary
                          children: [
                            Text("Weekly Insight", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text(
                              "He knew what he was supposed to do. Tas supposed to do and what he would do were not the same. This would have been fine if he were willing to face the inevitable consequences, but he wasn't.",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}