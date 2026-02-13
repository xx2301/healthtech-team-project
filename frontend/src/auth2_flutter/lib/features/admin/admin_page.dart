import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:flutter/material.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DefaultAppBar(),
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(15.0), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Update Bar
            Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.black.withOpacity(0.06)),
    boxShadow: [
      BoxShadow(
        blurRadius: 20,
        offset: const Offset(0, 10),
        color: Colors.black.withOpacity(0.05),
      )
    ],
  ),
  child: Column(
    children: [
      // -------- Row 1 --------
      Row(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 18, color: Color(0xFF2F7D63)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'System Health',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All services OK',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.55),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.group_rounded,
                    size: 18, color: Color(0xFF2F7D63)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Users',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1,240 Total',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.55),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      const SizedBox(height: 14),

      // -------- Row 2 --------
      Row(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.security_rounded,
                    size: 18, color: Color(0xFF2F7D63)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Security',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '0 Open incidents',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.55),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sd_storage_rounded,
                    size: 18, color: Color(0xFF2F7D63)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Storage',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '68%',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.55),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: LinearProgressIndicator(
                                value: 0.68,
                                minHeight: 8,
                                backgroundColor:
                                    Colors.black.withOpacity(0.06),
                                valueColor:
                                    const AlwaysStoppedAnimation(
                                        Color(0xFF2F7D63)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  ),
),

// ================= USER & ACCESS =================
      const SizedBox(height: 8),

const Text(
  'User & Access',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
),
const SizedBox(height: 12),

// -------- User Management --------
Container(
  padding: const EdgeInsets.all(16),
  margin: const EdgeInsets.only(bottom: 12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.black.withOpacity(0.06)),
    boxShadow: [
      BoxShadow(
        blurRadius: 20,
        offset: const Offset(0, 10),
        color: Colors.black.withOpacity(0.05),
      )
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F2EC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person_add_alt_1_rounded,
                color: Color(0xFF2F7D63)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'User Management',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Manage users, passwords, lock accounts',
        style: TextStyle(
          color: Colors.black.withOpacity(0.6),
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 16),

SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.black.withOpacity(0.1)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Search Users', style: TextStyle(color: Colors.black),),
        ),
      ),
            const SizedBox(height: 10),

      // Buttons stacked vertically to prevent overflow
      SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2F7D63),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('+ Add User', style: TextStyle(color: Colors.white),),
        ),
      ),
      const SizedBox(height: 10),

      //add Doctors
      SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2F7D63),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('+ Add Doctor', style: TextStyle(color: Colors.white),),
        ),
      ),

const SizedBox(height: 10),
      //add admin
      SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2F7D63),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('+ Add Admin', style: TextStyle(color: Colors.white),),
        ),
      ),
      
      
    ],
  ),
),



// -------- Roles & Permissions --------
Container(
  padding: const EdgeInsets.all(16),
  margin: const EdgeInsets.only(bottom: 12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.black.withOpacity(0.06)),
    boxShadow: [
      BoxShadow(
        blurRadius: 20,
        offset: const Offset(0, 10),
        color: Colors.black.withOpacity(0.05),
      )
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F2EC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: Color(0xFF2F7D63)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Roles & Permissions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Manage roles & access',
        style: TextStyle(
          color: Colors.black.withOpacity(0.6),
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2F7D63),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('View Access Matrix', style: TextStyle(color: Colors.white),),
        ),
      ),
    ],
  ),
),

const Text(
  'Content & Config',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
),
const SizedBox(height: 12),

// -------- System Settings --------
Container(
  padding: const EdgeInsets.all(16),
  margin: const EdgeInsets.only(bottom: 12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.black.withOpacity(0.06)),
    boxShadow: [
      BoxShadow(
        blurRadius: 20,
        offset: const Offset(0, 10),
        color: Colors.black.withOpacity(0.05),
      )
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F2EC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.settings_suggest_rounded,
                color: Color(0xFF2F7D63)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'System Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Configure system settings & features',
        style: TextStyle(
          color: Colors.black.withOpacity(0.6),
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2F7D63),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('Manage Settings', style: TextStyle(color: Colors.white),),
        ),
      ),
    ],
  ),
),

// -------- Data & Integrations --------
Container(
  padding: const EdgeInsets.all(16),
  margin: const EdgeInsets.only(bottom: 12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.black.withOpacity(0.06)),
    boxShadow: [
      BoxShadow(
        blurRadius: 20,
        offset: const Offset(0, 10),
        color: Colors.black.withOpacity(0.05),
      )
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F2EC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.extension_rounded,
                color: Color(0xFF2F7D63)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Data & Integrations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Manage APIs & external services',
        style: TextStyle(
          color: Colors.black.withOpacity(0.6),
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2F7D63),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('Test Connection', style: TextStyle(color: Colors.white),),
        ),
      ),
    ],
  ),
),

],
        )),
      )
    );
  }
}