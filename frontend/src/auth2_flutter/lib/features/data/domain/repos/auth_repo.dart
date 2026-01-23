// auth respository outlibne the auth operations for this app

import '../entities/app_user.dart';

abstract class AuthRepo {
  Future<AppUser> loginWithEmailAndPassword(String email, String password);
  Future<AppUser> registerWithEmailAndPassword(String fullName, String email, String password, String age, String weight, String height);
  Future<void> logout();
  Future<AppUser?> getCurrentUser();
  Future<String> sendPasswordResetEmail(String email);
  Future<void> deleteAccount();
  //Future<AppUser?> signInWithGoogle();
}
