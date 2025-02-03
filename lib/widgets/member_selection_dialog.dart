import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectMembersDialog extends StatelessWidget {
  final String department;
  final String currentUserEmail;
  final List<String> selectedMembers;
  final Function(List<String>) onMembersSelected;

  // Add caching for students query
  final Stream<QuerySnapshot> _studentsStream;

  SelectMembersDialog({
    required this.department,
    required this.currentUserEmail,
    required this.selectedMembers,
    required this.onMembersSelected,
  }) : _studentsStream = FirebaseFirestore.instance
            .collection('students')
            .where('department', isEqualTo: department)
            .limit(20) // Limit initial load
            .snapshots()
            .asBroadcastStream();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(
        // Add responsive sizing
        builder: (context, constraints) {
          return Container(
            width:
                constraints.maxWidth > 600 ? 500 : constraints.maxWidth * 0.9,
            height:
                constraints.maxHeight > 800 ? 600 : constraints.maxHeight * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.group, size: 28, color: Colors.purple),
                    const SizedBox(width: 12),
                    const Text(
                      'Select Team Members',
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
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _studentsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final students = snapshot.data?.docs ?? [];
                      final filteredStudents = students
                          .where((doc) => doc['email'] != currentUserEmail)
                          .toList();

                      return ListView.builder(
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index].data()
                              as Map<String, dynamic>;
                          final email = student['email'] as String;
                          final isSelected = selectedMembers.contains(email);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Material(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.purple[100],
                                  child: Text(
                                    student['name'][0].toUpperCase(),
                                    style:
                                        const TextStyle(color: Colors.purple),
                                  ),
                                ),
                                title: Text(student['name']),
                                subtitle: Text(email),
                                trailing: Checkbox(
                                  value: isSelected,
                                  activeColor: Colors.purple,
                                  onChanged: (value) {
                                    List<String> newList =
                                        List.from(selectedMembers);
                                    if (value ?? false) {
                                      newList.add(email);
                                    } else {
                                      newList.remove(email);
                                    }
                                    onMembersSelected(newList);
                                    // Close dialog if maximum members reached
                                    if (newList.length >= 4) {
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                                onTap: () {
                                  // Toggle selection on row tap too
                                  List<String> newList =
                                      List.from(selectedMembers);
                                  if (!isSelected) {
                                    newList.add(email);
                                  } else {
                                    newList.remove(email);
                                  }
                                  onMembersSelected(newList);
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SelectFacultyDialog extends StatelessWidget {
  final String department;
  final Function(String) onFacultySelected;

  const _SelectFacultyDialog({
    required this.department,
    required this.onFacultySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_search, size: 28, color: Colors.purple),
                const SizedBox(width: 12),
                const Text(
                  'Select Faculty Guide',
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
            TextField(
              decoration: InputDecoration(
                hintText: 'Search faculty...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('faculty')
                    .where('department', isEqualTo: department)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final faculty = snapshot.data?.docs ?? [];

                  return ListView.builder(
                    itemCount: faculty.length,
                    itemBuilder: (context, index) {
                      final facultyMember =
                          faculty[index].data() as Map<String, dynamic>;
                      final email = facultyMember['email'] as String;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: Text(
                            facultyMember['name'][0].toUpperCase(),
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                        title: Text(facultyMember['name']),
                        subtitle: Text(email),
                        onTap: () {
                          onFacultySelected(email);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
