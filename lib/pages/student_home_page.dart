import 'package:flutter/material.dart';
import '/widgets/student_selector_dialog.dart';
import '/widgets/faculty_selector_dialog.dart';

class StudentHomePage extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const StudentHomePage({
    Key? key,
    required this.studentData,
  }) : super(key: key);

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  String selectedDepartment = 'Computer Science and Engineering';
  String selectedYear = '2022';
  List<String> selectedStudents = [];
  String selectedFaculty = '';

  final List<String> departments = [
    'Computer Science and Engineering',
    'Mechanical Engineering',
    'Electrical Engineering',
    // Add more departments
  ];

  final List<String> years = [
    '2022',
    '2023',
    '2024',
    // Add more years
  ];

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Project Group'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Department Dropdown
              DropdownButtonFormField<String>(
                value: selectedDepartment,
                decoration: const InputDecoration(
                  labelText: 'Department',
                ),
                items: departments.map((String department) {
                  return DropdownMenuItem(
                    value: department,
                    child: Text(department),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedDepartment = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Year Dropdown
              DropdownButtonFormField<String>(
                value: selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Year',
                ),
                items: years.map((String year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedYear = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  // Show available students
                  _showAvailableStudents();
                },
                child: const Text('Select Team Members'),
              ),
              const SizedBox(height: 8),

              ElevatedButton(
                onPressed: () {
                  // Show available faculty
                  _showAvailableFaculty();
                },
                child: const Text('Select Faculty Guide'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: selectedStudents.isNotEmpty && selectedFaculty.isNotEmpty
                ? () {
                    _createGroup();
                    Navigator.pop(context);
                  }
                : null,
            child: const Text('Create Group'),
          ),
        ],
      ),
    );
  }

  void _showAvailableStudents() {
    showDialog(
      context: context,
      builder: (context) => StudentSelectorDialog(
        department: selectedDepartment,
        selectedStudents: Set<String>.from(selectedStudents),
        onSelectionChanged: (newSelection) {
          setState(() {
            selectedStudents = newSelection.toList();
          });
        },
      ),
    );
  }

  void _showAvailableFaculty() {
    showDialog(
      context: context,
      builder: (context) => FacultySelectorDialog(
        department: selectedDepartment,
        selectedFaculty: selectedFaculty,
        onSelected: (value) {
          setState(() {
            selectedFaculty = value;
          });
        },
      ),
    );
  }

  Future<void> _createGroup() async {
    // TODO: Implement group creation in Firebase
    // This should:
    // 1. Create a new group document
    // 2. Send invitations to selected students
    // 3. Send request to selected faculty
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // TODO: Navigate to profile page
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
              'Welcome, ${widget.studentData['name']}!',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Text('Email: ${widget.studentData['email']}'),
            Text('Phone: ${widget.studentData['phone']}'),
            // Add more student-specific widgets here
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        label: const Text('Create Group'),
        icon: const Icon(Icons.group_add),
      ),
    );
  }
}
