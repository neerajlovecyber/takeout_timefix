# Product Overview

Takeout TimeFix is a Flutter application that organizes Google Photos takeout exports by fixing timestamp issues and reorganizing photos by date. The app helps users who have exported their Google Photos data and need to organize thousands of photos with missing or incorrect metadata.

## Core Purpose
- Process Google Photos takeout folders containing unzipped export data
- Extract creation dates from multiple sources (JSON metadata, EXIF data, filenames)
- Organize photos into date-based folder structures or single folders with date prefixes
- Handle edge cases like missing metadata, duplicates, and multi-language edited files

## Key User Workflows
1. **Folder Selection**: Users select their unzipped Google Photos takeout folder and choose an output directory
2. **Organization Options**: Choose between year-month folder structure (`2023/01-January/`) or single folder with date prefixes
3. **Batch Processing**: Process hundreds or thousands of photos with real-time progress tracking
4. **Metadata Recovery**: Apply custom dates to photos missing timestamp information

## Target Users
- Google Photos users who have exported their data via Google Takeout
- Users dealing with large photo collections (1000+ photos)
- People who need organized photo libraries with proper date structures
- Users experiencing timestamp issues in their exported Google Photos data