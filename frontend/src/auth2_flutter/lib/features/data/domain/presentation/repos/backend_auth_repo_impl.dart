import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../entities/app_user.dart';
import '../../repos/auth_repo.dart';

class BackendAuthRepoImpl implements AuthRepo {
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3001';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3001';
    } else if (Platform.isIOS) {
      return 'http://localhost:3001';
    } else {
      return 'http://localhost:3001';
    }
  }
  
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  
  final http.Client _client = http.Client();
  
  // ways that store data in local storage
  Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }
  
  Future<void> _saveAuthData(String token, Map<String, dynamic> userJson) async {
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(userJson));
  }
  
  Future<void> _clearAuthData() async {
    final prefs = await _prefs;
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
  
  Future<String?> _getToken() async {
    final prefs = await _prefs;
    return prefs.getString(_tokenKey);
  }
  
  Future<AppUser?> _getUserFromStorage() async {
    final prefs = await _prefs;
    final userString = prefs.getString(_userKey);
    
    if (userString != null) {
      try {
        final userJson = jsonDecode(userString);
        return AppUser.fromJson(userJson);
      } catch (e) {
        print('Failed to parse user from storage: $e');
        return null;
      }
    }
    return null;
  }
  
  // http request method
  Future<Map<String, dynamic>> _sendRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    bool needsAuth = false,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = {'Content-Type': 'application/json'};
      
      if (needsAuth) {
        final token = await _getToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        } else {
          throw Exception('Please log in first.');
        }
      }
      
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(url, headers: headers);
          break;
        case 'POST':
          response = await _client.post(
            url,
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        case 'DELETE':
          response = await _client.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw Exception(responseData['error'] ?? 'Request failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  //  implement AuthRepo methods
  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      final localUser = await _getUserFromStorage();
      if (localUser != null) {
        final token = await _getToken();
        if (token != null) {
          try {
            await _sendRequest(
              method: 'GET',
              endpoint: '/api/auth/verify',
              needsAuth: true,
            );
            return localUser;
          } catch (e) {
            await _clearAuthData();
            return null;
          }
        }
        return localUser;
      }
      return null;
    } catch (e) {
      print('Retrieve data failed: $e');
      return null;
    }
  }
  
  @override
  Future<AppUser> loginWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _sendRequest(
        method: 'POST',
        endpoint: '/api/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );
      
      if (response['success'] == true) {
        final userJson = response['user'];
        final token = response['token'];
        
        await _saveAuthData(token, {
          ...userJson,
          'uid': userJson['_id'] ?? userJson['id'],
        });
        
        return AppUser.fromBackendJson(userJson);
      } else {
        throw Exception(response['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
  
  @override
  Future<AppUser> registerWithEmailAndPassword(
    String fullName,
    String email,
    String password,
    String age,
    String weight,
    String height,
  ) async {
    try {
      final response = await _sendRequest(
        method: 'POST',
        endpoint: '/api/auth/register',
        body: {
          'email': email,
          'password': password,
          'name': fullName,
          'age': int.tryParse(age),
          'weight': double.tryParse(weight),
          'height': double.tryParse(height),
        },
      );
      
      if (response['success'] == true) {
        final userJson = response['user'];
        final token = response['token'];
        
        await _saveAuthData(token, {
          ...userJson,
          'uid': userJson['_id'] ?? userJson['id'],
        });
        
        return AppUser.fromBackendJson(userJson);
      } else {
        throw Exception(response['error'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }
  
  @override
  Future<void> logout() async {
    try {
      await _sendRequest(
        method: 'POST',
        endpoint: '/api/auth/logout',
        needsAuth: true,
      );
    } catch (e) {
      print('Backend logout failed: $e');
    } finally {
      await _clearAuthData();
    }
  }
  
  @override
  Future<String> sendPasswordResetEmail(String email) async {
    try {
      final response = await _sendRequest(
        method: 'POST',
        endpoint: '/api/auth/forgot-password',
        body: {'email': email},
      );
      
      return response['message'] ?? 'Password reset email sent';
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }
  
  @override
  Future<void> deleteAccount() async {
    try {
      await _sendRequest(
        method: 'DELETE',
        endpoint: '/api/auth/delete-account',
        needsAuth: true,
      );
    } finally {
      await _clearAuthData();
    }
  }
  
  Future<bool> testConnection() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/health'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}