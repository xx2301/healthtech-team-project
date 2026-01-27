import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Appbar2 extends StatelessWidget implements PreferredSizeWidget {
  const Appbar2({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
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
      )
    ;
  }
  @override
  // TODO: implement preferredSize
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}