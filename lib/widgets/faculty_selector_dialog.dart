import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class FacultySelectorDialog extends StatefulWidget {
  final String department;
  final String selectedFaculty;
  final Function(String) onSelected;

  const FacultySelectorDialog({
    Key? key,
    required this.department,
    required this.selectedFaculty,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<FacultySelectorDialog> createState() => _FacultySelectorDialogState();
}

class _FacultySelectorDialogState extends State<FacultySelectorDialog> {
  final FirebaseService _firebaseService = FirebaseService();
  String _selectedFaculty = '';

  @override
  void initState() {
    super.initState();
    _selectedFaculty = widget.selectedFaculty;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Faculty Guide'),
      content: FutureBuilder<List<Map<String, dynamic>>>(
        future: _firebaseService.getAvailableFaculty(widget.department),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No faculty available'));
          }

          return SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
              child: Column(
                children: snapshot.data!.map((faculty) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: RadioListTile<String>(
                      title: Text(faculty['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${faculty['email']}'),
                          Text('Phone: ${faculty['phone']}'),
                          if (faculty['designation'] != null)
                            Text('Designation: ${faculty['designation']}'),
                        ],
                      ),
                      value: faculty['email'],
                      groupValue: _selectedFaculty,
                      onChanged: (value) {
                        setState(() {
                          _selectedFaculty = value!;
                        });
                        widget.onSelected(value!);
                        Navigator.pop(context, value);
                      },
                    ),
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
      ],
    );
  }
}
