import 'dart:async';
import 'dart:io';
import '../models/media.dart';
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
  final FileService _fileService = FileService();
  final DuplicateService _duplicateService = DuplicateService();
  final FileOrganizationService _organizationService = FileOrganizationService();
  final ProgressService _progressService = ProgressService();
  final ErrorHandlingService _errorService = ErrorHandlingService();

  final JsonExtractor _jsonExtractor = JsonExtractor();
  final ExifExtractor _exifExtractor = ExifExtractor();
  final FilenameExtractor _filenameExtractor = FilenameExtractor();

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
      // Phase 1: File Discovery
      final mediaFiles = await _discoverMediaFiles();
      _progressService.updateProgress(20, statusMessage: 'Found ${mediaFiles.length} media files');

      // Phase 2: Timestamp Extraction
      final mediaWithTimestamps = await _extractTimestamps(mediaFiles);
      _progressService.updateProgress(50, statusMessage: 'Extracted timestamps for ${mediaWithTimestamps.length} files');

      // Phase 3: Duplicate Detection and Merging
      final uniqueMedia = await _processDuplicates(mediaWithTimestamps);
      _progressService.updateProgress(70, statusMessage: 'Processed duplicates, ${uniqueMedia.length} unique files');

      // Phase 4: File Organization
      final organizationResult = await _organizeFiles(uniqueMedia);
      _progressService.updateProgress(100, statusMessage: 'Organized ${organizationResult.successfulFiles} files');

      _progressService.completeOperation();

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

      final mediaFiles = await _fileService.findMediaFiles(_config.inputDirectory);

      if (mediaFiles.isEmpty) {
        throw Exception('No media files found in the specified directory');
      }

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

  /// Phase 2: Extract timestamps from all media files
  Future<List<Media>> _extractTimestamps(List<File> files) async {
    final mediaList = <Media>[];
    final totalFiles = files.length;

    _progressService.updateProgress(25, statusMessage: 'Starting timestamp extraction...');

    for (int i = 0; i < files.length; i++) {
      final file = files[i];

      try {
        final media = await _extractTimestampForFile(file);

        if (media.dateTaken != null) {
          mediaList.add(media);
        } else {
          _errorService.logError(
            message: 'No timestamp could be extracted',
            filePath: file.path,
            severity: ErrorSeverity.warning,
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

      // Update progress every 10 files or at the end
      if (i % 10 == 0 || i == files.length - 1) {
        final progress = 25 + ((i / totalFiles) * 25);
        _progressService.updateProgress(progress.round(),
          statusMessage: 'Processed ${i + 1}/$totalFiles files for timestamps');
      }
    }

    return mediaList;
  }

  /// Extract timestamp for a single file using multiple methods
  Future<Media> _extractTimestampForFile(File file) async {
    final media = Media.single(file);

    // Method 1: JSON metadata (most accurate)
    try {
      final jsonTimestamp = await _jsonExtractor.extractTimestamp(file);
      if (jsonTimestamp != null) {
        media.dateTaken = jsonTimestamp;
        media.dateTakenAccuracy = 0; // Most accurate
        return media;
      }
    } catch (e) {
      _errorService.logError(
        message: 'JSON extraction failed: $e',
        filePath: file.path,
        severity: ErrorSeverity.info,
        category: ErrorCategory.metadataExtraction,
        exception: e as Exception?,
      );
    }

    // Method 2: EXIF data (medium accuracy)
    try {
      final exifTimestamp = await _exifExtractor.extractTimestamp(file);
      if (exifTimestamp != null) {
        media.dateTaken = exifTimestamp;
        media.dateTakenAccuracy = 1; // Medium accuracy
        return media;
      }
    } catch (e) {
      _errorService.logError(
        message: 'EXIF extraction failed: $e',
        filePath: file.path,
        severity: ErrorSeverity.info,
        category: ErrorCategory.metadataExtraction,
        exception: e as Exception?,
      );
    }

    // Method 3: Filename pattern (least accurate)
    try {
      final filenameTimestamp = _filenameExtractor.extractTimestamp(file);
      if (filenameTimestamp != null) {
        media.dateTaken = filenameTimestamp;
        media.dateTakenAccuracy = 2; // Least accurate
        return media;
      }
    } catch (e) {
      _errorService.logError(
        message: 'Filename extraction failed: $e',
        filePath: file.path,
        severity: ErrorSeverity.info,
        category: ErrorCategory.metadataExtraction,
        exception: e as Exception?,
      );
    }

    // Method 4: File system date (fallback)
    try {
      final fileStat = await file.stat();
      final fileSystemDate = fileStat.modified; // or accessed/created
      media.dateTaken = fileSystemDate;
      media.dateTakenAccuracy = 3; // Fallback
    } catch (e) {
      _errorService.logError(
        message: 'File system date extraction failed: $e',
        filePath: file.path,
        severity: ErrorSeverity.info,
        category: ErrorCategory.metadataExtraction,
        exception: e as Exception?,
      );
    }

    return media;
  }

  /// Phase 3: Process duplicates and merge them
  Future<List<Media>> _processDuplicates(List<Media> mediaList) async {
    _progressService.updateProgress(55, statusMessage: 'Detecting duplicates...');

    try {
      // Group media by hash to find duplicates
      final hashGroups = await _duplicateService.groupMediaByHash(mediaList);

      // Merge duplicate groups
      final mergedMedia = _duplicateService.mergeDuplicates(hashGroups);

      // Add any media that couldn't be hashed (treat as unique)
      final unhashableMedia = mediaList.where((media) => media.hash == null).toList();
      mergedMedia.addAll(unhashableMedia);

      return mergedMedia;
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
    _progressService.updateProgress(75, statusMessage: 'Organizing files...');

    try {
      return await _organizationService.organizeFiles(
        mediaList,
        _config.outputDirectory,
        _config.organizationMode,
        preserveOriginalFilename: _config.preserveOriginalFilename,
      );
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
    _duplicateService.clearCaches();
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