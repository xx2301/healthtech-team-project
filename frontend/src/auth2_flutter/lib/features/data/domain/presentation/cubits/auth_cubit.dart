// cubit states

import '../../entities/app_user.dart';
import 'auth_states.dart';
import '../../repos/auth_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:auth2_flutter/features/data/domain/entities/app_user.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;
  AppUser? _currentUser;

  AuthCubit({required this.authRepo}) : super(AuthInitial());
  AppUser? get currentUser => _currentUser;

  //check if user is authenticated
  void checkAuth() async {
    //loading
    emit(AuthLoading());

    //get current user
    final AppUser? user = await authRepo.getCurrentUser();

    if (user != null) {
      _currentUser = user;
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  //login with email and password
  Future<void> login(String email, String password) async {
    try {
      emit(AuthLoading());
      final user = await authRepo.loginWithEmailAndPassword(email, password);

      _currentUser = user;
      emit(Authenticated(user));
        } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  //register with email, name and password
  Future<void> register(
    String fullName,
    String email,
    String password,
    String age,
    String weight,
    String height,
  ) async {
    try {
      emit(AuthLoading());
      final user = await authRepo.registerWithEmailAndPassword(
        fullName,
        email,
        password,
        age,
        weight,
        height,
      );

      _currentUser = user;
      emit(Authenticated(user));
        } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  //logout
  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await authRepo.logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
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
    // return 'http://192.168.0.3:3001'; // Connect wifi ip
    // return 'http://172.20.10.2:3001'; // Connect hotspot ip
  }
  
  Future<void> refreshUser() async {
    final token = await _getToken();
    if (token == null) return;
    final response = await http.get(
      Uri.parse('${_getBaseUrl()}/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final userData = jsonData['user'];
      if (userData != null) {
        final user = AppUser.fromBackendJson(userData);
        _currentUser = user;
        emit(Authenticated(user));
      }
    }
  }

  //forgot password
  Future<String> forgotPassword(String email) async {
    try {
      final message = await authRepo.sendPasswordResetEmail(email);
      return message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    try {
      emit(AuthLoading());
      final message = await authRepo.resetPassword(token, newPassword);
      emit(Unauthenticated()); 
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  //delete user account
  Future<void> deleteAccount() async {
    try {
      emit(AuthLoading());
      await authRepo.deleteAccount();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

 /* Future<void> signInWithGoogle() async {
    try {
      emit(AuthLoading());
      final user = await authRepo.signInWithGoogle();

      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }*/
}
