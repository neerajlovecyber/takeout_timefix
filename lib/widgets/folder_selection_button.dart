import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class FolderSelectionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const FolderSelectionButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.buttonPadding,
          horizontal: AppConstants.buttonPadding,
        ),
        textStyle: const TextStyle(fontSize: AppConstants.buttonFontSize),
      ),
    );
  }
}