import 'dart:io';
import 'package:path/path.dart' as p;

/// Extracts a year from the parent folder name (e.g., "Photos from 2016").
class FolderNameExtractor {
  DateTime? extractTimestamp(File file) {
    try {
      final parentDirName = p.basename(file.parent.path);
      final yearMatch = RegExp(r'(20|19)\d{2}').firstMatch(parentDirName);

      if (yearMatch != null) {
        final year = int.parse(yearMatch.group(0)!);
        // Default to January 1st of the found year
        return DateTime(year, 1, 1);
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }
}