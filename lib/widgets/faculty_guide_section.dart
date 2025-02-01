import 'package:flutter/material.dart';

class FacultyGuideSection extends StatelessWidget {
  final String selectedFaculty;
  final VoidCallback onAddPressed;
  final VoidCallback onRemovePressed;

  const FacultyGuideSection({
    Key? key,
    required this.selectedFaculty,
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
            Text('Faculty Guide',
                style: Theme.of(context).textTheme.titleSmall),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Select'),
              onPressed: selectedFaculty.isEmpty ? onAddPressed : null,
            ),
          ],
        ),
        if (selectedFaculty.isNotEmpty)
          Card(
            child: ListTile(
              title: Text(selectedFaculty),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: onRemovePressed,
              ),
            ),
          ),
      ],
    );
  }
}
