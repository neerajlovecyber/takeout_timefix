import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Represents a media file (photo/video) with its metadata and processing information
/// Simplified to match the original implementation's direct approach
class Media {
  /// Map between albums and files of same given media
  /// null key represents files not associated with any specific album
  Map<String?, File> files;

  /// DateTaken from any source
  DateTime? dateTaken;

  /// Higher number = worse accuracy
  int? dateTakenAccuracy;

  /// Constructor matching original
  Media(
    this.files, {
    this.dateTaken,
    this.dateTakenAccuracy,
  });

  /// Factory constructor for single file without album association
  factory Media.single(File file) {
    return Media({null: file});
  }

  /// Factory constructor for file with album association
  factory Media.withAlbum(File file, String albumName) {
    return Media({albumName: file});
  }

  /// Get the primary file (first album file or the single file)
  File? get primaryFile => files.isNotEmpty ? files.values.first : null;

  /// Get all associated files
  List<File> get allFiles => files.values.toList();

  // Simple caching like original
  int? _size;
  /// File size for duplicate detection
  int get size => _size ??= primaryFile?.lengthSync() ?? 0;

  // Simple caching like original
  Digest? _hash;
  /// SHA256 hash for finding duplicates/albums
  /// WARNING: Returns same value for files > 64MB
  Digest get hash => _hash ??= (size > 64 * 1024 * 1024)
      ? Digest([0]) // Files > 64MB get dummy hash like original
      : sha256.convert(primaryFile?.readAsBytesSync() ?? Uint8List(0));

  @override
  String toString() => 'Media('
      '${primaryFile?.path ?? 'no-file'}, '
      'dateTaken: $dateTaken, '
      'albums: ${files.keys.where((k) => k != null).toList()}'
      ')';
}