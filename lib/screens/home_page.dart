import 'package:flutter/material.dart';
import '../models/folder_state.dart';
import '../services/folder_service.dart';
import '../utils/app_constants.dart';
import '../utils/ui_helpers.dart';
import '../widgets/app_header.dart';
import '../widgets/folder_selection_button.dart';
import '../widgets/ready_for_processing_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FolderService _folderService = FolderService();

  FolderState _folderState = const FolderState();
  OutputFolderConfig _outputConfig = const OutputFolderConfig();

  Future<void> _selectTakeoutFolder() async {
    try {
      await Future.delayed(AppConstants.folderSelectionDelay);

      String? selectedDirectory = await _folderService.selectTakeoutFolder(
        initialDirectory: _folderState.selectedFolderPath ?? AppConstants.defaultDirectory,
      );

      if (selectedDirectory != null && mounted) {
        setState(() {
          _folderState = FolderState(
            selectedFolderPath: selectedDirectory,
            isValidTakeoutFolder: false,
            imageFiles: [],
          );
        });

        await _validateTakeoutFolder(selectedDirectory);
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(context, 'Error selecting folder: ${e.toString()}');
      }
    }
  }

  Future<void> _validateTakeoutFolder(String folderPath) async {
    final result = await _folderService.validateTakeoutFolder(folderPath);

    setState(() {
      _folderState = _folderState.copyWith(
        isValidTakeoutFolder: result.isValid,
        imageFiles: result.imageFiles,
      );
    });

    if (mounted) {
      if (result.isValid) {
        if (result.imageFiles.isNotEmpty) {
          UIHelpers.showSuccessSnackBar(
            context,
            'Found ${result.imageFiles.length} media files in the selected folder',
          );
        } else {
          UIHelpers.showSnackBar(
            context,
            'Folder appears to be a Google Photos takeout folder (no files found yet)',
            backgroundColor: AppColors.info,
          );
        }
      } else {
        UIHelpers.showWarningSnackBar(
          context,
          result.errorMessage ?? AppConstants.noMediaFilesFound,
        );
      }
    }
  }

  Future<void> _selectOutputFolder() async {
    try {
      await Future.delayed(AppConstants.folderSelectionDelay);

      String? selectedDirectory = await _folderService.selectOutputFolder();

      if (selectedDirectory != null && mounted) {
        setState(() {
          _outputConfig = OutputFolderConfig(
            outputFolderPath: selectedDirectory,
            isValidOutputFolder: false,
            hasWritePermissions: false,
          );
        });

        await _validateOutputFolder(selectedDirectory);
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(context, 'Error selecting output folder: ${e.toString()}');
      }
    }
  }

  Future<void> _validateOutputFolder(String folderPath) async {
    final result = await _folderService.validateOutputFolder(folderPath);

    setState(() {
      _outputConfig = OutputFolderConfig(
        outputFolderPath: folderPath,
        isValidOutputFolder: result.isValid,
        hasWritePermissions: result.hasWritePermissions,
      );
    });

    if (mounted) {
      if (result.isValid && result.hasWritePermissions) {
        UIHelpers.showSuccessSnackBar(context, AppConstants.folderConfiguredSuccessfully);
      } else if (result.isValid && !result.hasWritePermissions) {
        UIHelpers.showWarningSnackBar(context, AppConstants.noWritePermissions);
      } else {
        UIHelpers.showErrorSnackBar(context, AppConstants.invalidOutputFolder);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - kToolbarHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppConstants.defaultPadding,
              right: AppConstants.defaultPadding,
              top: AppConstants.defaultPadding,
              bottom: AppConstants.largeSpacing,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const AppHeader(),
                const SizedBox(height: AppConstants.largeSpacing),

                // Takeout Folder Selection Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.folder_open, color: Colors.blue),
                            const SizedBox(width: AppConstants.smallSpacing),
                            Text(
                              'Takeout Folder Selection',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.mediumSpacing),
                        FolderSelectionButton(
                          onPressed: _selectTakeoutFolder,
                          label: AppConstants.selectTakeoutFolder,
                          icon: Icons.folder_open,
                        ),

                        // Selected Folder Info (shown under the button)
                        if (_folderState.selectedFolderPath != null) ...[
                          const SizedBox(height: AppConstants.mediumSpacing),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _folderState.isValidTakeoutFolder
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _folderState.isValidTakeoutFolder
                                    ? Colors.green.shade200
                                    : Colors.orange.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _folderState.isValidTakeoutFolder ? Icons.check_circle : Icons.warning,
                                      color: _folderState.isValidTakeoutFolder ? AppColors.success : AppColors.warning,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppConstants.smallSpacing),
                                    Text(
                                      'Selected Folder:',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _folderState.selectedFolderPath!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _folderState.isValidTakeoutFolder
                                      ? '✅ Found ${_folderState.imageFiles.length} image files'
                                      : '⚠️ No image files found in this folder',
                                  style: TextStyle(
                                    color: _folderState.isValidTakeoutFolder ? AppColors.success : AppColors.warning,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.largeSpacing),

                // Output Folder Configuration Card (Feature 2)
                if (_folderState.isValidTakeoutFolder) ...[
                  Card(
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
                            onPressed: _selectOutputFolder,
                            label: AppConstants.selectOutputFolder,
                            icon: Icons.folder_open,
                          ),

                          // Selected Output Folder Info (shown under the button)
                          if (_outputConfig.outputFolderPath != null) ...[
                            const SizedBox(height: AppConstants.mediumSpacing),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _outputConfig.isReadyForProcessing
                                    ? Colors.green.shade50
                                    : _outputConfig.isValidOutputFolder
                                        ? Colors.orange.shade50
                                        : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _outputConfig.isReadyForProcessing
                                      ? Colors.green.shade200
                                      : _outputConfig.isValidOutputFolder
                                          ? Colors.orange.shade200
                                          : Colors.red.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        UIHelpers.getStatusIcon(
                                          _outputConfig.isValidOutputFolder,
                                          _outputConfig.hasWritePermissions,
                                        ),
                                        color: UIHelpers.getStatusColor(
                                          _outputConfig.isValidOutputFolder,
                                          _outputConfig.hasWritePermissions,
                                        ),
                                        size: 20,
                                      ),
                                      const SizedBox(width: AppConstants.smallSpacing),
                                      Text(
                                        'Output Folder:',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _outputConfig.outputFolderPath!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    UIHelpers.getStatusText(
                                      _outputConfig.isValidOutputFolder,
                                      _outputConfig.hasWritePermissions,
                                    ),
                                    style: TextStyle(
                                      color: UIHelpers.getStatusColor(
                                        _outputConfig.isValidOutputFolder,
                                        _outputConfig.hasWritePermissions,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.largeSpacing),
                ],

                // Next Steps Info
                if (_folderState.isValidTakeoutFolder && _outputConfig.isReadyForProcessing) ...[
                  const ReadyForProcessingCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}