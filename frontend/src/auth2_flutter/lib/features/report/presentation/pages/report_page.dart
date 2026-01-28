import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/info_cards.dart';
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
              Text("Health Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),),
              Text("Your health data overview and analysis", style: TextStyle(color: Colors.grey[700], fontSize: 15),),

              SizedBox(
                height: 150,
                child: GridView.count(crossAxisCount: 
                1, 
                scrollDirection: Axis.horizontal,
                mainAxisSpacing: 12,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  InfoCards(title:"Report Period", subtitle: "Nov 12 - Nov 19"),
                
                  InfoCards(title:"Generated On", subtitle: "Nov 19"),
                
                  InfoCards(title:"Goals Acheived", subtitle: "3/7 Days")
                ],),
              )
            ],
          ),
        ),
      ),
    );
  }
}
