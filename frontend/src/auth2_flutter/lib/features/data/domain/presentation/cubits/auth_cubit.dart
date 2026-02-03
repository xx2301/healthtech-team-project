// cubit states

import '../../entities/app_user.dart';
import 'auth_states.dart';
import '../../repos/auth_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    await authRepo.logout();
    emit(Unauthenticated());
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
