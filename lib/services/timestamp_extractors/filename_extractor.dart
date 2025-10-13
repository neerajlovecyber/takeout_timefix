import 'dart:io';
import 'package:convert/convert.dart';

/// Simple date/time formatter for parsing filename date patterns
class FixedDateTimeFormatter {
  final String format;
  final bool isUtc;

  const FixedDateTimeFormatter(this.format, {this.isUtc = false});

  /// Try to decode a date string using the format pattern
  DateTime? tryDecode(String dateStr) {
    try {
      // For now, implement basic parsing for common formats
      // This is a simplified version - in a real implementation you'd want more robust parsing

      // Handle IMG_YYYYMMDD_HHMMSS format
      if (format == 'IMG_YYYYMMDD_HHMMSS') {
        final regex = RegExp(r'IMG[_-](\d{4})(\d{2})(\d{2})[_-](\d{2})(\d{2})(\d{2})');
        final match = regex.firstMatch(dateStr);
        if (match != null) {
          return DateTime(
            int.parse(match.group(1)!), // year
            int.parse(match.group(2)!), // month
            int.parse(match.group(3)!), // day
            int.parse(match.group(4)!), // hour
            int.parse(match.group(5)!), // minute
            int.parse(match.group(6)!), // second
          );
        }
      }

      // Handle YYYYMMDDHHMMSS format
      if (format == 'YYYYMMDDHHMMSS') {
        if (dateStr.length >= 14) {
          return DateTime(
            int.parse(dateStr.substring(0, 4)),  // year
            int.parse(dateStr.substring(4, 6)),  // month
            int.parse(dateStr.substring(6, 8)),  // day
            int.parse(dateStr.substring(8, 10)), // hour
            int.parse(dateStr.substring(10, 12)), // minute
            int.parse(dateStr.substring(12, 14)), // second
          );
        }
      }

      // Handle YYYY-MM-DD-HHMMSS format
      if (format == 'YYYY-MM-DD-HHMMSS') {
        final regex = RegExp(r'(\d{4})[-_](\d{2})[-_](\d{2})[-_](\d{2})(\d{2})(\d{2})');
        final match = regex.firstMatch(dateStr);
        if (match != null) {
          return DateTime(
            int.parse(match.group(1)!), // year
            int.parse(match.group(2)!), // month
            int.parse(match.group(3)!), // day
            int.parse(match.group(4)!), // hour
            int.parse(match.group(5)!), // minute
            int.parse(match.group(6)!), // second
          );
        }
      }

      // Handle VID_YYYYMMDD_HHMMSS format (same as IMG)
      if (format == 'VID_YYYYMMDD_HHMMSS') {
        final regex = RegExp(r'VID[_-](\d{4})(\d{2})(\d{2})[_-](\d{2})(\d{2})(\d{2})');
        final match = regex.firstMatch(dateStr);
        if (match != null) {
          return DateTime(
            int.parse(match.group(1)!), // year
            int.parse(match.group(2)!), // month
            int.parse(match.group(3)!), // day
            int.parse(match.group(4)!), // hour
            int.parse(match.group(5)!), // minute
            int.parse(match.group(6)!), // second
          );
        }
      }

      // Handle Photo_YYYY-MM-DD_HH-MM-SS format
      if (format == 'Photo_YYYY-MM-DD_HH-MM-SS') {
        final regex = RegExp(r'Photo[_-](\d{4})[-_](\d{2})[-_](\d{2})[_-](\d{2})[-_](\d{2})[-_](\d{2})');
        final match = regex.firstMatch(dateStr);
        if (match != null) {
          return DateTime(
            int.parse(match.group(1)!), // year
            int.parse(match.group(2)!), // month
            int.parse(match.group(3)!), // day
            int.parse(match.group(4)!), // hour
            int.parse(match.group(5)!), // minute
            int.parse(match.group(6)!), // second
          );
        }
      }

      // Handle IMG_YYYYMMDD_WA format (WhatsApp without time)
      if (format == 'IMG_YYYYMMDD_WA') {
        final regex = RegExp(r'IMG[-_](\d{4})(\d{2})(\d{2})[-_]WA\d+');
        final match = regex.firstMatch(dateStr);
        if (match != null) {
          return DateTime(
            int.parse(match.group(1)!), // year
            int.parse(match.group(2)!), // month
            int.parse(match.group(3)!), // day
            12, // Default to noon for WhatsApp files without time
            0,  // minute
            0,  // second
          );
        }
      }

      // Handle IMG_YYYYMMDD_WA_YYYYMMDDHHMMSS format (WhatsApp with time)
      if (format == 'IMG_YYYYMMDD_WA_YYYYMMDDHHMMSS') {
        final regex = RegExp(r'IMG[-_](\d{4})(\d{2})(\d{2})[-_]WA\d+[-_](\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})');
        final match = regex.firstMatch(dateStr);
        if (match != null) {
          return DateTime(
            int.parse(match.group(1)!), // year
            int.parse(match.group(2)!), // month
            int.parse(match.group(3)!), // day
            int.parse(match.group(4)!), // hour
            int.parse(match.group(5)!), // minute
            int.parse(match.group(6)!), // second
          );
        }
      }

      // Handle YYYYMMDD_WA format (simple WhatsApp format)
      if (format == 'YYYYMMDD_WA') {
        final regex = RegExp(r'(\d{4})(\d{2})(\d{2})[-_]WA\d+');
        final match = regex.firstMatch(dateStr);
        if (match != null) {
          return DateTime(
            int.parse(match.group(1)!), // year
            int.parse(match.group(2)!), // month
            int.parse(match.group(3)!), // day
            12, // Default to noon for WhatsApp files without time
            0,  // minute
            0,  // second
          );
        }
      }

      // Handle VID_YYYYMMDD_WA format (WhatsApp video format)
      if (format == 'VID_YYYYMMDD_WA') {
        final regex = RegExp(r'VID[-_](\d{4})(\d{2})(\d{2})[-_]WA\d+');
        final match = regex.firstMatch(dateStr);
        if (match != null) {
          return DateTime(
            int.parse(match.group(1)!), // year
            int.parse(match.group(2)!), // month
            int.parse(match.group(3)!), // day
            12, // Default to noon for WhatsApp files without time
            0,  // minute
            0,  // second
          );
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Service for extracting timestamps from filename patterns when metadata is unavailable
/// Matches the original implementation's approach
class FilenameExtractor {
  /// Regex patterns for different filename formats
  /// Matches the original implementation exactly
  static final List<_FilenamePattern> _patterns = [
    // Pattern 1: Screenshot format - Screenshot_20190919-053857.jpg (matches original)
    _FilenamePattern(
      regex: RegExp(r'Screenshot[_-](\d{4})(\d{2})(\d{2})[-_](\d{2})(\d{2})(\d{2})'),
      format: 'Screenshot_YYYYMMDD-HHMMSS',
      yearGroup: 1,
      monthGroup: 2,
      dayGroup: 3,
      hourGroup: 4,
      minuteGroup: 5,
      secondGroup: 6,
    ),

    // Pattern 2: IMG format - IMG_20190509_154733.jpg (matches original)
    _FilenamePattern(
      regex: RegExp(r'IMG[_-](\d{4})(\d{2})(\d{2})[_-](\d{2})(\d{2})(\d{2})'),
      format: 'IMG_YYYYMMDD_HHMMSS',
      yearGroup: 1,
      monthGroup: 2,
      dayGroup: 3,
      hourGroup: 4,
      minuteGroup: 5,
      secondGroup: 6,
    ),

    // Pattern 2b: IMG format with milliseconds - IMG_20171224_215954337_no_date
    _FilenamePattern(
      regex: RegExp(r'IMG[_-](\d{4})(\d{2})(\d{2})[_-](\d{2})(\d{2})(\d{2})\d*'),
      format: 'IMG_YYYYMMDD_HHMMSS',
      yearGroup: 1,
      monthGroup: 2,
      dayGroup: 3,
      hourGroup: 4,
      minuteGroup: 5,
      secondGroup: 6,
    ),

    // Pattern 3: Signal format - signal-2020-10-26-163832.jpg (matches original)
    _FilenamePattern(
      regex: RegExp(r'signal[-_](\d{4})[-_](\d{2})[-_](\d{2})[-_](\d{2})[-_](\d{2})[-_](\d{2})'),
      format: 'signal-YYYY-MM-DD-HH-MM-SS',
      yearGroup: 1,
      monthGroup: 2,
      dayGroup: 3,
      hourGroup: 4,
      minuteGroup: 5,
      secondGroup: 6,
    ),

    // Pattern 4: Alternative format - 2016_01_30_11_49_15.mp4 (matches original)
    _FilenamePattern(
      regex: RegExp(r'(\d{4})[_-](\d{2})[_-](\d{2})[_-](\d{2})[_-](\d{2})[_-](\d{2})'),
      format: 'YYYY_MM_DD_HH_MM_SS',
      yearGroup: 1,
      monthGroup: 2,
      dayGroup: 3,
      hourGroup: 4,
      minuteGroup: 5,
      secondGroup: 6,
    ),

    // Pattern 5: Compact format - 20190919053857.jpg (matches original)
    _FilenamePattern(
      regex: RegExp(r'(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})'),
      format: 'YYYYMMDDHHMMSS',
      yearGroup: 1,
      monthGroup: 2,
      dayGroup: 3,
      hourGroup: 4,
      minuteGroup: 5,
      secondGroup: 6,
    ),

    // Pattern 6: Date with time format - 2020-10-26-163832.jpg (matches original)
    _FilenamePattern(
      regex: RegExp(r'(\d{4})[-_](\d{2})[-_](\d{2})[-_](\d{2})(\d{2})(\d{2})'),
      format: 'YYYY-MM-DD-HHMMSS',
      yearGroup: 1,
      monthGroup: 2,
      dayGroup: 3,
      hourGroup: 4,
      minuteGroup: 5,
      secondGroup: 6,
    ),

    // Pattern 7: VID format - VID_20180115_120000.mp4 (similar to IMG)
    _FilenamePattern(
      regex: RegExp(r'VID[_-](\d{4})(\d{2})(\d{2})[_-](\d{2})(\d{2})(\d{2})'),
      format: 'VID_YYYYMMDD_HHMMSS',
      yearGroup: 1,
      monthGroup: 2,
      dayGroup: 3,
      hourGroup: 4,
      minuteGroup: 5,
      secondGroup: 6,
    ),

    // Pattern 8: Photo format - Photo_2023-05-15_14-30-25.jpg
    _FilenamePattern(
      regex: RegExp(r'Photo[_-](\d{4})[-_](\d{2})[-_](\d{2})[_-](\d{2})[-_](\d{2})[-_](\d{2})'),
      format: 'Photo_YYYY-MM-DD_HH-MM-SS',
      yearGroup: 1,
      monthGroup: 2,
      dayGroup: 3,
      hourGroup: 4,
      minuteGroup: 5,
      secondGroup: 6,
    ),

    // Pattern 9: Camera format - 20230101_123456.jpg
    _FilenamePattern(
      regex: RegExp(r'(\d{4})(\d{2})(\d{2})[_-](\d{2})(\d{2})(\d{2})'),
      format: 'YYYYMMDD_HHMMSS',
      yearGroup: 1,
      monthGroup: 2,
      dayGroup: 3,
      hourGroup: 4,
      minuteGroup: 5,
      secondGroup: 6,
    ),

    // Pattern 10: WhatsApp format - IMG-20150224-WA0058_no_date.jpg
    _FilenamePattern(
      regex: RegExp(r'IMG[-_](\d{4})(\d{2})(\d{2})[-_]WA\d+'),
      format: 'IMG_YYYYMMDD_WA',
      yearGroup: 1,
      monthGroup: 2,
      dayGroup: 3,
      hourGroup: 0, // No time in WhatsApp format
      minuteGroup: 0,
      secondGroup: 0,
    ),

    // Pattern 11: WhatsApp format with time - IMG-20150224-WA0058-20210203123456.jpg
    _FilenamePattern(
      regex: RegExp(r'IMG[-_](\d{4})(\d{2})(\d{2})[-_]WA\d+[-_](\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})'),
      format: 'IMG_YYYYMMDD_WA_YYYYMMDDHHMMSS',
      yearGroup: 1,
      monthGroup: 2,
      dayGroup: 3,
      hourGroup: 4,
      minuteGroup: 5,
      secondGroup: 6,
    ),

    // Pattern 12: Simple date format - 20150224-WA0058.jpg
    _FilenamePattern(
      regex: RegExp(r'(\d{4})(\d{2})(\d{2})[-_]WA\d+'),
      format: 'YYYYMMDD_WA',
      yearGroup: 1,
      monthGroup: 2,
      dayGroup: 3,
      hourGroup: 0,
      minuteGroup: 0,
      secondGroup: 0,
    ),

    // Pattern 13: VID WhatsApp format - VID-20150224-WA0058.mp4
    _FilenamePattern(
      regex: RegExp(r'VID[-_](\d{4})(\d{2})(\d{2})[-_]WA\d+'),
      format: 'VID_YYYYMMDD_WA',
      yearGroup: 1,
      monthGroup: 2,
      dayGroup: 3,
      hourGroup: 0,
      minuteGroup: 0,
      secondGroup: 0,
    ),
  ];

  /// Extract timestamp from filename pattern
  /// Returns the DateTime if a pattern matches, null otherwise
  DateTime? extractTimestamp(File file) {
    final filename = _getFilenameWithoutExtension(file.path);

    // Try each pattern in order
    for (final pattern in _patterns) {
      final match = pattern.regex.firstMatch(filename);
      if (match != null) {
        final dateTime = _buildDateTimeFromMatch(match, pattern);
        if (dateTime != null && _isValidDateTime(dateTime)) {
          return dateTime;
        }
      }
    }

    return null;
  }

  /// Get filename without extension
  String _getFilenameWithoutExtension(String filePath) {
    final filename = filePath.split('/').last; // Handle both Unix and Windows paths
    final lastDot = filename.lastIndexOf('.');
    return lastDot != -1 ? filename.substring(0, lastDot) : filename;
  }

  /// Build DateTime object from regex match groups (matches original)
  DateTime? _buildDateTimeFromMatch(RegExpMatch match, _FilenamePattern pattern) {
    try {
      final dateStr = match.group(0);
      if (dateStr == null) return null;

      // Use FixedDateTimeFormatter like original for reliable parsing
      return FixedDateTimeFormatter(pattern.format, isUtc: false).tryDecode(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// Validate if the extracted date/time is reasonable
  bool _isValidDateTime(DateTime dateTime) {
    // Basic range checks
    if (dateTime.year < 1900 || dateTime.year > 2100) return false;
    if (dateTime.month < 1 || dateTime.month > 12) return false;
    if (dateTime.day < 1 || dateTime.day > 31) return false;
    if (dateTime.hour < 0 || dateTime.hour > 23) return false;
    if (dateTime.minute < 0 || dateTime.minute > 59) return false;
    if (dateTime.second < 0 || dateTime.second > 59) return false;

    // Additional validation for days in month
    final daysInMonth = DateTime(dateTime.year, dateTime.month + 1, 0).day;
    if (dateTime.day > daysInMonth) return false;

    return true;
  }

  /// Check if a filename contains recognizable date patterns
  static bool hasDatePattern(String filename) {
    final filenameWithoutExt = _getFilenameWithoutExtensionStatic(filename);

    return _patterns.any((pattern) =>
      pattern.regex.hasMatch(filenameWithoutExt));
  }

  /// Static version of filename extraction for utility use
  static String _getFilenameWithoutExtensionStatic(String filePath) {
    final filename = filePath.split('/').last; // Handle both Unix and Windows paths
    final lastDot = filename.lastIndexOf('.');
    return lastDot != -1 ? filename.substring(0, lastDot) : filename;
  }
}

/// Internal class to represent a filename pattern with regex and group mappings
class _FilenamePattern {
  final RegExp regex;
  final String format;
  final int yearGroup;
  final int monthGroup;
  final int dayGroup;
  final int hourGroup;
  final int minuteGroup;
  final int secondGroup;

  const _FilenamePattern({
    required this.regex,
    required this.format,
    required this.yearGroup,
    required this.monthGroup,
    required this.dayGroup,
    this.hourGroup = 0,
    this.minuteGroup = 0,
    this.secondGroup = 0,
  });
}