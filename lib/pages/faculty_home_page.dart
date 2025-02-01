import 'package:flutter/material.dart';

class FacultyHomePage extends StatefulWidget {
  final Map<String, dynamic> facultyData;

  const FacultyHomePage({
    Key? key,
    required this.facultyData,
  }) : super(key: key);

  @override
  State<FacultyHomePage> createState() => _FacultyHomePageState();
}

class _FacultyHomePageState extends State<FacultyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // Show profile options dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Profile Options'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('View Profile'),
                        onTap: () {
                          // TODO: Implement view profile
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        onTap: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, ${widget.facultyData['name']}!',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Text('Email: ${widget.facultyData['email']}'),
            Text('Phone: ${widget.facultyData['phone']}'),
            // Add more faculty-specific widgets here
          ],
        ),
      ),
    );
  }
}
