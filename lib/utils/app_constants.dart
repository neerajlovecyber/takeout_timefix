import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appTitle = 'Takeout TimeFix';
  static const String appName = 'Google Photos Takeout Organizer';

  // UI Strings
  static const String selectTakeoutFolder = 'Select Takeout Folder';
  static const String selectOutputFolder = 'Select Output Folder';
  static const String outputFolderConfiguration = 'Output Folder Configuration';
  static const String chooseOutputLocation = 'Choose where you want the organized photos to be saved.';
  static const String readyForProcessing = 'Ready for Processing';
  static const String processingReadyMessage = 'Both takeout and output folders are configured. You can now proceed to choose your organization method and start processing.';

  // Status Messages
  static const String folderConfiguredSuccessfully = 'Output folder configured successfully';
  static const String noWritePermissions = 'Output folder exists but no write permissions. Try a different location.';
  static const String invalidOutputFolder = 'Invalid output folder. Please select a different location.';
  static const String noMediaFilesFound = 'No media files found and doesn\'t appear to be a Google Photos takeout folder';
  static const String googlePhotosFolderDetected = 'Folder appears to be a Google Photos takeout folder (no files found yet)';

  // File Extensions
  static const List<String> supportedImageExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic', '.mov', '.mp4'
  ];

  // Google Photos Indicators
  static const List<String> googlePhotosIndicators = [
    'google photos', 'photos', 'takeout', 'media'
  ];

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardPadding = 16.0;
  static const double buttonPadding = 16.0;
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double buttonFontSize = 16.0;
  static const double titleFontSize = 16.0;

  // Animation durations
  static const Duration snackBarDuration = Duration(seconds: 5);
  static const Duration shortSnackBarDuration = Duration(seconds: 4);
  static const Duration folderSelectionDelay = Duration(milliseconds: 100);

  // Default paths
  static const String defaultDirectory = 'C:\\';
  static const String testFileName = '.takeout_timefix_test';
}

class AppColors {
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = Colors.red;
  static const Color info = Colors.blue;
}