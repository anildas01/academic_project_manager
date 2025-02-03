import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import '../widgets/side_menu.dart';
import '../widgets/notifications_panel.dart';

class FacultyHomePage extends StatefulWidget {
  final Map<String, dynamic> facultyData;

  const FacultyHomePage({
    super.key,
    required this.facultyData,
  });

  @override
  State<FacultyHomePage> createState() => _FacultyHomePageState();
}

class _FacultyHomePageState extends State<FacultyHomePage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 1200;

        return Scaffold(
          body: Column(
            children: [
              // Full-width Header Bar
              Container(
                width: double.infinity,
                color: Colors.purple,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                child: const Text(
                  'Academic Project Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Main Content Row
              Expanded(
                child: Row(
                  children: [
                    // Notifications Panel (Left)
                    if (isWide)
                      SizedBox(
                        width: 300,
                        child: NotificationsPanel(
                          userEmail: widget.facultyData['email'],
                          userType: 'faculty',
                          userData: widget.facultyData,
                          onCreateGroup: null,
                        ),
                      ),

                    // Main content (Center)
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          // Search Bar
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Search...',
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Content Area
                          Expanded(
                            child: Container(
                              color: Colors.grey[100],
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Assigned Groups',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(child: _buildGroupsList()),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right Profile Panel
                    if (isWide)
                      Container(
                        width: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            left: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Profile Section
                            Container(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.green[100],
                                    child: Text(
                                      widget.facultyData['name'][0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    widget.facultyData['name'],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    widget.facultyData['email'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.facultyData['department'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                            // No create group button for faculty
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          drawer: !isWide
              ? Drawer(
                  child: NotificationsPanel(
                    userEmail: widget.facultyData['email'],
                    userType: 'faculty',
                    userData: widget.facultyData,
                    onCreateGroup: null,
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildGroupsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('facultyGuide', isEqualTo: widget.facultyData['email'])
          // Remove status check to show all groups where faculty is guide
          //.where('facultyStatus', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Stream error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = snapshot.data?.docs ?? [];

        if (groups.isEmpty) {
          return const Center(
            child: Text('No groups assigned yet'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index].data() as Map<String, dynamic>;
            final List<dynamic> acceptedMembers =
                group['acceptedMembers'] ?? [];
            final String facultyStatus = group['facultyStatus'] ?? 'pending';
            final List<dynamic> allMembers = group['members'] ?? [];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(group['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Department: ${group['department']}'),
                    Text('Faculty Status: $facultyStatus'),
                    Text('Created by: ${group['creator']}'),
                    Text('All Members: ${allMembers.join(", ")}'),
                    Text('Accepted Members: ${acceptedMembers.join(", ")}'),
                  ],
                ),
                onTap: () {
                  // TODO: Navigate to group details page
                },
              ),
            );
          },
        );
      },
    );
  }
}
