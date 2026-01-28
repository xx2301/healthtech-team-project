import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BackendAuthRepository {
  // - Android Demo: http://10.0.2.2:3001
  // - iOS Demo: http://localhost:3001
  // - Actual device: http://<你的电脑IP>:3001
  // - Flutter Web: http://localhost:3001
  static const String baseUrl = 'http://localhost:3001';
  
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  
  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }
  
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      return jsonDecode(userString);
    }
    return null;
  }
  
  // clear log in status
  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await saveToken(data['token']);
          await saveUser(data['user']);
          return data;
        } else {
          throw Exception(data['error'] ?? 'Login failed');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    int? age,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'age': age,
          'phone': phone,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await saveToken(data['token']);
          await saveUser(data['user']);
          return data;
        } else {
          throw Exception(data['error'] ?? 'Registration failed');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
  
  // get health data from backend (example)
  Future<List<dynamic>> getHealthData() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Not logged in');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/health-data'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Fetch health data failed: HTTP ${response.statusCode}');
    }
  }
}