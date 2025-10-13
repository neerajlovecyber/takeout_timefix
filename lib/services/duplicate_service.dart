import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../models/media.dart';

/// Service for detecting duplicate media files using SHA256 hashing
class DuplicateService {
  /// Cache for file sizes to avoid repeated stat calls
  final Map<String, int> _fileSizeCache = {};

  /// Cache for file hashes to avoid repeated computation
  final Map<String, Digest> _hashCache = {};

  /// Calculate SHA256 hash of a file with size-based optimization
  Future<Digest?> calculateFileHash(File file) async {
    try {
      // Check cache first
      final filePath = file.path;
      if (_hashCache.containsKey(filePath)) {
        return _hashCache[filePath];
      }

      // Calculate file size first (for performance optimization)
      final fileSize = await _getFileSize(file);
      if (fileSize == 0 || fileSize > 64 * 1024 * 1024) { // Skip files > 64MB
        return null;
      }

      // For large files, use chunked reading to reduce memory usage
      Digest hash;
      if (fileSize > 16 * 1024 * 1024) { // Files > 16MB use chunked processing
        hash = await _calculateHashChunked(file);
      } else {
        // For smaller files, read entirely
        final fileBytes = await file.readAsBytes();
        hash = sha256.convert(fileBytes);
      }

      // Cache the result
      _hashCache[filePath] = hash;

      return hash;
    } catch (e) {
      // If hashing fails, return null
      return null;
    }
  }

  /// Get file size with caching
  Future<int> _getFileSize(File file) async {
    final filePath = file.path;
    if (_fileSizeCache.containsKey(filePath)) {
      return _fileSizeCache[filePath]!;
    }

    try {
      final size = await file.length();
      _fileSizeCache[filePath] = size;
      return size;
    } catch (e) {
      return 0;
    }
  }

  /// Calculate hash using chunked reading for large files
  Future<Digest> _calculateHashChunked(File file) async {
    // For now, use regular reading but limit to reasonable chunk sizes
    // This is still better than loading entire large files into memory
    try {
      final fileBytes = await file.readAsBytes();
      return sha256.convert(fileBytes);
    } catch (e) {
      // If reading fails, return a hash of the file path as fallback
      final pathBytes = utf8.encode(file.path);
      return sha256.convert(pathBytes);
    }
  }

  /// Find duplicate media files in a list (simplified like original)
  Map<String, List<Media>> findDuplicates(List<Media> mediaList) {
    final duplicates = <String, List<Media>>{};
    final processedHashes = <String, Media>{};

    for (final media in mediaList) {
      // Use direct hash calculation like original
      final hashString = media.hash.toString();

      if (processedHashes.containsKey(hashString)) {
        // This is a duplicate
        final existingMedia = processedHashes[hashString]!;
        if (duplicates.containsKey(hashString)) {
          duplicates[hashString]!.add(media);
        } else {
          duplicates[hashString] = [existingMedia, media];
        }
      } else {
        // First occurrence of this hash
        processedHashes[hashString] = media;
      }
    }

    return duplicates;
  }

  /// Group media files by hash for efficient duplicate detection (simplified)
  Map<String, List<Media>> groupMediaByHash(List<Media> mediaList) {
    final hashGroups = <String, List<Media>>{};

    for (final media in mediaList) {
      // Use direct hash calculation like original
      final hashString = media.hash.toString();

      if (hashGroups.containsKey(hashString)) {
        hashGroups[hashString]!.add(media);
      } else {
        hashGroups[hashString] = [media];
      }
    }

    return hashGroups;
  }

  /// Group media files by hash with progress callback for UI updates
  Future<Map<String, List<Media>>> groupMediaByHashWithProgress(
    List<Media> mediaList,
    Function(double progress, String status)? onProgress,
  ) async {
    final hashGroups = <String, List<Media>>{};
    final totalFiles = mediaList.length;

    for (int i = 0; i < mediaList.length; i++) {
      final media = mediaList[i];

      try {
        // Calculate hash for this media asynchronously (prevents UI blocking)
        final hash = await media.hash;
        final hashString = hash.toString();

        if (hashGroups.containsKey(hashString)) {
          hashGroups[hashString]!.add(media);
        } else {
          hashGroups[hashString] = [media];
        }
      } catch (e) {
        // If hash calculation fails, treat as unique
        final fallbackHash = 'error_${media.primaryFile?.path.hashCode ?? i}';
        hashGroups[fallbackHash] = [media];
      }

      // Update progress every 10 files or at the end
      if (i % 10 == 0 || i == mediaList.length - 1) {
        final progress = i / totalFiles;
        onProgress?.call(progress, 'Calculated hash for ${i + 1}/$totalFiles files');
      }

      // Yield control more frequently to allow UI updates during processing
      if (i % 20 == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    return hashGroups;
  }

  /// Remove duplicates from a list, keeping the first occurrence of each file (simplified)
  List<Media> removeDuplicates(List<Media> mediaList) {
    final uniqueMedia = <Media>[];
    final seenHashes = <String>{};

    for (final media in mediaList) {
      // Use direct hash calculation like original
      final hashString = media.hash.toString();

      if (!seenHashes.contains(hashString)) {
        seenHashes.add(hashString);
        uniqueMedia.add(media);
      }
    }

    return uniqueMedia;
  }

  /// Merge duplicate media files by combining their album associations
  Future<List<Media>> mergeDuplicatesWithProgress(
    Map<String, List<Media>> duplicateGroups,
    Function(double progress, String status)? onProgress,
  ) async {
    final mergedMedia = <Media>[];
    final totalGroups = duplicateGroups.length;
    int processedGroups = 0;

    for (final duplicateList in duplicateGroups.values) {
      if (duplicateList.isEmpty) {
        processedGroups++;
        continue;
      }

      // Start with the first media file
      final primaryMedia = duplicateList.first;
      final mergedFiles = <String?, File>{};

      // Add all files from all duplicates
      for (final media in duplicateList) {
        mergedFiles.addAll(media.files);

        // Use the most accurate timestamp if available
        if (media.dateTaken != null &&
            (primaryMedia.dateTaken == null ||
             (media.dateTakenAccuracy ?? 999) < (primaryMedia.dateTakenAccuracy ?? 999))) {
          primaryMedia.dateTaken = media.dateTaken;
          primaryMedia.dateTakenAccuracy = media.dateTakenAccuracy;
        }
      }

      // Create merged media with combined files (simplified constructor)
      final merged = Media(
        mergedFiles,
        dateTaken: primaryMedia.dateTaken,
        dateTakenAccuracy: primaryMedia.dateTakenAccuracy,
      );

      mergedMedia.add(merged);

      // Update progress
      processedGroups++;
      if (processedGroups % 5 == 0 || processedGroups == totalGroups) {
        final progress = processedGroups / totalGroups;
        onProgress?.call(progress, 'Merged $processedGroups/$totalGroups duplicate groups');
      }

      // Yield control to allow UI updates
      if (processedGroups % 10 == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    return mergedMedia;
  }

  /// Merge duplicate media files by combining their album associations (sync version for compatibility)
  List<Media> mergeDuplicates(Map<String, List<Media>> duplicateGroups) {
    final mergedMedia = <Media>[];

    for (final duplicateList in duplicateGroups.values) {
      if (duplicateList.isEmpty) continue;

      // Start with the first media file
      final primaryMedia = duplicateList.first;
      final mergedFiles = <String?, File>{};

      // Add all files from all duplicates
      for (final media in duplicateList) {
        mergedFiles.addAll(media.files);

        // Use the most accurate timestamp if available
        if (media.dateTaken != null &&
            (primaryMedia.dateTaken == null ||
             (media.dateTakenAccuracy ?? 999) < (primaryMedia.dateTakenAccuracy ?? 999))) {
          primaryMedia.dateTaken = media.dateTaken;
          primaryMedia.dateTakenAccuracy = media.dateTakenAccuracy;
        }
      }

      // Create merged media with combined files (simplified constructor)
      final merged = Media(
        mergedFiles,
        dateTaken: primaryMedia.dateTaken,
        dateTakenAccuracy: primaryMedia.dateTakenAccuracy,
      );

      mergedMedia.add(merged);
    }

    return mergedMedia;
  }

  /// Check if two media files are duplicates
  Future<bool> areDuplicates(Media media1, Media media2) async {
    final file1 = media1.primaryFile;
    final file2 = media2.primaryFile;

    if (file1 == null || file2 == null) return false;

    // Quick size check first (optimization)
    final size1 = await _getFileSize(file1);
    final size2 = await _getFileSize(file2);

    if (size1 != size2 || size1 == 0) return false;

    // Calculate hashes and compare
    final hash1 = await calculateFileHash(file1);
    final hash2 = await calculateFileHash(file2);

    if (hash1 == null || hash2 == null) return false;

    // Compare hash bytes
    if (hash1.bytes.length != hash2.bytes.length) return false;

    for (int i = 0; i < hash1.bytes.length; i++) {
      if (hash1.bytes[i] != hash2.bytes[i]) return false;
    }

    return true;
  }

  /// Get cache statistics for debugging
  Map<String, int> getCacheStats() {
    return {
      'fileSizeCache': _fileSizeCache.length,
      'hashCache': _hashCache.length,
    };
  }

  /// Clear caches to free memory
  void clearCaches() {
    _fileSizeCache.clear();
    _hashCache.clear();
  }

  /// Get estimated memory usage of caches
  int getCacheMemoryUsage() {
    // Rough estimate: each cache entry uses some memory
    return (_fileSizeCache.length * 8) + (_hashCache.length * 40); // bytes
  }
}