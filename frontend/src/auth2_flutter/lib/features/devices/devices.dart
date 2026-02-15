import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';
import 'package:flutter/material.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
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
              Text(
                "Devices Management",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
              ),
              const SizedBox(height: 20),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,

                  children: [
                    SizedBox(
                      width: 250,
                      child: ElevatedButton(
                        onPressed: () {},
                        child: Text("Link Device by QR"),
                      ),
                    ),

                    SizedBox(
                      width: 250,
                      child: ElevatedButton(
                        onPressed: () {},
                        child: Text("Link Device by Bluetooth"),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text("This Device"),

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
                    // total value of steps this week
                    Text(
                      "iphone 14",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),

                    Text("Health IOS 1.0.1", style: TextStyle(fontSize: 15)),

                    Text(
                      "Kuala Lumpur, Malaysia · Online",
                      style: TextStyle(fontSize: 15),
                    ),

                    const SizedBox(height: 10),

                    // steps progress bar
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Text("Logs out all devices except for this one"),

              const SizedBox(height: 20),

              Text("Active Sessions"),

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
                    // total value of steps this week
                    Text(
                      "iphone 14",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),

                    Text("Health IOS 1.0.1", style: TextStyle(fontSize: 15)),

                    Text(
                      "Kuala Lumpur, Malaysia · Online",
                      style: TextStyle(fontSize: 15),
                    ),

                    const SizedBox(height: 10),

                    // steps progress bar
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
