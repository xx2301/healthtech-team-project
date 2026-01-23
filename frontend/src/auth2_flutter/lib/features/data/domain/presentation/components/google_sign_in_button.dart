import 'package:flutter/material.dart';

class MyGoogleSignInButton extends StatelessWidget {
  const MyGoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white)
      ),
    );
  }
}
