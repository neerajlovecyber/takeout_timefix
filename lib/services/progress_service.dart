import 'dart:async';

/// Service for tracking and reporting progress during long-running operations
class ProgressService {
  /// Stream controllers for different types of progress updates
  final StreamController<ProgressUpdate> _progressController = StreamController<ProgressUpdate>.broadcast();
  final StreamController<String> _statusController = StreamController<String>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  /// Current operation state
  OperationState _currentState = OperationState.idle;
  Timer? _updateTimer;
  DateTime? _startTime;
  int _lastReportedProgress = 0;
  DateTime? _lastUpdateTime;
  static const Duration _minUpdateInterval = Duration(milliseconds: 200);

  /// Public streams for listening to updates
  Stream<ProgressUpdate> get progressStream => _progressController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<String> get errorStream => _errorController.stream;

  /// Current operation state
  OperationState get currentState => _currentState;

  /// Whether an operation is currently running
  bool get isRunning => _currentState == OperationState.running;

  /// Start a new operation
  void startOperation(String operationName, int totalSteps) {
    _currentState = OperationState.running;
    _startTime = DateTime.now();
    _lastReportedProgress = 0;

    _statusController.add('Starting $operationName...');

    // Send initial progress update
    _progressController.add(ProgressUpdate(
      currentStep: 0,
      totalSteps: totalSteps,
      percentage: 0.0,
      operationName: operationName,
      elapsedTime: Duration.zero,
    ));

    // Start periodic updates every 500ms (reduced frequency to improve performance)
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_currentState != OperationState.running) {
        timer.cancel();
      }
    });
  }

  /// Update progress for the current operation
  void updateProgress(int currentStep, {String? statusMessage}) {
    if (_currentState != OperationState.running) return;

    final totalSteps = _getCurrentTotalSteps();
    if (totalSteps == 0) return;

    final now = DateTime.now();
    final percentage = (currentStep / totalSteps) * 100;
    final elapsedTime = _startTime != null ? now.difference(_startTime!) : Duration.zero;

    // Enhanced throttling: check time interval and progress significance
    final shouldUpdate = _shouldUpdateProgress(currentStep, percentage, now);

    if (shouldUpdate) {
      _lastReportedProgress = currentStep;
      _lastUpdateTime = now;

      final progress = ProgressUpdate(
        currentStep: currentStep,
        totalSteps: totalSteps,
        percentage: percentage,
        operationName: _getCurrentOperationName(),
        elapsedTime: elapsedTime,
        statusMessage: statusMessage,
      );

      _progressController.add(progress);

      if (statusMessage != null) {
        _statusController.add(statusMessage);
      }
    }
  }

  /// Determine if progress should be updated based on throttling rules
  bool _shouldUpdateProgress(int currentStep, double percentage, DateTime now) {
    // Always update at completion
    if (percentage >= 100) return true;

    // Check minimum time interval since last update
    if (_lastUpdateTime != null) {
      final timeSinceLastUpdate = now.difference(_lastUpdateTime!);
      if (timeSinceLastUpdate < _minUpdateInterval) {
        return false;
      }
    }

    // Update every N steps (batch updates)
    const int updateBatchSize = 5;
    if (currentStep % updateBatchSize == 0) return true;

    // Update if progress changed significantly (at least 2%)
    if (_lastReportedProgress > 0) {
      final progressDiff = ((currentStep - _lastReportedProgress) / _getCurrentTotalSteps()) * 100;
      if (progressDiff >= 2.0) return true;
    }

    return false;
  }



  /// Report an error during the operation
  void reportError(String error, {bool isFatal = false}) {
    _errorController.add(error);

    if (isFatal) {
      _currentState = OperationState.error;
      _statusController.add('Error: $error');
    }
  }

  /// Complete the current operation successfully
  void completeOperation({String? successMessage}) {
    if (_currentState == OperationState.running) {
      _currentState = OperationState.completed;
      final elapsedTime = _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;

      _progressController.add(ProgressUpdate(
        currentStep: _getCurrentTotalSteps(),
        totalSteps: _getCurrentTotalSteps(),
        percentage: 100.0,
        operationName: _getCurrentOperationName(),
        elapsedTime: elapsedTime,
        isCompleted: true,
      ));

      final message = successMessage ?? 'Operation completed successfully';
      _statusController.add(message);

      _updateTimer?.cancel();
    }
  }

  /// Cancel the current operation
  void cancelOperation() {
    if (_currentState == OperationState.running) {
      _currentState = OperationState.cancelled;
      _statusController.add('Operation cancelled');
      _updateTimer?.cancel();
    }
  }

  /// Reset the service state
  void reset() {
    _currentState = OperationState.idle;
    _startTime = null;
    _lastReportedProgress = 0;
    _lastUpdateTime = null;
    _updateTimer?.cancel();
  }

  /// Get estimated time remaining based on current progress
  Duration? getEstimatedTimeRemaining() {
    if (_startTime == null || _currentState != OperationState.running) {
      return null;
    }

    final elapsed = DateTime.now().difference(_startTime!);
    final totalSteps = _getCurrentTotalSteps();
    final currentStep = _lastReportedProgress;

    if (totalSteps == 0 || currentStep == 0) return null;

    final progressRatio = currentStep / totalSteps;
    if (progressRatio <= 0) return null;

    final totalEstimated = elapsed * (1 / progressRatio);
    return totalEstimated - elapsed;
  }

  /// Get formatted time remaining string
  String? getFormattedTimeRemaining() {
    final remaining = getEstimatedTimeRemaining();
    if (remaining == null) return null;

    if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m ${remaining.inSeconds.remainder(60)}s';
    } else {
      return '${remaining.inSeconds}s';
    }
  }

  /// Get formatted elapsed time string
  String getFormattedElapsedTime() {
    if (_startTime == null) return '0s';

    final elapsed = DateTime.now().difference(_startTime!);
    return _formatDuration(elapsed);
  }

  /// Format a duration for display
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Get current operation statistics
  OperationStats getStats() {
    return OperationStats(
      state: _currentState,
      elapsedTime: _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero,
      estimatedTimeRemaining: getEstimatedTimeRemaining(),
      currentProgress: _lastReportedProgress,
      totalSteps: _getCurrentTotalSteps(),
    );
  }

  // Private helper methods (would need to be implemented based on actual operation tracking)
  String _getCurrentOperationName() => 'Processing'; // Placeholder
  int _getCurrentTotalSteps() => 100; // Placeholder

  /// Clean up resources
  void dispose() {
    _progressController.close();
    _statusController.close();
    _errorController.close();
    _updateTimer?.cancel();
  }
}

/// Represents different states of an operation
enum OperationState {
  idle,
  running,
  completed,
  cancelled,
  error,
}

/// Progress update information
class ProgressUpdate {
  final int currentStep;
  final int totalSteps;
  final double percentage;
  final String operationName;
  final Duration elapsedTime;
  final String? statusMessage;
  final bool isCompleted;

  const ProgressUpdate({
    required this.currentStep,
    required this.totalSteps,
    required this.percentage,
    required this.operationName,
    required this.elapsedTime,
    this.statusMessage,
    this.isCompleted = false,
  });

  String get formattedPercentage => '${percentage.toStringAsFixed(1)}%';
  String get formattedProgress => '$currentStep / $totalSteps';
}

/// Operation statistics
class OperationStats {
  final OperationState state;
  final Duration elapsedTime;
  final Duration? estimatedTimeRemaining;
  final int currentProgress;
  final int totalSteps;

  const OperationStats({
    required this.state,
    required this.elapsedTime,
    this.estimatedTimeRemaining,
    required this.currentProgress,
    required this.totalSteps,
  });

  double get progressPercentage => totalSteps > 0 ? (currentProgress / totalSteps) * 100 : 0.0;
}