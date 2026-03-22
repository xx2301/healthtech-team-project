import 'package:auth2_flutter/features/data/domain/entities/app_user.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_cubit.dart';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth2_flutter/features/data/domain/entities/health_metric.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

class MetricConfig {
  final String type;
  final String title;
  final IconData icon;
  final Color color;
  final String unit;
  final String dataKey;

  const MetricConfig(
    this.type,
    this.title,
    this.icon,
    this.color,
    this.unit,
    this.dataKey,
  );
}

const List<MetricConfig> allMetrics = [
  MetricConfig(
    'steps',
    'Steps',
    Icons.directions_walk,
    Colors.green,
    'steps',
    'todaySteps',
  ),
  MetricConfig(
    'heart_rate',
    'Heart Rate',
    Icons.monitor_heart,
    Colors.red,
    'bpm',
    'avgHeartRate',
  ),
  MetricConfig(
    'calories',
    'Calories',
    Icons.local_fire_department,
    Colors.orange,
    'kcal',
    'todayCalories',
  ),
  MetricConfig(
    'sleep',
    'Sleep',
    Icons.bedtime,
    Colors.purple,
    'hrs',
    'todaySleep',
  ),
  MetricConfig(
    'glucose',
    'Glucose',
    Icons.bloodtype,
    Colors.teal,
    'mmol/L',
    'todayAvgGlucose',
  ),
  MetricConfig(
    'blood_pressure',
    'Blood Pressure',
    Icons.monitor_heart_outlined,
    Colors.blue,
    'mmHg',
    'bloodPressure',
  ),
  MetricConfig(
    'weight', 
    'Weight', 
    Icons.monitor_weight, 
    Colors.blue, 
    'kg', 
    'todayWeight'
  ),
  MetricConfig(
    'height', 
    'Height', 
    Icons.straighten, 
    Colors.purple, 
    'cm', 
    'todayHeight'
  ),
  MetricConfig(
    'body_temperature', 
    'Body Temp', 
    Icons.thermostat, 
    Colors.red, 
    '°C', 
    'todayTemp'
  ),
  MetricConfig(
    'oxygen_saturation', 
    'Oxygen', 
    Icons.air, 
    Colors.teal, 
    '%', 
    'todayOxygen'
  ),
  MetricConfig(
    'water_intake', 
    'Water', 
    Icons.water_drop,
     Colors.cyan, 
     'ml', 
     'todayWater'
    ),
  MetricConfig(
    'respiratory_rate', 
    'Respiratory', 
    Icons.airline_seat_recline_normal, 
    Colors.orange, 
    'breaths/min', 
    'todayRespiratory'
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _selectedMetricTypes = [];

  final String _storageKey = 'selected_metrics';

  Map<String, dynamic>? _homeData;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadSelectedMetrics();
    _loadHomeData();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadHomeData();
      }
    });
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _fetchHomeData();
      if (mounted) {
        setState(() {
          _homeData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSelectedMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_storageKey);
    setState(() {
      if (saved != null && saved.isNotEmpty) {
        // filter out expired metrics
        _selectedMetricTypes = saved
            .where((type) => allMetrics.any((m) => m.type == type))
            .toList();
      } else {
        _selectedMetricTypes = [
          'steps',
          'heart_rate',
          'calories',
          'sleep',
        ]; //defalut metrics
      }
    });
  }

  Future<void> _saveSelectedMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _selectedMetricTypes);
  }

  // limit 8
  void _addMetric(String type) {
    const int maxLimit = 8;
    if (_selectedMetricTypes.length >= maxLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Can display up to 8 indicators')),
      );
      return;
    }
    if (!_selectedMetricTypes.contains(type)) {
      setState(() {
        _selectedMetricTypes.add(type);
      });
      _saveSelectedMetrics();
    }
  }

  void _removeMetric(String type) {
    setState(() {
      _selectedMetricTypes.remove(type);
    });
    _saveSelectedMetrics();
  }

  List<MetricConfig> get _availableMetrics =>
      allMetrics.where((m) => !_selectedMetricTypes.contains(m.type)).toList();

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

  Future<Map<String, dynamic>> _fetchHomeData() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final now = DateTime.now();
    final String? currentUserId = (context.read<AuthCubit>().currentUser)?.uid;

    // today range
    final startDate = DateTime(now.year, now.month, now.day);
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // last 7 days range
    final weekStart = DateTime(now.year, now.month, now.day - 6);
    final weekEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // get todays data
    final todayUrl = Uri.parse('${_getBaseUrl()}/api/health-metrics').replace(
      queryParameters: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'limit': '500',
        if (currentUserId != null) 'userId': currentUserId,
      },
    );
    final todayResponse = await http.get(
      todayUrl,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (todayResponse.statusCode != 200)
      throw Exception('Failed to load today metrics');

    // get last 7 days data
    final weekUrl = Uri.parse('${_getBaseUrl()}/api/health-metrics').replace(
      queryParameters: {
        'startDate': weekStart.toIso8601String(),
        'endDate': weekEnd.toIso8601String(),
        'limit': '500',
        if (currentUserId != null) 'userId': currentUserId,
      },
    );
    final weekResponse = await http.get(
      weekUrl,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (weekResponse.statusCode != 200)
      throw Exception('Failed to load week metrics');

    // parse data
    final todayData = jsonDecode(todayResponse.body)['data'] as List;
    final todayMetrics = todayData
        .map((e) => HealthMetric.fromJson(e))
        .toList();

    final weekData = jsonDecode(weekResponse.body)['data'] as List;
    final weekMetrics = weekData.map((e) => HealthMetric.fromJson(e)).toList();

    final deviceStatus = await _fetchDeviceStatusMap();

    bool stepsDeviceError = false;
    bool heartRateDeviceError = false;
    bool caloriesDeviceError = false;
    bool sleepDeviceError = false;
    bool glucoseDeviceError = false;
    bool bpDeviceError = false;

    // steps
    final stepDeviceIds = todayMetrics
        .where((m) => m.metricType == 'steps')
        .map((m) => m.deviceId)
        .whereType<String>()
        .toSet();
    stepsDeviceError = stepDeviceIds.any((id) => deviceStatus[id] == true);

    // heart rate
    final heartDeviceIds = todayMetrics
        .where((m) => m.metricType == 'heart_rate')
        .map((m) => m.deviceId)
        .whereType<String>()
        .toSet();
    heartRateDeviceError = heartDeviceIds.any((id) => deviceStatus[id] == true);

    // calories
    final calorieDeviceIds = todayMetrics
        .where((m) => m.metricType == 'calories_burned')
        .map((m) => m.deviceId)
        .whereType<String>()
        .toSet();
    caloriesDeviceError = calorieDeviceIds.any(
      (id) => deviceStatus[id] == true,
    );

    // sleep
    final sleepDeviceIds = todayMetrics
        .where((m) => m.metricType == 'sleep_duration')
        .map((m) => m.deviceId)
        .whereType<String>()
        .toSet();
    sleepDeviceError = sleepDeviceIds.any((id) => deviceStatus[id] == true);

    // glucose
    final glucoseDeviceIds = todayMetrics
        .where((m) => m.metricType == 'glucose')
        .map((m) => m.deviceId)
        .whereType<String>()
        .toSet();
    glucoseDeviceError = glucoseDeviceIds.any((id) => deviceStatus[id] == true);

    // blood pressure
    final bpDeviceIds = todayMetrics
        .where((m) => m.metricType == 'blood_pressure')
        .map((m) => m.deviceId)
        .whereType<String>()
        .toSet();
    bpDeviceError = bpDeviceIds.any((id) => deviceStatus[id] == true);

    int todaySteps = 0;
    double avgHeartRate = 0;
    int todayCalories = 0;
    double todaySleep = 0;
    double todayWeight = 0;
    double todayHeight = 0;
    double todayTemp = 0;
    double todayOxygen = 0;
    double todayWater = 0;
    double todayRespiratory = 0;

    final stepsMetricsToday = todayMetrics
        .where((m) => m.metricType == 'steps')
        .toList();
    todaySteps = stepsMetricsToday.fold(
      0,
      (sum, m) => sum + (m.value as num).toInt(),
    );

    final heartMetricsToday = todayMetrics
        .where((m) => m.metricType == 'heart_rate')
        .toList();
    if (heartMetricsToday.isNotEmpty) {
      avgHeartRate =
          heartMetricsToday.fold<double>(
            0,
            (sum, m) => sum + (m.value as num).toDouble(),
          ) /
          heartMetricsToday.length;
    }

    final calorieMetricsToday = todayMetrics
        .where((m) => m.metricType == 'calories_burned')
        .toList();
    todayCalories = calorieMetricsToday.fold(
      0,
      (sum, m) => sum + (m.value as num).toInt(),
    );

    final sleepMetricsToday = todayMetrics
        .where((m) => m.metricType == 'sleep_duration')
        .toList();
    todaySleep = sleepMetricsToday.fold(
      0.0,
      (sum, m) => sum + (m.value as num).toDouble(),
    );

    double avgGlucose = 0;
    int? latestSystolic;
    int? latestDiastolic;

    final glucoseMetrics = todayMetrics
        .where((m) => m.metricType == 'glucose')
        .toList();
    if (glucoseMetrics.isNotEmpty) {
      avgGlucose =
          glucoseMetrics.map((m) => m.value as double).reduce((a, b) => a + b) /
          glucoseMetrics.length;
    }

    // get latest data for blood pressure
    final bpMetrics =
        todayMetrics.where((m) => m.metricType == 'blood_pressure').toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    String bloodPressure = '--/--';
    if (bpMetrics.isNotEmpty) {
      final value = bpMetrics.first.value;
      if (value is Map) {
        final systolic = value['systolic']?.toString() ?? '?';
        final diastolic = value['diastolic']?.toString() ?? '?';
        bloodPressure = '$systolic/$diastolic';
      }
    }

    int stepsGoal = 6700; // default value
    try {
      final goalsUrl = Uri.parse('${_getBaseUrl()}/api/health-goals');
      final goalsResponse = await http.get(
        goalsUrl,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (goalsResponse.statusCode == 200) {
        final goalsData = jsonDecode(goalsResponse.body)['data'] as List;
        final stepsGoalObj = goalsData.firstWhere(
          (g) => g['goalType'] == 'steps',
          orElse: () => null,
        );
        if (stepsGoalObj != null) {
          stepsGoal = stepsGoalObj['targetValue']?.toInt() ?? stepsGoal;
        }
      }
    } catch (e) {
      print('Error fetching goals: $e');
    }

    final stepsMetricsWeek = weekMetrics
        .where((m) => m.metricType == 'steps' && !m.isAbnormal)
        .toList();
    List<bool> weeklyDailyStatus = List.filled(7, false);
    for (int i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day - (6 - i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
      final daySteps = stepsMetricsWeek
          .where(
            (m) =>
                m.timestamp.isAfter(dayStart) && m.timestamp.isBefore(dayEnd),
          )
          .fold<int>(0, (sum, m) => sum + (m.value as num).toInt());
      weeklyDailyStatus[i] = daySteps >= stepsGoal;
    }

    double stepsProgress = stepsGoal > 0 ? todaySteps / stepsGoal : 0;
    if (stepsProgress > 1.0) stepsProgress = 1.0;

    bool isGoalAchievedToday = todaySteps >= stepsGoal;

    final weightMetrics = todayMetrics.where((m) => m.metricType == 'weight').toList();
    if (weightMetrics.isNotEmpty) todayWeight = weightMetrics.last.value;

    final heightMetrics = todayMetrics.where((m) => m.metricType == 'height').toList();
    if (heightMetrics.isNotEmpty) todayHeight = heightMetrics.last.value;

    final tempMetrics = todayMetrics.where((m) => m.metricType == 'body_temperature').toList();
    if (tempMetrics.isNotEmpty) todayTemp = tempMetrics.last.value;

    final oxygenMetrics = todayMetrics.where((m) => m.metricType == 'oxygen_saturation').toList();
    if (oxygenMetrics.isNotEmpty) todayOxygen = oxygenMetrics.last.value;

    final waterMetrics = todayMetrics.where((m) => m.metricType == 'water_intake').toList();
    todayWater = waterMetrics.fold(0.0, (sum, m) => sum + (m.value as num).toDouble());

    final respiratoryMetrics = todayMetrics.where((m) => m.metricType == 'respiratory_rate').toList();
    if (respiratoryMetrics.isNotEmpty) todayRespiratory = respiratoryMetrics.last.value;

    return {
      'todaySteps': todaySteps,
      'avgHeartRate': avgHeartRate,
      'todayCalories': todayCalories,
      'todaySleep': todaySleep,
      'stepsGoal': stepsGoal,
      'stepsProgress': stepsProgress,
      'isGoalAchievedToday': isGoalAchievedToday,
      'weeklyDailyStatus': weeklyDailyStatus,
      'todayAvgGlucose': avgGlucose,
      'bloodPressure': bloodPressure,
      'stepsDeviceError': stepsDeviceError,
      'heartRateDeviceError': heartRateDeviceError,
      'caloriesDeviceError': caloriesDeviceError,
      'sleepDeviceError': sleepDeviceError,
      'glucoseDeviceError': glucoseDeviceError,
      'bpDeviceError': bpDeviceError,
      'todayWeight': todayWeight,
      'todayHeight': todayHeight,
      'todayTemp': todayTemp,
      'todayOxygen': todayOxygen,
      'todayWater': todayWater,
      'todayRespiratory': todayRespiratory,
    };
  }

  Future<Map<String, bool>> _fetchDeviceStatusMap() async {
    try {
      final token = await _getToken();
      if (token == null) return {};
      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/api/devices'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final devices = json['data'] as List;
        final Map<String, bool> statusMap = {};
        for (var d in devices) {
          final id = d['_id'] as String;
          final status = d['status'] as String? ?? 'online';
          statusMap[id] = (status == 'error' || status == 'offline');
        }
        return statusMap;
      }
    } catch (e) {
      print('Error fetching device status: $e');
    }
    return {};
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "morning";
    if (hour < 17) return "afternoon";
    return "evening";
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        return Scaffold(
          appBar: DefaultAppBar(),
          drawer: DefaultDrawer(),
          body: _buildContentBasedOnAuthState(context, authState),
        );
      },
    );
  }

  Widget _buildHealthCard({
    required String title,
    required dynamic value,
    required String unit,
    required IconData icon,
    required Color color,
    double? progress, // unused now (percentage)
    VoidCallback? onRemove,
    required String metricType,
    bool isDeviceError = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/metric-detail',
          arguments: {'metricType': metricType, 'title': title},
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // percentage on top right of health card
                    /*Icon(icon, color: color, size: 28),
                    if (progress != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${(progress * 100).toInt()}%",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                        ),
                      ),*/
                  ],
                ),
                const Spacer(),
                Text(
                  "$value $unit",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[200]
                    : Colors.grey[700]),
                ),
              ],
            ),
            if (onRemove != null)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

            // Device error logo
            if (isDeviceError)
              Positioned(
                top: 0,
                left: 0,
                child: Tooltip(
                  message: 'Device error detected',
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(AppUser user) {
    if (user.avatarColor != null) {
      return Color(user.avatarColor!);
    }

    final hash = user.uid.hashCode.abs();
    return HSLColor.fromAHSL(1.0, (hash % 360).toDouble(), 0.6, 0.7).toColor();
  }

  Widget _buildContentBasedOnAuthState(
    BuildContext context,
    AuthState authState,
  ) {
    if (authState is AuthLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (authState is Authenticated) {
      return _buildAuthenticatedContent(context, authState.user);
    } else if (authState is Unauthenticated) {
      return _buildUnauthenticatedContent(context);
    } else if (authState is AuthError) {
      return _buildErrorContent(authState.message);
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildAuthenticatedContent(BuildContext context, AppUser user) {
    if (_isLoading && _homeData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text('Error: $_errorMessage'));
    }
    if (_homeData == null) {
      return const Center(child: Text('No data available'));
    }

    final data = _homeData!;
    final todaySteps = data['todaySteps'] as int;
    final avgHeartRate = data['avgHeartRate'] as double;
    final todayCalories = data['todayCalories'] as int;
    final todaySleep = data['todaySleep'] as double;
    final stepsGoal = data['stepsGoal'] as int;
    final stepsProgress = data['stepsProgress'] as double;
    final isGoalAchievedToday = data['isGoalAchievedToday'] as bool;
    final weeklyDailyStatus = data['weeklyDailyStatus'] as List<bool>;
    const int maxLimit = 8;

    bool hasUserInfo =
        (user.age != null && user.age!.isNotEmpty) ||
        (user.height != null && user.height!.isNotEmpty) ||
        (user.weight != null && user.weight!.isNotEmpty);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Dashboard",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/personalinfopage');
                  },
                  child: CircleAvatar(
                    backgroundColor: _getAvatarColor(user),
                    child: Text(
                      user.fullName?.isNotEmpty == true
                          ? user.fullName![0].toUpperCase()
                          : user.email[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              "Good ${_getTimeOfDay()}, ${user.fullName?.isNotEmpty == true ? user.fullName!.split(' ')[0] : user.email.split('@')[0]}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              "Let's stay healthy today!",
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[200]
                    : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),

            if (hasUserInfo)...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                  ? Colors.blue[50]
                  : Colors.blue.shade800,
                  // color: Theme.of(context).brightness == Brightness.light
                  // ? Colors.blue[50]
                  // : const Color(0xFF1E2A38),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (user.age != null && user.age!.isNotEmpty)
                      _buildUserInfoItem(
                        "Age", 
                        "${user.age} yrs", 
                        Icons.cake
                      ),
                    if (user.height != null && user.height!.isNotEmpty)
                      _buildUserInfoItem(
                        "Height",
                        "${user.height} cm",
                        Icons.straighten,
                      ),
                    if (user.weight != null && user.weight!.isNotEmpty)
                      _buildUserInfoItem(
                        "Weight",
                        "${user.weight} kg",
                        Icons.monitor_weight,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                  ?  [Colors.blue.shade800, const Color.fromARGB(160, 0, 0, 0)]
                  : [Colors.blue.shade50, Colors.white],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Progress",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[200]
                          : Colors.grey[800],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isGoalAchievedToday
                              ? Colors.green[100]
                              : Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isGoalAchievedToday
                              ? "Goal Met"
                              : "${(stepsGoal - todaySteps)} steps left",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isGoalAchievedToday
                                ? Colors.green[800]
                                : Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${(stepsProgress * 100).toInt()}%",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "of daily goal",
                        style: TextStyle(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[200]
                          : Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: stepsProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.green.shade400,
                      ),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            /*Row(
                  children: [
                    Text(
                      "Good afternoon, ",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                      ),
                    ),
                    
                    //dynamic name
                    Text(
                      user.fullName?.isNotEmpty == true 
                          ? user.fullName!
                          : user.email.split('@')[0],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ],
                ),

                if (user.age != null || user.height != null || user.weight != null)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade100, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (user.age != null && user.age!.isNotEmpty)
                          _buildUserInfoItem("Age", "${user.age} yrs"),
                        if (user.height != null && user.height!.isNotEmpty)
                          _buildUserInfoItem("Height", "${user.height} cm"),
                        if (user.weight != null && user.weight!.isNotEmpty)
                          _buildUserInfoItem("Weight", "${user.weight} kg"),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
            
                Row(
                  children: [
                    Text(
                      "Health details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                //weather
                Text("Weather is Sunny, perfect for a walk!"),

                const SizedBox(height: 20),

                //progress header
                Text("Today's Progress: ${(stepsProgress * 100).toInt()}%"),

                //steps progress bar
                Text("$todaySteps / $stepsGoal steps"), 
                LinearProgressIndicator(
                  value: stepsProgress,
                  valueColor: const AlwaysStoppedAnimation(Colors.black),
                ),

                const SizedBox(height: 10),

                //progress report
                Text(progressMessage),

                const SizedBox(height: 20),*/

            // My Health Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "My Health",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (_availableMetrics.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      _selectedMetricTypes.length >= maxLimit
                          ? Icons.edit
                          : Icons.add_circle_outline,
                      color: Colors.blue,
                    ),
                    onPressed: () => _showAddMetricDialog(context),
                    tooltip: _selectedMetricTypes.length >= maxLimit
                        ? 'Edit indicators'
                        : 'Add indicator',
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_selectedMetricTypes.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                child: const Text('No health cards yet, click + to add'),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _selectedMetricTypes.length,
                itemBuilder: (context, index) {
                  final type = _selectedMetricTypes[index];
                  final config = allMetrics.firstWhere((c) => c.type == type);
                  dynamic value = data[config.dataKey];

                  if (config.type == 'heart_rate' && value is double) value = value.toInt();
                  else if (config.type == 'sleep' && value is double) value = value.toStringAsFixed(1);
                  else if (config.type == 'glucose' && value is double) value = value.toStringAsFixed(1);
                  if (value == null) value = '--';

                  bool isDeviceError = false;
                  switch (config.type) {
                    case 'steps':
                      isDeviceError = data['stepsDeviceError'] ?? false;
                      break;
                    case 'heart_rate':
                      isDeviceError = data['heartRateDeviceError'] ?? false;
                      break;
                    case 'calories':
                      isDeviceError = data['caloriesDeviceError'] ?? false;
                      break;
                    case 'sleep':
                      isDeviceError = data['sleepDeviceError'] ?? false;
                      break;
                    case 'glucose':
                      isDeviceError = data['glucoseDeviceError'] ?? false;
                      break;
                    case 'blood_pressure':
                      isDeviceError = data['bpDeviceError'] ?? false;
                      break;
                  }

                  return _buildHealthCard(
                    title: config.title,
                    value: value,
                    unit: config.unit,
                    icon: config.icon,
                    color: config.color,
                    progress: config.type == 'steps' ? stepsProgress : null,
                    onRemove: () => _removeMetric(type),
                    metricType: config.type,
                    isDeviceError: isDeviceError,
                  );
                },
              ),
            const SizedBox(height: 24),

            // Progress Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "My Progress",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                // view more button -> report page
                GestureDetector(
                  onTap: () {
                    // Navigator.pop(context);
                    Navigator.pushNamed(context, '/reportpage');
                  },
                  child: Row(
                    children: const [
                      Text("View All", style: TextStyle(color: Colors.blue)),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Goal card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                          ? const Color.fromARGB(255, 36, 36, 36)
                          : Colors.white,
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
                    "Your Weekly Goals",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (index) {
                      final isAchieved = weeklyDailyStatus[index];
                      return Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isAchieved
                                  ? Colors.green[100]
                                  : Colors.red[100],
                            ),
                            child: Icon(
                              isAchieved
                                  ? Icons.check
                                  : Icons.watch_later_outlined,
                              color: isAchieved
                                  ? Colors.green[700]
                                  : Colors.grey[600],
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ][index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isAchieved
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isAchieved
                                  ? Colors.green[700]
                                  : Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[200]
                          : Colors.grey[600],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
              // sleep progression card
              /*Container(
                  padding: const EdgeInsets.all(12),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sleep Duration",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          Text(
                            "Last 7 days",
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                            // textAlign: TextAlign.left,
                          ),
                          const SizedBox(height: 8),

                          Center(
                            child: Column(
                              children: [
                                Text(
                                  "${(totalSleep / 7).toStringAsFixed(1)} hrs",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  "Daily Avg",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(width: 12),

                      // sleep progress per day 

                      Row(
                        children: List.generate(7, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              children: [
                                Icon(Icons.bedtime, color: Colors.blue[200], size: 20),
                                const SizedBox(height: 2),
                                Text(
                                  ['M','T','W','T','F','S','S'][index],
                                  style: const TextStyle(fontSize: 8),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),*/
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMetricDialog(BuildContext context) {
    final available = _availableMetrics;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Health Indicators'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: available.length,
            itemBuilder: (_, index) {
              final metric = available[index];
              return ListTile(
                leading: Icon(metric.icon, color: metric.color),
                title: Text(metric.title),
                onTap: () {
                  Navigator.pop(ctx);
                  _addMetric(metric.type);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:  Text('Cancel', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,),),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.blue[300]
              : Colors.blue[700],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[300]
                : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUnauthenticatedContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.health_and_safety, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Welcome to HealthTech',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please log in to access your health dashboard',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 20),
          Text(
            'Error: $errorMessage',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.read<AuthCubit>().checkAuth();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
