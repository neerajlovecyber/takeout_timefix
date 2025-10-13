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

    // Create output directory if it doesn't exist
    await _ensureDirectoryExists(outputDirectory);

    for (final media in mediaList) {
      try {
        final organizedFile = await _organizeSingleMedia(
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

    return OrganizationResult(
      organizedFiles: organizedFiles,
      errors: errors,
      totalFiles: mediaList.length,
      successfulFiles: organizedFiles.length,
      failedFiles: errors.length,
    );
  }

  /// Organize a single media file
  Future<OrganizedFile> _organizeSingleMedia(
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
    final targetPath = await _getTargetPath(
      media,
      outputDirectory,
      mode,
      preserveOriginalFilename: preserveOriginalFilename,
      customDateFormat: customDateFormat,
    );

    // Ensure target directory exists
    final targetDir = path.dirname(targetPath);
    await _ensureDirectoryExists(targetDir);

    // Copy or move file to target location
    final targetFile = await _copyFileToTarget(sourceFile, targetPath);

    return OrganizedFile(
      sourceFile: sourceFile,
      targetFile: targetFile,
      organizationMode: mode,
      dateTaken: media.dateTaken,
      dateAccuracy: media.dateTakenAccuracy,
    );
  }

  /// Get the target path for a media file based on organization mode
  Future<String> _getTargetPath(
    Media media,
    String outputDirectory,
    OrganizationMode mode, {
    bool preserveOriginalFilename = false,
    String? customDateFormat,
  }) async {
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

      default:
        throw UnsupportedError('Organization mode $mode not supported');
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
      final datePrefix = '${year}${monthPadded}${dateTaken.day.toString().padLeft(2, '0')}_${dateTaken.hour.toString().padLeft(2, '0')}${dateTaken.minute.toString().padLeft(2, '0')}${dateTaken.second.toString().padLeft(2, '0')}';
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
    final timestamp = DateTime.now();
    final fallbackDate = '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}';

    if (preserveOriginalFilename) {
      final originalName = path.basename(media.primaryFile!.path);
      return path.join(outputDirectory, 'no_date', originalName);
    } else {
      final extension = path.extension(media.primaryFile!.path);
      final newFilename = '${fallbackDate}_no_date$extension';
      return path.join(outputDirectory, 'no_date', newFilename);
    }
  }

  /// Copy file to target location with conflict resolution
  Future<File> _copyFileToTarget(File sourceFile, String targetPath) async {
    final targetFile = File(targetPath);

    // Handle filename conflicts
    if (await targetFile.exists()) {
      targetPath = await _resolveFilenameConflict(targetPath);
    }

    // Copy the file
    await sourceFile.copy(targetPath);

    return File(targetPath);
  }

  /// Resolve filename conflicts by adding a suffix
  Future<String> _resolveFilenameConflict(String targetPath) async {
    final directory = path.dirname(targetPath);
    final filename = path.basenameWithoutExtension(targetPath);
    final extension = path.extension(targetPath);

    int counter = 1;
    String newPath;

    do {
      newPath = path.join(directory, '$filename($counter)$extension');
      counter++;
    } while (await File(newPath).exists());

    return newPath;
  }

  /// Ensure directory exists, creating it if necessary
  Future<void> _ensureDirectoryExists(String directoryPath) async {
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
        final targetPath = await _getTargetPath(media, outputDirectory, mode);
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