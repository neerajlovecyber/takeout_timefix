import 'dart:io';
import 'dart:math';
import 'package:exif/exif.dart';

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

      // Extract EXIF data directly from bytes (like original)
      final tags = await readExifFromBytes(bytes);

      if (tags.isEmpty) {
        return null;
      }

      // Try EXIF fields in priority order (like original)
      String? datetime;

      // Priority 1: DateTime (file modification time)
      datetime ??= tags['Image DateTime']?.printable;

      // Priority 2: DateTimeOriginal (most accurate for when photo was taken)
      datetime ??= tags['EXIF DateTimeOriginal']?.printable;

      // Priority 3: DateTimeDigitized (when image was digitized)
      datetime ??= tags['EXIF DateTimeDigitized']?.printable;

      if (datetime == null) return null;

      // Parse datetime string (like original)
      return _parseExifDateTime(datetime);
    } catch (e) {
      // EXIF extraction failed, return null to try next extractor
      return null;
    }
  }

  /// Parse EXIF date time string into DateTime object (like original)
  DateTime? _parseExifDateTime(String datetime) {
    try {
      // Replace all separators with colons (like original)
      datetime = datetime
          .replaceAll('-', ':')
          .replaceAll('/', ':')
          .replaceAll('.', ':')
          .replaceAll('\\', ':')
          .replaceAll(': ', ':0')
          .substring(0, min(datetime.length, 19))
          .replaceFirst(':', '-') // Replace first : with - for year/month
          .replaceFirst(':', '-'); // Replace second : with - for month/day

      // Now date should be like: "1999-06-23 23:55"
      return DateTime.tryParse(datetime);
    } catch (e) {
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