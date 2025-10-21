# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Modern Material Design 3 UI implementation
- Responsive layout for desktop and mobile platforms
- Cross-platform support (Windows, macOS, Linux, Android, Web)
- Real-time progress tracking during photo processing
- Multiple organization modes (year-month folders, single folder)
- EXIF metadata extraction for timestamp recovery
- JSON metadata support for Google Photos exports
- Duplicate file detection and handling
- Smart date guessing from folder names (enabled by default)
- Custom date application for files missing metadata
- Interactive step-by-step workflow
- Dark mode support

### Changed
- Complete UI redesign with Material Design 3 components
- Improved folder selection with better validation
- Enhanced progress display with detailed statistics
- Modern card-based layout with proper spacing
- Responsive design optimized for both desktop and mobile
- Date guessing feature now enabled by default with detailed explanations
- Better information about what date guessing does (assigns January 1st of detected year)

### Technical
- Flutter 3.24.0+ compatibility
- Provider pattern for state management
- Service layer architecture
- Comprehensive error handling
- Cross-platform file operations
- Modern build system with GitHub Actions

## [1.0.0] - Initial Release

### Added
- Basic Google Photos takeout organization functionality
- Timestamp extraction from multiple sources
- File organization by date
- Cross-platform Flutter implementation