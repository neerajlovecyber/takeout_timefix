# Technology Stack

## Framework & Language
- **Flutter SDK**: 3.9.2+ (cross-platform UI framework)
- **Dart**: Language for Flutter development
- **Material Design 3**: UI design system with `useMaterial3: true`

## Architecture Pattern
- **Provider Pattern**: State management using `provider` package
- **Service Layer Architecture**: Organized into models, providers, services, screens, utils, widgets
- **Separation of Concerns**: Clear separation between UI, business logic, and data processing

## Key Dependencies

### Core Flutter Packages
- `flutter/material.dart` - Material Design UI components
- `provider: ^6.0.0` - State management and dependency injection

### File System & I/O
- `file_picker: ^8.0.6` - Cross-platform file and folder selection
- `path_provider: ^2.1.3` - Platform-specific directory access
- `path: ^1.9.0` - Cross-platform path manipulation
- `mime: ^1.0.5` - MIME type detection for file filtering

### Image Processing & Metadata
- `image: ^4.1.7` - Image processing and metadata extraction
- `exif: ^3.3.0` - EXIF metadata extraction (matches reference implementation)
- `crypto: ^3.0.3` - SHA256 hashing for duplicate detection

### Utilities
- `convert: ^3.1.1` - Date/time formatting utilities
- `rxdart: ^0.27.7` - Reactive extensions for Dart streams
- `unorm_dart: ^0.2.0` - Unicode normalization for multi-language support
- `collection: ^1.18.0` - Advanced collection operations
- `proper_filesize: ^0.0.1` - Human-readable file size formatting

### Development
- `flutter_lints: ^5.0.0` - Recommended linting rules
- `flutter_test` - Testing framework

## Build & Development Commands

### Setup
```bash
# Install dependencies
flutter pub get

# Check for outdated packages
flutter pub outdated

# Upgrade packages
flutter pub upgrade
```

### Development
```bash
# Run in development mode
flutter run

# Run on specific platform
flutter run -d windows
flutter run -d android
flutter run -d ios

# Hot reload is automatic in development mode
```

### Code Quality
```bash
# Run static analysis
flutter analyze

# Run tests
flutter test

# Format code
dart format .

# Check for linting issues
dart analyze
```

### Building
```bash
# Build for release (Android)
flutter build apk --release
flutter build appbundle --release

# Build for release (iOS)
flutter build ios --release

# Build for desktop
flutter build windows --release
flutter build macos --release
flutter build linux --release

# Build for web
flutter build web --release
```

## Platform Support
- ✅ Android (API level varies by Flutter version)
- ✅ iOS (iOS 11.0+)
- ✅ Windows (Windows 10+)
- ✅ macOS (macOS 10.14+)
- ✅ Linux (64-bit)
- ✅ Web (modern browsers)

## Code Style & Linting
- Uses `package:flutter_lints/flutter.yaml` for recommended Flutter linting rules
- Analysis options configured in `analysis_options.yaml`
- Follows Flutter/Dart naming conventions and best practices
- Material Design 3 theming with seed color approach