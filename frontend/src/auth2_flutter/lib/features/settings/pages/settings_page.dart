import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';
import 'package:auth2_flutter/features/settings/pages/presentation/components/setting_tiles.dart';
import 'package:auth2_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: Color(0xFFB6D9B6), // soft green
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
                'Lim',
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
            '162 cm · 42kg',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
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
                title: 'Aims',
                isLinkTile: true,
                routeName: '/homepage',
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
  initialSwitchValue: themeNotifier.value == ThemeMode.dark,
  onSwitchChanged: (val) {
    themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
  },
),


              SettingsTile(
                icon: Icons.phone_android,
                title: 'Device Management',
                isLinkTile: true,
                routeName: '/devicepage',
              ),

              SettingsTile(
                icon: Icons.bar_chart,
                title: 'Unit',
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
