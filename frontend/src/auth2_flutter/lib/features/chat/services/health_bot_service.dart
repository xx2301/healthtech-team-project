import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class HealthBotService {
  static Future<String> getReply(String userMessage, Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) return _fallbackReply(userMessage, data);

    final url = Uri.parse('${_getBaseUrl()}/api/chatbot/message');
    final body = {
      'message': userMessage,
      'healthData': {
        'steps': data['todaySteps'] ?? 0,
        'stepsGoal': data['stepsGoal'] ?? 6700,
        'avgHeartRate': data['avgHeartRate'] ?? 0,
        'calories': data['todayCalories'] ?? 0,
        'sleep': data['todaySleep'] ?? 0,
      }
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      final result = jsonDecode(response.body);
      if (result['success'] == true && result['reply'] != null) {
        return result['reply'];
      }
    } catch (e) {
      print('AI bot error: $e');
    }
    return _fallbackReply(userMessage, data);
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static String _getBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    if (Platform.isIOS) return 'http://localhost:3001';
    return 'http://localhost:3001';
  }

  static String _fallbackReply(String userMessage, Map<String, dynamic> data) {
    final text = userMessage.toLowerCase();
    final steps = data['todaySteps'] ?? 0;
    final goal = data['stepsGoal'] ?? 6700;
    final heartRate = (data['avgHeartRate'] ?? 0).toDouble();
    final calories = (data['todayCalories'] ?? 0).toDouble();
    final sleep = (data['todaySleep'] ?? 0).toDouble();

    if (text.contains('health') || text.contains('summary')) {
      return 'Today you have walked $steps steps. '
          'Your average heart rate is ${heartRate.toInt()} bpm. '
          'You burned ${calories.toStringAsFixed(1)} kcal today and slept ${sleep.toStringAsFixed(1)} hours.';
    }
    if (text.contains('step')) {
      if (steps >= goal) {
        return 'Great job! You have already reached your daily step goal.';
      } else {
        final remaining = goal - steps;
        return 'You still need $remaining more steps to reach your daily goal.';
      }
    }
    if (text.contains('goal')) {
      if (steps >= goal) {
        return 'You already reached your daily goal! Congratulations!';
      } else {
        final remaining = goal - steps;
        return 'You need $remaining more steps to reach your goal. Keep moving!';
      }
    }
    if (text.contains('sleep')) {
      if (sleep >= 8) {
        return 'You slept ${sleep.toStringAsFixed(1)} hours. That looks good today.';
      } else {
        return 'You slept ${sleep.toStringAsFixed(1)} hours. Try resting a bit earlier tonight.';
      }
    }
    if (text.contains('heart')) {
      return 'Your average heart rate today is ${heartRate.toInt()} bpm. '
          'Heart rate shows how fast your heart is beating.';
    }
    return 'I can help with your health summary, steps, sleep, and heart rate.';
  }
}