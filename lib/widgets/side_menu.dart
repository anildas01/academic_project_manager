import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final String userType; // 'student' or 'faculty'
  final Map<String, dynamic> userData;
  final VoidCallback onCreateGroup;

  const SideMenu({
    super.key,
    required this.userType,
    required this.userData,
    required this.onCreateGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          // Logo/Brand
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  userType == 'student' ? Icons.school : Icons.person_2,
                  color: Colors.purple,
                  size: 32,
                ),
                const SizedBox(width: 8),
                const Text(
                  'COURSUE',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Overview Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'OVERVIEW',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Menu Items (removed create group and groups)
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Scaffold.of(context).openDrawer();
            },
          ),

          const Spacer(),

          // Settings and Logout at bottom
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
