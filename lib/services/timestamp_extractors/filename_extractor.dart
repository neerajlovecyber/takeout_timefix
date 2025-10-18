import 'dart:io';

import '../error_handling_service.dart';
import 'package:path/path.dart' as p;

// These are thanks to @hheimbuerger <3
final _commonDatetimePatterns = [
  // example: Screenshot_20190919-053857_Camera-edited.jpg
  [
    RegExp(
        r'(?<date>(20|19|18)\\d{2}(01|02|03|04|05|06|07|08|09|10|11|12)[0-3]\\d-\\d{6})'),
    'YYYYMMDD-hhmmss'
  ],
  // example: IMG_20190509_154733.jpg, VID_20221024_225432_HSR_120.mp4, etc.
  [
    RegExp(
        r'(?<date>(?:20|19|18)\d{2}(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\d|3[01])(?:_|-)\d{6})'),
    'YYYYMMDD_hhmmss',
  ],
  // example: Screenshot_2019-04-16-11-19-37-232_com.google.a.jpg
  [
    RegExp(
        r'(?<date>(20|19|18)\\d{2}-(01|02|03|04|05|06|07|08|09|10|11|12)-[0-3]\\d-\\d{2}-\\d{2}-\\d{2})'),
    'YYYY-MM-DD-hh-mm-ss',
  ],
  // example: signal-2020-10-26-163832.jpg
  [
    RegExp(
        r'(?<date>(20|19|18)\\d{2}-(01|02|03|04|05|06|07|08|09|10|11|12)-[0-3]\\d-\\d{6})'),
    'YYYY-MM-DD-hhmmss',
  ],
  // Those two are thanks to @matt-boris <3
  // https://github.com/TheLastGimbus/GooglePhotosTakeoutHelper/commit/e0d9ee3e71def69d74eba7cf5ec204672924726d
  // example: 00004XTR_00004_BURST20190216172030.jpg, 201801261147521000.jpg, IMG_1_BURST20160520195318.jpg
  [
    RegExp(
        r'(?<date>(20|19|18)\\d{2}(01|02|03|04|05|06|07|08|09|10|11|12)[0-3]\\d{7})'),
    'YYYYMMDDhhmmss',
  ],
  // example: 2016_01_30_11_49_15.mp4
  [
    RegExp(
        r'(?<date>(20|19|18)\\d{2}_(01|02|03|04|05|06|07|08|09|10|11|12)_[0-3]\\d_\\d{2}_\\d{2}_\\d{2})'),
    'YYYY_MM_DD_hh_mm_ss',
  ],
];

class FilenameExtractor {
  final ErrorHandlingService? _errorService;

  FilenameExtractor([this._errorService]);

  DateTime? extractTimestamp(File file) {
    final filename = p.basename(file.path);
    for (final pat in _commonDatetimePatterns) {
      final regex = pat.first as RegExp;
      final match = regex.firstMatch(filename);
      final dateStr = match?.group(0);

      _errorService?.logError(
        message: 'Attempting regex: ${regex.pattern} on filename: $filename',
        filePath: file.path,
        severity: ErrorSeverity.info,
        category: ErrorCategory.metadataExtraction,
        context: {'match': dateStr},
      );

      if (dateStr == null) continue;

      DateTime? date;
      try {
        date = FixedDateTimeFormatter(pat.last as String, isUtc: false, errorService: _errorService)
            .tryDecode(dateStr, file.path);
      } on RangeError catch (_) {}
      if (date == null) continue;
      return date; // success!
    }
    return null; // none matched
  }
}

class FixedDateTimeFormatter {
  final String format;
  final bool isUtc;
  final ErrorHandlingService? errorService;

  const FixedDateTimeFormatter(this.format, {this.isUtc = false, this.errorService});

  DateTime? tryDecode(String dateStr, String filePath) {
    try {
      String sanitized = dateStr.replaceAll('-', '').replaceAll('_', '').replaceAll(':', '');
      errorService?.logError(
        message: 'Sanitizing date string. Original: "$dateStr", Sanitized: "$sanitized"',
        filePath: filePath,
        severity: ErrorSeverity.info,
        category: ErrorCategory.metadataExtraction,
      );

      if (sanitized.length < 8) {
        errorService?.logError(
          message: 'Sanitized string length is less than 8. Cannot parse date.',
          filePath: filePath,
          severity: ErrorSeverity.info,
          category: ErrorCategory.metadataExtraction,
        );
        return null;
      }

      final year = int.parse(sanitized.substring(0, 4));
      final month = int.parse(sanitized.substring(4, 6));
      final day = int.parse(sanitized.substring(6, 8));

      // Default time to midnight if not present
      final hour = sanitized.length >= 10 ? int.parse(sanitized.substring(8, 10)) : 0;
      final minute = sanitized.length >= 12 ? int.parse(sanitized.substring(10, 12)) : 0;
      final second = sanitized.length >= 14 ? int.parse(sanitized.substring(12, 14)) : 0;

      if (isUtc) {
        return DateTime.utc(year, month, day, hour, minute, second);
      } else {
        return DateTime(year, month, day, hour, minute, second);
      }
    } catch (e) {
      return null;
    }
  }
}