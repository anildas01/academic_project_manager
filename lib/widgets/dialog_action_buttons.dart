import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

class DialogActionButtons extends StatelessWidget {
  final bool isLoading;
  final bool isValid;
  final VoidCallback onCancel;
  final VoidCallback? onCreate;

  const DialogActionButtons({
    super.key,
    required this.isLoading,
    required this.isValid,
    required this.onCancel,
    this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('--- DialogActionButtons State ---');
      print('isLoading: $isLoading');
      print('isValid: $isValid');
      print('onCreate is null: ${onCreate == null}');
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: isLoading ? null : onCancel,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed:
              (!isLoading && isValid && onCreate != null) ? onCreate : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: (isValid && !isLoading)
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
