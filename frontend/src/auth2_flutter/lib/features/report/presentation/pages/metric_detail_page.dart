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

  List<FlSpot> _spots = [];
  List<FlSpot> _systolicSpots = [];
  List<FlSpot> _diastolicSpots = [];
  List<int> _hoursWithData = [];

  double _todayTotal = 0;
  double _todayAvg = 0;
  double _todaySystolic = 0;
  double _todayDiastolic = 0;

  String get _backendMetricType {
    switch (widget.metricType) {
      case 'calories':
        return 'calories_burned';
      case 'sleep':
        return 'sleep_duration';
      case 'glucose':
        return 'blood_glucose';
      default:
        return widget.metricType;
    }
  }

  bool get _useBarChart {
    return widget.metricType == 'steps' ||
           widget.metricType == 'calories' ||
           widget.metricType == 'sleep';
  }

  @override
  void initState() {
    super.initState();
    _loadTodayData();
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

  Future<void> _loadTodayData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final url = Uri.parse('${_getBaseUrl()}/api/health-metrics').replace(queryParameters: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'metricType': _backendMetricType,
        'limit': '1000',
      });

      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode != 200) throw Exception('Failed to load data');

      final data = jsonDecode(response.body)['data'] as List;
      final metrics = data.map((e) => HealthMetric.fromJson(e)).toList();

      metrics.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (metrics.isEmpty) {
        setState(() {
          _loading = false;
          _errorMessage = 'No data for today';
        });
        return;
      }

      if (widget.metricType == 'blood_pressure') {
        Map<int, List<double>> systolicMap = {};
        Map<int, List<double>> diastolicMap = {};

        double sumSystolic = 0;
        double sumDiastolic = 0;
        int totalPoints = 0;

        for (var m in metrics) {
          final hour = m.timestamp.hour;
          final value = m.value;
          if (value is Map && value.containsKey('systolic') && value.containsKey('diastolic')) {
            double systolic = (value['systolic'] as num).toDouble();
            double diastolic = (value['diastolic'] as num).toDouble();

            systolicMap.putIfAbsent(hour, () => []).add(systolic);
            diastolicMap.putIfAbsent(hour, () => []).add(diastolic);

            sumSystolic += systolic;
            sumDiastolic += diastolic;
            totalPoints++;
          }
        }

        List<FlSpot> systolicSpots = [];
        List<FlSpot> diastolicSpots = [];
        List<int> hours = [];

        for (int h = 0; h < 24; h++) {
          if (systolicMap.containsKey(h) && diastolicMap.containsKey(h)) {
            double avgSystolic = systolicMap[h]!.reduce((a, b) => a + b) / systolicMap[h]!.length;
            double avgDiastolic = diastolicMap[h]!.reduce((a, b) => a + b) / diastolicMap[h]!.length;
            systolicSpots.add(FlSpot(h.toDouble(), avgSystolic));
            diastolicSpots.add(FlSpot(h.toDouble(), avgDiastolic));
            hours.add(h);
          }
        }

        setState(() {
          _systolicSpots = systolicSpots;
          _diastolicSpots = diastolicSpots;
          _hoursWithData = hours;
          _todaySystolic = totalPoints > 0 ? sumSystolic / totalPoints : 0;
          _todayDiastolic = totalPoints > 0 ? sumDiastolic / totalPoints : 0;
          _loading = false;
        });
      } else {
        Map<int, List<double>> hourlyMap = {};
        double sum = 0;
        int totalPoints = 0;

        for (var m in metrics) {
          final hour = m.timestamp.hour;
          double val = (m.value as num).toDouble();
          hourlyMap.putIfAbsent(hour, () => []).add(val);
          sum += val;
          totalPoints++;
        }

        List<FlSpot> spots = [];
        List<int> hours = [];

        for (int h = 0; h < 24; h++) {
          if (hourlyMap.containsKey(h)) {
            final values = hourlyMap[h]!;
            double aggregated;
            if (_useBarChart) {
              aggregated = values.reduce((a, b) => a + b);
            } else {
              aggregated = values.reduce((a, b) => a + b) / values.length;
            }
            spots.add(FlSpot(h.toDouble(), aggregated));
            hours.add(h);
          }
        }

        double todayDisplay;
        if (_useBarChart) {
          todayDisplay = sum;
        } else {
          todayDisplay = totalPoints > 0 ? sum / totalPoints : 0;
        }

        setState(() {
          _spots = spots;
          _hoursWithData = hours;
          _todayTotal = sum;
          _todayAvg = todayDisplay;
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
      case 'calories':
        return 'kcal';
      case 'sleep':
        return 'hrs';
      case 'glucose':
        return 'mmol/L';
      case 'blood_pressure':
        return 'mmHg';
      default:
        return '';
    }
  }

  String _formatTodayValue() {
    if (widget.metricType == 'blood_pressure') {
      return '${_todaySystolic.toInt()}/${_todayDiastolic.toInt()} ${_getUnit()}';
    } else if (_useBarChart) {
      if (widget.metricType == 'sleep') {
        return '${_todayTotal.toStringAsFixed(1)} ${_getUnit()}';
      }
      return '${_todayTotal.toInt()} ${_getUnit()}';
    } else {
      if (_todayAvg == 0) return '--';
      if (widget.metricType == 'glucose') {
        return '${_todayAvg.toStringAsFixed(1)} ${_getUnit()}';
      }
      return '${_todayAvg.toInt()} ${_getUnit()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Today',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTodayValue(),
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Graph title
                      Text(
                        _useBarChart ? 'Hourly Total' : 'Hourly Average',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),

                      // Graph
                      Expanded(
                        child: _hoursWithData.isEmpty
                            ? const Center(child: Text('No hourly data available'))
                            : _buildChart(),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildChart() {
    if (widget.metricType == 'blood_pressure') {
      return LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: _buildTitlesData(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    spot.y.toStringAsFixed(1),
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _systolicSpots,
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.red.withOpacity(0.1),
              ),
            ),
            LineChartBarData(
              spots: _diastolicSpots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
        ),
      );
    } else if (_useBarChart) {
      // Bar chart
      return BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  rod.toY.toStringAsFixed(1),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: _buildTitlesData(),
          barGroups: _spots.asMap().entries.map((entry) {
            final index = entry.key;
            final spot = entry.value;
            final hour = spot.x.toInt();
            return BarChartGroupData(
              x: hour,
              barRods: [
                BarChartRodData(
                  toY: spot.y,
                  color: Colors.blue,
                  width: 12,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      );
    } else {
      // Single line graph
      return LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: _buildTitlesData(),
          lineBarsData: [
            LineChartBarData(
              spots: _spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
        ),
      );
    }
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toInt().toString(),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 2,
          getTitlesWidget: (value, meta) {
            int hour = value.toInt();
            if (hour < 0 || hour > 23) return const Text('');
            return Text(
              '$hour:00',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            );
          },
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}