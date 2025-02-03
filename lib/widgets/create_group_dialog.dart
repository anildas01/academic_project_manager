import 'package:flutter/material.dart';
import 'faculty_selection_dialog.dart';
import 'member_selection_dialog.dart';

class CreateGroupDialog extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final List<String> selectedStudents;
  final String selectedFaculty;
  final Function(List<String>) onStudentsSelected;
  final Function(String) onFacultySelected;
  final VoidCallback onSubmit;

  const CreateGroupDialog({
    super.key,
    required this.studentData,
    required this.selectedStudents,
    required this.selectedFaculty,
    required this.onStudentsSelected,
    required this.onFacultySelected,
    required this.onSubmit,
  });

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  List<String> selectedStudents = [];
  String selectedFaculty = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with widget values
    selectedStudents = List.from(widget.selectedStudents);
    selectedFaculty = widget.selectedFaculty;
  }

  @override
  void didUpdateWidget(CreateGroupDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update state when widget updates
    if (oldWidget.selectedStudents != widget.selectedStudents) {
      selectedStudents = List.from(widget.selectedStudents);
    }
    if (oldWidget.selectedFaculty != widget.selectedFaculty) {
      selectedFaculty = widget.selectedFaculty;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Explicit validation checks with debug prints
    bool hasStudents = selectedStudents.isNotEmpty;
    bool hasFaculty = selectedFaculty.isNotEmpty;
    bool isValid = hasStudents && hasFaculty;

    print('\n=== Create Group Button Debug ===');
    print(
        'Selected Students: ${selectedStudents.length} (Has Students: $hasStudents)');
    print('Selected Faculty: "$selectedFaculty" (Has Faculty: $hasFaculty)');
    print('Is Loading: $isLoading');
    print('Final Is Valid: $isValid');

    return Dialog(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width:
                constraints.maxWidth > 600 ? 500 : constraints.maxWidth * 0.9,
            height:
                constraints.maxHeight > 800 ? 600 : constraints.maxHeight * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header (fixed)
                Row(
                  children: [
                    const Icon(Icons.group_add, size: 28, color: Colors.purple),
                    const SizedBox(width: 12),
                    const Text(
                      'Create Project Group',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Department Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.school, color: Colors.purple),
                              const SizedBox(width: 12),
                              Text(
                                'Department: ${widget.studentData['department']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Team Members Section
                        Row(
                          children: [
                            const Text(
                              'Team Members',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _showMemberSelectionDialog(context),
                              icon: const Icon(Icons.person_add),
                              label: const Text('Add Members'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (selectedStudents.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: selectedStudents.map((email) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person,
                                          color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(email)),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Colors.red),
                                        onPressed: () {
                                          final newList = List<String>.from(
                                              selectedStudents)
                                            ..remove(email);
                                          setState(() {
                                            selectedStudents = newList;
                                          });
                                          widget.onStudentsSelected(newList);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'No team members selected',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Faculty Guide Section
                        Row(
                          children: [
                            const Text(
                              'Faculty Guide',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _showFacultySelectionDialog(context),
                              icon: const Icon(Icons.person_search),
                              label: const Text('Select Faculty'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (selectedFaculty.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(child: Text(selectedFaculty)),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      selectedFaculty = '';
                                    });
                                    widget.onFacultySelected('');
                                  },
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'No faculty guide selected',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Submit Button (fixed at bottom)
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedStudents.isNotEmpty &&
                            selectedFaculty.isNotEmpty
                        ? widget.onSubmit
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text('Create Group'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showMemberSelectionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true, // Allow closing by tapping outside
      builder: (context) => SelectMembersDialog(
        department: widget.studentData['department'],
        currentUserEmail: widget.studentData['email'],
        selectedMembers: selectedStudents, // Use local state
        onMembersSelected: (students) {
          setState(() {
            selectedStudents = students;
          });
          widget.onStudentsSelected(students);
        },
      ),
    );
  }

  Future<void> _showFacultySelectionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true, // Allow closing by tapping outside
      builder: (context) => SelectFacultyDialog(
        department: widget.studentData['department'],
        selectedFaculty: selectedFaculty, // Pass current selection
        onFacultySelected: (faculty) {
          setState(() {
            selectedFaculty = faculty;
          });
          widget.onFacultySelected(faculty);
        },
      ),
    );
  }

  String _generateGroupNumber() {
    // Generate a random 4-digit number
    return (1000 + DateTime.now().millisecond % 9000).toString();
  }
}
