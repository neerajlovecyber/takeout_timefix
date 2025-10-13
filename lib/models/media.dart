import 'dart:io';
import 'package:crypto/crypto.dart';

/// Represents a media file (photo/video) with its metadata and processing information
class Media {
  /// Maps album names to their corresponding files
  /// null key represents files not associated with any specific album
  final Map<String?, File> files;

  /// The extracted timestamp when the media was taken
  DateTime? dateTaken;

  /// Accuracy score for the timestamp extraction method used
  /// 0 = JSON metadata (most accurate)
  /// 1 = EXIF data (medium accuracy)
  /// 2 = Filename pattern (least accurate)
  /// 3 = File system date (fallback)
  int? dateTakenAccuracy;

  /// SHA256 hash for duplicate detection
  Digest? hash;

  /// File size in bytes for performance optimization
  int? _fileSize;

  /// Constructor
  Media({
    required this.files,
    this.dateTaken,
    this.dateTakenAccuracy,
    this.hash,
  });

  /// Factory constructor for single file without album association
  factory Media.single(File file) {
    return Media(files: {null: file});
  }

  /// Factory constructor for file with album association
  factory Media.withAlbum(File file, String albumName) {
    return Media(files: {albumName: file});
  }

  /// Get the primary file (first album file or the single file)
  File? get primaryFile {
    if (files.isNotEmpty) {
      return files.values.first;
    }
    return null;
  }

  /// Get all associated files
  List<File> get allFiles => files.values.toList();

  /// Get file size in bytes (cached for performance)
  Future<int> getFileSize() async {
    if (_fileSize == null) {
      final file = primaryFile;
      if (file != null) {
        _fileSize = await file.length();
      }
    }
    return _fileSize ?? 0;
  }

  /// Check if this media represents a duplicate of another
  bool isDuplicateOf(Media other) {
    if (hash == null || other.hash == null) return false;
    if (hash!.bytes.length != other.hash!.bytes.length) return false;
    for (int i = 0; i < hash!.bytes.length; i++) {
      if (hash!.bytes[i] != other.hash!.bytes[i]) return false;
    }
    return true;
  }

  /// Get formatted file size string
  Future<String> getFormattedFileSize() async {
    final size = await getFileSize();
    return _formatFileSize(size);
  }

  /// Static method to format file size
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get accuracy description for UI display
  String get accuracyDescription {
    switch (dateTakenAccuracy) {
      case 0:
        return 'JSON metadata';
      case 1:
        return 'EXIF data';
      case 2:
        return 'Filename pattern';
      case 3:
        return 'File system date';
      default:
        return 'Unknown';
    }
  }

  /// Check if timestamp extraction was successful
  bool get hasValidTimestamp => dateTaken != null && dateTakenAccuracy != null;

  /// Copy with updated values
  Media copyWith({
    Map<String?, File>? files,
    DateTime? dateTaken,
    int? dateTakenAccuracy,
    Digest? hash,
  }) {
    return Media(
      files: files ?? this.files,
      dateTaken: dateTaken ?? this.dateTaken,
      dateTakenAccuracy: dateTakenAccuracy ?? this.dateTakenAccuracy,
      hash: hash ?? this.hash,
    );
  }

  @override
  String toString() {
    return 'Media(files: ${files.length}, dateTaken: $dateTaken, accuracy: $dateTakenAccuracy)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Media) return false;
    if (hash == null || other.hash == null) return false;
    if (hash!.bytes.length != other.hash!.bytes.length) return false;
    for (int i = 0; i < hash!.bytes.length; i++) {
      if (hash!.bytes[i] != other.hash!.bytes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => hash?.bytes.length ?? files.length.hashCode;
}