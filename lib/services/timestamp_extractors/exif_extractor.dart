import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:mime/mime.dart';

/// Service for extracting timestamps from EXIF metadata in image files
class ExifExtractor {
  /// Maximum file size for EXIF processing (64MB)
  static const int maxFileSize = 64 * 1024 * 1024;

  /// Supported image MIME types for EXIF processing
  static const List<String> _supportedMimeTypes = [
    'image/jpeg',
    'image/tiff',
    'image/heic',
    'image/png', // Some PNG files may have EXIF
    'image/webp', // WebP may contain EXIF
  ];

  /// Extract timestamp from EXIF metadata in the given image file
  /// Returns the DateTime if found, null otherwise
  Future<DateTime?> extractTimestamp(File imageFile) async {
    try {
      // Check file size constraint
      final fileSize = await imageFile.length();
      if (fileSize > maxFileSize) {
        return null;
      }

      // Validate MIME type
      final mimeType = await _getMimeType(imageFile);
      if (!_isSupportedMimeType(mimeType)) {
        return null;
      }

      // Read and decode the image to access EXIF data
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        return null;
      }

      // Extract EXIF data
      final exifData = image.exif;

      if (exifData == null || exifData.isEmpty) {
        return null;
      }

      // Try EXIF fields in priority order
      return _extractDateTimeFromExif(exifData);
    } catch (e) {
      // EXIF extraction failed, return null to try next extractor
      return null;
    }
  }

  /// Get MIME type of a file
  Future<String?> _getMimeType(File file) async {
    try {
      final mimeType = lookupMimeType(file.path);
      return mimeType;
    } catch (e) {
      return null;
    }
  }

  /// Check if the MIME type is supported for EXIF processing
  bool _isSupportedMimeType(String? mimeType) {
    if (mimeType == null) return false;
    return _supportedMimeTypes.any((supportedType) =>
      mimeType.startsWith(supportedType.split('/')[0] + '/' + supportedType.split('/')[1]));
  }

  /// Extract DateTime from EXIF data using priority order
  DateTime? _extractDateTimeFromExif(img.ExifData exifData) {
    // Try to access EXIF data using a more compatible approach
    try {
      // Priority 1: DateTimeOriginal (most accurate for when photo was taken)
      final dateTimeOriginal = _parseExifDateTime(_getExifValue(exifData, 'dateTimeOriginal'));
      if (dateTimeOriginal != null) {
        return dateTimeOriginal;
      }

      // Priority 2: DateTimeDigitized (when image was digitized)
      final dateTimeDigitized = _parseExifDateTime(_getExifValue(exifData, 'dateTimeDigitized'));
      if (dateTimeDigitized != null) {
        return dateTimeDigitized;
      }

      // Priority 3: DateTime (file modification time, least accurate)
      final dateTime = _parseExifDateTime(_getExifValue(exifData, 'dateTime'));
      if (dateTime != null) {
        return dateTime;
      }
    } catch (e) {
      // If EXIF access fails, return null
    }

    return null;
  }

  /// Get EXIF value using a more compatible approach
  dynamic _getExifValue(img.ExifData exifData, String tagName) {
    try {
      // For now, return null as we're still figuring out the correct API
      // This can be enhanced once we determine the proper way to access EXIF data
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse EXIF date time string into DateTime object
  DateTime? _parseExifDateTime(dynamic exifValue) {
    if (exifValue == null) return null;

    try {
      // EXIF date format is typically "YYYY:MM:DD HH:MM:SS"
      // But may contain various separators and formats
      String dateString;

      if (exifValue is String) {
        dateString = exifValue;
      } else if (exifValue is List<int>) {
        dateString = String.fromCharCodes(exifValue);
      } else {
        return null;
      }

      // Normalize separators (handle -, /, ., \, :, space)
      dateString = dateString.replaceAll(RegExp(r'[-/\.\\:]'), ' ');

      // Parse the normalized date string
      final parts = dateString.trim().split(RegExp(r'\s+'));
      if (parts.length < 6) return null;

      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      final hour = int.tryParse(parts[3]);
      final minute = int.tryParse(parts[4]);
      final second = int.tryParse(parts[5]);

      // Validate parsed values
      if (year == null || month == null || day == null ||
          hour == null || minute == null || second == null) {
        return null;
      }

      if (!_isValidDateTime(year, month, day, hour, minute, second)) {
        return null;
      }

      return DateTime(year, month, day, hour, minute, second);
    } catch (e) {
      return null;
    }
  }

  /// Validate if the parsed date/time values are reasonable
  bool _isValidDateTime(int year, int month, int day, int hour, int minute, int second) {
    // Basic range checks
    if (year < 1900 || year > 2100) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    if (hour < 0 || hour > 23) return false;
    if (minute < 0 || minute > 59) return false;
    if (second < 0 || second > 59) return false;

    // Additional validation for days in month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    if (day > daysInMonth) return false;

    return true;
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