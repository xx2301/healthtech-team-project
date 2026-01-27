//login part --> redircted to home page if successfully logged in

//will be redirected to make account if there is no account

import 'package:auth2_flutter/features/data/domain/presentation/components/appbar2.dart';
import '../../components/my_button.dart';
import '../../components/my_textfield.dart';
import '../auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatefulWidget {
  final void Function()? togglePages;

  const LoginPage({super.key, required this.togglePages});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //text editting controllers for password and email
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  //auth cubit
  late final authCubit = context.read<AuthCubit>();

  void login() {
    final String email = emailController.text;
    final String password = passwordController.text;

    //ensure the fields are filled
    if (email.isNotEmpty && password.isNotEmpty) {
      //login
      authCubit.login(email, password);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and password")),
      );
    }
  }

  //forgot password box
  void openForgotPasswordBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.green.shade100,
        title: Text("Forgot Password"),
        content: MyTextfield(
          controller: emailController,
          hintText: "Enter Email..",
          obsecureText: false,
        ),
        actions: [
          //cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          //reset button
          TextButton(
            onPressed: () async {
              String message = await authCubit.forgotPassword(
                emailController.text,
              );

              if (message == "Password reset email! Check your inbox.") {
                Navigator.pop(context);
                emailController.clear();
              }

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Appbar2(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //page name
              Row(
                children: [
                  Text(
                    "LOGIN PAGE",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              //email textfield
              Row(
                children: [
                  Text(
                    "Email",
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              MyTextfield(
                controller: emailController,
                hintText: "limxt@gmail.com",
                obsecureText: false,
              ),

              const SizedBox(height: 15),

              //password textfield
              Row(
                children: [
                  Text(
                    "Password",
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              MyTextfield(
                controller: passwordController,
                hintText: "Apple67",
                obsecureText: true,
              ),
              const SizedBox(height: 10),

              //forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => openForgotPasswordBox(),
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              //login button
              MyButton(onTap: login, text: "LOGIN"),

              const SizedBox(height: 15),
              //dont have an account?
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.black),
                  ),
                  GestureDetector(
                    onTap: widget.togglePages,
                    child: Text(
                      "Register Now",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              //google sign in
              /* Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [MyGoogleSignInButton()],
                  ),*/
            ],
          ),
        ),
      ),
    );
  }
}
