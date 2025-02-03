import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectFacultyDialog extends StatelessWidget {
  final String department;
  final Function(String) onFacultySelected;
  final Stream<QuerySnapshot> _facultyStream;
  final String selectedFaculty;

  SelectFacultyDialog({
    required this.department,
    required this.onFacultySelected,
    required this.selectedFaculty,
  }) : _facultyStream = FirebaseFirestore.instance
            .collection('faculty')
            .where('department', isEqualTo: department)
            .limit(20)
            .snapshots()
            .asBroadcastStream();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(
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
                    const Icon(Icons.person_search,
                        size: 28, color: Colors.purple),
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
                    stream: _facultyStream,
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
                            trailing: Radio<String>(
                              value: email,
                              groupValue: selectedFaculty,
                              activeColor: Colors.green,
                              onChanged: (String? value) {
                                if (value != null) {
                                  onFacultySelected(value);
                                  Navigator.pop(context);
                                }
                              },
                            ),
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
          );
        },
      ),
    );
  }
}
