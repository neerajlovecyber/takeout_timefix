import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class FolderInfoCard extends StatelessWidget {
  final String title;
  final String folderPath;
  final String statusText;
  final IconData statusIcon;
  final Color statusColor;

  const FolderInfoCard({
    super.key,
    required this.title,
    required this.folderPath,
    required this.statusText,
    required this.statusIcon,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: AppConstants.smallSpacing),
                Expanded(
                  child: Text(
                    '$title:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallSpacing),
            Text(
              folderPath,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: AppConstants.smallSpacing),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}