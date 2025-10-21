import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/folder_state.dart';
import '../providers/stepper_provider.dart';
import '../services/folder_service.dart';
import '../utils/app_constants.dart';
import '../utils/ui_helpers.dart';
import '../widgets/folder_selection_button.dart';
import '../widgets/processing_progress_card.dart';

import '../widgets/app_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FolderService _folderService = FolderService();

  FolderState _folderState = const FolderState();
  OutputFolderConfig _outputConfig = const OutputFolderConfig();
  bool _guessFromFolderName = true;

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
          context.read<StepperProvider>().nextStep();
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
        context.read<StepperProvider>().nextStep();
      } else if (result.isValid && !result.hasWritePermissions) {
        UIHelpers.showWarningSnackBar(context, AppConstants.noWritePermissions);
      } else {
        UIHelpers.showErrorSnackBar(context, AppConstants.invalidOutputFolder);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepperProvider = context.watch<StepperProvider>();
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text(
              AppConstants.appTitle,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 0,
            pinned: true,
            expandedHeight: isDesktop ? 200 : 160,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: AppHeader(),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
            sliver: SliverToBoxAdapter(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 1200 : double.infinity,
                ),
                child: Center(
                  child: _buildContent(context, stepperProvider, isDesktop),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, StepperProvider stepperProvider, bool isDesktop) {
    if (isDesktop) {
      return _buildDesktopLayout(context, stepperProvider);
    } else {
      return _buildMobileLayout(context, stepperProvider);
    }
  }

  Widget _buildDesktopLayout(BuildContext context, StepperProvider stepperProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Navigation sidebar
        SizedBox(
          width: 280,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildStepIndicator(0, 'Select Takeout Folder', _folderState.isValidTakeoutFolder, stepperProvider.currentStep),
                  const SizedBox(height: 16),
                  _buildStepIndicator(1, 'Configure Output', _outputConfig.isReadyForProcessing, stepperProvider.currentStep),
                  const SizedBox(height: 16),
                  _buildStepIndicator(2, 'Process Files', false, stepperProvider.currentStep),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Main content
        Expanded(
          child: _buildStepContent(stepperProvider.currentStep),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, StepperProvider stepperProvider) {
    return Column(
      children: [
        // Progress indicator
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timeline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Step ${stepperProvider.currentStep + 1} of 3',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: (stepperProvider.currentStep + 1) / 3,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Step content
        _buildStepContent(stepperProvider.currentStep),
        const SizedBox(height: 24),
        // Navigation buttons
        _buildNavigationButtons(context, stepperProvider),
      ],
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title, bool isCompleted, int currentStep) {
    final isActive = currentStep == stepIndex;
    final isPast = currentStep > stepIndex;
    
    return InkWell(
      onTap: () => context.read<StepperProvider>().goToStep(stepIndex),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive 
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted || isPast
                  ? Theme.of(context).colorScheme.primary
                  : isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted || isPast ? Icons.check : Icons.circle,
                color: isCompleted || isPast || isActive
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.surface,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive 
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(int currentStep) {
    switch (currentStep) {
      case 0:
        return _buildFolderSelectionStep();
      case 1:
        return _buildOutputConfigurationStep();
      case 2:
        return _buildProcessingStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFolderSelectionStep() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_open,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Select Takeout Folder',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Choose the folder containing your unzipped Google Photos takeout files.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FolderSelectionButton(
              onPressed: _selectTakeoutFolder,
              label: AppConstants.selectTakeoutFolder,
              icon: Icons.folder_open,
            ),
            if (_folderState.selectedFolderPath != null) ...[
              const SizedBox(height: 24),
              _buildFolderInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOutputConfigurationStep() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.output,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Configure Output',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Choose where you want your organized photos to be saved.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FolderSelectionButton(
              onPressed: _selectOutputFolder,
              label: AppConstants.selectOutputFolder,
              icon: Icons.folder_open,
            ),
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: CheckboxListTile(
                title: const Text(AppConstants.guessDateTitle),
                subtitle: const Text(AppConstants.guessDateDescription),
                value: _guessFromFolderName,
                onChanged: (newValue) {
                  setState(() {
                    _guessFromFolderName = newValue!;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            if (_outputConfig.outputFolderPath != null) ...[
              const SizedBox(height: 24),
              _buildOutputInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingStep() {
    return (_folderState.selectedFolderPath != null && _outputConfig.outputFolderPath != null)
        ? ProcessingProgressCard(
            inputDirectory: _folderState.selectedFolderPath!,
            outputDirectory: _outputConfig.outputFolderPath!,
            guessFromFolderName: _guessFromFolderName,
            onProcessingComplete: () {
              if (_folderState.selectedFolderPath != null) {
                _validateTakeoutFolder(_folderState.selectedFolderPath!);
              }
            },
          )
        : Card(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Setup Required',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please complete the previous steps before processing.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildFolderInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _folderState.isValidTakeoutFolder
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _folderState.isValidTakeoutFolder ? Icons.check_circle : Icons.warning,
                color: _folderState.isValidTakeoutFolder
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _folderState.isValidTakeoutFolder
                    ? 'Valid takeout folder'
                    : 'No media files found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _folderState.isValidTakeoutFolder
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Path: ${_folderState.selectedFolderPath}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _folderState.isValidTakeoutFolder
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onErrorContainer,
              fontFamily: 'monospace',
            ),
          ),
          if (_folderState.isValidTakeoutFolder)
            Text(
              'Found ${_folderState.imageFiles.length} media files',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOutputInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _outputConfig.isReadyForProcessing
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _outputConfig.isReadyForProcessing ? Icons.check_circle : Icons.warning,
                color: _outputConfig.isReadyForProcessing
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _outputConfig.isReadyForProcessing
                    ? 'Ready for processing'
                    : 'Check permissions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _outputConfig.isReadyForProcessing
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Path: ${_outputConfig.outputFolderPath}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _outputConfig.isReadyForProcessing
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onErrorContainer,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, StepperProvider stepperProvider) {
    return Row(
      children: [
        if (stepperProvider.currentStep > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => stepperProvider.previousStep(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            ),
          ),
        if (stepperProvider.currentStep > 0) const SizedBox(width: 16),
        if (stepperProvider.currentStep < 2)
          Expanded(
            child: FilledButton.icon(
              onPressed: _canContinue(stepperProvider.currentStep)
                ? () => stepperProvider.nextStep()
                : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue'),
            ),
          ),
      ],
    );
  }

  bool _canContinue(int currentStep) {
    switch (currentStep) {
      case 0:
        return _folderState.isValidTakeoutFolder;
      case 1:
        return _outputConfig.isReadyForProcessing;
      default:
        return false;
    }
  }
}