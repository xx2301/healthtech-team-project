import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:auth2_flutter/features/data/domain/entities/health_metric.dart';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_cubit.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MetricDetailPage extends StatefulWidget {
  final String metricType;
  final String title;

  const MetricDetailPage({
    Key? key,
    required this.metricType,
    required this.title,
  }) : super(key: key);

  @override
  State<MetricDetailPage> createState() => _MetricDetailPageState();
}

class _MetricDetailPageState extends State<MetricDetailPage> {
  bool _loading = true;
  String? _errorMessage;

  List<FlSpot> _spots = [];
  List<FlSpot> _systolicSpots = [];
  List<FlSpot> _diastolicSpots = [];

  double _todayTotal = 0;
  double _todayAvg = 0;
  double _todaySystolic = 0;
  double _todayDiastolic = 0;

  int _recordCount = 0;
  DateTime? _latestRecordTime;
  DateTime? _lastRefreshedAt;

  _ViewMode _viewMode = _ViewMode.day;

  String get _backendMetricType {
    switch (widget.metricType) {
      case 'calories':
        return 'calories_burned';
      case 'sleep':
        return 'sleep_duration';
      case 'glucose':
        return 'glucose';
      default:
        return widget.metricType;
    }
  }

  bool get _useBarChart {
    return widget.metricType == 'steps' ||
        widget.metricType == 'calories' ||
        widget.metricType == 'sleep';
  }

  bool get _isBloodPressure => widget.metricType == 'blood_pressure';

  bool get _isLineMetric => !_useBarChart && !_isBloodPressure;

  @override
  void initState() {
    super.initState();
    _loadMetricData();
  }

  String _getBaseUrl() {
    if (kIsWeb) return 'http://10.101.61.123:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    if (Platform.isIOS) return 'http://10.101.61.123:3001';
    return 'http://10.101.61.123:3001';
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _loadMetricData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final currentUserId = context.read<AuthCubit>().currentUser?.uid;

      final now = DateTime.now();
      late DateTime start;
      late DateTime end;

      if (_viewMode == _ViewMode.day) {
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else {
        final today = DateTime(now.year, now.month, now.day);
        start = today.subtract(const Duration(days: 6));
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      }

      final url = Uri.parse('${_getBaseUrl()}/api/health-metrics').replace(
        queryParameters: {
          'startDate': start.toIso8601String(),
          'endDate': end.toIso8601String(),
          'metricType': _backendMetricType,
          'limit': '2000',
          if (currentUserId != null) 'userId': currentUserId,
        },
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load data (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      final data = (decoded['data'] as List?) ?? [];

      final metrics = data
          .map((e) => HealthMetric.fromJson(e))
          .where((m) => m.metricType == _backendMetricType)
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (metrics.isEmpty) {
        setState(() {
          _loading = false;
          _errorMessage = _viewMode == _ViewMode.day
              ? 'No data for today'
              : 'No data for this week';
          _spots = [];
          _systolicSpots = [];
          _diastolicSpots = [];
          _recordCount = 0;
          _latestRecordTime = null;
          _lastRefreshedAt = DateTime.now();
          _todayTotal = 0;
          _todayAvg = 0;
          _todaySystolic = 0;
          _todayDiastolic = 0;
        });
        return;
      }

      _recordCount = metrics.length;
      _latestRecordTime = metrics.last.timestamp;
      _lastRefreshedAt = DateTime.now();

      if (_isBloodPressure) {
        _processBloodPressure(metrics);
      } else {
        _processNormalMetric(metrics);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _processBloodPressure(List<HealthMetric> metrics) {
    final Map<int, List<double>> systolicMap = {};
    final Map<int, List<double>> diastolicMap = {};

    double sumSystolic = 0;
    double sumDiastolic = 0;
    int totalPoints = 0;

    for (final m in metrics) {
      final localTime = m.timestamp.toLocal();
      final bucket = _viewMode == _ViewMode.day
          ? localTime.hour
          : DateTime(localTime.year, localTime.month, localTime.day)
              .difference(_weekStart())
              .inDays;

      final value = m.value;

      if (value is Map &&
          value.containsKey('systolic') &&
          value.containsKey('diastolic')) {
        final systolic = (value['systolic'] as num).toDouble();
        final diastolic = (value['diastolic'] as num).toDouble();

        systolicMap.putIfAbsent(bucket, () => []).add(systolic);
        diastolicMap.putIfAbsent(bucket, () => []).add(diastolic);

        sumSystolic += systolic;
        sumDiastolic += diastolic;
        totalPoints++;
      }
    }

    final List<FlSpot> systolicSpots = [];
    final List<FlSpot> diastolicSpots = [];

    final maxBucket = _viewMode == _ViewMode.day ? 24 : 7;

    for (int i = 0; i < maxBucket; i++) {
      if (systolicMap.containsKey(i) && diastolicMap.containsKey(i)) {
        final avgSystolic =
            systolicMap[i]!.reduce((a, b) => a + b) / systolicMap[i]!.length;
        final avgDiastolic =
            diastolicMap[i]!.reduce((a, b) => a + b) / diastolicMap[i]!.length;

        systolicSpots.add(FlSpot(i.toDouble(), avgSystolic));
        diastolicSpots.add(FlSpot(i.toDouble(), avgDiastolic));
      }
    }

    setState(() {
      _systolicSpots = systolicSpots;
      _diastolicSpots = diastolicSpots;
      _spots = [];
      _todaySystolic = totalPoints > 0 ? sumSystolic / totalPoints : 0;
      _todayDiastolic = totalPoints > 0 ? sumDiastolic / totalPoints : 0;
      _loading = false;
    });
  }

  void _processNormalMetric(List<HealthMetric> metrics) {
    final Map<int, List<double>> groupedMap = {};
    double sum = 0;
    int totalPoints = 0;

    for (final m in metrics) {
      final localTime = m.timestamp.toLocal();
      final value = m.value;

      if (value is num) {
        final val = value.toDouble();

        final bucket = _viewMode == _ViewMode.day
            ? localTime.hour
            : DateTime(localTime.year, localTime.month, localTime.day)
                .difference(_weekStart())
                .inDays;

        groupedMap.putIfAbsent(bucket, () => []).add(val);
        sum += val;
        totalPoints++;
      }
    }

    final List<FlSpot> spots = [];
    final maxBucket = _viewMode == _ViewMode.day ? 24 : 7;

    for (int i = 0; i < maxBucket; i++) {
      if (groupedMap.containsKey(i)) {
        final values = groupedMap[i]!;
        final aggregated = _useBarChart
            ? values.reduce((a, b) => a + b).toDouble()
            : values.reduce((a, b) => a + b) / values.length;
        spots.add(FlSpot(i.toDouble(), aggregated));
      }
    }

    final displayValue = _useBarChart
        ? sum.toDouble()
        : totalPoints > 0
            ? (sum / totalPoints).toDouble()
            : 0.0;

    setState(() {
      _spots = spots;
      _systolicSpots = [];
      _diastolicSpots = [];
      _todayTotal = sum;
      _todayAvg = displayValue;
      _loading = false;
    });
  }

  DateTime _weekStart() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(const Duration(days: 6));
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

  IconData _getMetricIcon() {
    switch (widget.metricType) {
      case 'steps':
        return Icons.directions_walk_rounded;
      case 'heart_rate':
        return Icons.favorite_rounded;
      case 'calories':
        return Icons.local_fire_department_rounded;
      case 'sleep':
        return Icons.nightlight_round;
      case 'glucose':
        return Icons.bloodtype_rounded;
      case 'blood_pressure':
        return Icons.monitor_heart_rounded;
      default:
        return Icons.insights_rounded;
    }
  }

  Color _getMetricColor(BuildContext context) {
    switch (widget.metricType) {
      case 'steps':
        return Colors.green;
      case 'heart_rate':
        return Colors.red;
      case 'calories':
        return Colors.orange;
      case 'sleep':
        return Colors.indigo;
      case 'glucose':
        return Colors.purple;
      case 'blood_pressure':
        return Colors.teal;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  List<Color> _getMetricGradient(BuildContext context) {
    final color = _getMetricColor(context);
    return [
      color.withOpacity(0.95),
      color.withOpacity(0.55),
    ];
  }

  String _formatTodayValue() {
    if (_isBloodPressure) {
      if (_todaySystolic == 0 && _todayDiastolic == 0) return '--';
      return '${_todaySystolic.toInt()}/${_todayDiastolic.toInt()} ${_getUnit()}';
    }

    if (_useBarChart) {
      if (_todayTotal == 0) return '--';
      if (widget.metricType == 'sleep') {
        return '${_todayTotal.toStringAsFixed(1)} ${_getUnit()}';
      }
      return '${_todayTotal.toInt()} ${_getUnit()}';
    }

    if (_todayAvg == 0) return '--';
    if (widget.metricType == 'glucose') {
      return '${_todayAvg.toStringAsFixed(1)} ${_getUnit()}';
    }
    return '${_todayAvg.toInt()} ${_getUnit()}';
  }

  String _formatSubtitle() {
    if (_isBloodPressure) {
      return _viewMode == _ViewMode.day ? 'Daily average' : 'Weekly average';
    }
    if (_useBarChart) {
      return _viewMode == _ViewMode.day ? 'Today total' : 'Last 7 days total';
    }
    return _viewMode == _ViewMode.day ? 'Today average' : 'Last 7 days average';
  }

  String _formatLatestRecordTime() {
    if (_latestRecordTime == null) return '--';
    final localTime = _latestRecordTime!.toLocal();
    final h = localTime.hour.toString().padLeft(2, '0');
    final m = localTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatRefreshTime() {
    if (_lastRefreshedAt == null) return '--';

    final diff = DateTime.now().difference(_lastRefreshedAt!);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';

    final h = _lastRefreshedAt!.hour.toString().padLeft(2, '0');
    final m = _lastRefreshedAt!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _buildInsightText() {
    if (_isBloodPressure) {
      final source = _systolicSpots.isNotEmpty ? _systolicSpots : _diastolicSpots;
      if (source.isEmpty) return 'No trend insight available yet.';
      final peak = source.reduce((a, b) => a.y > b.y ? a : b);
      return _viewMode == _ViewMode.day
          ? 'Highest average reading was around ${peak.x.toInt().toString().padLeft(2, '0')}:00.'
          : 'Highest average reading was on ${_weekLabel(peak.x.toInt())}.';
    }

    if (_spots.isEmpty) return 'No trend insight available yet.';

    final peak = _spots.reduce((a, b) => a.y > b.y ? a : b);

    if (_viewMode == _ViewMode.day) {
      return _useBarChart
          ? 'Peak activity was around ${peak.x.toInt().toString().padLeft(2, '0')}:00.'
          : 'Highest average reading was around ${peak.x.toInt().toString().padLeft(2, '0')}:00.';
    }

    return _useBarChart
        ? 'Highest total was on ${_weekLabel(peak.x.toInt())}.'
        : 'Highest average reading was on ${_weekLabel(peak.x.toInt())}.';
  }

  double _getChartMaxY() {
    if (_isBloodPressure) {
      final all = [..._systolicSpots, ..._diastolicSpots];
      if (all.isEmpty) return 100;
      final maxValue =
          all.map((e) => e.y).reduce((a, b) => math.max(a, b).toDouble());
      return (maxValue * 1.2).ceilToDouble();
    }

    if (_spots.isEmpty) return 10;
    final maxValue =
        _spots.map((e) => e.y).reduce((a, b) => math.max(a, b).toDouble());

    if (maxValue <= 5) return 6;
    if (maxValue <= 10) return 12;
    return (maxValue * 1.2).ceilToDouble();
  }

  double _getChartMinY() {
    if (_isBloodPressure) {
      final all = [..._systolicSpots, ..._diastolicSpots];
      if (all.isEmpty) return 0;
      final minValue =
          all.map((e) => e.y).reduce((a, b) => math.min(a, b).toDouble());
      return math.max(0, (minValue - 15).floorToDouble()).toDouble();
    }

    return 0;
  }

  double _getHorizontalInterval() {
    final maxY = _getChartMaxY();
    if (maxY <= 10) return 2;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    if (maxY <= 300) return 50;
    if (maxY <= 1000) return 200;
    return maxY / 4;
  }

  String _formatAxisValue(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
    }
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  String _formatTooltipValue(double value) {
    if (widget.metricType == 'sleep' || widget.metricType == 'glucose') {
      return '${value.toStringAsFixed(1)} ${_getUnit()}';
    }
    return '${value.toStringAsFixed(0)} ${_getUnit()}';
  }

  String _weekLabel(int index) {
    final day = _weekStart().add(Duration(days: index));
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekdayIndex = day.weekday - 1;
    return labels[weekdayIndex];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final metricColor = _getMetricColor(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState(context)
              : RefreshIndicator(
                  onRefresh: _loadMetricData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _buildModeToggle(context),
                      const SizedBox(height: 16),
                      _buildHeroCard(context, metricColor),
                      const SizedBox(height: 12),
                      _buildInsightCard(context),
                      const SizedBox(height: 16),
                      _buildInfoRow(context),
                      const SizedBox(height: 20),
                      _buildChartSection(context),
                    ],
                  ),
                ),
    );
  }

  Widget _buildModeToggle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metricColor = _getMetricColor(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A20) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildToggleButton(
            label: 'Day',
            selected: _viewMode == _ViewMode.day,
            onTap: () {
              if (_viewMode != _ViewMode.day) {
                setState(() => _viewMode = _ViewMode.day);
                _loadMetricData();
              }
            },
            metricColor: metricColor,
          ),
          _buildToggleButton(
            label: 'Week',
            selected: _viewMode == _ViewMode.week,
            onTap: () {
              if (_viewMode != _ViewMode.week) {
                setState(() => _viewMode = _ViewMode.week);
                _loadMetricData();
              }
            },
            metricColor: metricColor,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color metricColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? metricColor.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? metricColor : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, Color metricColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  metricColor.withOpacity(0.38),
                  const Color(0xFF1A1D24),
                ]
              : [
                  metricColor.withOpacity(0.16),
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: metricColor.withOpacity(isDark ? 0.18 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: metricColor.withOpacity(isDark ? 0.25 : 0.10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: metricColor.withOpacity(isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              _getMetricIcon(),
              color: metricColor,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatSubtitle(),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTodayValue(),
                  style: TextStyle(
                    fontSize: 30,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metricColor = _getMetricColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A20) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: metricColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _buildInsightText(),
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniInfoCard(
            context,
            title: 'Records',
            value: '$_recordCount',
            icon: Icons.dataset_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniInfoCard(
            context,
            title: 'Refreshed',
            value: _formatRefreshTime(),
            icon: Icons.refresh_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniInfoCard(
            context,
            title: 'Latest data',
            value: _formatLatestRecordTime(),
            icon: Icons.schedule_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final metricColor = _getMetricColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A20) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: metricColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: metricColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final chartTitle = _isBloodPressure
        ? (_viewMode == _ViewMode.day ? 'Hourly Trend' : 'Daily Trend')
        : _useBarChart
            ? (_viewMode == _ViewMode.day ? 'Today by Hour' : 'Daily Total')
            : (_viewMode == _ViewMode.day ? 'Hourly Average' : 'Daily Average');

    final subtitle = _viewMode == _ViewMode.day
        ? '00:00 - 23:59 overview'
        : 'Last 7 days overview';

    final hasData = _isBloodPressure
        ? (_systolicSpots.isNotEmpty || _diastolicSpots.isNotEmpty)
        : _spots.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A20) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chartTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          if (_isBloodPressure) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _buildLegend(context, 'Systolic', Colors.red),
                const SizedBox(width: 16),
                _buildLegend(context, 'Diastolic', Colors.blue),
              ],
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 280,
            child: hasData
                ? _buildChart(context)
                : Center(
                    child: Text(
                      _viewMode == _ViewMode.day
                          ? 'No hourly data available'
                          : 'No daily data available',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context) {
    if (_isBloodPressure) {
      return _buildBloodPressureChart(context);
    } else if (_useBarChart) {
      return _buildBarChart(context);
    } else {
      return _buildLineChart(context);
    }
  }

  Widget _buildBarChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = _getMetricGradient(context);
    final maxY = _getChartMaxY();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        groupsSpace: 10,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getHorizontalInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.06),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: _buildTitlesData(context),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = _viewMode == _ViewMode.day
                  ? '${group.x.toInt().toString().padLeft(2, '0')}:00'
                  : _weekLabel(group.x.toInt());

              return BarTooltipItem(
                '$label\n${_formatTooltipValue(rod.toY)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        barGroups: _spots.map((spot) {
          final index = spot.x.toInt();
          final isCurrentHour =
              _viewMode == _ViewMode.day && index == DateTime.now().hour;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: spot.y,
                width: _viewMode == _ViewMode.day ? 16 : 22,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                gradient: LinearGradient(
                  colors: isCurrentHour
                      ? [
                          gradientColors.first,
                          gradientColors.first.withOpacity(0.75),
                        ]
                      : gradientColors,
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.black.withOpacity(0.035),
                ),
              ),
            ],
          );
        }).toList(),
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildLineChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metricColor = _getMetricColor(context);

    return LineChart(
      LineChartData(
        minY: _getChartMinY(),
        maxY: _getChartMaxY(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getHorizontalInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.06),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: _buildTitlesData(context),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final label = _viewMode == _ViewMode.day
                    ? '${spot.x.toInt().toString().padLeft(2, '0')}:00'
                    : _weekLabel(spot.x.toInt());

                return LineTooltipItem(
                  '$label\n${_formatTooltipValue(spot.y)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: metricColor,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: _spots.length <= 8,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 3.2,
                  color: metricColor,
                  strokeWidth: 1.5,
                  strokeColor: isDark ? const Color(0xFF171A20) : Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  metricColor.withOpacity(0.22),
                  metricColor.withOpacity(0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildBloodPressureChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LineChart(
      LineChartData(
        minY: _getChartMinY(),
        maxY: _getChartMaxY(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getHorizontalInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.06),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: _buildTitlesData(context),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final label = _viewMode == _ViewMode.day
                    ? '${spot.x.toInt().toString().padLeft(2, '0')}:00'
                    : _weekLabel(spot.x.toInt());
                final type = spot.barIndex == 0 ? 'SYS' : 'DIA';

                return LineTooltipItem(
                  '$type $label\n${spot.y.toStringAsFixed(0)} mmHg',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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
            curveSmoothness: 0.25,
            color: Colors.red,
            barWidth: 3.2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: _systolicSpots.length <= 8,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 3.2,
                  color: Colors.red,
                  strokeWidth: 1.5,
                  strokeColor: isDark ? const Color(0xFF171A20) : Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.12),
                  Colors.red.withOpacity(0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          LineChartBarData(
            spots: _diastolicSpots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: Colors.blue,
            barWidth: 3.2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: _diastolicSpots.length <= 8,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 3.2,
                  color: Colors.blue,
                  strokeWidth: 1.5,
                  strokeColor: isDark ? const Color(0xFF171A20) : Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.12),
                  Colors.blue.withOpacity(0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  FlTitlesData _buildTitlesData(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white60 : Colors.black54;

    return FlTitlesData(
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          interval: _getHorizontalInterval(),
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                _formatAxisValue(value),
                style: TextStyle(
                  fontSize: 11,
                  color: labelColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 34,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();

            if (_viewMode == _ViewMode.day) {
              if (index < 0 || index > 23 || index % 4 != 0) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${index.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    fontSize: 10,
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            if (index < 0 || index > 6) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _weekLabel(index),
                style: TextStyle(
                  fontSize: 10,
                  color: labelColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metricColor = _getMetricColor(context);

    final noDataText = _viewMode == _ViewMode.day
        ? 'There is no recorded ${widget.title.toLowerCase()} data yet for today.'
        : 'There is no recorded ${widget.title.toLowerCase()} data yet for the last 7 days.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171A20) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_chart_outlined_rounded,
                size: 54,
                color: metricColor,
              ),
              const SizedBox(height: 14),
              Text(
                _errorMessage == 'No data for today' || _errorMessage == 'No data for this week'
                    ? 'No data available'
                    : 'Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage == 'No data for today' || _errorMessage == 'No data for this week'
                    ? noDataText
                    : (_errorMessage ?? 'Unknown error'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _loadMetricData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: metricColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ViewMode {
  day,
  week,
}
