import 'package:flutter/material.dart';
import 'group_form_field.dart';
import 'team_members_section.dart';
import 'faculty_guide_section.dart';
import 'student_selector_dialog.dart';
import 'faculty_selector_dialog.dart';
import 'dialog_action_buttons.dart';
import '../services/group_creation_service.dart';

class CreateGroupDialog extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const CreateGroupDialog({
    Key? key,
    required this.studentData,
  }) : super(key: key);

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  List<String> selectedStudents = [];
  String selectedFaculty = '';
  bool isLoading = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Project Group'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GroupFormField(controller: _groupNameController),
              const SizedBox(height: 16),
              Text('Department: ${widget.studentData['department']}',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              TeamMembersSection(
                selectedStudents: selectedStudents,
                onAddPressed: _showAvailableStudents,
                onRemovePressed: (index) {
                  setState(() {
                    selectedStudents.removeAt(index);
                  });
                },
              ),
              FacultyGuideSection(
                selectedFaculty: selectedFaculty,
                onAddPressed: _showAvailableFaculty,
                onRemovePressed: () {
                  setState(() {
                    selectedFaculty = '';
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        DialogActionButtons(
          isLoading: isLoading,
          onCancel: () => Navigator.pop(context),
          onCreate: _createGroup,
        ),
      ],
    );
  }

  void _showAvailableStudents() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => StudentSelectorDialog(
        department: widget.studentData['department'],
        selectedStudents: Set<String>.from(selectedStudents),
        onSelectionChanged: (newSelection) {
          setState(() {
            selectedStudents = newSelection.toList();
          });
        },
      ),
    );

    if (result != null) {
      setState(() {
        selectedStudents = result;
      });
    }
  }

  void _showAvailableFaculty() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => FacultySelectorDialog(
        department: widget.studentData['department'],
        selectedFaculty: selectedFaculty,
        onSelected: (value) {
          setState(() {
            selectedFaculty = value;
          });
        },
      ),
    );

    if (result != null) {
      setState(() {
        selectedFaculty = result;
      });
    }
  }

  Future<void> _createGroup() async {
    setState(() {
      isLoading = true;
    });

    final success = await GroupCreationService.validateAndCreateGroup(
      context: context,
      formKey: _formKey,
      groupName: _groupNameController.text,
      creatorEmail: widget.studentData['email'],
      selectedStudents: selectedStudents,
      selectedFaculty: selectedFaculty,
      department: widget.studentData['department'],
      semester: widget.studentData['semester'],
    );

    if (success) {
      Navigator.pop(context);
    }

    setState(() {
      isLoading = false;
    });
  }
}
