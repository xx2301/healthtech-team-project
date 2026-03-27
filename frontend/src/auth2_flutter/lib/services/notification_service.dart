import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String baseUrl = 'http://10.0.2.2:3001';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<int> getUnreadCount() async {
    try {
      final token = await _getToken();
      if (token == null) return 0;
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/unread-count'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data']['count'] ?? 0;
      }
    } catch (e) {
      print('Error fetching unread count: $e');
    }
    return 0;
  }
}
