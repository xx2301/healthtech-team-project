import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/my_button.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/my_textfield.dart';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_cubit.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  void _submit() async {
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

    try {
      await context.read<AuthCubit>().resetPassword(token, password);
      _showMessage('Password reset successful! Redirecting to login...');
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
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
            MyButton(onTap: _submit, text: 'Reset Password'),
          ],
        ),
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