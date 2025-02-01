import 'package:flutter/material.dart';

class TeamMembersSection extends StatelessWidget {
  final List<String> selectedStudents;
  final VoidCallback onAddPressed;
  final Function(int) onRemovePressed;

  const TeamMembersSection({
    Key? key,
    required this.selectedStudents,
    required this.onAddPressed,
    required this.onRemovePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Team Members (${selectedStudents.length})',
                style: Theme.of(context).textTheme.titleSmall),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              onPressed: onAddPressed,
            ),
          ],
        ),
        if (selectedStudents.isNotEmpty)
          Card(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedStudents.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(selectedStudents[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => onRemovePressed(index),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
