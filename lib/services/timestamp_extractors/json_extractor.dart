import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Service for extracting timestamps from Google Photos JSON metadata files
/// Simplified to match the original implementation's direct approach
class JsonExtractor {
  /// Maximum filename length before trying alternative matching strategies
  static const int _maxFilenameLength = 51;

  /// Multi-language edited suffixes to remove
  static const List<String> _editedSuffixes = [
    '-edited',
    '-effects',
    '-smile',
    '-mix',
    '-edytowane', // Polish
    '-bearbeitet', // German
    '-bewerkt', // Dutch
    '-編集済み', // Japanese
    '-modificato', // Italian
    '-modifié', // French
    '-ha editado', // Spanish
    '-editat', // Catalan
  ];

  /// Extract timestamp from JSON metadata for the given media file
  /// Returns the DateTime if found, null otherwise
  Future<DateTime?> extractTimestamp(File mediaFile) async {
    try {
      // Try to find the corresponding JSON file (direct like original)
      final jsonFile = await _findJsonFile(mediaFile);
      if (jsonFile == null) {
        return null;
      }

      // Parse the JSON metadata (direct like original)
      final jsonContent = await jsonFile.readAsString();
      final metadata = json.decode(jsonContent) as Map<String, dynamic>;

      // Extract the photoTakenTime timestamp (direct like original)
      return _extractPhotoTakenTime(metadata);
    } catch (e) {
      // JSON parsing failed, return null to try next extractor
      return null;
    }
  }

  /// Find the corresponding JSON file for a media file (direct like original)
  Future<File?> _findJsonFile(File mediaFile) async {
    final mediaPath = mediaFile.path;
    final mediaDir = path.dirname(mediaPath);
    final mediaName = path.basenameWithoutExtension(mediaPath);
    final mediaExt = path.extension(mediaPath);

    // Strategy 1: Basic filename matching (direct like original)
    File? jsonFile = await _tryFindJsonFile(mediaDir, '$mediaName.json');
    if (jsonFile != null) return jsonFile;

    // Strategy 2: Try-hard mode for problematic files (direct like original)
    jsonFile = await _tryHardJsonMatching(mediaDir, mediaName, mediaExt);
    if (jsonFile != null) return jsonFile;

    return null;
  }

  /// Try to find JSON file with basic filename matching
  Future<File?> _tryFindJsonFile(String directory, String jsonFilename) async {
    final jsonFile = File(path.join(directory, jsonFilename));

    if (await jsonFile.exists()) {
      return jsonFile;
    }

    return null;
  }

  /// Aggressive JSON matching for problematic files
  Future<File?> _tryHardJsonMatching(String directory, String mediaName, String mediaExt) async {
    // Strategy: Remove edited suffixes and try again
    for (final suffix in _editedSuffixes) {
      if (mediaName.contains(suffix)) {
        final cleanedName = mediaName.replaceFirst(suffix, '');
        final jsonFile = await _tryFindJsonFile(directory, '$cleanedName.json');
        if (jsonFile != null) return jsonFile;

        // Also try with extension added back
        final jsonFileWithExt = await _tryFindJsonFile(directory, '$cleanedName$mediaExt.json');
        if (jsonFileWithExt != null) return jsonFileWithExt;
      }
    }

    // Strategy: Handle bracket swapping (image(1).jpg → image.jpg(1).json)
    final bracketPattern = RegExp(r'\((\d+)\)$');
    final bracketMatch = bracketPattern.firstMatch(mediaName);
    if (bracketMatch != null) {
      final number = bracketMatch.group(1);
      final nameWithoutBracket = mediaName.substring(0, bracketMatch.start);
      final swappedName = '$nameWithoutBracket$mediaExt($number)';

      final jsonFile = await _tryFindJsonFile(directory, '$swappedName.json');
      if (jsonFile != null) return jsonFile;
    }

    // Strategy: Remove digits from brackets
    final digitBracketPattern = RegExp(r'\(\d+\)\.');
    if (digitBracketPattern.hasMatch(mediaName)) {
      final cleanedName = mediaName.replaceAll(digitBracketPattern, '.');
      final jsonFile = await _tryFindJsonFile(directory, '$cleanedName.json');
      if (jsonFile != null) return jsonFile;
    }

    // Strategy: Try shortened names for very long filenames
    if (mediaName.length > _maxFilenameLength) {
      final shortenedName = mediaName.substring(0, _maxFilenameLength);
      final jsonFile = await _tryFindJsonFile(directory, '$shortenedName.json');
      if (jsonFile != null) return jsonFile;
    }

    return null;
  }

  /// Extract photoTakenTime from JSON metadata
  DateTime? _extractPhotoTakenTime(Map<String, dynamic> metadata) {
    try {
      // Navigate to photoTakenTime in the JSON structure
      final photoMetadata = metadata['photoTakenTime'] as Map<String, dynamic>?;
      if (photoMetadata == null) return null;

      final timestampSeconds = photoMetadata['timestamp'] as int?;
      if (timestampSeconds == null) return null;

      // Convert Unix timestamp to DateTime
      return DateTime.fromMillisecondsSinceEpoch(timestampSeconds * 1000);
    } catch (e) {
      return null;
    }
  }

  /// Check if a file is likely a Google Photos JSON metadata file
  static bool isJsonMetadataFile(File file) {
    final filename = path.basename(file.path).toLowerCase();
    return filename.endsWith('.json') &&
           !_isSystemFile(filename) &&
           !_isUnrelatedJsonFile(filename);
  }

  /// Check if filename suggests a system or unrelated JSON file
  static bool _isSystemFile(String filename) {
    final systemPatterns = [
      'desktop.ini',
      'thumbs.db',
      '.ds_store',
      'metadata.json', // Different from individual photo metadata
    ];

    return systemPatterns.any((pattern) =>
      filename.contains(pattern.toLowerCase()));
  }

  /// Check if this is an unrelated JSON file (not photo metadata)
  static bool _isUnrelatedJsonFile(String filename) {
    final unrelatedPatterns = [
      'album.json',
      'archive_browser.json',
      'user_generated_memory.json',
    ];

    return unrelatedPatterns.any((pattern) =>
      filename.contains(pattern.toLowerCase()));
  }
}