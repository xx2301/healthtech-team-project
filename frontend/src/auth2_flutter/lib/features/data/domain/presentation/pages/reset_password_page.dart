import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/my_button.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/my_textfield.dart';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_cubit.dart';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_states.dart';
import 'package:auth2_flutter/features/data/domain/presentation/pages/login.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? token;
  const ResetPasswordPage({super.key, this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      _tokenController.text = widget.token!;
    }
  }

  void _submit() {
    final token = _tokenController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (token.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showMessage('Please fill all fields');
      return;
    }
    if (password != confirm) {
      _showMessage('Passwords do not match');
      return;
    }

    context.read<AuthCubit>().resetPassword(token, password);
    print('New password: $password');
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is ResetPasswordSuccess) {
            _showMessage('Password reset successful! Redirecting to login...');
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => LoginPage(
                    togglePages: () {},
                  ),
                ),
              );
            });
          } else if (state is AuthError) {
            _showMessage('Error: ${state.message}');
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Enter the token from your email and your new password',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                MyTextfield(
                  controller: _tokenController,
                  hintText: 'Reset Token',
                  obsecureText: false,
                ),
                const SizedBox(height: 15),
                MyTextfield(
                  controller: _passwordController,
                  hintText: 'New Password',
                  obsecureText: true,
                ),
                const SizedBox(height: 15),
                MyTextfield(
                  controller: _confirmController,
                  hintText: 'Confirm Password',
                  obsecureText: true,
                ),
                const SizedBox(height: 30),
                MyButton(
                  onTap: _submit,
                  text: state is AuthLoading ? 'Resetting...' : 'Reset Password',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}