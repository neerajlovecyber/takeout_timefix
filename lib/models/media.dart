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
  Future<int>? _sizeFuture;

  /// File size for duplicate detection (async to prevent UI blocking)
  Future<int> get size async {
    if (_size != null) return _size!;
    if (_sizeFuture != null) return _sizeFuture!;

    _sizeFuture = _calculateSize();
    _size = await _sizeFuture;
    return _size!;
  }

  /// File size for duplicate detection (sync version for compatibility)
  int get sizeSync => _size ??= primaryFile?.lengthSync() ?? 0;

  // Simple caching like original
  Digest? _hash;
  Future<Digest>? _hashFuture;

  /// SHA256 hash for finding duplicates/albums (async to prevent UI blocking)
  Future<Digest> get hash async {
    if (_hash != null) return _hash!;
    if (_hashFuture != null) return _hashFuture!;

    _hashFuture = _calculateHash();
    _hash = await _hashFuture;
    return _hash!;
  }

  /// SHA256 hash for finding duplicates/albums (sync version for compatibility)
  /// WARNING: Returns same value for files > 64MB
  Digest get hashSync => _hash ??= (sizeSync > 64 * 1024 * 1024)
      ? Digest([0]) // Files > 64MB get dummy hash like original
      : sha256.convert(primaryFile?.readAsBytesSync() ?? Uint8List(0));

  /// Calculate file size asynchronously
  Future<int> _calculateSize() async {
    final file = primaryFile;
    if (file == null) return 0;
    try {
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  /// Calculate hash asynchronously
  Future<Digest> _calculateHash() async {
    final file = primaryFile;
    if (file == null) return Digest([0]);

    try {
      final fileSize = await size;
      if (fileSize > 64 * 1024 * 1024) {
        return Digest([0]); // Files > 64MB get dummy hash like original
      }

      final fileBytes = await file.readAsBytes();
      return sha256.convert(fileBytes);
    } catch (e) {
      // Return a hash based on file path as fallback
      final pathBytes = file.path.codeUnits;
      return sha256.convert(Uint8List.fromList(pathBytes));
    }
  }

  @override
  String toString() => 'Media('
      '${primaryFile?.path ?? 'no-file'}, '
      'dateTaken: $dateTaken, '
      'albums: ${files.keys.where((k) => k != null).toList()}'
      ')';
}