import 'dart:io';
import 'package:convert/convert.dart';

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