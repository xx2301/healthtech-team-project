import 'package:auth2_flutter/features/data/domain/presentation/components/appbar2.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/goal_chips.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/header_title.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/my_button.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/my_textfield.dart';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_cubit.dart';
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
  Set<String> selectedGoals = {};

  //focusnode for enter key navigation
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();
  final FocusNode ageFocusNode = FocusNode();
  final FocusNode weightFocusNode = FocusNode();
  final FocusNode heightFocusNode = FocusNode();

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
    confirmPasswordController.dispose();
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();

    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    ageFocusNode.dispose();
    weightFocusNode.dispose();
    heightFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Appbar2(),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //page name
                Row(
                  children: [
                    Text(
                      "REGISTER PAGE",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                HeaderTitle(text: "Full Name"),
                //full name textfield
                MyTextfield(
                  controller: fullNameController,
                  hintText: "Joseph Wong",
                  obsecureText: false,
                  textInputAction: TextInputAction.next,
                  onSubmitted: () {
                    FocusScope.of(context).requestFocus(emailFocusNode);
                  },
                ),
                const SizedBox(height: 15),

                HeaderTitle(text: "Email"),
                //email textfield
                MyTextfield(
                  controller: emailController,
                  hintText: "josephw@gmail.com",
                  obsecureText: false,
                  focusNode: emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onSubmitted: () {
                    FocusScope.of(context).requestFocus(passwordFocusNode);
                  },
                ),

                const SizedBox(height: 15),

                HeaderTitle(text: "Password"),
                //password textfield
                MyTextfield(
                  controller: passwordController,
                  hintText: "*******",
                  obsecureText: true,
                  focusNode: passwordFocusNode,
                  textInputAction: TextInputAction.next,
                  onSubmitted: () {
                    FocusScope.of(
                      context,
                    ).requestFocus(confirmPasswordFocusNode);
                  },
                ),
                const SizedBox(height: 15),

                HeaderTitle(text: "Confirm Password"),
                //confirm password
                MyTextfield(
                  controller: confirmPasswordController,
                  hintText: "*******",
                  obsecureText: true,
                  focusNode: confirmPasswordFocusNode,
                  textInputAction: TextInputAction.next,
                  onSubmitted: () {
                    FocusScope.of(context).requestFocus(ageFocusNode);
                  },
                ),

                const SizedBox(height: 15),

                //row textfield details
                Row(
                  children: [
                    // AGE
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HeaderTitle(text: "Age"),
                          const SizedBox(height: 6),
                          MyTextfield(
                            controller: ageController,
                            hintText: "17yrs",
                            obsecureText: false,
                            focusNode: ageFocusNode,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            onSubmitted: () {
                              FocusScope.of(
                                context,
                              ).requestFocus(weightFocusNode);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // WEIGHT
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HeaderTitle(text: "Weight (kgs)"),
                          const SizedBox(height: 6),
                          MyTextfield(
                            controller: weightController,
                            hintText: "62",
                            obsecureText: false,
                            focusNode: weightFocusNode,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            onSubmitted: () {
                              FocusScope.of(
                                context,
                              ).requestFocus(heightFocusNode);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // HEIGHT
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HeaderTitle(text: "Height (cm)"),
                          const SizedBox(height: 6),
                          MyTextfield(
                            controller: heightController,
                            hintText: "180",
                            obsecureText: false,
                            focusNode: heightFocusNode,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onSubmitted: register,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                HeaderTitle(text: "Health Goals"),
                const SizedBox(height: 5),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 5,
                  children: [
                    GoalChip(
                      label: "Weight Loss",
                      isSelected: selectedGoals.contains("Weight Loss"),
                      onTap: () {
                        setState(() {
                          if (selectedGoals.contains("Weight Loss")) {
                            selectedGoals.remove("Weight Loss");
                          } else {
                            selectedGoals.add("Weight Loss");
                          }
                        });
                      },
                    ),

                    GoalChip(
                      label: "Muscle Gain",
                      isSelected: selectedGoals.contains("Muscle Gain"),
                      onTap: () {
                        setState(() {
                          if (selectedGoals.contains("Muscle Gain")) {
                            selectedGoals.remove("Muscle Gain");
                          } else {
                            selectedGoals.add("Muscle Gain");
                          }
                        });
                      },
                    ),

                    GoalChip(
                      label: "Maintain Weight",
                      isSelected: selectedGoals.contains("Maintain Weight"),
                      onTap: () {
                        setState(() {
                          if (selectedGoals.contains("Maintain Weight")) {
                            selectedGoals.remove("Maintain Weight");
                          } else {
                            selectedGoals.add("Maintain Weight");
                          }
                        });
                      },
                    ),

                    GoalChip(
                      label: "Improve Fitness",
                      isSelected: selectedGoals.contains("Improve Fitness"),
                      onTap: () {
                        setState(() {
                          if (selectedGoals.contains("Improve Fitness")) {
                            selectedGoals.remove("Improve Fitness");
                          } else {
                            selectedGoals.add("Improve Fitness");
                          }
                        });
                      },
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
