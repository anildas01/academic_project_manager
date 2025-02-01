import 'package:flutter/material.dart';
import 'firebase_service.dart';

class GroupCreationService {
  static Future<bool> validateAndCreateGroup({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required String groupName,
    required String creatorEmail,
    required List<String> selectedStudents,
    required String selectedFaculty,
    required String department,
    required int semester,
  }) async {
    if (!formKey.currentState!.validate()) return false;

    if (selectedStudents.isEmpty) {
      _showError(context, 'Please select team members');
      return false;
    }

    if (selectedFaculty.isEmpty) {
      _showError(context, 'Please select a faculty guide');
      return false;
    }

    try {
      final success = await FirebaseService().createProjectGroup(
        groupName: groupName,
        creatorEmail: creatorEmail,
        memberEmails: selectedStudents,
        facultyEmail: selectedFaculty,
        department: department,
        semester: semester,
      );

      if (success) {
        _showSuccess(context, 'Group created successfully');
      } else {
        _showError(context, 'Failed to create group');
      }

      return success;
    } catch (e) {
      _showError(context, 'Error: $e');
      return false;
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  static void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
