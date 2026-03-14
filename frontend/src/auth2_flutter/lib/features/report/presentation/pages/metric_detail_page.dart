import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:auth2_flutter/features/data/domain/entities/health_metric.dart';

class MetricDetailPage extends StatefulWidget {
  final String metricType;
  final String title;

  const MetricDetailPage({
    Key? key,
    required this.metricType,
    required this.title,
  }) : super(key: key);

  @override
  _MetricDetailPageState createState() => _MetricDetailPageState();
}

class _MetricDetailPageState extends State<MetricDetailPage> {
  bool _loading = true;
  String? _errorMessage;

  // Single-value metric data
  List<FlSpot> _spots = [];
  double _thisWeekAvg = 0;
  double _lastWeekAvg = 0;
  double _todayValue = 0;

  // Blood Pressure Index Data (Hyperbolic Curve)
  List<FlSpot> _systolicSpots = [];
  List<FlSpot> _diastolicSpots = [];
  double _thisWeekAvgSystolic = 0;
  double _thisWeekAvgDiastolic = 0;
  double _lastWeekAvgSystolic = 0;
  double _lastWeekAvgDiastolic = 0;
  double _todaySystolic = 0;
  double _todayDiastolic = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  String _getBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    if (Platform.isIOS) return 'http://localhost:3001';
    return 'http://localhost:3001';
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final now = DateTime.now();
      // The past 14 days (including today)
      final startDate = DateTime(now.year, now.month, now.day - 13);
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final url = Uri.parse('${_getBaseUrl()}/api/health-metrics').replace(queryParameters: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'metricType': widget.metricType,
        'limit': '1000',
      });

      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode != 200) throw Exception('Failed to load data');

      final data = jsonDecode(response.body)['data'] as List;
      final metrics = data.map((e) => HealthMetric.fromJson(e)).toList();

      if (widget.metricType == 'blood_pressure') {
        // Blood pressure data processing (object format)
        final Map<DateTime, List<dynamic>> dailyValues = {};
        for (var m in metrics) {
          final day = DateTime(m.timestamp.year, m.timestamp.month, m.timestamp.day);
          dailyValues.putIfAbsent(day, () => []).add(m.value);
        }

        List<FlSpot> systolicSpots = [];
        List<FlSpot> diastolicSpots = [];
        double thisWeekSystolicSum = 0, thisWeekDiastolicSum = 0;
        int thisWeekCount = 0;
        double lastWeekSystolicSum = 0, lastWeekDiastolicSum = 0;
        int lastWeekCount = 0;
        double todaySystolic = 0, todayDiastolic = 0;

        for (int i = 13; i >= 0; i--) {
          final day = DateTime(now.year, now.month, now.day - i);
          final values = dailyValues[DateTime(day.year, day.month, day.day)];

          double avgSystolic = 0;
          double avgDiastolic = 0;

          if (values != null && values.isNotEmpty) {
            double sumSystolic = 0;
            double sumDiastolic = 0;
            int count = 0;
            for (var val in values) {
              if (val is Map && val.containsKey('systolic') && val.containsKey('diastolic')) {
                sumSystolic += (val['systolic'] as num).toDouble();
                sumDiastolic += (val['diastolic'] as num).toDouble();
                count++;
              }
            }
            if (count > 0) {
              avgSystolic = sumSystolic / count;
              avgDiastolic = sumDiastolic / count;
            }
          }

          double x = (13 - i).toDouble();
          systolicSpots.add(FlSpot(x, avgSystolic));
          diastolicSpots.add(FlSpot(x, avgDiastolic));

          if (i <= 6) {
            thisWeekSystolicSum += avgSystolic;
            thisWeekDiastolicSum += avgDiastolic;
            thisWeekCount++;
            if (i == 0) {
              todaySystolic = avgSystolic;
              todayDiastolic = avgDiastolic;
            }
          } else {
            lastWeekSystolicSum += avgSystolic;
            lastWeekDiastolicSum += avgDiastolic;
            lastWeekCount++;
          }
        }

        setState(() {
          _systolicSpots = systolicSpots;
          _diastolicSpots = diastolicSpots;
          _thisWeekAvgSystolic = thisWeekCount > 0 ? thisWeekSystolicSum / thisWeekCount : 0;
          _thisWeekAvgDiastolic = thisWeekCount > 0 ? thisWeekDiastolicSum / thisWeekCount : 0;
          _lastWeekAvgSystolic = lastWeekCount > 0 ? lastWeekSystolicSum / lastWeekCount : 0;
          _lastWeekAvgDiastolic = lastWeekCount > 0 ? lastWeekDiastolicSum / lastWeekCount : 0;
          _todaySystolic = todaySystolic;
          _todayDiastolic = todayDiastolic;
          _loading = false;
        });
      } else {
        // Single-value Indicator Processing
        final Map<DateTime, List<double>> dailyValues = {};
        for (var m in metrics) {
          final day = DateTime(m.timestamp.year, m.timestamp.month, m.timestamp.day);
          dailyValues.putIfAbsent(day, () => []).add(m.value.toDouble());
        }

        List<FlSpot> spots = [];
        double thisWeekSum = 0;
        int thisWeekCount = 0;
        double lastWeekSum = 0;
        int lastWeekCount = 0;
        double todayVal = 0;

        for (int i = 13; i >= 0; i--) {
          final day = DateTime(now.year, now.month, now.day - i);
          final values = dailyValues[DateTime(day.year, day.month, day.day)];
          double avg = values != null ? values.reduce((a, b) => a + b) / values.length : 0;
          spots.add(FlSpot((13 - i).toDouble(), avg));

          if (i <= 6) {
            thisWeekSum += avg;
            thisWeekCount++;
            if (i == 0) todayVal = avg;
          } else {
            lastWeekSum += avg;
            lastWeekCount++;
          }
        }

        setState(() {
          _spots = spots;
          _thisWeekAvg = thisWeekCount > 0 ? thisWeekSum / thisWeekCount : 0;
          _lastWeekAvg = lastWeekCount > 0 ? lastWeekSum / lastWeekCount : 0;
          _todayValue = todayVal;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  String _getUnit() {
    switch (widget.metricType) {
      case 'steps':
        return 'steps';
      case 'heart_rate':
        return 'bpm';
      case 'calories_burned':
        return 'kcal';
      case 'sleep_duration':
        return 'hrs';
      case 'glucose':
        return 'mmol/L';
      case 'blood_pressure':
        return 'mmHg';
      default:
        return '';
    }
  }

  String _formatValue(double value) {
    if (value == 0) return '--';
    if (widget.metricType == 'sleep_duration') {
      return value.toStringAsFixed(1);
    }
    if (widget.metricType == 'glucose') {
      return value.toStringAsFixed(1);
    }
    return value.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Today',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                            if (widget.metricType == 'blood_pressure')
                              Text(
                                '${_todaySystolic.toInt()}/${_todayDiastolic.toInt()} ${_getUnit()}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              )
                            else
                              Text(
                                '${_formatValue(_todayValue)} ${_getUnit()}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Charts
                      Expanded(
                        flex: 2,
                        child: widget.metricType == 'blood_pressure'
                            ? (_systolicSpots.isEmpty || _diastolicSpots.isEmpty
                                ? const Center(child: Text('No data for chart'))
                                : LineChart(
                                    LineChartData(
                                      gridData: FlGridData(show: true),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: (value, meta) {
                                              return Text(value.toInt().toString());
                                            },
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 30,
                                            getTitlesWidget: (value, meta) {
                                              int index = value.toInt();
                                              if (index < 0 || index > 13) return const Text('');
                                              final now = DateTime.now();
                                              final day = DateTime(now.year, now.month, now.day - (13 - index));
                                              return Text('${day.month}/${day.day}');
                                            },
                                          ),
                                        ),
                                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      borderData: FlBorderData(show: true),
                                      lineBarsData: [
                                        // Systolic pressure (red)
                                        LineChartBarData(
                                          spots: _systolicSpots,
                                          isCurved: true,
                                          color: Colors.red,
                                          barWidth: 3,
                                          isStrokeCapRound: true,
                                          dotData: FlDotData(show: true),
                                          belowBarData: BarAreaData(show: false),
                                        ),
                                        // Diastolic pressure (blue)
                                        LineChartBarData(
                                          spots: _diastolicSpots,
                                          isCurved: true,
                                          color: Colors.blue,
                                          barWidth: 3,
                                          isStrokeCapRound: true,
                                          dotData: FlDotData(show: true),
                                          belowBarData: BarAreaData(show: false),
                                        ),
                                      ],
                                    ),
                                  ))
                            : (_spots.isEmpty
                                ? const Center(child: Text('No data for chart'))
                                : LineChart(
                                    LineChartData(
                                      gridData: FlGridData(show: true),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: (value, meta) {
                                              return Text(value.toInt().toString());
                                            },
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 30,
                                            getTitlesWidget: (value, meta) {
                                              int index = value.toInt();
                                              if (index < 0 || index > 13) return const Text('');
                                              final now = DateTime.now();
                                              final day = DateTime(now.year, now.month, now.day - (13 - index));
                                              return Text('${day.month}/${day.day}');
                                            },
                                          ),
                                        ),
                                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      borderData: FlBorderData(show: true),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: _spots,
                                          isCurved: true,
                                          color: Colors.blue,
                                          barWidth: 3,
                                          isStrokeCapRound: true,
                                          dotData: FlDotData(show: true),
                                          belowBarData: BarAreaData(show: false),
                                        ),
                                      ],
                                    ),
                                  )),
                      ),
                      const SizedBox(height: 24),

                      // This week vs last week
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: widget.metricType == 'blood_pressure'
                            ? Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildComparisonCard(
                                        'This Week (Sys)',
                                        '${_thisWeekAvgSystolic.toInt()} mmHg',
                                        '',
                                      ),
                                      _buildComparisonCard(
                                        'Last Week (Sys)',
                                        '${_lastWeekAvgSystolic.toInt()} mmHg',
                                        '',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildComparisonCard(
                                        'This Week (Dias)',
                                        '${_thisWeekAvgDiastolic.toInt()} mmHg',
                                        '',
                                      ),
                                      _buildComparisonCard(
                                        'Last Week (Dias)',
                                        '${_lastWeekAvgDiastolic.toInt()} mmHg',
                                        '',
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildComparisonCard(
                                    'This Week',
                                    '${_formatValue(_thisWeekAvg)} ${_getUnit()}',
                                    _thisWeekAvg > _lastWeekAvg ? '▲' : (_thisWeekAvg < _lastWeekAvg ? '▼' : ''),
                                  ),
                                  _buildComparisonCard(
                                    'Last Week',
                                    '${_formatValue(_lastWeekAvg)} ${_getUnit()}',
                                    '',
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildComparisonCard(String label, String value, String trend) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (trend.isNotEmpty)
          Text(
            trend,
            style: TextStyle(
              fontSize: 16,
              color: trend == '▲' ? Colors.green : Colors.red,
            ),
          ),
      ],
    );
  }
}