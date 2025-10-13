import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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

  // Output folder configuration (Feature 2)
  String? _outputFolderPath;
  bool _isValidOutputFolder = false;
  bool _hasWritePermissions = false;

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

  Future<void> _selectOutputFolder() async {
    try {
      // Add a small delay to ensure proper isolate handling
      await Future.delayed(const Duration(milliseconds: 100));

      // Get the default path first and log it for debugging
      String defaultPath = 'C:\\'; // Fallback
      try {
        defaultPath = await _getDefaultOutputPath();
      } catch (e) {
        defaultPath = 'C:\\';
      }

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Output Folder',
        initialDirectory: 'C:\\', // Use same simple approach as takeout folder
      );

      if (selectedDirectory != null) {
        setState(() {
          _outputFolderPath = selectedDirectory;
          _isValidOutputFolder = false;
          _hasWritePermissions = false;
        });

        // Validate the selected output folder
        await _validateOutputFolder(selectedDirectory);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting output folder: ${e.toString().substring(0, min(100, e.toString().length))}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<String> _getDefaultOutputPath() async {
    // Use same simple approach as takeout folder - just return C:\
    // The user can navigate to their preferred location from there
    return 'C:\\';
  }

  Future<void> _validateOutputFolder(String folderPath) async {
    try {
      // Basic validation - check if folder exists or can be created
      final directory = Directory(folderPath);

      // Check if directory exists, if not, try to create it
      bool exists = await directory.exists();
      if (!exists) {
        try {
          await directory.create(recursive: true);
          exists = true;
        } catch (e) {
          setState(() {
            _isValidOutputFolder = false;
            _hasWritePermissions = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot create output folder. Check permissions: ${e.toString().substring(0, min(80, e.toString().length))}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      }

      // Check write permissions by trying to create a test file
      bool canWrite = false;
      try {
        final String testFilePath = path.join(folderPath, '.takeout_timefix_test');
        final File testFile = File(testFilePath);
        await testFile.writeAsString('test');
        await testFile.delete(); // Clean up test file
        canWrite = true;
      } catch (e) {
        canWrite = false;
      }

      setState(() {
        _isValidOutputFolder = exists;
        _hasWritePermissions = canWrite;
      });

      if (mounted) {
        if (_isValidOutputFolder && _hasWritePermissions) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Output folder configured successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (_isValidOutputFolder && !_hasWritePermissions) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Output folder exists but no write permissions. Try a different location.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid output folder. Please select a different location.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isValidOutputFolder = false;
        _hasWritePermissions = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error validating output folder: ${e.toString().substring(0, min(80, e.toString().length))}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - kToolbarHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 24.0,
            ),
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

                // Output Folder Configuration (Feature 2)
                if (_isValidTakeoutFolder) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.output, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Output Folder Configuration',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose where you want the organized photos to be saved.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _selectOutputFolder,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Select Output Folder'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],

                // Selected Output Folder Info
                if (_outputFolderPath != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isValidOutputFolder && _hasWritePermissions
                                    ? Icons.check_circle
                                    : _isValidOutputFolder
                                        ? Icons.warning
                                        : Icons.error,
                                color: _isValidOutputFolder && _hasWritePermissions
                                    ? Colors.green
                                    : _isValidOutputFolder
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Output Folder:',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _outputFolderPath!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                _isValidOutputFolder && _hasWritePermissions
                                    ? '✅ Ready for processing'
                                    : _isValidOutputFolder
                                        ? '⚠️ No write permissions'
                                        : '❌ Invalid folder',
                                style: TextStyle(
                                  color: _isValidOutputFolder && _hasWritePermissions
                                      ? Colors.green
                                      : _isValidOutputFolder
                                          ? Colors.orange
                                          : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],

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

                // Next Steps Info
                if (_isValidTakeoutFolder && _isValidOutputFolder && _hasWritePermissions) ...[
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ready for Processing',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Both takeout and output folders are configured. You can now proceed to choose your organization method and start processing.',
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
        ),
      ),
    );
  }
}
