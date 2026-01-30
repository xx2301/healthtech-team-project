import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/bar_graph.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/info_cards.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/line_graph.dart';
import 'package:flutter/material.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
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
              // Page Title
              Text(
                "Health Report",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
              ),

              // Page Subtitle
              Text(
                "Your health data overview and analysis",
                style: TextStyle(color: Colors.grey[700], fontSize: 15),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 120,
                child: GridView.count(
                  crossAxisCount: 1,
                  scrollDirection: Axis.horizontal,
                  mainAxisSpacing: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  children: [
                    // Report Info Card Duration
                    InfoCards(
                      title: "Report Period",
                      subtitle: "Nov 12 - Nov 19",
                    ),

                    // Report Info Card Creation Date
                    InfoCards(title: "Generated On", subtitle: "Nov 19"),

                    // Report Info Card Goals Achieved
                    InfoCards(title: "Goals Acheived", subtitle: "3/7 Days"),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Steps Health Card
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

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Steps",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        // steps progress status
                        Container(
                          padding: EdgeInsets.only(left: 5, right: 5),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text("+5%"),
                        ),
                      ],
                    ),

                    // total value of steps this week
                    Text(
                      "36,841",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),

                    Text(
                      "Total steps this week",
                      style: TextStyle(fontSize: 10),
                    ),

                    const SizedBox(height: 10),

                    // steps progress bar
                    LinearProgressIndicator(
                      value: 0.75,
                      valueColor: AlwaysStoppedAnimation(Colors.green),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(12),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          children: [
                            // daily average steps
                            Text(
                              "5,263",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Daily Average",
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),

                        Column(
                          children: [
                            // total steps last week
                            Text(
                              "4,900",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text("Last Week", style: TextStyle(fontSize: 10)),
                          ],
                        ),

                        Column(
                          children: [
                            // total steps goal
                            Text(
                              "6,700",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text("Goal", style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // heart rate health card
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

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Heart Rate",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        // steps progress status
                        Container(
                          padding: EdgeInsets.only(left: 5, right: 5),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text("+10%"),
                        ),
                      ],
                    ),

                    // heart rate value
                    Text(
                      "72 BPM",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),

                    Text("Average heart rate", style: TextStyle(fontSize: 10)),

                    // heart rate line graph
                    SizedBox(height: 150, child: LineGraph()),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          children: [
                            Text(
                              "2,004",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Daily Average",
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),

                        Column(
                          children: [
                            Text(
                              "12,700",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text("Goal", style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

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

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Calories",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        // steps progress status
                        Container(
                          padding: EdgeInsets.only(left: 5, right: 5),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text("+10%"),
                        ),
                      ],
                    ),

                    Text(
                      "12,000",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),

                    Text(
                      "Active calories burned this week",
                      style: TextStyle(fontSize: 10),
                    ),

                    const SizedBox(height: 10),

                    // steps progress bar
                    LinearProgressIndicator(
                      value: 0.55,
                      valueColor: AlwaysStoppedAnimation(Colors.green),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(12),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          children: [
                            Text(
                              "2,004",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Daily Average",
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),

                        Column(
                          children: [
                            Text(
                              "8,900",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text("Last Week", style: TextStyle(fontSize: 10)),
                          ],
                        ),

                        Column(
                          children: [
                            Text(
                              "12,700",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text("Goal", style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

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

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Sleep",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        // steps progress status
                        Container(
                          padding: EdgeInsets.only(left: 5, right: 5),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text("-10%"),
                        ),
                      ],
                    ),

                    Text(
                      "72 Hours",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),

                    Text(
                      "Average resting rate",
                      style: TextStyle(fontSize: 10),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(height: 130, child: BarGraph()),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          children: [
                            Text(
                              "8 hours",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Daily Average",
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),

                        Column(
                          children: [
                            Text(
                              "71 Hours",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text("Last Week", style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Weekly Progress Summary Card
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

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Weekly Progress",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "3/7",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Text(
                          "Goals Achieved This Week",
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),

                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 223, 242, 250),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(20),
                        ),
                        border: Border(
                          left: BorderSide(
                            style: BorderStyle.solid,
                            width: 3,
                            color: Colors.blue,
                          ),
                        ),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Weekly Insight",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // Weekly Health Summary
                          Text(
                            "He knew what he was supposed to do. Tas supposed to do and what he would do were not the same. This would have been fine if he were willing to face the inevitable consequences, but he wasn't.",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
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
