import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import 'folder_selection_button.dart';

class OutputFolderConfigCard extends StatelessWidget {
  final VoidCallback onSelectOutputFolder;

  const OutputFolderConfigCard({
    super.key,
    required this.onSelectOutputFolder,
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
                const Icon(Icons.output, color: Colors.blue),
                const SizedBox(width: AppConstants.smallSpacing),
                Text(
                  AppConstants.outputFolderConfiguration,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallSpacing),
            Text(
              AppConstants.chooseOutputLocation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppConstants.mediumSpacing),
            FolderSelectionButton(
              onPressed: onSelectOutputFolder,
              label: AppConstants.selectOutputFolder,
              icon: Icons.folder_open,
            ),
          ],
        ),
      ),
    );
  }
}