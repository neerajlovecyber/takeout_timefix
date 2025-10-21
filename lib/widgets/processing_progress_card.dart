import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:rxdart/rxdart.dart';
import '../services/processing_service.dart';
import '../services/file_organization_service.dart';

/// Widget that displays processing progress and controls
class ProcessingProgressCard extends StatefulWidget {
  final String inputDirectory;
  final String outputDirectory;
  final bool guessFromFolderName;
  final VoidCallback onProcessingComplete;

  const ProcessingProgressCard({
    super.key,
    required this.inputDirectory,
    required this.outputDirectory,
    required this.guessFromFolderName,
    required this.onProcessingComplete,
  });

  @override
  State<ProcessingProgressCard> createState() => _ProcessingProgressCardState();
}

class _ProcessingProgressCardState extends State<ProcessingProgressCard>
  with TickerProviderStateMixin {
  final ProcessingService _processingService = ProcessingService();
  bool _isProcessing = false;
  String _currentStatus = '';
  double _progress = 0.0;
  String _elapsedTime = '';
  String? _estimatedTime;
  ProcessingResult? _result;
  Timer? _timeUpdateTimer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
    _setupProgressListeners();
    _startTimeUpdateTimer();
  }

  StreamSubscription? _elapsedTimeSubscription;

  void _startTimeUpdateTimer() {
    // No longer needed - progress stream provides time updates
    // Timer removed to reduce unnecessary rebuilds
  }

  void _startElapsedTimeUpdates() {
    // Subscribe to periodic elapsed time updates (less frequent than progress updates)
    _elapsedTimeSubscription = Stream.periodic(
      const Duration(seconds: 1), // Update every second, not 2
      (_) => _processingService.getStats().elapsedTime,
    ).listen((elapsedTime) {
      if (mounted && _isProcessing) {
        setState(() {
          _elapsedTime = _formatDuration(elapsedTime);
        });
      } else {
        _elapsedTimeSubscription?.cancel();
      }
    });
  }

  void _setupProgressListeners() {
    // Listen to progress updates with improved responsiveness
    _processingService.progressStream
      .debounceTime(const Duration(milliseconds: 50)) // Reduced debounce time
      .distinct((prev, next) => prev.percentage == next.percentage)
      .listen((progress) {
        if (mounted) {
          setState(() {
            _progress = progress.percentage / 100.0;
            _elapsedTime = _formatDuration(progress.elapsedTime);
            _isProcessing = !progress.isCompleted;
          });
        }
      });

    // Listen to status updates
    _processingService.statusStream
      .debounceTime(const Duration(milliseconds: 25)) // Reduced debounce time
      .distinct()
      .listen((status) {
        if (mounted && status != _currentStatus) {
          setState(() {
            _currentStatus = status;
          });
        }
      });

    // Listen for errors
    _processingService.errorStream
      .debounceTime(const Duration(milliseconds: 100))
      .listen((error) {
        if (mounted) {
          setState(() {
            _currentStatus = 'Error: $error';
          });
        }
      });
  }

  Future<void> _startProcessing() async {
    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _currentStatus = 'Initializing...';
      _result = null;
    });

    // Start optimized elapsed time updates
    _elapsedTimeSubscription?.cancel();
    _startElapsedTimeUpdates();

    final config = ProcessingConfig(
      inputDirectory: widget.inputDirectory,
      outputDirectory: widget.outputDirectory,
      organizationMode: OrganizationMode.yearMonthFolders, // Default mode
      preserveOriginalFilename: false,
      guessFromFolderName: widget.guessFromFolderName,
    );

    try {
      final result = await _processingService.startProcessing(config);

      if (mounted) {
        setState(() {
          _result = result;
          _isProcessing = false;
        });

        if (result.isSuccess) {
          widget.onProcessingComplete();
          _showSuccessDialog(result);
        } else {
          _showErrorDialog(result.error!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showErrorDialog('Processing failed: $e');
      }
    }
  }

  void _cancelProcessing() {
    _processingService.cancelProcessing();
    setState(() {
      _isProcessing = false;
      _currentStatus = 'Processing cancelled';
    });
  }

  void _showSuccessDialog(ProcessingResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
        ),
        title: const Text('Processing Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDialogStatRow('Files processed', '${result.organizedFiles}'),
                  const Divider(height: 16),
                  _buildDialogStatRow('Total files found', '${result.totalFiles}'),
                  const Divider(height: 16),
                  _buildDialogStatRow('Files with timestamps', '${result.processedFiles}'),
                  const Divider(height: 16),
                  _buildDialogStatRow('Unique files', '${result.uniqueFiles}'),
                  if (result.warnings.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDialogStatRow('Warnings', '${result.warnings.length}'),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error,
            color: Theme.of(context).colorScheme.error,
            size: 32,
          ),
        ),
        title: const Text('Processing Error'),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Process Files',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Start organizing your photos by extracting timestamps and creating date-based folders.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Progress indicator
            if (_isProcessing || _progress > 0) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isProcessing ? Icons.hourglass_empty : Icons.check_circle,
                          color: _progress == 1.0 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentStatus,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(_progress * 100).toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _progress == 1.0 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary,
                      ),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Elapsed: $_elapsedTime',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (_estimatedTime != null)
                          Row(
                            children: [
                              Icon(
                                Icons.timer,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Remaining: $_estimatedTime',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Control buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isProcessing ? null : _startProcessing,
                    icon: _isProcessing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _animationController.value * 2 * pi,
                                  child: Icon(
                                    Icons.refresh,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                );
                              },
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isProcessing ? 'Processing...' : 'Start Processing'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_isProcessing) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cancelProcessing,
                      icon: const Icon(Icons.stop),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(color: Theme.of(context).colorScheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Results summary
            if (_result != null && !_isProcessing) ...[
              const SizedBox(height: 24),
              _buildResultsSummary(_result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSummary(ProcessingResult result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: result.isSuccess 
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: result.isSuccess 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  result.isSuccess ? Icons.check : Icons.close,
                  color: result.isSuccess 
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onError,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                result.isSuccess ? 'Processing Complete!' : 'Processing Failed',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: result.isSuccess 
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (result.isSuccess) ...[
            _buildStatRow(Icons.photo, 'Files processed', '${result.organizedFiles}'),
            const SizedBox(height: 8),
            _buildStatRow(Icons.folder, 'Total files found', '${result.totalFiles}'),
            const SizedBox(height: 8),
            _buildStatRow(Icons.schedule, 'Files with timestamps', '${result.processedFiles}'),
            const SizedBox(height: 8),
            _buildStatRow(Icons.filter_none, 'Unique files', '${result.uniqueFiles}'),
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildStatRow(Icons.warning, 'Warnings', '${result.warnings.length}'),
            ],
          ] else
            Text(
              result.error ?? 'An unknown error occurred during processing.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _elapsedTimeSubscription?.cancel();
    _animationController.dispose();
    _processingService.reset();
    super.dispose();
  }
}