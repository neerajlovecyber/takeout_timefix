import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/media.dart';

/// Service for detecting duplicate media files using SHA256 hashing
class DuplicateService {
  /// Cache for file sizes to avoid repeated stat calls
  final Map<String, int> _fileSizeCache = {};

  /// Cache for file hashes to avoid repeated computation
  final Map<String, Digest> _hashCache = {};

  /// Calculate SHA256 hash of a file
  Future<Digest?> calculateFileHash(File file) async {
    try {
      // Check cache first
      final filePath = file.path;
      if (_hashCache.containsKey(filePath)) {
        return _hashCache[filePath];
      }

      // Calculate file size first (for performance optimization)
      final fileSize = await _getFileSize(file);
      if (fileSize == 0) {
        return null;
      }

      // For large files, we might want to hash only portions
      // but for now, we'll hash the entire file
      final fileBytes = await file.readAsBytes();

      // Calculate SHA256 hash
      final hash = sha256.convert(fileBytes);

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

  /// Find duplicate media files in a list
  Future<Map<String, List<Media>>> findDuplicates(List<Media> mediaList) async {
    final duplicates = <String, List<Media>>{};
    final processedHashes = <String, Media>{};

    for (final media in mediaList) {
      final primaryFile = media.primaryFile;
      if (primaryFile == null) continue;

      // Calculate hash for the primary file
      final hash = await calculateFileHash(primaryFile);
      if (hash == null) continue;

      // Set the hash in the media object
      media.hash = hash;

      // Convert hash to string for comparison
      final hashString = hash.toString();

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

  /// Group media files by hash for efficient duplicate detection
  Future<Map<String, List<Media>>> groupMediaByHash(List<Media> mediaList) async {
    final hashGroups = <String, List<Media>>{};

    for (final media in mediaList) {
      final primaryFile = media.primaryFile;
      if (primaryFile == null) continue;

      // Calculate hash for the primary file
      final hash = await calculateFileHash(primaryFile);
      if (hash == null) continue;

      // Set the hash in the media object
      media.hash = hash;

      // Convert hash to string for grouping
      final hashString = hash.toString();

      if (hashGroups.containsKey(hashString)) {
        hashGroups[hashString]!.add(media);
      } else {
        hashGroups[hashString] = [media];
      }
    }

    return hashGroups;
  }

  /// Remove duplicates from a list, keeping the first occurrence of each file
  Future<List<Media>> removeDuplicates(List<Media> mediaList) async {
    final uniqueMedia = <Media>[];
    final seenHashes = <String>{};

    for (final media in mediaList) {
      final primaryFile = media.primaryFile;
      if (primaryFile == null) continue;

      // Calculate hash for the primary file
      final hash = await calculateFileHash(primaryFile);
      if (hash == null) {
        // If we can't hash it, include it to be safe
        uniqueMedia.add(media);
        continue;
      }

      // Set the hash in the media object
      media.hash = hash;

      // Convert hash to string for comparison
      final hashString = hash.toString();

      if (!seenHashes.contains(hashString)) {
        seenHashes.add(hashString);
        uniqueMedia.add(media);
      }
    }

    return uniqueMedia;
  }

  /// Merge duplicate media files by combining their album associations
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

      // Create merged media with combined files
      final merged = Media(
        files: mergedFiles,
        dateTaken: primaryMedia.dateTaken,
        dateTakenAccuracy: primaryMedia.dateTakenAccuracy,
        hash: primaryMedia.hash,
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