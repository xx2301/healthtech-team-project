import 'package:auth2_flutter/features/data/domain/entities/app_user.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';
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
      drawer: DefaultDrawer(),
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
              Text(
                "My Health",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
              ),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true, // let it size to content
                physics:
                    const NeverScrollableScrollPhysics(), // disable its own scrolling
                //health cards
                children: [
                  //steps card
                  HealthCards(
                    title: "Steps",
                    icon: Icons.directions_walk,
                    hasProgressCircle: true,
                    value: 2000,
                    unit: 'steps',
                    progress: 0.7,
                  ),

                  //heart card
                  HealthCards(
                    title: "Heart Rate",
                    icon: Icons.monitor_heart,
                    hasProgressCircle: false,
                    value: 72,
                    unit: 'bpm',
                  ),

                  //calories card
                  HealthCards(
                    title: "Calories",
                    icon: Icons.local_fire_department,
                    hasProgressCircle: true,
                    value: 342,
                    unit: 'Kcal',
                    progress: 0.5,
                  ),

                  //sleep card
                  HealthCards(
                    title: "Sleep",
                    icon: Icons.bedtime,
                    hasProgressCircle: true,
                    value: 8,
                    unit: 'hours',
                    progress: 0.2,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "My Progress",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                  ),

                  // view more button -> report page
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/reportpage');
                    },
                    child: Text("View All >"),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Goal card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Weekly Goals",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        Text(
                          "Last 7 days",
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                          textAlign: TextAlign.left,
                        ),

                        Center(
                          child: Column(
                            children: [
                              Text(
                                "3/7",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),

                              Text(
                                "Achieved",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(width: 12),

                    // week goal progression

                    Row(
                      children: [
                        Column(
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            Text("Mon", style: TextStyle(fontSize: 10)),
                          ],
                        ),

                        SizedBox(width: 5),

                        Column(
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            Text("Tues", style: TextStyle(fontSize: 10)),
                          ],
                        ),

                        SizedBox(width: 5),

                        Column(
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            Text("Wed", style: TextStyle(fontSize: 10)),
                          ],
                        ),

                        SizedBox(width: 5),

                        Column(
                          children: [
                            Icon(
                              Icons.watch_later_outlined,
                              color: Colors.yellow,
                            ),
                            Text("Thurs", style: TextStyle(fontSize: 10)),
                          ],
                        ),

                        SizedBox(width: 5),

                        Column(
                          children: [
                            Icon(
                              Icons.watch_later_outlined,
                              color: Colors.yellow,
                            ),
                            Text("Fri", style: TextStyle(fontSize: 10)),
                          ],
                        ),

                        SizedBox(width: 5),

                        Column(
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            Text("Sat", style: TextStyle(fontSize: 10)),
                          ],
                        ),

                        SizedBox(width: 5),

                        Column(
                          children: [
                            Icon(Icons.close, color: Colors.red),
                            Text("Sun", style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // sleep progression card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sleep Duration",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        Text(
                          "Last 7 days",
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                          textAlign: TextAlign.left,
                        ),

                        Center(
                          child: Column(
                            children: [
                              Text(
                                "3/7",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                "Achieved",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(width: 12),

                    // sleep progress per day 

                    Row(
                      children: [
                        Column(
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            Text("Mon", style: TextStyle(fontSize: 10)),
                          ],
                        ),

                        SizedBox(width: 5),

                        Column(
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            Text("Tues", style: TextStyle(fontSize: 10)),
                          ],
                        ),

                        SizedBox(width: 5),

                        Column(
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            Text("Wed", style: TextStyle(fontSize: 10)),
                          ],
                        ),

                        SizedBox(width: 5),

                        Column(
                          children: [
                            Icon(
                              Icons.watch_later_outlined,
                              color: Colors.yellow,
                            ),
                            Text("Thurs", style: TextStyle(fontSize: 10)),
                          ],
                        ),

                        SizedBox(width: 5),

                        Column(
                          children: [
                            Icon(
                              Icons.watch_later_outlined,
                              color: Colors.yellow,
                            ),
                            Text("Fri", style: TextStyle(fontSize: 10)),
                          ],
                        ),

                        SizedBox(width: 5),

                        Column(
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            Text("Sat", style: TextStyle(fontSize: 10)),
                          ],
                        ),

                        SizedBox(width: 5),

                        Column(
                          children: [
                            Icon(Icons.close, color: Colors.red),
                            Text("Sun", style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
