import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/media.dart';

/// Organization modes for file arrangement
enum OrganizationMode {
  yearMonthFolders,  // Organize into YYYY/MM-MonthName/ structure
  singleFolder,      // Place all files in one folder with date prefixes
}

/// Service for organizing media files into structured folders
class FileOrganizationService {
  /// Month names for folder organization (English)
  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  /// Organize media files according to the specified mode
  Future<OrganizationResult> organizeFiles(
    List<Media> mediaList,
    String outputDirectory,
    OrganizationMode mode, {
    bool preserveOriginalFilename = false,
    String? customDateFormat,
  }) async {
    final organizedFiles = <OrganizedFile>[];
    final errors = <String>[];

    // Create output directory if it doesn't exist (async)
    await _ensureDirectoryExistsAsync(outputDirectory);

    // Process files with progress-aware batching
    const batchSize = 10; // Process in smaller batches for better responsiveness
    for (int i = 0; i < mediaList.length; i += batchSize) {
      final endIndex = (i + batchSize < mediaList.length) ? i + batchSize : mediaList.length;
      final batch = mediaList.sublist(i, endIndex);

      for (final media in batch) {
        try {
          final organizedFile = await _organizeSingleMediaAsync(
            media,
            outputDirectory,
            mode,
            preserveOriginalFilename: preserveOriginalFilename,
            customDateFormat: customDateFormat,
          );
          organizedFiles.add(organizedFile);
        } catch (e) {
          errors.add('Failed to organize ${media.primaryFile?.path}: $e');
        }
      }
    }

    return OrganizationResult(
      organizedFiles: organizedFiles,
      errors: errors,
      totalFiles: mediaList.length,
      successfulFiles: organizedFiles.length,
      failedFiles: errors.length,
    );
  }

  /// Organize a single media file (async version to prevent UI blocking)
  Future<OrganizedFile> _organizeSingleMediaAsync(
    Media media,
    String outputDirectory,
    OrganizationMode mode, {
    bool preserveOriginalFilename = false,
    String? customDateFormat,
  }) async {
    final sourceFile = media.primaryFile;
    if (sourceFile == null) {
      throw Exception('No primary file found for media');
    }

    // Determine target path based on organization mode
    final targetPath = _getTargetPath(
      media,
      outputDirectory,
      mode,
      preserveOriginalFilename: preserveOriginalFilename,
      customDateFormat: customDateFormat,
    );

    // Ensure target directory exists (async)
    final targetDir = path.dirname(targetPath);
    await _ensureDirectoryExistsAsync(targetDir);

    // Copy or move file to target location (async)
    final targetFile = await _moveFileToTarget(sourceFile, targetPath);

    // Preserve ORIGINAL timestamp from Media object (matches example script approach)
    if (media.dateTaken != null) {
      try {
        await targetFile.setLastModified(media.dateTaken!);
      } catch (e) {
        // Handle cases where timestamp setting fails (matches example script error handling)
        // Log warning but continue processing
      }
    }

    return OrganizedFile(
      sourceFile: sourceFile,
      targetFile: targetFile,
      organizationMode: mode,
      dateTaken: media.dateTaken,
      dateAccuracy: media.dateTakenAccuracy,
    );
  }

  /// Get the target path for a media file based on organization mode (synchronous for performance)
  String _getTargetPath(
    Media media,
    String outputDirectory,
    OrganizationMode mode, {
    bool preserveOriginalFilename = false,
    String? customDateFormat,
  }) {
    final dateTaken = media.dateTaken;
    if (dateTaken == null) {
      // If no date available, use current date or a default structure
      return _getFallbackTargetPath(media, outputDirectory, mode, preserveOriginalFilename);
    }

    switch (mode) {
      case OrganizationMode.yearMonthFolders:
        return _getYearMonthFolderPath(media, outputDirectory, preserveOriginalFilename);

      case OrganizationMode.singleFolder:
        return _getSingleFolderPath(media, outputDirectory, preserveOriginalFilename);
    }
  }

  /// Get target path for year-month folder organization
  String _getYearMonthFolderPath(Media media, String outputDirectory, bool preserveOriginalFilename) {
    final dateTaken = media.dateTaken!;
    final year = dateTaken.year.toString();
    final month = _monthNames[dateTaken.month - 1];
    final monthPadded = dateTaken.month.toString().padLeft(2, '0');

    // Create folder structure: outputDirectory/YYYY/MM-MonthName/
    final folderPath = path.join(outputDirectory, year, '$monthPadded-$month');

    if (preserveOriginalFilename) {
      // Use original filename in the dated folder
      final originalName = path.basename(media.primaryFile!.path);
      return path.join(folderPath, originalName);
    } else {
      // Create new filename with date prefix
      final datePrefix = '$year$monthPadded${dateTaken.day.toString().padLeft(2, '0')}_${dateTaken.hour.toString().padLeft(2, '0')}${dateTaken.minute.toString().padLeft(2, '0')}${dateTaken.second.toString().padLeft(2, '0')}';
      final extension = path.extension(media.primaryFile!.path);
      final newFilename = '$datePrefix$extension';
      return path.join(folderPath, newFilename);
    }
  }

  /// Get target path for single folder organization
  String _getSingleFolderPath(Media media, String outputDirectory, bool preserveOriginalFilename) {
    final dateTaken = media.dateTaken!;

    if (preserveOriginalFilename) {
      // Use original filename in the output folder
      final originalName = path.basename(media.primaryFile!.path);
      return path.join(outputDirectory, originalName);
    } else {
      // Create new filename with date prefix
      final datePrefix = '${dateTaken.year}${dateTaken.month.toString().padLeft(2, '0')}${dateTaken.day.toString().padLeft(2, '0')}_${dateTaken.hour.toString().padLeft(2, '0')}${dateTaken.minute.toString().padLeft(2, '0')}${dateTaken.second.toString().padLeft(2, '0')}';
      final extension = path.extension(media.primaryFile!.path);
      final newFilename = '$datePrefix$extension';
      return path.join(outputDirectory, newFilename);
    }
  }

  /// Get fallback target path when no date is available
  String _getFallbackTargetPath(Media media, String outputDirectory, OrganizationMode mode, bool preserveOriginalFilename) {
    // Match original script: use 'date-unknown' folder name
    if (preserveOriginalFilename) {
      final originalName = path.basename(media.primaryFile!.path);
      return path.join(outputDirectory, 'date-unknown', originalName);
    } else {
      final extension = path.extension(media.primaryFile!.path);
      final baseName = path.basenameWithoutExtension(media.primaryFile!.path);
      final newFilename = '${baseName}_no_date$extension';
      return path.join(outputDirectory, 'date-unknown', newFilename);
    }
  }

  /// Move file to target location with conflict resolution
  Future<File> _moveFileToTarget(File sourceFile, String targetPath) async {
    final targetFile = _findNotExistingName(File(targetPath));

    try {
      return await sourceFile.rename(targetFile.path);
    } on FileSystemException {
      // If rename fails (e.g., different drives), fall back to copy
      return await sourceFile.copy(targetFile.path);
    }
  }

  /// This will add (1) add end of file name over and over until file with such
  /// name doesn't exist yet. Will leave without "(1)" if is free already
  File _findNotExistingName(File initialFile) {
    var file = initialFile;
    while (file.existsSync()) {
      file = File(
          '${path.withoutExtension(file.path)}(1)${path.extension(file.path)}');
    }
    return file;
  }


  /// Ensure directory exists, creating it if necessary (async version)
  Future<void> _ensureDirectoryExistsAsync(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  /// Get organized folder structure for preview
  Future<List<String>> getPreviewStructure(
    List<Media> mediaList,
    String outputDirectory,
    OrganizationMode mode,
  ) async {
    final structure = <String>{};

    for (final media in mediaList) {
      if (media.dateTaken == null) continue;

      try {
        final targetPath = _getTargetPath(media, outputDirectory, mode);
        final relativePath = path.relative(targetPath, from: outputDirectory);
        structure.add(relativePath);
      } catch (e) {
        // Skip files that can't be organized
      }
    }

    return structure.toList()..sort();
  }

  /// Calculate total size of files to be organized
  Future<int> calculateTotalSize(List<Media> mediaList) async {
    int totalSize = 0;

    for (final media in mediaList) {
      final file = media.primaryFile;
      if (file != null) {
        try {
          totalSize += await file.length();
        } catch (e) {
          // Skip files that can't be accessed
        }
      }
    }

    return totalSize;
  }
}

/// Represents the result of a file organization operation
class OrganizationResult {
  final List<OrganizedFile> organizedFiles;
  final List<String> errors;
  final int totalFiles;
  final int successfulFiles;
  final int failedFiles;

  const OrganizationResult({
    required this.organizedFiles,
    required this.errors,
    required this.totalFiles,
    required this.successfulFiles,
    required this.failedFiles,
  });

  bool get isSuccessful => errors.isEmpty;
  double get successRate => totalFiles > 0 ? successfulFiles / totalFiles : 0.0;
}

/// Represents a single organized file
class OrganizedFile {
  final File sourceFile;
  final File targetFile;
  final OrganizationMode organizationMode;
  final DateTime? dateTaken;
  final int? dateAccuracy;

  const OrganizedFile({
    required this.sourceFile,
    required this.targetFile,
    required this.organizationMode,
    this.dateTaken,
    this.dateAccuracy,
  });

  String get sourcePath => sourceFile.path;
  String get targetPath => targetFile.path;
  String? get dateSource => dateAccuracy == 0 ? 'JSON' : dateAccuracy == 1 ? 'EXIF' : dateAccuracy == 2 ? 'Filename' : 'Unknown';
}