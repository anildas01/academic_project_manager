import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import '../widgets/side_menu.dart';
import '../widgets/notifications_panel.dart';
import '../widgets/create_group_dialog.dart';

class StudentHomePage extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const StudentHomePage({
    super.key,
    required this.studentData,
  });

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  List<String> selectedStudents = [];
  String selectedFaculty = '';
  bool isLoading = false;

  // Cache streams
  late final Stream<QuerySnapshot> _groupsStream;
  late final Stream<QuerySnapshot> _notificationsStream;

  @override
  void initState() {
    super.initState();
    // Initialize streams with proper error handling
    try {
      _groupsStream = FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: widget.studentData['email'])
          // Remove this line since we want to show all groups
          //.where('acceptedMembers', arrayContains: widget.studentData['email'])
          .limit(10)
          .snapshots()
          .asBroadcastStream();

      _notificationsStream = FirebaseFirestore.instance
          .collection('notifications')
          .where('recipient', isEqualTo: widget.studentData['email'])
          .snapshots()
          .asBroadcastStream();
    } catch (e) {
      print('Error initializing streams: $e');
    }
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateGroupDialog(
        studentData: widget.studentData,
        selectedStudents: selectedStudents,
        selectedFaculty: selectedFaculty,
        onStudentsSelected: (students) {
          setState(() => selectedStudents = students);
        },
        onFacultySelected: (faculty) {
          setState(() => selectedFaculty = faculty);
        },
        onSubmit: () => _createGroup(context),
      ),
    );
  }

  Future<void> _selectStudents(StateSetter setState) async {
    try {
      print(
          'Fetching students for department: ${widget.studentData['department']}');

      // First, check if the collection exists and has documents
      final collectionRef = FirebaseFirestore.instance.collection('students');
      final checkQuery = await collectionRef.limit(1).get();

      if (checkQuery.docs.isEmpty) {
        print('Students collection is empty');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No students found in the database'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Fetch students from the same department, excluding the current user
      final QuerySnapshot studentsSnapshot = await collectionRef
          .where('department', isEqualTo: widget.studentData['department'])
          .get();

      print('Found ${studentsSnapshot.docs.length} students in department');

      if (!mounted) return;

      // Filter out the current user from the results
      final filteredDocs = studentsSnapshot.docs
          .where((doc) => doc['email'] != widget.studentData['email'])
          .toList();

      if (filteredDocs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No other students found in your department'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Create a temporary list to hold selections
      List<String> tempSelectedStudents = List.from(selectedStudents);

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Team Members'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Column(
              children: [
                const Text('Maximum 3 members allowed',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final studentDoc = filteredDocs[index];
                      final studentData =
                          studentDoc.data() as Map<String, dynamic>;
                      final email =
                          studentData['email'] as String? ?? 'No email';
                      final name = studentData['name'] as String? ?? 'No name';

                      return CheckboxListTile(
                        title: Text(name),
                        subtitle: Text(email),
                        value: tempSelectedStudents.contains(email),
                        onChanged: (tempSelectedStudents.length < 3 ||
                                tempSelectedStudents.contains(email))
                            ? (bool? value) {
                                if (value == true &&
                                    tempSelectedStudents.length < 3) {
                                  setState(() {
                                    tempSelectedStudents.add(email);
                                  });
                                } else if (value == false) {
                                  setState(() {
                                    tempSelectedStudents.remove(email);
                                  });
                                }
                              }
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedStudents = tempSelectedStudents;
                });
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );

      print('Final selected students: $selectedStudents');
    } catch (e, stackTrace) {
      print('Error selecting students: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading students: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectFaculty(StateSetter setState) async {
    try {
      final QuerySnapshot facultySnapshot = await FirebaseFirestore.instance
          .collection('faculty')
          .where('department', isEqualTo: widget.studentData['department'])
          .get();

      if (!mounted) return;

      if (facultySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No faculty members found in your department'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Faculty Guide'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: facultySnapshot.docs.length,
              itemBuilder: (context, index) {
                final faculty =
                    facultySnapshot.docs[index].data() as Map<String, dynamic>;
                final email = faculty['email'] as String;
                final name = faculty['name'] as String;

                return ListTile(
                  title: Text(name),
                  subtitle: Text(email),
                  onTap: () {
                    setState(() => selectedFaculty = email);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error selecting faculty: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading faculty members: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createGroup(BuildContext context) async {
    setState(() => isLoading = true);
    try {
      final groupNumber = (1000 + DateTime.now().millisecond % 9000).toString();
      final groupName = 'Group-$groupNumber';

      // Create group first to get the group ID
      final groupRef =
          await FirebaseFirestore.instance.collection('groups').add({
        'name': groupName,
        'department': widget.studentData['department'],
        'creator': widget.studentData['email'],
        'members': [widget.studentData['email'], ...selectedStudents],
        'acceptedMembers': [widget.studentData['email']],
        'facultyGuide': selectedFaculty,
        'facultyStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Send notifications with group ID
      await NotificationService.sendGroupInvitation(
        memberEmails: selectedStudents,
        facultyEmail: selectedFaculty,
        groupName: groupName,
        creatorName: widget.studentData['name'],
        department: widget.studentData['department'],
        groupId: groupRef.id, // Pass the group ID
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('$groupName created and invitations sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildGroupsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _groupsStream,
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
            child: Text('No groups yet'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index].data() as Map<String, dynamic>;
            final List<dynamic> acceptedMembers =
                group['acceptedMembers'] ?? [];
            final bool isAccepted =
                acceptedMembers.contains(widget.studentData['email']);
            final List<dynamic> allMembers = group['members'] ?? [];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(group['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Department: ${group['department']}'),
                    Text('Status: ${isAccepted ? "Accepted" : "Pending"}'),
                    Text('Faculty Guide: ${group['facultyGuide']}'),
                    Text('All Members: ${allMembers.join(", ")}'),
                    Text('Accepted Members: ${acceptedMembers.join(", ")}'),
                  ],
                ),
                trailing: group['creator'] == widget.studentData['email']
                    ? const Icon(Icons.star, color: Colors.amber)
                    : null,
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
                          userEmail: widget.studentData['email'],
                          userType: 'student',
                          userData: widget.studentData,
                          onCreateGroup: _showCreateGroupDialog,
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
                                    'Your Groups',
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

                    // Profile Panel (Right)
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
                                    backgroundColor: Colors.purple[100],
                                    child: Text(
                                      widget.studentData['name'][0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    widget.studentData['name'],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    widget.studentData['email'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.studentData['department'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                            const Spacer(),
                            // Create Group Button
                            Container(
                              padding: const EdgeInsets.all(16),
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _showCreateGroupDialog,
                                icon: const Icon(Icons.group_add),
                                label: const Text('Create Group'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  backgroundColor: Colors.purple,
                                ),
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
          // Mobile drawer with notifications
          drawer: !isWide
              ? Drawer(
                  child: NotificationsPanel(
                    userEmail: widget.studentData['email'],
                    userType: 'student',
                    userData: widget.studentData,
                    onCreateGroup: _showCreateGroupDialog,
                  ),
                )
              : null,
        );
      },
    );
  }
}
