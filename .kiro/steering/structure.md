# Project Structure

## Root Directory Organization

### Core Flutter Structure
- `lib/` - Main application source code
- `pubspec.yaml` - Project dependencies and configuration
- `analysis_options.yaml` - Dart analyzer and linting configuration

### Platform-Specific Directories
- `android/` - Android platform configuration and build files
- `ios/` - iOS platform configuration and build files
- `windows/` - Windows desktop platform files
- `macos/` - macOS desktop platform files
- `linux/` - Linux desktop platform files
- `web/` - Web platform assets and configuration

### Development & Documentation
- `test/` - Unit and widget tests
- `example_libraries/` - Reference implementation from Google Photos Takeout Helper
- `README.md` - Project documentation and usage guide
- `FEATURES.md` - Feature implementation tracking
- `REFERENCE_IMPLEMENTATION.md` - Technical reference from original implementation

## lib/ Directory Architecture

### Entry Point
- `main.dart` - Application entry point with Provider setup and MaterialApp configuration

### Feature-Based Organization

#### `/models` - Data Models
- `folder_state.dart` - State management for folder selection
- `media.dart` - Core media file representation with metadata

#### `/providers` - State Management
- `stepper_provider.dart` - UI state management for step-by-step workflow

#### `/screens` - UI Screens
- `home_page.dart` - Main application screen with stepper interface

#### `/services` - Business Logic Layer
- `duplicate_service.dart` - Duplicate file detection and handling
- `error_handling_service.dart` - Centralized error management
- `file_organization_service.dart` - File organization and folder structure creation
- `file_service.dart` - Core file operations and utilities
- `folder_service.dart` - Folder scanning and validation
- `processing_service.dart` - Main photo processing orchestration
- `progress_service.dart` - Progress tracking and user feedback
- `timestamp_extractors/` - Subdirectory for timestamp extraction methods

#### `/utils` - Shared Utilities
- `app_constants.dart` - Application-wide constants and configuration
- `ui_helpers.dart` - UI utility functions and helpers

#### `/widgets` - Reusable UI Components
- `app_header.dart` - Application header component
- `folder_info_card.dart` - Folder information display widget
- `folder_selection_button.dart` - Folder selection UI component
- `output_folder_config_card.dart` - Output configuration widget
- `processing_progress_card.dart` - Progress display component
- `step_wrapper.dart` - Stepper UI wrapper component

## Architecture Patterns

### Service Layer Pattern
- Services handle all business logic and data processing
- Clear separation between UI components and business operations
- Services are stateless and can be easily tested

### Provider Pattern Implementation
- `ChangeNotifierProvider` at app root for global state
- `StepperProvider` manages UI workflow state
- State changes trigger UI rebuilds automatically

### Widget Composition
- Small, focused widgets for better reusability
- Card-based UI components for consistent design
- Wrapper components for common UI patterns

## File Naming Conventions

### Dart Files
- Use `snake_case` for file names
- Descriptive names indicating purpose (e.g., `file_organization_service.dart`)
- Group related functionality in subdirectories when appropriate

### Widget Files
- Widget files should match the main widget class name in snake_case
- Prefix with component type when helpful (e.g., `folder_selection_button.dart`)

### Service Files
- End service files with `_service.dart` suffix
- Use descriptive names for the service's primary responsibility

## Import Organization
- Flutter framework imports first
- Third-party package imports second
- Local project imports last
- Group imports with blank lines between categories

## Reference Implementation Integration
- `example_libraries/` contains reference code from Google Photos Takeout Helper v3.4.3
- Use as technical reference for timestamp extraction algorithms
- Key files: `gpth.dart`, `media.dart`, `date_extractors/`, `utils.dart`
- Maintain compatibility with reference implementation's data processing approach

## Testing Structure
- `test/` directory mirrors `lib/` structure
- Widget tests for UI components
- Unit tests for services and utilities
- Integration tests for complete workflows