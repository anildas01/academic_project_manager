import 'package:flutter/material.dart';

class DialogActionButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onCreate;

  const DialogActionButtons({
    Key? key,
    required this.isLoading,
    required this.onCancel,
    required this.onCreate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: isLoading ? null : onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : onCreate,
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Group'),
        ),
      ],
    );
  }
}
