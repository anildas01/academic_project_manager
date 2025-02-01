import 'package:flutter/material.dart';

class GroupFormField extends StatelessWidget {
  final TextEditingController controller;

  const GroupFormField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Group Name',
        hintText: 'Enter your project group name',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a group name';
        }
        return null;
      },
    );
  }
}
