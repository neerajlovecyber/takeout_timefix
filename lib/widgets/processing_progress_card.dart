import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:rxdart/rxdart.dart';
import '../services/processing_service.dart';
import '../services/file_organization_service.dart';
import '../utils/app_constants.dart';

/// Widget that displays processing progress and controls
class ProcessingProgressCard extends StatefulWidget {
  final String inputDirectory;
  final String outputDirectory;
  final VoidCallback onProcessingComplete;

  const ProcessingProgressCard({
    super.key,
    required this.inputDirectory,
    required this.outputDirectory,
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
        title: const Text('Processing Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Successfully processed ${result.organizedFiles} files'),
            const SizedBox(height: 8),
            Text('📊 Total files found: ${result.totalFiles}'),
            Text('🔍 Files with timestamps: ${result.processedFiles}'),
            Text('📁 Unique files: ${result.uniqueFiles}'),
            if (result.warnings.isNotEmpty)
              Text('⚠️ Warnings: ${result.warnings.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Processing Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.play_arrow, color: Colors.green),
                const SizedBox(width: AppConstants.smallSpacing),
                Text(
                  'Start Processing',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.mediumSpacing),

            // Progress indicator
            if (_isProcessing || _progress > 0) ...[
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _progress == 1.0 ? Colors.green : Colors.blue,
                ),
              ),
              const SizedBox(height: AppConstants.smallSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currentStatus,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '${(_progress * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.smallSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Elapsed: $_elapsedTime',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (_estimatedTime != null)
                    Text(
                      'Remaining: $_estimatedTime',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppConstants.mediumSpacing),
            ],

            // Control buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _startProcessing,
                    icon: _isProcessing
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _animationController.value * 2 * pi,
                                  child: const Icon(Icons.refresh, size: 16),
                                );
                              },
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isProcessing ? 'Processing...' : 'Start Processing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_isProcessing) ...[
                  const SizedBox(width: AppConstants.smallSpacing),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cancelProcessing,
                      icon: const Icon(Icons.stop),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Results summary
            if (_result != null && !_isProcessing) ...[
              const SizedBox(height: AppConstants.mediumSpacing),
              const Divider(),
              const SizedBox(height: AppConstants.smallSpacing),
              Text(
                'Processing Results',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.smallSpacing),
              _buildResultsSummary(_result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSummary(ProcessingResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.isSuccess ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                result.isSuccess ? Icons.check_circle : Icons.error,
                color: result.isSuccess ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: AppConstants.smallSpacing),
              Text(
                result.isSuccess ? 'Success' : 'Failed',
                style: TextStyle(
                  color: result.isSuccess ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.isSuccess
                ? 'Organized ${result.organizedFiles} files successfully'
                : result.error ?? 'Processing failed',
            style: TextStyle(
              color: result.isSuccess ? Colors.green.shade700 : Colors.red.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
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