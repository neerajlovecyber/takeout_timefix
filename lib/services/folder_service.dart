import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

class FolderService {
  static const List<String> _imageExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic', '.mov', '.mp4'
  ];

  static const List<String> _googlePhotosIndicators = [
    'google photos', 'photos', 'takeout', 'media'
  ];

  Future<String?> selectTakeoutFolder({String? initialDirectory}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      return await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Google Photos Takeout Folder',
        initialDirectory: initialDirectory ?? 'C:\\',
      );
    } catch (e) {
      throw Exception('Error selecting folder: ${e.toString()}');
    }
  }

  Future<String?> selectOutputFolder() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      return await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Output Folder',
        initialDirectory: 'C:\\',
      );
    } catch (e) {
      throw Exception('Error selecting output folder: ${e.toString()}');
    }
  }

  Future<FolderValidationResult> validateTakeoutFolder(String folderPath) async {
    try {
      final directory = Directory(folderPath);

      if (!await directory.exists()) {
        return FolderValidationResult.invalid('Folder does not exist');
      }

      final foundImages = await _findImageFiles(directory);
      final hasGooglePhotosStructure = await _checkGooglePhotosStructure(directory);

      return FolderValidationResult(
        isValid: foundImages.isNotEmpty || hasGooglePhotosStructure,
        imageFiles: foundImages,
        hasGooglePhotosStructure: hasGooglePhotosStructure,
      );
    } catch (e) {
      return FolderValidationResult.invalid('Error validating folder: $e');
    }
  }

  Future<OutputFolderValidationResult> validateOutputFolder(String folderPath) async {
    try {
      final directory = Directory(folderPath);
      bool exists = await directory.exists();

      if (!exists) {
        try {
          await directory.create(recursive: true);
          exists = true;
        } catch (e) {
          return OutputFolderValidationResult.invalid(
            'Cannot create output folder. Check permissions: ${e.toString().substring(0, min(80, e.toString().length))}'
          );
        }
      }

      final canWrite = await _checkWritePermissions(folderPath);

      return OutputFolderValidationResult(
        isValid: exists,
        hasWritePermissions: canWrite,
      );
    } catch (e) {
      return OutputFolderValidationResult.invalid(
        'Error validating output folder: ${e.toString().substring(0, min(80, e.toString().length))}'
      );
    }
  }

  Future<List<String>> _findImageFiles(Directory directory) async {
    List<String> foundImages = [];

    await for (var entity in directory.list(recursive: true)) {
      if (entity is File) {
        String extension = path.extension(entity.path).toLowerCase();
        if (_imageExtensions.contains(extension)) {
          foundImages.add(entity.path);
        }
      }
    }

    return foundImages;
  }

  Future<bool> _checkGooglePhotosStructure(Directory directory) async {
    try {
      List<String> subdirs = [];
      await for (var entity in directory.list(recursive: false)) {
        if (entity is Directory) {
          subdirs.add(path.basename(entity.path));
        }
      }

      return subdirs.any((dir) =>
        _googlePhotosIndicators.any((indicator) =>
          dir.toLowerCase().contains(indicator)));
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkWritePermissions(String folderPath) async {
    try {
      final String testFilePath = path.join(folderPath, '.takeout_timefix_test');
      final File testFile = File(testFilePath);
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}

class FolderValidationResult {
  final bool isValid;
  final List<String> imageFiles;
  final bool hasGooglePhotosStructure;
  final String? errorMessage;

  FolderValidationResult({
    required this.isValid,
    this.imageFiles = const [],
    this.hasGooglePhotosStructure = false,
    this.errorMessage,
  });

  factory FolderValidationResult.invalid(String message) {
    return FolderValidationResult(
      isValid: false,
      errorMessage: message,
    );
  }

  String get statusMessage {
    if (!isValid) {
      return errorMessage ?? 'Invalid folder';
    }
    if (imageFiles.isNotEmpty) {
      return 'Found ${imageFiles.length} media files';
    }
    if (hasGooglePhotosStructure) {
      return 'Google Photos takeout folder detected';
    }
    return 'No media files found';
  }
}

class OutputFolderValidationResult {
  final bool isValid;
  final bool hasWritePermissions;
  final String? errorMessage;

  OutputFolderValidationResult({
    required this.isValid,
    this.hasWritePermissions = false,
    this.errorMessage,
  });

  factory OutputFolderValidationResult.invalid(String message) {
    return OutputFolderValidationResult(
      isValid: false,
      errorMessage: message,
    );
  }

  String get statusMessage {
    if (!isValid) {
      return errorMessage ?? 'Invalid folder';
    }
    if (hasWritePermissions) {
      return 'Ready for processing';
    }
    return 'No write permissions';
  }
}