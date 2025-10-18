import 'dart:io';

import 'package:path/path.dart' as p;

// These are thanks to @hheimbuerger <3
final _commonDatetimePatterns = [
  // example: Screenshot_20190919-053857_Camera-edited.jpg
  [
    RegExp(
        r'(?<date>(20|19|18)\\d{2}(01|02|03|04|05|06|07|08|09|10|11|12)[0-3]\\d-\\d{6})'),
    'YYYYMMDD-hhmmss'
  ],
  // example: IMG_20190509_154733-edited.jpg, MVIMG_20190215_193501.MP4, IMG_20190221_112112042_BURST000_COVER_TOP.MP4
  [
    RegExp(
        r'(?<date>(20|19|18)\\d{2}(01|02|03|04|05|06|07|08|09|10|11|12)[0-3]\\d_\\d{6})'),
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
  DateTime? extractTimestamp(File file) {
    for (final pat in _commonDatetimePatterns) {
      // extract date str with regex
      final match = (pat.first as RegExp).firstMatch(p.basename(file.path));
      final dateStr = match?.group(0);
      if (dateStr == null) continue;
      // parse it with given pattern
      DateTime? date;
      try {
        date = FixedDateTimeFormatter(pat.last as String, isUtc: false)
            .tryDecode(dateStr);
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

  const FixedDateTimeFormatter(this.format, {this.isUtc = false});

  DateTime? tryDecode(String dateStr) {
    try {
      String sanitized = dateStr.replaceAll('-', '').replaceAll('_', '').replaceAll(':', '');
      if (sanitized.length < 14) return null;

      final year = int.parse(sanitized.substring(0, 4));
      final month = int.parse(sanitized.substring(4, 6));
      final day = int.parse(sanitized.substring(6, 8));
      final hour = int.parse(sanitized.substring(8, 10));
      final minute = int.parse(sanitized.substring(10, 12));
      final second = int.parse(sanitized.substring(12, 14));

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