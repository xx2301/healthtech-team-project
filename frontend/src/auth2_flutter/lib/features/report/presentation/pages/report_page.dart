import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_cubit.dart';
import 'package:auth2_flutter/features/data/domain/entities/health_metric.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/info_cards.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/line_graph.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/bar_graph.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

enum ViewMode { day, week, month, custom }

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  List<String> _sleepDateLabels = [];
  List<HealthMetric> _metrics = [];
  bool _isLoading = true;
  String? _error;
  List<double> _heartRatePoints = [];
  List<double> _sleepDataPoints = List.filled(7, 0.0);
  List<double> _glucosePoints = [];
  List<double> _systolicPoints = [];
  List<double> _diastolicPoints = [];

  int _totalSteps = 0;
  double _avgHeartRate = 0;
  int _totalCalories = 0;
  double _totalSleepHours = 0;

  double _avgGlucose = 0;
  int _systolic = 0;
  int _diastolic = 0;
  String _bloodPressure = '--/--';

  String _reportPeriod = '';
  String _generatedDate = '';

  String _searchName = '';
  bool _isAdmin = false;

  String _viewingUserName = '';
  bool _viewingAll = true;

  String? _currentViewingUserId;

  bool _fromDoctorDashboard = false;
  String _doctorPatientName = '';

  bool get _canEditGoal {
    if (!_isAdmin) return true;
    return !_viewingAll && _viewingUserName == 'your own data';
  }

  final _searchController = TextEditingController();

  double _stepsChangePercent = 0.0;
  double _heartRateChangePercent = 0.0;
  double _caloriesChangePercent = 0.0;
  double _sleepChangePercent = 0.0;
  bool _hasStepsChange = false;
  bool _hasHeartRateChange = false;
  bool _hasCaloriesChange = false;
  bool _hasSleepChange = false;
  bool _hasGlucoseChange = false;
  double _glucoseChangePercent = 0.0;
  bool _hasBpChange = false;
  double _systolicChangePercent = 0.0;
  double _diastolicChangePercent = 0.0;
  DateTime? _latestBpDate;
  String _weeklyInsight = '';

  double _totalWater = 0;
  bool _hasWaterChange = false;
  double _waterChangePercent = 0;

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  final ValueNotifier<Color?> _periodCardHoverColor = ValueNotifier(null);

  int _stepsGoal = 6000;
  int _caloriesGoal = 12700;
  int _waterGoal = 2000;
  int _sleepGoal = 8;
  int _goalsAchievedDays = 3;

  ViewMode _currentMode = ViewMode.week;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;

      if (args != null && args.containsKey('userId')) {
        final userId = args['userId'] as String;
        final userName = args['userName'] as String? ?? 'Patient';
        final fromDoctorDashboard = args['fromDoctorDashboard'] == true;

        _currentViewingUserId = userId;
        _fetchHealthData(specificUserId: userId);

        setState(() {
          _viewingUserName = userName;
          _viewingAll = false;
          _fromDoctorDashboard = fromDoctorDashboard;
          _doctorPatientName = userName;
        });
      } else {
        final currentUser = context.read<AuthCubit>().currentUser;
        if (currentUser != null) {
          _currentViewingUserId = currentUser.uid;
          _fetchHealthData(specificUserId: currentUser.uid);
          setState(() {
            _viewingUserName = 'your own data';
            _viewingAll = false;
            _fromDoctorDashboard = false;
            _doctorPatientName = '';
          });
        } else {
          _fetchHealthData();
        }
      }
    });
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

    if (_selectedStartDate == null || _selectedEndDate == null) {
      _updateDateRangeForMode(_currentMode);
    }

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final user = context.read<AuthCubit>().currentUser;
      _isAdmin = user?.role == 'admin' || user?.role == 'super_admin';

      final now = DateTime.now();

      DateTime start, end;
      if (_selectedStartDate != null && _selectedEndDate != null) {
        start = _selectedStartDate!;
        end = _selectedEndDate!;
      } else {
        start = DateTime(now.year, now.month, now.day - 6);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      }

      final rangeLength = end.difference(start).inDays + 1;
      final lastWeekStart = DateTime(
        start.year,
        start.month,
        start.day - rangeLength,
      );
      final lastWeekEnd = DateTime(
        end.year,
        end.month,
        end.day - rangeLength,
        23,
        59,
        59,
      );

      final baseParams = {
        'limit': '10000',
        if (_searchName.isNotEmpty) 'search': _searchName,
        if (specificUserId != null) 'userId': specificUserId,
        if (_isAdmin && specificUserId == null) 'all': 'true',
      };

      final mainParams = {
        ...baseParams,
        'startDate': start.toIso8601String(),
        'endDate': end.toIso8601String(),
      };
      final mainUrl = Uri.parse(
        '${_getBaseUrl()}/api/health-metrics',
      ).replace(queryParameters: mainParams);

      final mainResponse = await http.get(
        mainUrl,
        headers: {'Authorization': 'Bearer $token'},
      );

      // fetch goals
      try {
        final goalsResponse = await http.get(
          Uri.parse('${_getBaseUrl()}/api/health-goals'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (goalsResponse.statusCode == 200) {
          final goalsJson = jsonDecode(goalsResponse.body);
          final List<dynamic> goalsData = goalsJson['data'] ?? [];

          final stepsGoalObj = goalsData.firstWhere(
            (g) => g['goalType'] == 'steps',
            orElse: () => null,
          );
          if (stepsGoalObj != null) {
            _stepsGoal = stepsGoalObj['targetValue']?.toInt() ?? _stepsGoal;
          }

          final caloriesGoalObj = goalsData.firstWhere(
            (g) => g['goalType'] == 'calories_burned',
            orElse: () => null,
          );
          if (caloriesGoalObj != null) {
            _caloriesGoal =
                caloriesGoalObj['targetValue']?.toInt() ?? _caloriesGoal;
          }

          final waterGoalObj = goalsData.firstWhere(
            (g) => g['goalType'] == 'water_intake',
            orElse: () => null,
          );
          if (waterGoalObj != null) {
            _waterGoal = waterGoalObj['targetValue']?.toInt() ?? 2000;
          }

          final sleepGoalObj = goalsData.firstWhere(
            (g) => g['goalType'] == 'sleep_duration',
            orElse: () => null,
          );
          if (sleepGoalObj != null) {
            _sleepGoal = sleepGoalObj['targetValue']?.toInt() ?? 8;
          }
        }
      } catch (e) {
        print('Error fetching goals: $e');
      }

      final lastWeekParams = {
        ...baseParams,
        'startDate': lastWeekStart.toIso8601String(),
        'endDate': lastWeekEnd.toIso8601String(),
      };
      final lastWeekUrl = Uri.parse(
        '${_getBaseUrl()}/api/health-metrics',
      ).replace(queryParameters: lastWeekParams);
      final lastWeekResponse = await http.get(
        lastWeekUrl,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mainResponse.statusCode == 200 &&
          lastWeekResponse.statusCode == 200) {
        final mainData = jsonDecode(mainResponse.body)['data'] ?? [];
        final lastWeekData = jsonDecode(lastWeekResponse.body)['data'] ?? [];
        final userIds = mainData
            .map<String>((e) => e['userId'] as String)
            .toSet();

        final mainMetrics = mainData
            .map<HealthMetric?>((e) {
              try {
                return HealthMetric.fromJson(e as Map<String, dynamic>);
              } catch (err) {
                print('Error parsing main metric: $err');
                return null;
              }
            })
            .whereType<HealthMetric>()
            .toList();

        final lastWeekMetrics = lastWeekData
            .map<HealthMetric?>((e) {
              try {
                return HealthMetric.fromJson(e as Map<String, dynamic>);
              } catch (err) {
                print('Error parsing lastWeek metric: $err');
                return null;
              }
            })
            .whereType<HealthMetric>()
            .toList();

        _calculateStats(mainMetrics);
        _prepareChartData(mainMetrics);
        _calculateChangePercentages(mainMetrics, lastWeekMetrics);

        int achievedDays = 0;
        final stepsMetrics = mainMetrics
            .where((m) => m.metricType == 'steps' && !m.isAbnormal)
            .toList();

        final Map<DateTime, int> dailySteps = {};
        for (var metric in stepsMetrics) {
          final day = DateTime(
            metric.timestamp.year,
            metric.timestamp.month,
            metric.timestamp.day,
          );
          dailySteps[day] =
              (dailySteps[day] ?? 0) +
              (metric.value is num ? (metric.value as num).toInt() : 0);
        }

        for (var steps in dailySteps.values) {
          if (steps >= _stepsGoal) achievedDays++;
        }
        _goalsAchievedDays = achievedDays;

        _reportPeriod = '${_formatDate(start)} - ${_formatDate(end)}';
        _generatedDate = _formatDate(now);

        if (_isAdmin) {
          if (specificUserId != null) {
            _viewingAll = false;
            if (_viewingUserName.isEmpty) {
              final currentUser = context.read<AuthCubit>().currentUser;
              if (currentUser != null && specificUserId == currentUser.uid) {
                _viewingUserName = 'your own data';
              } else {
                _viewingUserName = 'selected user';
              }
            }
          } else {
            _viewingUserName = 'all users'; // will not run through this loop anymore
            _viewingAll = true;
          }
        } else {
          _viewingUserName = 'your own data';
          _viewingAll = false;
        }

        _weeklyInsight = _generateInsight();

        if (_selectedStartDate == null && _selectedEndDate == null &&
            _totalSteps == 0 && _totalCalories == 0 && _totalSleepHours == 0 &&
            _totalWater == 0 && _avgHeartRate == 0 && _avgGlucose == 0) {
          try {
            final earliestRes = await http.get(
              Uri.parse('${_getBaseUrl()}/api/health-metrics')
                  .replace(queryParameters: {
                    if (specificUserId != null) 'userId': specificUserId,
                    if (_isAdmin && specificUserId == null) 'all': 'true',
                    'limit': '1',
                    'sort': 'timestamp',
                  }),
              headers: {'Authorization': 'Bearer $token'},
            );
            final latestRes = await http.get(
              Uri.parse('${_getBaseUrl()}/api/health-metrics')
                  .replace(queryParameters: {
                    if (specificUserId != null) 'userId': specificUserId,
                    if (_isAdmin && specificUserId == null) 'all': 'true',
                    'limit': '1',
                    'sort': '-timestamp',
                  }),
              headers: {'Authorization': 'Bearer $token'},
            );

            if (earliestRes.statusCode == 200 && latestRes.statusCode == 200) {
              final earliestData = jsonDecode(earliestRes.body)['data'] ?? [];
              final latestData = jsonDecode(latestRes.body)['data'] ?? [];
              if (earliestData.isNotEmpty && latestData.isNotEmpty) {
                final earliest = DateTime.parse(earliestData[0]['timestamp']);
                final latest = DateTime.parse(latestData[0]['timestamp']);
                setState(() {
                  _selectedStartDate = earliest;
                  _selectedEndDate = latest;
                });
                _fetchHealthData(specificUserId: specificUserId);
                return;
              }
            }
          } catch (e) {
            print('Error auto-adjusting date range: $e');
          }
        }

        setState(() {
          _metrics = mainMetrics;
          _isLoading = false;
        });
        _fetchAIInsight();
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

    final stepsByUser = <String, int>{};
    for (var m in metrics.where((m) => m.metricType == 'steps')) {
      stepsByUser[m.userId] =
          (stepsByUser[m.userId] ?? 0) + (m.value as num).toInt();
    }

    final heartMetrics = metrics
        .where((m) => m.metricType == 'heart_rate')
        .toList();
    if (heartMetrics.isNotEmpty) {
      _avgHeartRate =
          heartMetrics
              .where((m) => !m.isAbnormal)
              .fold<double>(0, (sum, m) => sum + (m.value as num).toDouble()) /
          heartMetrics.length;
    } else {
      _avgHeartRate = 0;
    }

    final calorieMetrics = metrics
        .where((m) => m.metricType == 'calories_burned')
        .toList();
    _totalCalories = calorieMetrics.fold<int>(0, (sum, m) {
      if (m.value is num) return sum + (m.value as num).toInt();
      return sum;
    });

    final sleepMetrics = metrics
        .where((m) => m.metricType == 'sleep_duration')
        .toList();
    _totalSleepHours = sleepMetrics.fold<double>(
      0,
      (sum, m) => sum + (m.value as num).toDouble(),
    );

    final glucoseMetrics = metrics
        .where((m) => m.metricType == 'glucose')
        .toList();
    if (glucoseMetrics.isNotEmpty) {
      _avgGlucose =
          glucoseMetrics.fold<double>(
            0,
            (sum, m) => sum + (m.value as num).toDouble(),
          ) /
          glucoseMetrics.length;
    } else {
      _avgGlucose = 0;
    }

    final bpMetrics = metrics.where((m) => m.metricType == 'blood_pressure').toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (bpMetrics.isNotEmpty) {
      final latest = bpMetrics.first;
      _latestBpDate = latest.timestamp;
      final val = latest.value;
      if (val is Map) {
        _systolic = (val['systolic'] as num?)?.toInt() ?? 0;
        _diastolic = (val['diastolic'] as num?)?.toInt() ?? 0;
        _bloodPressure = '$_systolic/$_diastolic';
      } else {
        _bloodPressure = '--/--';
      }
    } else {
      _bloodPressure = '--/--';
      _latestBpDate = null;
    }

    final waterMetrics = metrics.where((m) => m.metricType == 'water_intake').toList();
    _totalWater = waterMetrics.fold<double>(0, (sum, m) => sum + (m.value as num).toDouble());
  }

  void _prepareChartData(List<HealthMetric> metrics) {
    const int maxPoints = 30;

    // heart rate chart
    final heartMetrics = metrics
            .where((m) => m.metricType == 'heart_rate' && !m.isAbnormal)
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final recentHeartMetrics = heartMetrics.length > maxPoints
        ? heartMetrics.sublist(heartMetrics.length - maxPoints)
        : heartMetrics;

    _heartRatePoints = recentHeartMetrics
        .map((m) => (m.value as num).toDouble())
        .toList();

    // glucose chart
    final glucoseMetrics = metrics
        .where((m) => m.metricType == 'glucose')
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final recentGlucose = glucoseMetrics.length > maxPoints
        ? glucoseMetrics.sublist(glucoseMetrics.length - maxPoints)
        : glucoseMetrics;

    _glucosePoints = recentGlucose
        .map((m) => (m.value as num).toDouble())
        .toList();

    // sleep chart
    DateTime start = _selectedStartDate ?? DateTime.now().subtract(const Duration(days: 6));
    DateTime end = _selectedEndDate ?? DateTime.now();
    int days = end.difference(start).inDays + 1;
    _sleepDataPoints = List.filled(days, 0.0);
    _sleepDateLabels = List.filled(days, '');

    final sleepMetrics = metrics
        .where((m) => m.metricType == 'sleep_duration')
        .toList();

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i < days; i++) {
      final day = start.add(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
      final daySleep = sleepMetrics
          .where((m) => m.timestamp.isAfter(dayStart) && m.timestamp.isBefore(dayEnd))
          .fold<double>(0, (sum, m) => sum + (m.value as num).toDouble());
      _sleepDataPoints[i] = daySleep;

      _sleepDateLabels[i] = weekdays[day.weekday - 1];
    }

    // blood pressure chart
    final bpMetrics = metrics
      .where((m) => m.metricType == 'blood_pressure')
      .toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  
    final recentBp = bpMetrics.length > maxPoints
        ? bpMetrics.sublist(bpMetrics.length - maxPoints)
        : bpMetrics;
    
    _systolicPoints = recentBp
        .map((m) {
          final val = m.value;
          if (val is Map && val['systolic'] is num) {
            return (val['systolic'] as num).toDouble();
          }
          return double.nan;
        })
        .where((v) => v.isFinite)
        .toList();
    
    _diastolicPoints = recentBp
        .map((m) {
          final val = m.value;
          if (val is Map && val['diastolic'] is num) {
            return (val['diastolic'] as num).toDouble();
          }
          return double.nan;
        })
        .where((v) => v.isFinite)
        .toList();
  }

  void _calculateChangePercentages(
    List<HealthMetric> thisWeek,
    List<HealthMetric> lastWeek,
  ) {
    double thisSteps = thisWeek
        .where((m) => m.metricType == 'steps' && !m.isAbnormal)
        .fold<double>(
          0,
          (sum, m) => sum + (m.value is num ? (m.value as num).toDouble() : 0),
        );
    double lastSteps = lastWeek
        .where((m) => m.metricType == 'steps' && !m.isAbnormal)
        .fold<double>(
          0,
          (sum, m) => sum + (m.value is num ? (m.value as num).toDouble() : 0),
        );
    if (lastSteps > 0) {
      _stepsChangePercent = ((thisSteps - lastSteps) / lastSteps) * 100;
      _hasStepsChange = true;
    } else {
      _hasStepsChange = false;
    }

    final thisHeart = thisWeek
        .where((m) => m.metricType == 'heart_rate' && !m.isAbnormal)
        .toList();
    final lastHeart = lastWeek
        .where((m) => m.metricType == 'heart_rate' && !m.isAbnormal)
        .toList();
    if (thisHeart.isNotEmpty && lastHeart.isNotEmpty) {
      double thisAvg =
          thisHeart.fold<double>(
            0,
            (sum, m) => sum + (m.value as num).toDouble(),
          ) /
          thisHeart.length;
      double lastAvg =
          lastHeart.fold<double>(
            0,
            (sum, m) => sum + (m.value as num).toDouble(),
          ) /
          lastHeart.length;
      _heartRateChangePercent = ((thisAvg - lastAvg) / lastAvg) * 100;
      _hasHeartRateChange = true;
    } else {
      _hasHeartRateChange = false;
    }

    double thisCal = thisWeek
        .where((m) => m.metricType == 'calories_burned')
        .fold<double>(
          0,
          (sum, m) => sum + (m.value is num ? (m.value as num).toDouble() : 0),
        );
    double lastCal = lastWeek
        .where((m) => m.metricType == 'calories_burned')
        .fold<double>(
          0,
          (sum, m) => sum + (m.value is num ? (m.value as num).toDouble() : 0),
        );
    if (lastCal > 0) {
      _caloriesChangePercent = ((thisCal - lastCal) / lastCal) * 100;
      _hasCaloriesChange = true;
    } else {
      _hasCaloriesChange = false;
    }

    double thisSleep = thisWeek
        .where((m) => m.metricType == 'sleep_duration')
        .fold<double>(
          0,
          (sum, m) => sum + (m.value is num ? (m.value as num).toDouble() : 0),
        );
    double lastSleep = lastWeek
        .where((m) => m.metricType == 'sleep_duration')
        .fold<double>(
          0,
          (sum, m) => sum + (m.value is num ? (m.value as num).toDouble() : 0),
        );
    if (lastSleep > 0) {
      _sleepChangePercent = ((thisSleep - lastSleep) / lastSleep) * 100;
      _hasSleepChange = true;
    } else {
      _hasSleepChange = false;
    }

    // Glucose Change
    double thisGlucose = 0;
    int glucoseCount = 0;
    for (var m in thisWeek) {
      if (m.metricType == 'glucose') {
        thisGlucose += (m.value as num).toDouble();
        glucoseCount++;
      }
    }
    double lastGlucose = 0;
    int lastGlucoseCount = 0;
    for (var m in lastWeek) {
      if (m.metricType == 'glucose') {
        lastGlucose += (m.value as num).toDouble();
        lastGlucoseCount++;
      }
    }
    double thisGlucoseAvg = glucoseCount > 0 ? thisGlucose / glucoseCount : 0;
    double lastGlucoseAvg = lastGlucoseCount > 0
        ? lastGlucose / lastGlucoseCount
        : 0;
    if (lastGlucoseAvg > 0) {
      _glucoseChangePercent =
          ((thisGlucoseAvg - lastGlucoseAvg) / lastGlucoseAvg) * 100;
      _hasGlucoseChange = true;
    } else {
      _hasGlucoseChange = false;
    }

    // BP Avg
    double thisSystolicSum = 0, thisDiastolicSum = 0;
    int thisBpCount = 0;
    for (var m in thisWeek) {
      if (m.metricType == 'blood_pressure' && m.value is Map) {
        thisSystolicSum += (m.value['systolic'] as num).toDouble();
        thisDiastolicSum += (m.value['diastolic'] as num).toDouble();
        thisBpCount++;
      }
    }
    double lastSystolicSum = 0, lastDiastolicSum = 0;
    int lastBpCount = 0;
    for (var m in lastWeek) {
      if (m.metricType == 'blood_pressure' && m.value is Map) {
        lastSystolicSum += (m.value['systolic'] as num).toDouble();
        lastDiastolicSum += (m.value['diastolic'] as num).toDouble();
        lastBpCount++;
      }
    }
    double thisSystolicAvg = thisBpCount > 0
        ? thisSystolicSum / thisBpCount
        : 0;
    double thisDiastolicAvg = thisBpCount > 0
        ? thisDiastolicSum / thisBpCount
        : 0;
    double lastSystolicAvg = lastBpCount > 0
        ? lastSystolicSum / lastBpCount
        : 0;
    double lastDiastolicAvg = lastBpCount > 0
        ? lastDiastolicSum / lastBpCount
        : 0;
    if (lastSystolicAvg > 0) {
      _systolicChangePercent =
          ((thisSystolicAvg - lastSystolicAvg) / lastSystolicAvg) * 100;
      _diastolicChangePercent =
          ((thisDiastolicAvg - lastDiastolicAvg) / lastDiastolicAvg) * 100;
      _hasBpChange = true;
    } else {
      _hasBpChange = false;
    }

    double thisWater = thisWeek.where((m) => m.metricType == 'water_intake').fold<double>(
      0, (sum, m) => sum + (m.value is num ? (m.value as num).toDouble() : 0));
    double lastWater = lastWeek.where((m) => m.metricType == 'water_intake').fold<double>(
      0, (sum, m) => sum + (m.value is num ? (m.value as num).toDouble() : 0));
    if (lastWater > 0) {
      _waterChangePercent = ((thisWater - lastWater) / lastWater) * 100;
      _hasWaterChange = true;
    } else {
      _hasWaterChange = false;
    }
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

  String _getDefaultUnit(String metricType) {
    switch (metricType) {
      case 'steps':
        return 'steps';
      case 'heart_rate':
        return 'bpm';
      case 'blood_pressure':
        return 'mmHg';
      case 'glucose':
        return 'mmol/L';
      case 'weight':
        return 'kg';
      case 'height':
        return 'cm';
      case 'body_temperature':
        return '°C';
      case 'oxygen_saturation':
        return '%';
      case 'sleep_duration':
        return 'hours';
      case 'calories_burned':
        return 'kcal';
      case 'water_intake':
        return 'ml';
      case 'respiratory_rate':
        return 'breaths/min';
      default:
        return '';
    }
  }

  void _updateDateRangeForMode(ViewMode mode) {
    if (mode == ViewMode.custom) return;
    final now = DateTime.now();
    switch (mode) {
      case ViewMode.day:
        _selectedStartDate = DateTime(now.year, now.month, now.day);
        _selectedEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case ViewMode.week:
        _selectedStartDate = DateTime(now.year, now.month, now.day - 6);
        _selectedEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case ViewMode.month:
        _selectedStartDate = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        _selectedEndDate = DateTime(now.year, now.month, lastDay, 23, 59, 59);
        break;
      default:
        break;
    }
  }

  // Future<void> _generateSimulatedData() async {
  //   final token = await _getToken();
  //   if (token == null) return;
  //   try {
  //     final response = await http.post(
  //       Uri.parse('${_getBaseUrl()}/api/dev/simulate-health-data'),
  //       headers: {'Authorization': 'Bearer $token'},
  //     );
  //     if (response.statusCode == 200) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Simulated data generated')),
  //       );
  //       _fetchHealthData(specificUserId: _currentViewingUserId);
  //     } else {
  //       throw Exception('Failed to generate data');
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Error: $e')));
  //   }
  // }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _selectedStartDate != null && _selectedEndDate != null
          ? DateTimeRange(start: _selectedStartDate!, end: _selectedEndDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
        _currentMode = ViewMode.custom;
      });
      _fetchHealthData(specificUserId: _currentViewingUserId);
    }
  }

  Future<void> _showAddMetricDialog() async {
    final metricTypes = [
      'steps',
      'heart_rate',
      'blood_pressure',
      'glucose',
      'weight',
      'height',
      'body_temperature',
      'oxygen_saturation',
      'sleep_duration',
      'calories_burned',
      'water_intake',
      'respiratory_rate',
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
                      onChanged: (value) =>
                          setState(() => selectedMetric = value!),
                      decoration: const InputDecoration(
                        labelText: 'Metric Type',
                      ),
                    ),
                    TextField(
                      controller: valueController,
                      decoration: const InputDecoration(labelText: 'Value'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit (optional)',
                      ),
                    ),
                    ListTile(
                      title: Text('Date & Time'),
                      subtitle: Text(
                        '${selectedDateTime.toLocal()}'.split('.')[0],
                      ),
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
                            initialTime: TimeOfDay.fromDateTime(
                              selectedDateTime,
                            ),
                          );
                          if (time != null) {
                            setState(() {
                              selectedDateTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
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
                      'unit': unitController.text.isNotEmpty ? unitController.text : _getDefaultUnit(selectedMetric),
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

  Future<void> _showEditGoalDialog(String goalType, int currentValue) async {
    final TextEditingController controller = TextEditingController(
      text: currentValue.toString(),
    );
    return showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Edit ${goalType == 'steps' ? 'Steps' :
                    goalType == 'calories_burned' ? 'Calories' :
                    goalType == 'water_intake' ? 'Water Intake' :
                    'Sleep'} Goal',
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'New goal value'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newValue = int.tryParse(controller.text);
                if (newValue == null || newValue <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid number'),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await _updateGoal(goalType, newValue);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateGoal(String goalType, int newValue) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final getResponse = await http.get(
        Uri.parse('${_getBaseUrl()}/api/health-goals'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (getResponse.statusCode == 200) {
        final jsonData = jsonDecode(getResponse.body);
        final List<dynamic> goals = jsonData['data'] ?? [];
        final existingGoal = goals.firstWhere(
          (g) => g['goalType'] == goalType,
          orElse: () => null,
        );

        if (existingGoal != null) {
          final updateResponse = await http.put(
            Uri.parse(
              '${_getBaseUrl()}/api/health-goals/${existingGoal['_id']}',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'targetValue': newValue}),
          );
          if (updateResponse.statusCode == 200) {
            _fetchHealthData(specificUserId: _currentViewingUserId);
          } else {
            throw Exception('Failed to update goal');
          }
        } else {
          final now = DateTime.now();
          final createResponse = await http.post(
            Uri.parse('${_getBaseUrl()}/api/health-goals'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'goalType': goalType,
              'targetValue': newValue,
              'targetDate': now
                  .add(const Duration(days: 30))
                  .toIso8601String(), // dafault after 30 days
              'title': goalType == 'steps' ? 'Steps Goal' :
                        goalType == 'calories_burned' ? 'Calories Goal' :
                        goalType == 'water_intake' ? 'Water Intake Goal' :
                        'Sleep Goal',
            }),
          );
          if (createResponse.statusCode == 201) {
            _fetchHealthData(specificUserId: _currentViewingUserId);
          } else {
            throw Exception('Failed to create goal');
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to fetch existing goal: ${getResponse.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating goal: $e')));
    }
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
        await _fetchHealthData(specificUserId: _currentViewingUserId);
      } else {
        final error =
            jsonDecode(response.body)['error'] ?? 'Failed to add data';
        throw Exception(error);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _generateInsight() {
    List<String> points = [];

    if (_hasStepsChange) {
      if (_stepsChangePercent > 10) {
        points.add("Big step count increase, great job! 🎉");
      } else if (_stepsChangePercent > 0) {
        points.add("Steps increased a bit, keep going! 👍");
      } else if (_stepsChangePercent < -10) {
        points.add("Steps dropped significantly, try to move more. 👣");
      } else if (_stepsChangePercent < 0) {
        points.add("Steps decreased slightly, stay active. 💪");
      }
    } else {
      points.add("Insufficient step data to compare with last week.");
    }

    if (_hasSleepChange) {
      if (_sleepChangePercent > 5) {
        points.add("Sleep duration increased, better recovery! 😴");
      } else if (_sleepChangePercent < -5) {
        points.add("Lack of sleep, make sure to rest. 🌙");
      } else if (_sleepChangePercent.abs() <= 5) {
        points.add("Sleep stable, keep it up. 💤");
      }
    } else {
      points.add("Insufficient sleep data to compare with last week.");
    }

    final waterWeekTarget = _waterGoal * 7;
    final waterRatio = waterWeekTarget > 0 ? _totalWater / waterWeekTarget : 0;
    if (waterRatio >= 1.0) {
      points.add("Hydration goal met, stay hydrated! 💧");
    } else if (waterRatio >= 0.8) {
      points.add("Close to water intake goal, keep it up. 🥤");
    } else if (waterRatio > 0) {
      points.add("Water intake low, don't forget to drink. 🚰");
    } else {
      points.add("No water intake data yet, remember to stay hydrated.");
    }

    if (_avgHeartRate > 0) {
      if (_avgHeartRate >= 60 && _avgHeartRate <= 100) {
        points.add("Heart rate in normal range, heart healthy. ❤️");
      } else {
        points.add("Heart rate slightly high/low, monitor closely. 📊");
      }
    }

    if (points.isEmpty) {
      points.add("Your data looks steady this week, keep up the healthy habits! 🌟");
    }

    return points.join(' ');
  }

  Future<Map<String, String>?> _searchUserByName(String name) async {
    final token = await _getToken();
    if (token == null) return null;

    final url = Uri.parse('${_getBaseUrl()}/api/admin/users?search=$name&limit=1');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final users = data['data'] as List<dynamic>?;
      if (users != null && users.isNotEmpty) {
        final user = users[0];
        return {
          'id': user['_id'],
          'name': user['fullName'] ?? user['email'],
        };
      }
    }
    return null;
  }

  Future<void> _fetchAIInsight() async {
    if (_totalSteps == 0 && _totalSleepHours == 0 && _totalWater == 0) return;

    final token = await _getToken();
    if (token == null) return;

    final url = Uri.parse('${_getBaseUrl()}/api/insight/weekly-insight');
    final body = {
      'stepsTotal': _totalSteps,
      'stepsGoal': _stepsGoal,
      'stepsChangePercent': _stepsChangePercent,
      'sleepTotal': _totalSleepHours,
      'sleepGoal': _sleepGoal,
      'sleepChangePercent': _sleepChangePercent,
      'waterTotal': _totalWater,
      'waterGoal': _waterGoal,
      'waterChangePercent': _waterChangePercent,
      'avgHeartRate': _avgHeartRate,
    };

    setState(() {
      _weeklyInsight = '✨ Generating health insight...';
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['insight'] != null) {
        setState(() {
          _weeklyInsight = data['insight'];
        });
      } else {
        setState(() {
          _weeklyInsight = _generateInsight();
        });
      }
    } catch (e) {
      print('AI insight error: $e');
      setState(() {
        _weeklyInsight = _generateInsight();
      });
    }
  }

  PreferredSizeWidget _buildReportAppBar() {
    if (_fromDoctorDashboard) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _doctorPatientName.isNotEmpty
              ? '$_doctorPatientName Report'
              : 'Patient Report',
        ),
        backgroundColor: Colors.green[500],
      );
    }

    return DefaultAppBar();
  }

  // to choose the three option button
  // Widget _buildModeSelector() {
  //   return SegmentedButton<ViewMode>(
  //     segments: const [
  //       ButtonSegment<ViewMode>(value: ViewMode.day, label: Text('Day')),
  //       ButtonSegment<ViewMode>(value: ViewMode.week, label: Text('Week')),
  //       ButtonSegment<ViewMode>(value: ViewMode.month, label: Text('Month')),
  //     ],
  //     selected: {_currentMode},
  //     onSelectionChanged: (Set<ViewMode> newSelection) {
  //       final newMode = newSelection.first;
  //       if (newMode != _currentMode) {
  //         setState(() {
  //           _currentMode = newMode;
  //           _updateDateRangeForMode(newMode);
  //         });
  //         _fetchHealthData(specificUserId: _currentViewingUserId);
  //       }
  //     },
  //   );
  // }

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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
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

  Widget _buildGoalColumn(int goalValue) {
    return Column(
      children: [
        Text(
          goalValue.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text("Goal/day", style: TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildGoalWidget({
    required String goalType,
    required int goalValue,
  }) {
    if (_fromDoctorDashboard) {
      return const SizedBox.shrink();
    }

    if (_canEditGoal) {
      return GestureDetector(
        onTap: () => _showEditGoalDialog(goalType, goalValue),
        child: _buildGoalColumn(goalValue),
      );
    }

    return _buildGoalColumn(goalValue);
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final stepsWeekTarget = _stepsGoal * 7;
    final stepsProgress = stepsWeekTarget > 0 ? (_totalSteps / stepsWeekTarget).clamp(0.0, 1.0) : 0.0;
    final caloriesWeekTarget = _caloriesGoal * 7;
    final caloriesProgress = caloriesWeekTarget > 0 ? (_totalCalories / caloriesWeekTarget).clamp(0.0, 1.0) : 0.0;
    final waterWeekTarget = _waterGoal * 7;
    final waterProgress = waterWeekTarget > 0 ? (_totalWater / waterWeekTarget).clamp(0.0, 1.0) : 0.0;

    if (_isLoading) {
      return Scaffold(
        appBar: _buildReportAppBar(),
        drawer: _fromDoctorDashboard ? null : DefaultDrawer(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: _buildReportAppBar(),
        drawer: _fromDoctorDashboard ? null : DefaultDrawer(),
        body: Center(child: Text('Error: $_error')),
      );
    }

    return Scaffold(
      appBar: _buildReportAppBar(),
      drawer: _fromDoctorDashboard ? null : DefaultDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Health Report",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                  ),
                  Row(
                    children: [
                      // _buildModeSelector(),
                      // const SizedBox(width: 8),
                      // if (_isAdmin) ...[
                      //   ElevatedButton(
                      //     onPressed: () {
                      //       final currentUser = context.read<AuthCubit>().currentUser;
                      //       if (currentUser != null) {
                      //         setState(() {
                      //           _searchName = '';
                      //           _searchController.clear();
                      //           _currentViewingUserId = currentUser.uid;
                      //           _viewingUserName = 'your own data';
                      //           _viewingAll = false;
                      //         });
                      //         _fetchHealthData(specificUserId: currentUser.uid);
                      //       }
                      //     },
                      //     child: const Text('My Data'),
                      //   ),
                      //   const SizedBox(width: 8),
                      // ],
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
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          setState(() {
                            _selectedStartDate = null;
                            _selectedEndDate = null;
                            _currentMode = ViewMode.week;
                          });
                          _fetchHealthData(specificUserId: _currentViewingUserId);
                        },
                      ),
                      const SizedBox(width: 8),
                      // if (kDebugMode)
                      //   ElevatedButton(
                      //     onPressed: _generateSimulatedData,
                      //     child: Text(
                      //       'Test',
                      //       style: TextStyle(color: isLight ? Colors.black : Colors.white),
                      //     ),
                      //   ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) async {
                          final searchName = _searchController.text.trim();
                          if (searchName.isEmpty) return;
                          setState(() => _isLoading = true);
                          final user = await _searchUserByName(searchName);
                          if (user != null) {
                            setState(() {
                              _searchName = searchName;
                              _currentViewingUserId = user['id']!;
                              _viewingUserName = user['name']!;
                              _viewingAll = false;
                            });
                            await _fetchHealthData(specificUserId: _currentViewingUserId);
                          } else {
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User not found')),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final searchName = _searchController.text.trim();
                        if (searchName.isEmpty) return;
                        setState(() => _isLoading = true);
                        final user = await _searchUserByName(searchName);
                        if (user != null) {
                          setState(() {
                            _searchName = searchName;
                            _currentViewingUserId = user['id']!;
                            _viewingUserName = user['name']!;
                            _viewingAll = false;
                          });
                          await _fetchHealthData(specificUserId: _currentViewingUserId);
                        } else {
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User not found')),
                          );
                        }
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
                Text(
                  _isAdmin
                      ? (_viewingAll
                          ? 'Your health data overview and analysis – All users'
                          : 'Your health data overview and analysis – $_viewingUserName')
                      : 'Your health data overview and analysis',
                  style: TextStyle(color: isLight ? Colors.grey[700] : Colors.grey[200], fontSize: 15),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 120,
                  child: GridView.count(
                    crossAxisCount: 1,
                    scrollDirection: Axis.horizontal,
                    mainAxisSpacing: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    children: [
                      MouseRegion(
                        onEnter: (_) => _periodCardHoverColor.value = Colors.grey[300],
                        onExit: (_) => _periodCardHoverColor.value = null,
                        child: ValueListenableBuilder<Color?>(
                          valueListenable: _periodCardHoverColor,
                          builder: (context, hoverColor, child) {
                            return GestureDetector(
                              onTap: _selectDateRange,
                              child: InfoCards(
                                title: "Report Period",
                                subtitle: _reportPeriod,
                                backgroundColor: hoverColor ?? const Color(0xFFE6F2E6),
                              ),
                            );
                          },
                        ),
                      ),
                      InfoCards(
                        title: "Generated On",
                        subtitle: _generatedDate,
                      ),
                      if (!_fromDoctorDashboard)
                        InfoCards(
                          title: "Goals Achieved",
                          subtitle: "$_goalsAchievedDays/7 Days",
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Steps Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isLight
                        ? Colors.white
                        : const Color(0xFF06241A),
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
                          Container(
                            padding: EdgeInsets.only(left: 5, right: 5),
                            decoration: BoxDecoration(
                              color: (_hasStepsChange && _stepsChangePercent >= 0)
                                  ? (isLight ? Colors.green[100] : Colors.green[700])
                                  : (isLight ? Colors.red[100] : Colors.red[600]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _hasStepsChange
                                  ? '${_stepsChangePercent >= 0 ? '+' : ''}${_stepsChangePercent.toStringAsFixed(1)}%'
                                  : '—',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isLight ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _totalSteps.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                      const Text(
                        "Total steps this week",
                        style: TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: stepsProgress,
                        valueColor: const AlwaysStoppedAnimation(Colors.green),
                        backgroundColor: isLight ? Colors.grey[300] : Colors.grey[800],
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
                                (_totalSteps / 7).toStringAsFixed(0),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                "Daily Average",
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                          Column(
                            children: const [
                              Text(
                                "N/A",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text("Last Week", style: TextStyle(fontSize: 10)),
                            ],
                          ),
                          _buildGoalWidget(
                            goalType: 'steps',
                            goalValue: _stepsGoal,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                // Heart Rate Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isLight
                        ? Colors.white
                        : const Color.fromARGB(255, 33, 11, 11),
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
                            "Heart Rate",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 5, right: 5),
                            decoration: BoxDecoration(
                              color: (_hasHeartRateChange && _heartRateChangePercent >= 0)
                                  ? (isLight ? Colors.green[100] : Colors.green[700])
                                  : (isLight ? Colors.red[100] : Colors.red[600]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _hasHeartRateChange
                                  ? '${_heartRateChangePercent >= 0 ? '+' : ''}${_heartRateChangePercent.toStringAsFixed(1)}%'
                                  : '—',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isLight ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_avgHeartRate.toStringAsFixed(0)} BPM',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                      const Text(
                        "Average heart rate",
                        style: TextStyle(fontSize: 10),
                      ),
                      SizedBox(
                        height: 150,
                        child: LineGraph(dataPoints: _heartRatePoints),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${_avgHeartRate.toStringAsFixed(0)} BPM',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                "Average",
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                          Column(
                            children: const [
                              Text(
                                "60–100",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Normal Range",
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                // Calories Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isLight
                        ? Colors.white
                        : const Color(0xFF3A2308),
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
                            "Calories",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 5, right: 5),
                            decoration: BoxDecoration(
                              color: (_hasCaloriesChange && _caloriesChangePercent >= 0)
                                  ? (isLight ? Colors.green[100] : Colors.green[700])
                                  : (isLight ? Colors.red[100] : Colors.red[600]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _hasCaloriesChange
                                  ? '${_caloriesChangePercent >= 0 ? '+' : ''}${_caloriesChangePercent.toStringAsFixed(1)}%'
                                  : '—',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isLight ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _totalCalories.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                      const Text(
                        "Active calories burned this week",
                        style: TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: caloriesProgress,
                        valueColor: const AlwaysStoppedAnimation(Colors.green),
                        backgroundColor: isLight ? Colors.grey[300] : Colors.grey[800],
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                "Daily Average",
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                          Column(
                            children: const [
                              Text(
                                "N/A",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text("Last Week", style: TextStyle(fontSize: 10)),
                            ],
                          ),
                          _buildGoalWidget(
                            goalType: 'calories_burned',
                            goalValue: _caloriesGoal,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                // Sleep Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isLight
                        ? Colors.white
                        : const Color(0xFF24102F),
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
                            "Sleep",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 5, right: 5),
                            decoration: BoxDecoration(
                              color: (_hasSleepChange && _sleepChangePercent >= 0)
                                  ? (isLight ? Colors.green[100] : Colors.green[700])
                                  : (isLight ? Colors.red[100] : Colors.red[600]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _hasSleepChange
                                  ? '${_sleepChangePercent >= 0 ? '+' : ''}${_sleepChangePercent.toStringAsFixed(1)}%'
                                  : '—',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isLight ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_totalSleepHours.toStringAsFixed(0)} hours',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                      const Text(
                        "Total sleep this week",
                        style: TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 130,
                        child: BarGraph(
                          dataPoints: _sleepDataPoints,
                          labels: _sleepDateLabels,
                        ),
                      ),
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
                          _buildGoalWidget(
                            goalType: 'sleep_duration',
                            goalValue: _sleepGoal,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                // Glucose Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isLight
                        ? Colors.white
                        : const Color(0xFF03292C),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/metric-detail',
                        arguments: {
                          'metricType': 'glucose',
                          'title': 'Glucose',
                        },
                      );
                    },
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Glucose",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _hasGlucoseChange && _glucoseChangePercent >= 0
                                    ? (isLight ? Colors.green[100] : Colors.green[700])
                                    : (isLight ? Colors.red[100] : Colors.red[600]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _hasGlucoseChange
                                    ? '${_glucoseChangePercent >= 0 ? '+' : ''}${_glucoseChangePercent.toStringAsFixed(1)}%'
                                    : '—',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isLight ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_avgGlucose.toStringAsFixed(1)} mmol/L',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          ),
                        ),
                        const Text(
                          "Average glucose this week",
                          style: TextStyle(fontSize: 10),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 150,
                          child: LineGraph(dataPoints: _glucosePoints),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${_avgGlucose.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "Avg",
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                            Column(
                              children: const [
                                Text(
                                  "3.9–7.8",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Normal Range",
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Blood Pressure Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isLight
                        ? Colors.white
                        : const Color(0xFF0A2238),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/metric-detail',
                        arguments: {
                          'metricType': 'blood_pressure',
                          'title': 'Blood Pressure',
                        },
                      );
                    },
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Blood Pressure",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _hasBpChange
                                    ? (isLight ? Colors.green[100] : Colors.green[700])
                                    : (isLight ? Colors.red[100] : Colors.red[600]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _hasBpChange
                                  ? '${_systolicChangePercent >= 0 ? '+' : ''}${_systolicChangePercent.toStringAsFixed(1)}%'
                                  : '—',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isLight ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _bloodPressure,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          ),
                        ),
                        const Text(
                          "Latest reading",
                          style: TextStyle(fontSize: 10),
                        ),
                        const SizedBox(height: 10),
                        if (_systolicPoints.isNotEmpty) ...[
                          const Text("Systolic Trend", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 100,
                            child: LineGraph(
                              dataPoints: _systolicPoints,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_diastolicPoints.isNotEmpty) ...[
                          const Text("Diastolic Trend", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 100,
                            child: LineGraph(dataPoints: _diastolicPoints),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '$_systolic / $_diastolic',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _latestBpDate != null ? _formatDate(_latestBpDate!) : 'No data',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                            Column(
                              children: const [
                                Text(
                                  "<120/80",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Optimal",
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Water Intake Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : const Color(0xFF0A3B3B),
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
                            "Water Intake",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 5, right: 5),
                            decoration: BoxDecoration(
                              color: (_hasWaterChange && _waterChangePercent >= 0)
                                  ? (isLight ? Colors.green[100] : Colors.green[700])
                                  : (isLight ? Colors.red[100] : Colors.red[600]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _hasWaterChange
                                  ? '${_waterChangePercent >= 0 ? '+' : ''}${_waterChangePercent.toStringAsFixed(1)}%'
                                  : '—',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isLight ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_totalWater.toStringAsFixed(0)} ml',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                      const Text("Total water intake this week", style: TextStyle(fontSize: 10)),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: waterProgress,
                        valueColor: const AlwaysStoppedAnimation(Colors.blue),
                        backgroundColor: isLight ? Colors.grey[300] : Colors.grey[800],
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
                                (_totalWater / 7).toStringAsFixed(0),
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
                          _buildGoalWidget(
                            goalType: 'water_intake',
                            goalValue: _waterGoal,
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
                    color: isLight ? Colors.white : const Color.fromARGB(255, 36, 36, 36),
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
                      const Text(
                        "Weekly Progress",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            "$_goalsAchievedDays/7",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Goals Achieved This Week",
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isLight
                              ? const Color(0xFFDFF2FA)
                              : const Color.fromARGB(44, 223, 242, 250),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(20),
                          ),
                          border: const Border(
                            left: BorderSide(width: 3, color: Colors.blue),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Weekly Insight",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _weeklyInsight,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black,
                              ),
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
}
