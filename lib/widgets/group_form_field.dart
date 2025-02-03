import 'package:flutter/material.dart';

class GroupFormField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const GroupFormField({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Group Name',
        hintText: 'Enter your project group name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.group),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a group name';
        }
        return null;
      },
      onChanged: onChanged,
    );
  }
}
