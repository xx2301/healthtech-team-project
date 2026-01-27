import '../../components/my_button.dart';
import '../../components/my_textfield.dart';
import '../auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? togglePages;

  const RegisterPage({super.key, required this.togglePages});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  //text editting controllers for password and email
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final ageController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();

  //register button pressed
  void register() async {
    //prepare info
    final String fullName = fullNameController.text;
    final String email = emailController.text;
    final String password = passwordController.text;
    final String confirmPassword = confirmPasswordController.text;
    final String age = ageController.text;
    final String weight = weightController.text;
    final String height = heightController.text;

    //auth cubit
    final authCubit = context.read<AuthCubit>();

    //ensure the fields arent empty
    if (email.isNotEmpty &&
        password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        age.isNotEmpty &&
        weight.isNotEmpty &&
        height.isNotEmpty) {
      if (password == confirmPassword) {
        authCubit.register(fullName, email, password, age, weight, height);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match!")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields!")),
      );
    }
  }

  //dispose all controllers
  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.health_and_safety, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              "HealthTech",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[500],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //page name
                Row(
                  children: [
                    Text(
                      "REGISTER PAGE",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                //full name textfield
                Row(
                  children: [
                    Text(
                      "Full Name",
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                MyTextfield(
                  controller: fullNameController,
                  hintText: "Full Name",
                  obsecureText: false,
                ),
                const SizedBox(height: 15),

                //full name textfield
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
                  hintText: "Email",
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
                  hintText: "******",
                  obsecureText: true,
                ),
                const SizedBox(height: 15),

                //confirm password
                Row(
                  children: [
                    Text(
                      "Confirm Password",
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                MyTextfield(
                  controller: confirmPasswordController,
                  hintText: "******",
                  obsecureText: true,
                ),

                const SizedBox(height: 15),

                //row textfield details
                Row(
                  children: [
                    //age textfield
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "Age",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),

                          MyTextfield(
                            controller: ageController,
                            hintText: "17",
                            obsecureText: false,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    //weight textfield
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "Weight (kgs)",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),

                          MyTextfield(
                            controller: weightController,
                            hintText: "62",
                            obsecureText: false,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    //height textfield
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "Height (cm)",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),

                          MyTextfield(
                            controller: heightController,
                            hintText: "162",
                            obsecureText: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                //login button
                MyButton(onTap: register, text: "SIGN UP"),

                const SizedBox(height: 15),

                //dont have an account?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? "),
                    GestureDetector(
                      onTap: widget.togglePages,
                      child: Text(
                        "Login Now",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
