import 'dart:async';
import 'dart:io';
import '../models/media.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'file_service.dart';
import 'duplicate_service.dart';
import 'file_organization_service.dart';
import 'progress_service.dart';
import 'error_handling_service.dart';
import 'timestamp_extractors/json_extractor.dart';
import 'timestamp_extractors/exif_extractor.dart';
import 'timestamp_extractors/filename_extractor.dart';

/// Main service that coordinates the entire image processing pipeline
class ProcessingService {
  final FileService _fileService;
  final DuplicateService _duplicateService;
  final FileOrganizationService _organizationService;
  final ProgressService _progressService;
  final ErrorHandlingService _errorService;

  final JsonExtractor _jsonExtractor;
  final ExifExtractor _exifExtractor;
  final FilenameExtractor _filenameExtractor;

  ProcessingService()
      : _fileService = FileService(),
        _duplicateService = DuplicateService(),
        _organizationService = FileOrganizationService(),
        _progressService = ProgressService(),
        _errorService = ErrorHandlingService(),
        _jsonExtractor = JsonExtractor(),
        _exifExtractor = ExifExtractor(),
        _filenameExtractor = FilenameExtractor(ErrorHandlingService());

  /// Processing configuration
  late ProcessingConfig _config;

  /// Streams for monitoring progress and status
  Stream<ProgressUpdate> get progressStream => _progressService.progressStream;
  Stream<String> get statusStream => _progressService.statusStream;
  Stream<String> get errorStream => _errorService.errorStream;

  /// Current processing state
  bool get isProcessing => _progressService.isRunning;

  /// Start the complete processing pipeline
  Future<ProcessingResult> startProcessing(ProcessingConfig config) async {
    _config = config;

    // Initialize services
    _progressService.startOperation('Complete Processing Pipeline', 100);

    try {
      // Use main thread processing for better progress reporting and reliability
      // Isolate processing had issues with progress updates and error handling
      final result = await _processInMainThread(config);

      _progressService.completeOperation();

      return result;

    } catch (e) {
      _progressService.reportError('Processing failed: $e', isFatal: true);
      return ProcessingResult.failure(
        error: e.toString(),
        errors: _errorService.errors,
      );
    }
  }

  /// Main processing method that runs on main thread with detailed progress updates
 Future<ProcessingResult> _processInMainThread(ProcessingConfig config) async {
   try {
     // Phase 1: File Discovery (0-10%) - REDUCED
     _progressService.updateProgress(3, statusMessage: 'Scanning for media files...');
     final mediaFiles = await _discoverMediaFiles();

     if (mediaFiles.isEmpty) {
       throw Exception('No media files found in the specified directory');
     }

     _progressService.updateProgress(10, statusMessage: 'Found ${mediaFiles.length} media files');

     // Phase 2: Timestamp Extraction (10-45%) - SLIGHTLY REDUCED
     _progressService.updateProgress(15, statusMessage: 'Starting timestamp extraction...');
     final mediaWithTimestamps = await _extractTimestamps(mediaFiles);
     _progressService.updateProgress(45, statusMessage: 'Extracted timestamps for ${mediaWithTimestamps.length}/${mediaFiles.length} files');

     // Phase 3: Duplicate Detection and Merging (45-80%) - INCREASED
     _progressService.updateProgress(47, statusMessage: 'Detecting duplicates...');
     final uniqueMedia = await _processDuplicates(mediaWithTimestamps);
     _progressService.updateProgress(80, statusMessage: 'Processed duplicates, ${uniqueMedia.length} unique files');

     // Phase 4: File Organization (80-100%) - SLIGHTLY REDUCED
     _progressService.updateProgress(83, statusMessage: 'Organizing files...');
     final organizationResult = await _organizeFiles(uniqueMedia);
     _progressService.updateProgress(100, statusMessage: 'Organized ${organizationResult.successfulFiles} files successfully');

     // After processing is complete, export the log
     final logFilePath = path.join(config.outputDirectory, 'takeout_timefix_log.txt');
     await _errorService.exportErrorLog(logFilePath);

      return ProcessingResult.success(
        totalFiles: mediaFiles.length,
        processedFiles: mediaWithTimestamps.length,
        uniqueFiles: uniqueMedia.length,
        organizedFiles: organizationResult.successfulFiles,
        errors: _errorService.errors,
        warnings: _errorService.getErrorsBySeverity(ErrorSeverity.warning),
      );

    } catch (e) {
      _progressService.reportError('Processing failed: $e', isFatal: true);
      return ProcessingResult.failure(
        error: e.toString(),
        errors: _errorService.errors,
      );
    }
  }


  /// Phase 1: Discover all media files in the input directory
  Future<List<File>> _discoverMediaFiles() async {
    try {
      _progressService.updateProgress(5, statusMessage: 'Scanning for media files...');

      // Add timeout to prevent hanging on inaccessible directories
      final mediaFiles = await _fileService.findMediaFiles(_config.inputDirectory)
        .timeout(const Duration(minutes: 2), onTimeout: () {
          throw TimeoutException('File discovery timed out after 2 minutes');
        });

      if (mediaFiles.isEmpty) {
        throw Exception('No media files found in the specified directory');
      }

      _progressService.updateProgress(10, statusMessage: 'Scan complete, found ${mediaFiles.length} files');
      return mediaFiles;
    } catch (e) {
      _errorService.logError(
        message: 'Failed to discover media files: $e',
        filePath: _config.inputDirectory,
        severity: ErrorSeverity.error,
        category: ErrorCategory.fileAccess,
        exception: e as Exception?,
      );
      rethrow;
    }
  }


  /// Phase 2: Extract timestamps from all media files (simplified like original)
  Future<List<Media>> _extractTimestamps(List<File> files) async {
    final mediaList = <Media>[];
    final totalFiles = files.length;

    _progressService.updateProgress(20, statusMessage: 'Starting timestamp extraction...');

    for (int i = 0; i < files.length; i++) {
      final file = files[i];

      try {
        // Extract timestamp for file (direct like original)
        final media = await _extractTimestampForFile(file);

        // Include ALL files in processing, even those without timestamps
        // Files without timestamps will go to date-unknown folder during organization
        mediaList.add(media);

        // If, after all attempts, the date is still null, log it for debugging.
        if (media.dateTaken == null) {
          _errorService.logError(
            message: 'Could not determine timestamp for file after trying all methods.',
            filePath: file.path,
            severity: ErrorSeverity.info,
            category: ErrorCategory.metadataExtraction,
          );
        }
      } catch (e) {
        _errorService.logError(
          message: 'Failed to process file: $e',
          filePath: file.path,
          severity: ErrorSeverity.error,
          category: ErrorCategory.processing,
          exception: e as Exception?,
        );
      }

      // Update progress every 10 files or at the end for more responsive updates
      if (i % 10 == 0 || i == files.length - 1) {
        final progress = 15 + ((i / totalFiles) * 30); // 15-45% range for this phase
        _progressService.updateProgress(progress.round(),
          statusMessage: 'Processed ${i + 1}/$totalFiles files for timestamps');
      }
    }

    return mediaList;
  }


  /// Extract timestamp for a single file using multiple methods
  Future<Media> _extractTimestampForFile(File file) async {
    final media = Media.single(file);
    DateTime? timestamp;
    int accuracy = 0;

    // Create a list of extraction methods to try in order
    final List<Future<DateTime?> Function()> extractors = [
      () => _jsonExtractor.extractTimestamp(file),
      () => _exifExtractor.extractTimestamp(file),
      () async => _filenameExtractor.extractTimestamp(file),
      () => _jsonExtractor.extractTimestamp(file, tryhard: true),
      () async { // Filesystem as a final fallback
        final fileStat = await file.stat();
        if (DateTime.now().difference(fileStat.modified).inDays < 30) {
          return null;
        }
        return fileStat.changed.millisecondsSinceEpoch > 0 ? fileStat.changed : null;
      },
    ];

    for (final extractor in extractors) {
      try {
        timestamp = await extractor();
        if (timestamp != null) {
          media.dateTaken = timestamp;
          media.dateTakenAccuracy = accuracy;
          return media; // Found a timestamp, so we can stop
        }
      } catch (e) {
        // Log the error but continue to the next extractor
        _errorService.logError(
          message: 'Timestamp extraction failed for method $accuracy: $e',
          filePath: file.path,
          severity: ErrorSeverity.info,
          category: ErrorCategory.metadataExtraction,
          exception: e is Exception ? e : Exception(e.toString()),
        );
      }
      accuracy++;
    }

    // If no extractor found a date, return the media object without a date
    return media;
  }


  /// Phase 3: Process duplicates and merge them
  Future<List<Media>> _processDuplicates(List<Media> mediaList) async {
    _progressService.updateProgress(47, statusMessage: 'Starting duplicate detection...');

    try {
      // Group media by hash to find duplicates with progress updates
      _progressService.updateProgress(48, statusMessage: 'Calculating file hashes...');

      final hashGroups = await _duplicateService.groupMediaByHashWithProgress(
        mediaList,
        (progress, status) {
          // Update progress during hash calculation (48-65% range) - INCREASED RANGE
          final progressValue = 48 + (progress * 17); // Spread over 17% range
          _progressService.updateProgress(progressValue.round(), statusMessage: status);
        },
      );

      _progressService.updateProgress(65, statusMessage: 'Merging duplicate groups...');

      // Separate the files that received a dummy hash because they were too large.
      // These should not be merged.
      final dummyHashKey = Digest([0]).toString();
      final largeFiles = hashGroups.remove(dummyHashKey) ?? [];

      // Merge the actual duplicates and then add the large files back in as unique items.
      final mergedDuplicates = await _duplicateService.mergeDuplicatesWithProgress(
        hashGroups,
        (progress, status) {
          final progressValue = 65 + (progress * 15); // 65-80% range
          _progressService.updateProgress(progressValue.round(), statusMessage: status);
        },
      );

      final uniqueMedia = mergedDuplicates + largeFiles;

      _progressService.updateProgress(80, statusMessage: 'Processed duplicates, ${uniqueMedia.length} unique files remaining');

      return uniqueMedia;
    } catch (e) {
      _errorService.logError(
        message: 'Duplicate processing failed: $e',
        filePath: 'batch_operation',
        severity: ErrorSeverity.error,
        category: ErrorCategory.processing,
        exception: e as Exception?,
      );
      return mediaList; // Return original list if duplicate processing fails
    }
  }


  /// Phase 4: Organize files into the target structure
  Future<OrganizationResult> _organizeFiles(List<Media> mediaList) async {
    _progressService.updateProgress(82, statusMessage: 'Preparing file organization...');

    try {
      // Update progress as files are being organized
      _progressService.updateProgress(85, statusMessage: 'Creating directories and organizing ${mediaList.length} files...');

      final result = await _organizationService.organizeFiles(
        mediaList,
        _config.outputDirectory,
        _config.organizationMode,
        preserveOriginalFilename: _config.preserveOriginalFilename,
      );

      _progressService.updateProgress(100, statusMessage: 'Successfully organized ${result.successfulFiles}/${result.totalFiles} files');

      return result;
    } catch (e) {
      _errorService.logError(
        message: 'File organization failed: $e',
        filePath: _config.outputDirectory,
        severity: ErrorSeverity.error,
        category: ErrorCategory.processing,
        exception: e as Exception?,
      );
      rethrow;
    }
  }


  /// Cancel the current processing operation
  void cancelProcessing() {
    _progressService.cancelOperation();
  }

  /// Get current processing statistics
  ProcessingStats getStats() {
    final errorStats = _errorService.getStats();
    final progressStats = _progressService.getStats();

    return ProcessingStats(
      isProcessing: isProcessing,
      errorStats: errorStats,
      progressStats: progressStats,
      elapsedTime: progressStats.elapsedTime,
      estimatedTimeRemaining: progressStats.estimatedTimeRemaining,
    );
  }

  /// Reset all services for a fresh start
  void reset() {
    _progressService.reset();
    _errorService.clearErrors();
  }
}

/// Configuration for the processing operation
class ProcessingConfig {
  final String inputDirectory;
  final String outputDirectory;
  final OrganizationMode organizationMode;
  final bool preserveOriginalFilename;

  const ProcessingConfig({
    required this.inputDirectory,
    required this.outputDirectory,
    required this.organizationMode,
    this.preserveOriginalFilename = false,
  });
}

/// Result of the complete processing operation
class ProcessingResult {
  final bool isSuccess;
  final String? error;
  final int totalFiles;
  final int processedFiles;
  final int uniqueFiles;
  final int organizedFiles;
  final List<ProcessingError> errors;
  final List<ProcessingError> warnings;

  ProcessingResult._({
    required this.isSuccess,
    this.error,
    this.totalFiles = 0,
    this.processedFiles = 0,
    this.uniqueFiles = 0,
    this.organizedFiles = 0,
    this.errors = const [],
    this.warnings = const [],
  });

  factory ProcessingResult.success({
    required int totalFiles,
    required int processedFiles,
    required int uniqueFiles,
    required int organizedFiles,
    required List<ProcessingError> errors,
    required List<ProcessingError> warnings,
  }) {
    return ProcessingResult._(
      isSuccess: true,
      totalFiles: totalFiles,
      processedFiles: processedFiles,
      uniqueFiles: uniqueFiles,
      organizedFiles: organizedFiles,
      errors: errors,
      warnings: warnings,
    );
  }

  factory ProcessingResult.failure({
    required String error,
    required List<ProcessingError> errors,
  }) {
    return ProcessingResult._(
      isSuccess: false,
      error: error,
      errors: errors,
    );
  }
}

/// Current processing statistics
class ProcessingStats {
  final bool isProcessing;
  final ErrorStats errorStats;
  final OperationStats progressStats;
  final Duration elapsedTime;
  final Duration? estimatedTimeRemaining;

  const ProcessingStats({
    required this.isProcessing,
    required this.errorStats,
    required this.progressStats,
    required this.elapsedTime,
    this.estimatedTimeRemaining,
  });
}