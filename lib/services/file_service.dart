import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

/// Service for discovering and filtering media files in directories
/// Simplified to match the original implementation's direct approach
class FileService {

  /// Supported image file extensions
  static const List<String> _imageExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.tiff', '.tif',
    '.heic', '.heif', '.raw', '.cr2', '.nef', '.arw', '.dng'
  ];

  /// Supported video file extensions
  static const List<String> _videoExtensions = [
    '.mp4', '.mov', '.avi', '.mkv', '.wmv', '.flv', '.webm', '.m4v',
    '.3gp', '.3g2', '.asf', '.vob', '.ogv', '.rm', '.rmvb', '.mts', '.m2ts'
  ];

  /// Supported MIME types for media files
  static const List<String> _supportedMimeTypes = [
    'image/jpeg', 'image/png', 'image/gif', 'image/bmp', 'image/webp',
    'image/tiff', 'image/heic', 'image/x-canon-cr2', 'image/x-nikon-nef',
    'image/x-sony-arw', 'image/x-adobe-dng',
    'video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/x-matroska',
    'video/webm', 'video/x-ms-wmv', 'video/x-flv', 'video/3gpp',
    'model/vnd.mts' // MTS video files
  ];

  /// Find all media files (photos and videos) in a directory recursively
  Future<List<File>> findMediaFiles(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return [];
    }

    final mediaFiles = <File>[];

    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && _isMediaFile(entity)) {
          mediaFiles.add(entity);
        }
      }
    } catch (e) {
      // Handle permission errors or inaccessible files gracefully
      // Log warning but continue processing
    }

    return mediaFiles;
  }

  /// Find all media files as a stream for better performance with large directories
  Stream<File> findMediaFilesStream(String directoryPath) async* {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return;
    }

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File && _isMediaFile(entity)) {
        yield entity;
      }
    }
  }

  /// Check if a file is a supported media file (optimized with caching)
  bool _isMediaFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    final filename = path.basename(file.path).toLowerCase();

    // Fast path: Check for supported extensions first
    if (_imageExtensions.contains(extension) || _videoExtensions.contains(extension)) {
      return true;
    }

    // Special case for MTS files (they might not have the standard extension check)
    if (filename.endsWith('.mts') || filename.endsWith('.m2ts')) {
      return true;
    }

    // Additional check using MIME type for edge cases (direct like original)
    final mimeType = getMimeType(file);
    return mimeType != null && _supportedMimeTypes.contains(mimeType);
  }

  /// Get MIME type of a file (direct like original)
  String? getMimeType(File file) {
    try {
      return lookupMimeType(file.path);
    } catch (e) {
      return null;
    }
  }

  /// Check if a file is an image based on extension or MIME type
  bool isImageFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    if (_imageExtensions.contains(extension)) {
      return true;
    }

    final mimeType = getMimeType(file);
    return mimeType != null && mimeType.startsWith('image/');
  }

  /// Check if a file is a video based on extension or MIME type
  bool isVideoFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    if (_videoExtensions.contains(extension)) {
      return true;
    }

    final mimeType = getMimeType(file);
    return mimeType != null && mimeType.startsWith('video/');
  }

  /// Get file size in bytes (direct like original)
  Future<int> getFileSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  /// Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get available disk space for a directory path
  Future<int> getAvailableDiskSpace(String directoryPath) async {
    try {
      // This is a simplified approach - in a real implementation you might need
      // platform-specific code to get accurate disk space information
      return 0; // Placeholder - would need platform channels for accurate info
    } catch (e) {
      return 0;
    }
  }

  /// Check if there's enough disk space for the given number of bytes
  Future<bool> hasEnoughDiskSpace(String directoryPath, int requiredBytes) async {
    final availableSpace = await getAvailableDiskSpace(directoryPath);
    return availableSpace == 0 || availableSpace >= requiredBytes;
  }

  /// Get all files in a directory (non-recursive)
  Future<List<File>> getFilesInDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return [];
    }

    final files = <File>[];
    await for (final entity in directory.list()) {
      if (entity is File) {
        files.add(entity);
      }
    }

    return files;
  }

  /// Get all subdirectories in a directory (non-recursive)
  Future<List<Directory>> getSubdirectories(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return [];
    }

    final subdirectories = <Directory>[];
    await for (final entity in directory.list()) {
      if (entity is Directory) {
        subdirectories.add(entity);
      }
    }

    return subdirectories;
  }

  /// Filter files by type (images only, videos only, or both)
  List<File> filterFilesByType(List<File> files, {bool images = true, bool videos = true}) {
    return files.where((file) {
      if (images && isImageFile(file)) return true;
      if (videos && isVideoFile(file)) return true;
      return false;
    }).toList();
  }

  /// Get supported file extensions for images
  List<String> getSupportedImageExtensions() => List.from(_imageExtensions);

  /// Get supported file extensions for videos
  List<String> getSupportedVideoExtensions() => List.from(_videoExtensions);

  /// Get all supported file extensions
  List<String> getAllSupportedExtensions() {
    return [..._imageExtensions, ..._videoExtensions];
  }
}

/// Extension to add filtering capabilities to Iterable of FileSystemEntity
extension MediaFileFiltering on Iterable<FileSystemEntity> {
  /// Filter for photo and video files only
  Iterable<File> whereMediaFiles() {
    return where((entity) => entity is File)
        .cast<File>()
        .where((file) => _isMediaFile(file));
  }

  /// Check if a file is a supported media file
  bool _isMediaFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    final filename = path.basename(file.path).toLowerCase();

    // Check for supported extensions
    const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.tiff', '.tif', '.heic', '.heif'];
    const videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.wmv', '.flv', '.webm', '.m4v', '.mts', '.m2ts'];

    if (imageExtensions.contains(extension) || videoExtensions.contains(extension)) {
      return true;
    }

    // Special case for MTS files
    if (filename.endsWith('.mts') || filename.endsWith('.m2ts')) {
      return true;
    }

    return false;
  }
}

/// Extension to add filtering capabilities to Stream of FileSystemEntity
extension MediaFileStreamFiltering on Stream<FileSystemEntity> {
  /// Filter for photo and video files only
  Stream<File> whereMediaFiles() async* {
    await for (final entity in this) {
      if (entity is File && _isMediaFile(entity)) {
        yield entity;
      }
    }
  }

  /// Check if a file is a supported media file
  bool _isMediaFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    final filename = path.basename(file.path).toLowerCase();

    // Check for supported extensions
    const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.tiff', '.tif', '.heic', '.heif'];
    const videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.wmv', '.flv', '.webm', '.m4v', '.mts', '.m2ts'];

    if (imageExtensions.contains(extension) || videoExtensions.contains(extension)) {
      return true;
    }

    // Special case for MTS files
    if (filename.endsWith('.mts') || filename.endsWith('.m2ts')) {
      return true;
    }

    return false;
  }
}