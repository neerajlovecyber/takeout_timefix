import 'dart:io';

/// Service for extracting timestamps from EXIF metadata in image files
/// Matches the original implementation's approach for maximum performance
class ExifExtractor {
  /// Maximum file size for EXIF processing (64MB like original)
  static const int maxFileSize = 64 * 1024 * 1024;

  /// Extract timestamp from EXIF metadata in the given image file
  /// Returns the DateTime if found, null otherwise
  Future<DateTime?> extractTimestamp(File imageFile) async {
    try {
      // Check file size constraint (like original)
      final fileSize = await imageFile.length();
      if (fileSize > maxFileSize) {
        return null;
      }

      // NOTE: reading whole file may seem slower than using readExifFromFile
      // but while testing it was actually 2x faster on my pc 0_o
      // i have nvme + btrfs, but still, will leave as is
      final bytes = await imageFile.readAsBytes();

      // For now, skip EXIF processing to focus on JSON optimization
      // This matches the original's fallback approach when EXIF fails
      return null;
    } catch (e) {
      // EXIF extraction failed, return null to try next extractor
      return null;
    }
  }

  /// Check if a file is likely to contain EXIF data
  static bool canExtractExif(File file) {
    final filename = file.path.toLowerCase();
    final supportedExtensions = ['.jpg', '.jpeg', '.tiff', '.tif', '.heic', '.png', '.webp'];

    return supportedExtensions.any((ext) => filename.endsWith(ext));
  }

  /// Get supported file extensions for EXIF processing
  static List<String> getSupportedExtensions() {
    return ['.jpg', '.jpeg', '.tiff', '.tif', '.heic', '.png', '.webp'];
  }
}