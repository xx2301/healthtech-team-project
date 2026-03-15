import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';
import 'package:auth2_flutter/features/settings/pages/presentation/components/setting_tiles.dart';
import 'package:auth2_flutter/themes/main_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final user = context.watch<AuthCubit>().currentUser;

    return Scaffold(
      appBar: DefaultAppBar(),
      drawer: DefaultDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Color(0xFFB6D9B6), //soft green
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF4F7F4F),
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user?.fullName ?? 'User',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            '🌿',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        user != null
                            ? '${user.height ?? '?'} cm · ${user.weight ?? '?'} kg'
                            : 'Login to see details',
                        style: TextStyle(
                          fontSize: 13,
                          
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                "Account",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),

              SettingsTile(
                icon: Icons.person,
                title: 'Personal Information',
                isLinkTile: true,
                routeName: '/personalinfopage',
              ),

              SettingsTile(
                icon: Icons.flag,
                title: 'Health Goals',
                isLinkTile: true,
                routeName: '/goals',
              ),

              SettingsTile(
                icon: Icons.notifications,
                title: 'Notifications',
                isLinkTile: false,
                initialSwitchValue: true,
                onSwitchChanged: (val) {
                  // handle toggle
                },
              ),
              SettingsTile(
                icon: Icons.lock,
                title: 'Change Password',
                isLinkTile: true,
                routeName: '/change-password',
              ),

              const SizedBox(height: 10),

              Text(
                "Preferences",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),

              SettingsTile(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                isLinkTile: false,
                initialSwitchValue: Theme.of(context).brightness == Brightness.dark,
                onSwitchChanged: (val) {
                  themeNotifier.toggleTheme(val);
                },
              ),

              SettingsTile(
                icon: Icons.health_and_safety,
                title: 'Health Devices',
                isLinkTile: true,
                routeName: '/devicepage',
              ),

              SettingsTile(
                icon: Icons.warning,
                title: 'Health Alerts',
                isLinkTile: true,
                routeName: '/thresholds',
              ),

              SettingsTile(
                icon: Icons.scale,
                title: 'Measurement Unit',
                isLinkTile: true,
                routeName: '/homepage',
              ),

              SettingsTile(
                icon: Icons.language,
                title: 'Language',
                isLinkTile: true,
                routeName: '/homepage',
              ),

              const SizedBox(height: 10),

              Text(
                "Support",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),

              SettingsTile(
                icon: Icons.medical_services,
                title: 'Apply as Doctor',
                isLinkTile: true,
                routeName: '/apply-doctor',
              ),
              
              SettingsTile(
                icon: Icons.question_mark,
                title: 'Help',
                isLinkTile: true,
                routeName: '/homepage',
              ),
            ],
          ),
        ),
      ),
    );
  }
}