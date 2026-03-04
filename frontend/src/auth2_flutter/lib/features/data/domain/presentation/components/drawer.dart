import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_cubit.dart';

class DefaultDrawer extends StatelessWidget {
  const DefaultDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().currentUser;
    final bool canAccessPatients = (user?.role == 'doctor' || user?.role == 'admin' || user?.role == 'super_admin');

    return Drawer(
        child: Column(
          children: [
            // common to place a drawer header here
            DrawerHeader(
              child: Icon(Icons.favorite, size: 48), // Icon
            ), // DrawerHeader
            // home page list tile
            ListTile(
              leading: Icon(Icons.home),
              title: Text("H O M E"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/homepage');
              },
            ), // ListTile
            // settings page list title
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("S E T T I N G S"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settingspage');
              },
            ),

            // report page list title
            ListTile(
              leading: Icon(Icons.analytics),
              title: Text("R E P O R T"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/reportpage');
              },
            ), // ListTile
            // chat page list title
            ListTile(
              leading: Icon(Icons.chat),
              title: Text("C H A T "),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/chatpage');
              },
            ),

            if (canAccessPatients)
              ListTile(
                leading: Icon(Icons.people),
                title: Text("P A T I E N T "),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/patientpage');
                },
              ),

            ListTile(
              leading: Icon(Icons.computer),
              title: Text("D E V I C E S "),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/devicepage');
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('L O G O U T'),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthCubit>().logout();
              },
            ),
          ],
        ),
      );
  }
}