//backend

import 'domain/entities/app_user.dart';
import 'domain/repos/auth_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthRepo implements AuthRepo {
  // access to Firebase
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
 // final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  


  //get current user
  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = firebaseAuth.currentUser;

    if (firebaseUser ==null) return null; 

    return AppUser(uid: firebaseUser.uid, email: firebaseUser.email!);
  }

  //LOGIN: email and password
  @override
  Future<AppUser> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      //attempt sign in
      UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      //create user
      AppUser user = AppUser(uid: userCredential.user!.uid, email: email);
      //return user
      return user;
    } catch (e) {
      //handle errors
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  //register user
  @override
  Future<AppUser> registerWithEmailAndPassword(
    String name,
    String email,
    String password,
    String age,
    String weight,
    String height,

) async {
    try {
      //attempt to sign in
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      //create user
      AppUser user = AppUser(uid: userCredential.user!.uid, email: email);
      //return user
      return user;
    }
    //handle errors
    catch (e) {
      throw Exception('Registration failed: $e');
    }
  }
  
  //remover user
  @override
  Future<void> deleteAccount() async {
  try{
    //get current user
    final user = firebaseAuth.currentUser;
    // check if there is a logged in user 
    if(user == null) throw Exception('No user logged in');

    //delete account 
    await user.delete();
  } catch (e) {
    throw Exception ('Failed to delete account: $e');
  }
  }


  @override
  Future<String> sendPasswordResetEmail(String email) async {
   try{
    await firebaseAuth.sendPasswordResetEmail(email: email);
    return "Password reset email! Check your email.";
    } catch (e){
      return "an error occured: $e";
    }
    

  }

  /*
  @override
  Future<AppUser?> signInWithGoogle() async {
  
    try{
      
      //begin the interactive sign-in process
      final GoogleSignInAccount gUser = await _googleSignIn.authenticate();

      // user cancelled sign-in
      if (gUser == null) return null;

      // obtain auth details from request
      final GoogleSignInAuthentication gAuth = gUser.authentication;

      // create a credential for the user
      final credential = GoogleAuthProvider.credential(
        idToken: gAuth.idToken,
      );

      // sign in with these credentials
      UserCredential userCredential =
          await firebaseAuth.signInWithCredential(credential);

      // firebase user
      final firebaseUser = userCredential.user;

      // user cancelled sign-in process
      if (firebaseUser == null) return null;

      AppUser appUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
      );

      return appUser;

    } catch (e){
      print(e);
      return null;
    }
  }*/
}
