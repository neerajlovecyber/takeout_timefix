# 🔬 Google Photos Takeout Helper - Reference Implementation

## Overview
Based on the analysis of `example_libraries/gpth.dart` and related files, here's the complete implementation approach for timestamp extraction and file processing from the Google Photos Takeout Helper (v3.4.3).

## Core Architecture Files

### Main Orchestrator
**Reference**: `example_libraries/gpth.dart` (403 lines)
- Command-line interface and processing pipeline
- Coordinates all extraction methods and file operations
- Handles both interactive and CLI modes
- Manages progress bars and user feedback
- Main processing function: `main(List<String> arguments)`

### Media Class
**Reference**: `example_libraries/media.dart` (68 lines)
```dart
class Media {
  Map<String?, File> files;  // album_name -> file mapping
  DateTime? dateTaken;       // extracted timestamp
  int? dateTakenAccuracy;    // accuracy score (lower = better)
  Digest hash;              // for duplicate detection
}
```

### Utilities and Extensions
**Reference**: `example_libraries/utils.dart` (135 lines)
- File system operations and extensions
- MIME type filtering for photos/videos
- Cross-platform disk space checking
- File size formatting utilities

## Timestamp Extraction Methods (Priority Order)

### 1. JSON Metadata Extractor (Most Accurate)
**Reference**: `example_libraries/date_extractors/json_extractor.dart` (130 lines)

**Primary Method**: Reads Google's JSON metadata files containing exact `photoTakenTime` timestamps

**File Matching Strategies**:
- Basic filename matching
- Shortened names for long filenames (>51 chars)
- Bracket swapping: `image(1).jpg` → `image.jpg(1).json`
- Multi-language "edited" suffix removal
- Extension stripping when needed

**Key Functions**:
```dart
Future<DateTime?> jsonExtractor(File file, {bool tryhard = false})
Future<File?> _jsonForFile(File file, {required bool tryhard})
```

**Error Handling**: Robust parsing with multiple fallback strategies for corrupted JSON files

### 2. EXIF Data Extractor
**Reference**: `example_libraries/date_extractors/exif_extractor.dart` (41 lines)

**Method**: Direct EXIF metadata reading from image files

**EXIF Fields Used**:
- `DateTimeOriginal` (primary)
- `DateTimeDigitized` (fallback)
- `DateTime` (last resort)

**Format Handling**: Normalizes various date separators (`-`, `/`, `.`, `\`)

**Constraints**:
- Only processes files under 64MB (`maxFileSize` constant)
- Validates MIME type is image/* before processing

**Implementation**:
```dart
Future<DateTime?> exifExtractor(File file)
```

### 3. Filename Pattern Extractor
**Reference**: `example_libraries/date_extractors/guess_extractor.dart` (66 lines)

**Method**: Regex-based date extraction from filenames

**Supported Patterns**:
- `Screenshot_20190919-053857.jpg` → `2019-09-19 05:38:57`
- `IMG_20190509_154733.jpg` → `2019-05-09 15:47:33`
- `signal-2020-10-26-163832.jpg` → `2020-10-26 16:38:32`
- `2016_01_30_11_49_15.mp4` → `2016-01-30 11:49:15`

**Pattern Categories**:
- `YYYYMMDD-hhmmss` (Screenshot format)
- `YYYYMMDD_hhmmss` (IMG format)
- `YYYY-MM-DD-hh-mm-ss` (Signal format)
- `YYYY-MM-DD-hhmmss` (Alternative format)

### 4. Try-hard JSON Extractor (Last Resort)
**Reference**: `example_libraries/date_extractors/json_extractor.dart`

**Method**: Aggressive JSON matching for problematic files

**Additional Strategies**:
- Regex-based suffix removal (`-[A-Za-zÀ-ÖØ-öø-ÿ]+(\(\d\))?`)
- Digit removal from brackets (`\(\d\)\.`)

## File Processing Pipeline

### 1. File Discovery
**Reference**: `example_libraries/utils.dart` (Extensions)

```dart
extension X on Iterable<FileSystemEntity> {
  Iterable<File> wherePhotoVideo() // Filters for images/videos by MIME type
}

extension Y on Stream<FileSystemEntity> {
  Stream<File> wherePhotoVideo() // Stream version for async processing
}
```

**MIME Types Detected**:
- Images: `image/*`
- Videos: `video/*`
- Special cases: `model/vnd.mts` (MTS video files)

### 2. Duplicate Detection
**Reference**: `example_libraries/grouping.dart` (Not analyzed yet)

**Hash-based Detection**:
- Uses SHA256 for file content comparison
- Size caching in Media class for performance
- Album merging combines duplicate files from different albums

### 3. Extra File Removal
**Reference**: `example_libraries/extras.dart` (50 lines)

**Multi-language Support**: Removes "edited" versions in 10+ languages:
```dart
const extraFormats = [
  '-edited', '-effects', '-smile', '-mix',
  '-edytowane' (PL), '-bearbeitet' (DE),
  '-bewerkt' (NL), '-編集済み' (JA),
  '-modificato' (IT), '-modifié' (FR),
  '-ha editado' (ES), '-editat' (CA)
];
```

**Unicode Handling**: Uses NFC normalization for accented characters

### 4. File Operations
**Reference**: `example_libraries/moving.dart` (Not analyzed yet)

**Modes**:
- **Copy Mode**: Preserves original files (`--copy` flag)
- **Move Mode**: Relocates files (default)
- **Date-based Organization**: Optional `YYYY/MM-MonthName/` structure (`--divide-to-dates`)

## Key Constants and Configuration

**Reference**: `example_libraries/utils.dart`
```dart
const version = '3.4.3';
const maxFileSize = 64 * 1024 * 1024;  // 64MB limit for processing
const barWidth = 40;  // Progress bar width
```

## Technical Dependencies Required

Based on the reference implementation, these packages would be needed:

**Core Dependencies**:
- `exif` - EXIF metadata extraction
- `crypto` - SHA256 hashing for duplicates
- `mime` - MIME type detection
- `path` - Cross-platform path operations
- `collection` - Advanced collection operations

**Utility Dependencies**:
- `unorm_dart` - Unicode normalization
- `console_bars` - Progress bars (CLI)
- `args` - Command-line argument parsing
- `proper_filesize` - Human-readable file sizes

**Date/Time Dependencies**:
- `convert` - DateTimeFormatter for filename parsing

## Implementation Strategy for Flutter

### Phase 1: Foundation (Start Here)
1. **JSON extraction** - Most reliable method, handles Google's format perfectly
2. **Media class** - Core data structure for file management
3. **File discovery** - MIME type filtering and recursive scanning

### Phase 2: Enhancement
4. **EXIF fallback** - For files without JSON metadata
5. **Duplicate detection** - Essential for album handling
6. **Progress tracking** - User feedback during processing

### Phase 3: Polish
7. **Filename parsing** - Handle edge cases and screenshots
8. **Extra file filtering** - Clean up edited versions
9. **Error recovery** - Robust handling of problematic files

## Code Examples

### Basic Usage Pattern
```dart
// 1. Find all media files
final mediaFiles = await findMediaFiles(inputDirectory);

// 2. Extract timestamps using cascade of methods
for (final file in mediaFiles) {
  DateTime? timestamp;

  // Try JSON first (most accurate)
  timestamp ??= await jsonExtractor(file);

  // Try EXIF second
  timestamp ??= await exifExtractor(file);

  // Try filename parsing last
  timestamp ??= await guessExtractor(file);

  if (timestamp != null) {
    await applyTimestamp(file, timestamp);
  }
}
```

### Media Object Management
```dart
// Create Media object for each file
Media media = Media({null: file});  // null key for year folders

// Add to album if found in album folder
if (albumName != null) {
  media.files[albumName] = file;
}

// Set extracted timestamp with accuracy score
media.dateTaken = extractedDate;
media.dateTakenAccuracy = accuracy;  // 0=JSON, 1=EXIF, 2=filename
```

This reference implementation provides a robust foundation for handling Google Photos exports with multiple fallback mechanisms ensuring high success rates for timestamp extraction.