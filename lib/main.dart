import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as path;

void main() {
  runApp(const TakeoutTimeFixApp());
}

class TakeoutTimeFixApp extends StatelessWidget {
  const TakeoutTimeFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Takeout TimeFix',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedFolderPath;
  bool _isValidTakeoutFolder = false;
  List<String> _imageFiles = [];

  Future<void> _selectTakeoutFolder() async {
    try {
      // Add a small delay to ensure proper isolate handling
      await Future.delayed(const Duration(milliseconds: 100));

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Google Photos Takeout Folder',
        initialDirectory: _selectedFolderPath ?? 'C:\\',
      );

      if (selectedDirectory != null) {
        setState(() {
          _selectedFolderPath = selectedDirectory;
          _isValidTakeoutFolder = false;
          _imageFiles = [];
        });

        // Validate the selected folder
        await _validateTakeoutFolder(selectedDirectory);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting folder: ${e.toString().substring(0, min(100, e.toString().length))}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _validateTakeoutFolder(String folderPath) async {
    try {
      // Basic validation - check if folder exists
      final directory = Directory(folderPath);

      if (!await directory.exists()) {
        setState(() {
          _isValidTakeoutFolder = false;
        });
        return;
      }

      // Look for common image file extensions recursively
      List<String> imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic', '.mov', '.mp4'];
      List<String> foundImages = [];

      await for (var entity in directory.list(recursive: true)) {
        if (entity is File) {
          String extension = path.extension(entity.path).toLowerCase();
          if (imageExtensions.contains(extension)) {
            foundImages.add(entity.path);
          }
        }
      }

      // Also check for Google Photos specific structure indicators
      bool hasGooglePhotosStructure = false;
      try {
        // Look for "Google Photos" folder or typical takeout structure
        List<String> subdirs = [];
        await for (var entity in directory.list(recursive: false)) {
          if (entity is Directory) {
            subdirs.add(path.basename(entity.path));
          }
        }

        // Check for common Google Photos takeout folder names
        List<String> googlePhotosIndicators = ['google photos', 'photos', 'takeout', 'media'];
        hasGooglePhotosStructure = subdirs.any((dir) =>
          googlePhotosIndicators.any((indicator) =>
            dir.toLowerCase().contains(indicator)));
      } catch (e) {
        // If we can't read subdirectories, that's okay
      }

      setState(() {
        _imageFiles = foundImages;
        // Consider it valid if we found images OR it looks like a Google Photos structure
        _isValidTakeoutFolder = foundImages.isNotEmpty || hasGooglePhotosStructure;
      });

      if (mounted) {
        if (_isValidTakeoutFolder) {
          if (foundImages.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Found ${foundImages.length} media files in the selected folder'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Folder appears to be a Google Photos takeout folder (no files found yet)'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No media files found and doesn\'t appear to be a Google Photos takeout folder'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isValidTakeoutFolder = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error validating folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Takeout TimeFix'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Photos Takeout Organizer',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select the folder containing your unzipped Google Photos takeout files to begin organizing them by date.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Folder Selection Button
            ElevatedButton.icon(
              onPressed: _selectTakeoutFolder,
              icon: const Icon(Icons.folder_open),
              label: const Text('Select Takeout Folder'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 24),

            // Selected Folder Info
            if (_selectedFolderPath != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isValidTakeoutFolder ? Icons.check_circle : Icons.warning,
                            color: _isValidTakeoutFolder ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Selected Folder:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFolderPath!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isValidTakeoutFolder
                            ? '✅ Found ${_imageFiles.length} image files'
                            : '⚠️ No image files found in this folder',
                        style: TextStyle(
                          color: _isValidTakeoutFolder ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const Spacer(),

            // Next Steps Info
            if (_isValidTakeoutFolder) ...[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready for Next Steps',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can now proceed to configure the output folder and choose your organization method.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
