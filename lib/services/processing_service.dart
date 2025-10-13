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

  /// Background processing function that runs in isolate
  static Future<ProcessingResult> _processInBackground(Map<String, dynamic> params) async {
    final config = params['config'] as ProcessingConfig;

    // Create new service instances for the isolate (no Timer objects)
    final fileService = FileService();
    final duplicateService = DuplicateService();
    final organizationService = FileOrganizationService();
    final errorService = ErrorHandlingService(); // Create new instance without Timer
    final jsonExtractor = JsonExtractor();
    final exifExtractor = ExifExtractor();
    final filenameExtractor = FilenameExtractor();

    try {
      // Phase 1: File Discovery with timeout and better error handling
      final mediaFiles = await _discoverMediaFilesInIsolate(config, fileService, errorService)
        .timeout(const Duration(minutes: 5), onTimeout: () {
          throw TimeoutException('File discovery took too long');
        });

      // Phase 2: Timestamp Extraction
      final mediaWithTimestamps = await _extractTimestampsInIsolate(
        mediaFiles, jsonExtractor, exifExtractor, filenameExtractor, errorService
      );

      // Phase 3: Duplicate Detection and Merging
      final uniqueMedia = await _processDuplicatesInIsolate(mediaWithTimestamps, duplicateService, errorService);

      // Phase 4: File Organization
      final organizationResult = await _organizeFilesInIsolate(
        uniqueMedia, config, organizationService, errorService
      );

      return ProcessingResult.success(
        totalFiles: mediaFiles.length,
        processedFiles: mediaWithTimestamps.length,
        uniqueFiles: uniqueMedia.length,
        organizedFiles: organizationResult.successfulFiles,
        errors: errorService.errors,
        warnings: errorService.getErrorsBySeverity(ErrorSeverity.warning),
      );

    } catch (e) {
      return ProcessingResult.failure(
        error: e.toString(),
        errors: errorService.errors,
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

  /// Phase 1: Discover all media files in the input directory (isolate version)
  static Future<List<File>> _discoverMediaFilesInIsolate(
    ProcessingConfig config,
    FileService fileService,
    ErrorHandlingService errorService,
  ) async {
    try {
      // Use a more efficient approach for large directories
      final mediaFiles = <File>[];

      // Check if directory exists first
      final directory = Directory(config.inputDirectory);
      if (!await directory.exists()) {
        throw Exception('Directory does not exist: ${config.inputDirectory}');
      }

      // Use a more controlled approach to avoid hanging
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          try {
            // Check if it's a media file using the service method
            if (fileService.isImageFile(entity) || fileService.isVideoFile(entity)) {
              mediaFiles.add(entity);
            }
          } catch (e) {
            // Skip files that can't be processed
            continue;
          }
        }

        // Prevent infinite loops by limiting file count (safety measure)
        if (mediaFiles.length > 100000) {
          break;
        }
      }

      if (mediaFiles.isEmpty) {
        throw Exception('No media files found in the specified directory');
      }

      return mediaFiles;
    } catch (e) {
      errorService.logError(
        message: 'Failed to discover media files: $e',
        filePath: config.inputDirectory,
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

      // Update progress every 10 files or at the end for more responsive updates
      if (i % 10 == 0 || i == files.length - 1) {
        final progress = 15 + ((i / totalFiles) * 30); // 15-45% range for this phase
        _progressService.updateProgress(progress.round(),
          statusMessage: 'Processed ${i + 1}/$totalFiles files for timestamps');
      }
    }

    return mediaList;
  }

  /// Phase 2: Extract timestamps from all media files (isolate version)
  static Future<List<Media>> _extractTimestampsInIsolate(
    List<File> files,
    JsonExtractor jsonExtractor,
    ExifExtractor exifExtractor,
    FilenameExtractor filenameExtractor,
    ErrorHandlingService errorService,
  ) async {
    final mediaList = <Media>[];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];

      try {
        final media = await _extractTimestampForFileInIsolate(
          file, jsonExtractor, exifExtractor, filenameExtractor
        );

        if (media.dateTaken != null) {
          mediaList.add(media);
        } else {
          errorService.logError(
            message: 'No timestamp could be extracted',
            filePath: file.path,
            severity: ErrorSeverity.warning,
            category: ErrorCategory.metadataExtraction,
          );
        }
      } catch (e) {
        errorService.logError(
          message: 'Failed to process file: $e',
          filePath: file.path,
          severity: ErrorSeverity.error,
          category: ErrorCategory.processing,
          exception: e as Exception?,
        );
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

  /// Extract timestamp for a single file using multiple methods (isolate version)
  static Future<Media> _extractTimestampForFileInIsolate(
    File file,
    JsonExtractor jsonExtractor,
    ExifExtractor exifExtractor,
    FilenameExtractor filenameExtractor,
  ) async {
    final media = Media.single(file);

    // Method 1: JSON metadata (most accurate)
    try {
      final jsonTimestamp = await jsonExtractor.extractTimestamp(file);
      if (jsonTimestamp != null) {
        media.dateTaken = jsonTimestamp;
        media.dateTakenAccuracy = 0; // Most accurate
        return media;
      }
    } catch (e) {
      // Log error would need error service passed in if needed
    }

    // Method 2: EXIF data (medium accuracy)
    try {
      final exifTimestamp = await exifExtractor.extractTimestamp(file);
      if (exifTimestamp != null) {
        media.dateTaken = exifTimestamp;
        media.dateTakenAccuracy = 1; // Medium accuracy
        return media;
      }
    } catch (e) {
      // Log error would need error service passed in if needed
    }

    // Method 3: Filename pattern (least accurate)
    try {
      final filenameTimestamp = filenameExtractor.extractTimestamp(file);
      if (filenameTimestamp != null) {
        media.dateTaken = filenameTimestamp;
        media.dateTakenAccuracy = 2; // Least accurate
        return media;
      }
    } catch (e) {
      // Log error would need error service passed in if needed
    }

    // Method 4: File system date (fallback)
    try {
      final fileStat = await file.stat();
      final fileSystemDate = fileStat.modified; // or accessed/created
      media.dateTaken = fileSystemDate;
      media.dateTakenAccuracy = 3; // Fallback
    } catch (e) {
      // Log error would need error service passed in if needed
    }

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

      // Merge duplicate groups with progress updates
      final mergedMedia = await _duplicateService.mergeDuplicatesWithProgress(
        hashGroups,
        (progress, status) {
          // Update progress during merging (65-75% range)
          final progressValue = 65 + (progress * 10); // Spread over 10% range
          _progressService.updateProgress(progressValue.round(), statusMessage: status);
        },
      );

      // Add any media that couldn't be hashed (treat as unique)
      final unhashableMedia = mediaList.where((media) => media.hash == null).toList();
      mergedMedia.addAll(unhashableMedia);

      _progressService.updateProgress(80, statusMessage: 'Duplicate detection complete, ${mergedMedia.length} unique files');

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

  /// Phase 3: Process duplicates and merge them (isolate version)
  static Future<List<Media>> _processDuplicatesInIsolate(
    List<Media> mediaList,
    DuplicateService duplicateService,
    ErrorHandlingService errorService,
  ) async {
    try {
      // Group media by hash to find duplicates
      final hashGroups = await duplicateService.groupMediaByHash(mediaList);

      // Merge duplicate groups
      final mergedMedia = duplicateService.mergeDuplicates(hashGroups);

      // Add any media that couldn't be hashed (treat as unique)
      final unhashableMedia = mediaList.where((media) => media.hash == null).toList();
      mergedMedia.addAll(unhashableMedia);

      return mergedMedia;
    } catch (e) {
      errorService.logError(
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

  /// Phase 4: Organize files into the target structure (isolate version)
  static Future<OrganizationResult> _organizeFilesInIsolate(
    List<Media> mediaList,
    ProcessingConfig config,
    FileOrganizationService organizationService,
    ErrorHandlingService errorService,
  ) async {
    try {
      return await organizationService.organizeFiles(
        mediaList,
        config.outputDirectory,
        config.organizationMode,
        preserveOriginalFilename: config.preserveOriginalFilename,
      );
    } catch (e) {
      errorService.logError(
        message: 'File organization failed: $e',
        filePath: config.outputDirectory,
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