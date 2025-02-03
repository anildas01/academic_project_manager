import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class StudentSelectorDialog extends StatefulWidget {
  final String department;
  final Set<String> selectedStudents;
  final Function(Set<String>) onSelectionChanged;

  const StudentSelectorDialog({
    super.key,
    required this.department,
    required this.selectedStudents,
    required this.onSelectionChanged,
  });

  @override
  State<StudentSelectorDialog> createState() => _StudentSelectorDialogState();
}

class _StudentSelectorDialogState extends State<StudentSelectorDialog> {
  final FirebaseService _firebaseService = FirebaseService();
  Set<String> _selectedStudents = {};

  @override
  void initState() {
    super.initState();
    _selectedStudents = widget.selectedStudents;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Team Members'),
      content: FutureBuilder<Map<int, List<Map<String, dynamic>>>>(
        future:
            _firebaseService.getAvailableStudentsBySemester(widget.department),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No students available'));
          }

          List<int> semesters = snapshot.data!.keys.toList()..sort();
          return SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
              child: Column(
                children: semesters.map((semester) {
                  var students = snapshot.data![semester]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Semester $semester',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...students.map((student) => CheckboxListTile(
                            title: Text(student['name']),
                            subtitle: Text(student['email']),
                            value: _selectedStudents.contains(student['email']),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedStudents.add(student['email']);
                                } else {
                                  _selectedStudents.remove(student['email']);
                                }
                              });
                              widget.onSelectionChanged(_selectedStudents);
                            },
                          )),
                      const Divider(),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedStudents.isNotEmpty
              ? () => Navigator.pop(context, _selectedStudents.toList())
              : null,
          child: Text('Select (${_selectedStudents.length})'),
        ),
      ],
    );
  }
}
