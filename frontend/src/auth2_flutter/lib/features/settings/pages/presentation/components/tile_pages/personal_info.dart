import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';
import 'package:flutter/material.dart';

class PersonalInfo extends StatefulWidget {
  const PersonalInfo({super.key});

  @override
  State<PersonalInfo> createState() => _PersonalInfoState();
}

class _PersonalInfoState extends State<PersonalInfo> {
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
                "Personal Information",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
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
                          "Joseph Wong",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      
                      Icon(Icons.edit)],
                    ),

const SizedBox(height: 10),


                        Text(
                          "Gender: Male",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),

const SizedBox(height: 5),

                        Text(
                          "Age: 19 years old",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      
                    
const SizedBox(height: 10),


                   Text(
                          "Weight: 62kgs",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                    

                    Text(
                      "Last Updated 1st March",
                      style: TextStyle(fontSize: 13),
                    ),

              const SizedBox(height: 10),

                    Text(
                          "Height: 170cm",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),

                    Text(
                      "Last Updated 1st March",
                      style: TextStyle(fontSize: 13),
                    ),
                  ]
                )
              ),

         const SizedBox(height: 10),
Container(
                width: double.infinity,
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
                          "Medical Record",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      
                      Icon(Icons.edit)],
                    ),

const SizedBox(height: 10),

Text(
                          "Doctor: Guru Priya",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),

const SizedBox(height: 5),

                        Text(
                          "Last Doctor Visit: 19/11/2022 ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),

const SizedBox(height: 10),

                   Text(
                          "Average Heart Rate: 70bpm",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                    

                    Text(
                      "Last Updated 1st March",
                      style: TextStyle(fontSize: 13),
                    ),

              const SizedBox(height: 10),

                    Text(
                          "Average Daily Steps: 8000",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),

                    Text(
                      "Last Updated 1st March",
                      style: TextStyle(fontSize: 13),
                    ),

                    const SizedBox(height: 10),

                    Text(
                          "Average Sleep Duration: 7 hours",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),

                    Text(
                      "Last Updated 1st March",
                      style: TextStyle(fontSize: 13),
                    ),
                  ]
                )
              ),

              
              
              ]))));
  }
}