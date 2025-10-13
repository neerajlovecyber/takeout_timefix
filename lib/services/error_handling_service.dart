import 'dart:io';

/// Service for handling errors and providing recovery mechanisms during file processing
class ErrorHandlingService {
  /// Error log for tracking issues during processing
  final List<ProcessingError> _errorLog = [];

  /// Maximum number of consecutive errors before suggesting operation stop
  static const int _maxConsecutiveErrors = 10;

  /// Counter for consecutive errors
  int _consecutiveErrors = 0;

  /// Get all logged errors
  List<ProcessingError> get errors => List.unmodifiable(_errorLog);

  /// Stream of error messages for real-time updates
  Stream<String> get errorStream => Stream.empty(); // Placeholder - would need StreamController

  /// Get errors of a specific severity
  List<ProcessingError> getErrorsBySeverity(ErrorSeverity severity) {
    return _errorLog.where((error) => error.severity == severity).toList();
  }

  /// Get errors for a specific file
  List<ProcessingError> getErrorsForFile(String filePath) {
    return _errorLog.where((error) => error.filePath == filePath).toList();
  }

  /// Log an error during processing
  void logError({
    required String message,
    required String filePath,
    ErrorSeverity severity = ErrorSeverity.warning,
    ErrorCategory category = ErrorCategory.processing,
    Exception? exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final error = ProcessingError(
      message: message,
      filePath: filePath,
      severity: severity,
      category: category,
      timestamp: DateTime.now(),
      exception: exception,
      stackTrace: stackTrace,
      context: context ?? {},
    );

    _errorLog.add(error);

    if (severity == ErrorSeverity.error) {
      _consecutiveErrors++;
    } else {
      _consecutiveErrors = 0; // Reset counter for non-critical errors
    }
  }

  /// Check if operation should be stopped due to too many consecutive errors
  bool shouldStopOperation() {
    return _consecutiveErrors >= _maxConsecutiveErrors;
  }

  /// Get recovery suggestion for an error
  RecoverySuggestion? getRecoverySuggestion(ProcessingError error) {
    switch (error.category) {
      case ErrorCategory.fileAccess:
        if (error.message.contains('Permission denied')) {
          return RecoverySuggestion(
            action: 'Check file permissions and try again',
            canRetry: true,
            severity: RecoverySeverity.manual,
          );
        }
        if (error.message.contains('File not found')) {
          return RecoverySuggestion(
            action: 'Skip missing file and continue',
            canRetry: false,
            severity: RecoverySeverity.automatic,
          );
        }
        break;

      case ErrorCategory.corruptedFile:
        return RecoverySuggestion(
          action: 'Skip corrupted file and continue processing',
          canRetry: false,
          severity: RecoverySeverity.automatic,
        );

      case ErrorCategory.metadataExtraction:
        return RecoverySuggestion(
          action: 'Use fallback extraction method or skip file',
          canRetry: true,
          severity: RecoverySeverity.automatic,
        );

      case ErrorCategory.diskSpace:
        return RecoverySuggestion(
          action: 'Free up disk space and try again',
          canRetry: true,
          severity: RecoverySeverity.manual,
        );

      case ErrorCategory.processing:
        return RecoverySuggestion(
          action: 'Retry operation or skip problematic file',
          canRetry: true,
          severity: RecoverySeverity.semiAutomatic,
        );

      case ErrorCategory.unknown:
      default:
        return RecoverySuggestion(
          action: 'Review error details and retry if appropriate',
          canRetry: true,
          severity: RecoverySeverity.manual,
        );
    }

    return null;
  }

  /// Attempt automatic recovery for an error
  Future<bool> attemptRecovery(ProcessingError error) async {
    final suggestion = getRecoverySuggestion(error);
    if (suggestion == null || !suggestion.canRetry) {
      return false;
    }

    switch (error.category) {
      case ErrorCategory.fileAccess:
        return await _recoverFileAccess(error);

      case ErrorCategory.metadataExtraction:
        return await _recoverMetadataExtraction(error);

      case ErrorCategory.processing:
        return await _recoverProcessing(error);

      default:
        return false;
    }
  }

  /// Recovery for file access errors
  Future<bool> _recoverFileAccess(ProcessingError error) async {
    try {
      final file = File(error.filePath);

      // Check if file exists
      if (!await file.exists()) {
        logError(
          message: 'File no longer exists, skipping',
          filePath: error.filePath,
          severity: ErrorSeverity.info,
          category: ErrorCategory.fileAccess,
        );
        return true; // Consider this "recovered" by skipping
      }

      // Check file permissions
      try {
        await file.length();
        return true; // File is accessible now
      } catch (e) {
        return false; // Still not accessible
      }
    } catch (e) {
      return false;
    }
  }

  /// Recovery for metadata extraction errors
  Future<bool> _recoverMetadataExtraction(ProcessingError error) async {
    // For metadata extraction errors, we can mark the file to use fallback methods
    // This is handled by the calling code, so we just return true
    return true;
  }

  /// Recovery for processing errors
  Future<bool> _recoverProcessing(ProcessingError error) async {
    // For processing errors, suggest retry with different parameters
    return true;
  }

  /// Clear error log
  void clearErrors() {
    _errorLog.clear();
    _consecutiveErrors = 0;
  }

  /// Get error statistics
  ErrorStats getStats() {
    final totalErrors = _errorLog.length;
    final criticalErrors = _errorLog.where((e) => e.severity == ErrorSeverity.error).length;
    final warnings = _errorLog.where((e) => e.severity == ErrorSeverity.warning).length;
    final info = _errorLog.where((e) => e.severity == ErrorSeverity.info).length;

    return ErrorStats(
      totalErrors: totalErrors,
      criticalErrors: criticalErrors,
      warnings: warnings,
      info: info,
      consecutiveErrors: _consecutiveErrors,
      shouldStop: shouldStopOperation(),
    );
  }

  /// Export errors to a log file
  Future<String> exportErrorLog(String outputPath) async {
    final buffer = StringBuffer();
    buffer.writeln('Takeout TimeFix Error Log');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Errors: ${_errorLog.length}');
    buffer.writeln('');

    for (final error in _errorLog) {
      buffer.writeln('=== ${error.severity.name.toUpperCase()} ===');
      buffer.writeln('Time: ${error.timestamp.toIso8601String()}');
      buffer.writeln('File: ${error.filePath}');
      buffer.writeln('Category: ${error.category.name}');
      buffer.writeln('Message: ${error.message}');

      if (error.exception != null) {
        buffer.writeln('Exception: ${error.exception}');
      }

      if (error.context.isNotEmpty) {
        buffer.writeln('Context: ${error.context}');
      }

      buffer.writeln('');
    }

    final logFile = File(outputPath);
    await logFile.writeAsString(buffer.toString());

    return logFile.path;
  }
}

/// Represents different categories of errors
enum ErrorCategory {
  fileAccess,
  corruptedFile,
  metadataExtraction,
  diskSpace,
  processing,
  unknown,
}

/// Represents error severity levels
enum ErrorSeverity {
  info,
  warning,
  error,
}

/// Represents an error during processing
class ProcessingError {
  final String message;
  final String filePath;
  final ErrorSeverity severity;
  final ErrorCategory category;
  final DateTime timestamp;
  final Exception? exception;
  final StackTrace? stackTrace;
  final Map<String, dynamic> context;

  const ProcessingError({
    required this.message,
    required this.filePath,
    required this.severity,
    required this.category,
    required this.timestamp,
    this.exception,
    this.stackTrace,
    required this.context,
  });
}

/// Represents a recovery suggestion for an error
class RecoverySuggestion {
  final String action;
  final bool canRetry;
  final RecoverySeverity severity;

  const RecoverySuggestion({
    required this.action,
    required this.canRetry,
    required this.severity,
  });
}

/// Represents the severity of recovery action needed
enum RecoverySeverity {
  automatic,      // Can be recovered automatically
  semiAutomatic,  // Needs some user input but can be handled
  manual,         // Requires manual user intervention
}

/// Error statistics
class ErrorStats {
  final int totalErrors;
  final int criticalErrors;
  final int warnings;
  final int info;
  final int consecutiveErrors;
  final bool shouldStop;

  const ErrorStats({
    required this.totalErrors,
    required this.criticalErrors,
    required this.warnings,
    required this.info,
    required this.consecutiveErrors,
    required this.shouldStop,
  });

  double get errorRate => totalErrors > 0 ? criticalErrors / totalErrors : 0.0;
}