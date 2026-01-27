import 'package:auth2_flutter/features/data/domain/entities/app_user.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/health_cards.dart';

import '../../../data/domain/presentation/cubits/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DefaultAppBar(),
      drawer: Drawer(
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
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Health Tech"),
              Row(
                children: [
                  Text("Good afternoon, "),

                  // app user name
                  Text("Lim"),
                ],
              ),

              const SizedBox(height: 10),

              //health details
              Row(
                children: [
                  Text("Health details"),
                  const SizedBox(width: 10),
                  Text("Health details"),
                ],
              ),

              const SizedBox(height: 20),

              //weather
              Text("Weather is Sunny, perfect for a walk!"),

              const SizedBox(height: 20),

              //progress header
              Text("Today’s Progress: 75%"),

              //steps progress bar
              LinearProgressIndicator(
                value: 0.75,
                valueColor: AlwaysStoppedAnimation(Colors.black),
              ),

              const SizedBox(height: 10),

              //progress report
              Text("Great! You’re close to hitting your step goal."),

              const SizedBox(height: 20),

              //Health Grid
              Text("My Health"),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true, // let it size to content
                physics:
                    const NeverScrollableScrollPhysics(), // disable its own scrolling

                //health cards    
                children: const [

                  //steps card
                   HealthCards(title: "Steps", icon: Icons.directions_walk, hasProgressCircle: true, value: 2000, unit: 'steps', progress: 0.7,),

                  //heart card
                  HealthCards(title: "Heart Rate", icon: Icons.monitor_heart, hasProgressCircle: false, value: 72, unit: 'bpm',),

                   //calories card
                  HealthCards(title: "Calories", icon: Icons.local_fire_department, hasProgressCircle: true, value: 342, unit: 'Kcal', progress: 0.5,),

                   //slee card
                  HealthCards(title: "Sleep", icon: Icons.bedtime, hasProgressCircle: true, value: 8, unit: 'hours', progress: 0.2,),


                 
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
