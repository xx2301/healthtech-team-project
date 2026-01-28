
import 'login.dart';
import 'register.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  

  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLoginPage = true;

  // toggle between pages 
  void toggePages(){
    setState(() {
      showLoginPage =!showLoginPage;
    });
  } 
  @override
  Widget build(BuildContext context) {
    if (showLoginPage){
      return LoginPage(togglePages: toggePages,);
    } else {
      return RegisterPage(togglePages: toggePages,);
    }
  }
}