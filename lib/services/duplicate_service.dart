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

  /// Group media files by size, then by hash, to find duplicates.
  /// This is much more efficient than hashing every file.
  Future<Map<String, List<Media>>> groupMediaByHashWithProgress(
    List<Media> mediaList,
    Function(double progress, String status)? onProgress,
  ) async {
    final totalFiles = mediaList.length;
    int processedFiles = 0;

    // 1. Group by file size
    onProgress?.call(0.1, 'Grouping files by size...');
    final sizeGroups = mediaList._groupListsBy((e) => e.size);

    final hashGroups = <String, List<Media>>{};

    for (final sizeGroup in sizeGroups.values) {
      if (sizeGroup.length <= 1) {
        // Unique size, no need to hash, treat as a unique group
        hashGroups['size_${sizeGroup.first.size}_${processedFiles}'] = sizeGroup;
      } else {
        // Multiple files with the same size, now group by hash
        final potentialDuplicatesByHash =
            sizeGroup._groupListsBy((e) => e.hash.toString());
        hashGroups.addAll(potentialDuplicatesByHash);
      }
      processedFiles += sizeGroup.length;
      final progress = processedFiles / totalFiles;
      onProgress?.call(
          0.1 + (progress * 0.8), 'Processing duplicates: $processedFiles/$totalFiles');
    }

    onProgress?.call(1.0, 'Duplicate detection complete.');
    return hashGroups;
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

}

extension _MediaGrouping on Iterable<Media> {
  /// Groups a list of media by a given key.
  Map<K, List<Media>> _groupListsBy<K>(K Function(Media) keyFunction) {
    final Map<K, List<Media>> grouped = {};
    for (final media in this) {
      final key = keyFunction(media);
      (grouped[key] ??= []).add(media);
    }
    return grouped;
  }
}