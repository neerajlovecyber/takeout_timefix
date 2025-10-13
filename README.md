# Takeout TimeFix 📸

A powerful Flutter application designed to organize and fix timestamp issues in Google Photos takeout exports. This tool helps you reorganize your exported Google Photos by date while providing options to handle images with missing or incorrect metadata.

## ✨ Key Features

### 📁 Smart Folder Selection
- **Takeout Folder Selection**: Choose the folder containing your unzipped Google Photos takeout files
- **Output Directory**: Specify where you want your organized photos to be saved
- **Intuitive Interface**: Easy-to-use file picker with clear visual feedback

### 📅 Flexible Organization Options

#### Year-Month Structure
```
Output Folder/
├── 2023/
│   ├── 01-January/
│   ├── 02-February/
│   └── ...
└── 2024/
    ├── 01-January/
    └── ...
```

#### Single Folder Organization
```
Output Folder/
├── IMG_001.jpg (2023-01-15)
├── IMG_002.jpg (2023-02-20)
└── IMG_003.jpg (2024-03-10)
```

### ⏰ Metadata Management
- **Automatic Date Detection**: Extracts creation dates from image metadata (EXIF, XMP)
- **Custom Time Application**: Apply a specific date/time to images missing metadata
- **Batch Processing**: Handle multiple images with the same custom timestamp
- **Preserve Original Quality**: No compression or quality loss during processing

### 🔧 Advanced Options
- **Format Selection**: Choose between year-month folders or single folder organization
- **Progress Tracking**: Real-time progress updates during processing
- **Error Handling**: Robust error handling for corrupted or inaccessible files
- **Duplicate Management**: Smart handling of duplicate filenames

## 🚀 How It Works

### Step 1: Select Your Takeout Folder
1. Launch the Takeout TimeFix application
2. Click "Select Takeout Folder"
3. Navigate to and select the folder containing your unzipped Google Photos takeout
4. The app will scan and display the number of images found

### Step 2: Choose Output Location
1. Click "Select Output Folder"
2. Choose where you want your organized photos to be saved
3. The app will create the necessary folder structure automatically

### Step 3: Configure Organization Settings
- **Year-Month Folders**: Organize photos into `YYYY/MM-MonthName/` structure
- **Single Folder**: Place all photos in one folder with date prefixes
- **Custom Date**: Set a specific date for images without metadata

### Step 4: Process Your Photos
1. Review your settings
2. Click "Start Processing"
3. Monitor progress in real-time
4. Receive completion notification with summary

## 📋 Workflow Example

```
User's Google Photos Takeout/
├── takeout-20231201T000000Z-001.zip (unzipped content)
│   ├── Photos/
│   │   ├── IMG_0001.jpg
│   │   ├── IMG_0002.jpg
│   │   └── ...
│   └── metadata.json

After Processing/
├── Organized Photos/
│   ├── 2023/
│   │   ├── 06-June/
│   │   │   ├── IMG_0001_20230615_143022.jpg
│   │   │   └── IMG_0002_20230620_091530.jpg
│   │   └── 12-December/
│   │       └── IMG_0003_20231201_120000.jpg
│   └── 2024/
│       └── 01-January/
│           └── IMG_0004_20240115_160000.jpg
```

## 🛠️ Installation & Setup

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK (compatible with Flutter version)
- Android Studio or VS Code with Flutter extensions
- iOS development tools (for iOS deployment)

### Installation
1. Clone the repository:
```bash
git clone <repository-url>
cd takeout_timefix
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

### Platform Support
- ✅ Android
- ✅ iOS
- ✅ Windows
- ✅ macOS
- ✅ Linux
- ✅ Web

## 📱 Usage Guide

### First Time Setup
1. Launch the application
2. Grant necessary file system permissions
3. Complete the initial configuration wizard

### Processing Your Photos
1. **Select Source**: Choose your Google Photos takeout folder
2. **Configure Output**: Set your preferred organization method
3. **Handle Missing Metadata**: Set custom dates if needed
4. **Start Processing**: Begin the organization process

### Tips for Best Results
- Ensure all photos from your takeout are in the selected folder
- Choose an output location with sufficient storage space
- Review settings before starting large batch operations
- Keep backups of original files until you're satisfied with results

## 🔧 Technical Details

### Dependencies
- **Flutter**: UI framework and cross-platform support
- **file_picker**: File and directory selection
- **image**: Image metadata reading and manipulation
- **path_provider**: Platform-specific directory access
- **permission_handler**: Runtime permission management

### File Format Support
- JPEG (.jpg, .jpeg)
- PNG (.png)
- HEIC (.heic) - with appropriate platform support
- TIFF (.tiff, .tif)
- WebP (.webp)

### Metadata Sources
1. **EXIF Data**: Primary source for creation timestamps
2. **XMP Data**: Alternative metadata format
3. **File System Dates**: Fallback to file creation/modification dates
4. **Custom Input**: User-specified dates for problematic files

### Performance Considerations
- **Memory Efficient**: Processes images in batches to minimize memory usage
- **Background Processing**: Non-blocking UI during long operations
- **Progress Updates**: Real-time feedback on processing status
- **Error Recovery**: Continues processing even if individual files fail

## 🐛 Troubleshooting

### Common Issues

**"Permission Denied" Error**
- Ensure the app has storage permissions on your device
- Check that the selected folders are accessible

**"No Images Found"**
- Verify the takeout folder contains image files
- Check that files aren't hidden or in subdirectories

**"Processing Failed"**
- Ensure sufficient disk space in output location
- Check for corrupted image files in source
- Try processing smaller batches first

### Getting Help
1. Check the troubleshooting section above
2. Review application logs for detailed error messages
3. Ensure you're using the latest version of the app

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines for details on:
- Reporting bugs
- Suggesting features
- Submitting pull requests

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Google Photos for the takeout export feature
- Flutter community for excellent documentation and packages
- Contributors and testers who help improve the application

---

**Made with ❤️ for Google Photos users who want better organization control**
