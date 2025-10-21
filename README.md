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
- **Smart Date Guessing**: For photos without metadata, automatically assigns January 1st of the year found in folder names (e.g., "Photos from 2017" → January 1, 2017) - **Enabled by default**
- **Custom Time Application**: Apply a specific date/time to images missing metadata
- **Batch Processing**: Handle multiple images with the same custom timestamp
- **Preserve Original Quality**: No compression or quality loss during processing

### 🔧 Advanced Options
- **Format Selection**: Choose between year-month folders or single folder organization
- **Progress Tracking**: Real-time progress updates during processing
- **Error Handling**: Robust error handling for corrupted or inaccessible files
- **Duplicate Management**: Smart handling of duplicate filenames

### 📅 Smart Date Guessing (Default: Enabled)

When photos don't have timestamp metadata, the app can intelligently guess dates from folder names:

**Example:**
- Folder `"Photos from 2017"` → Photos assigned to **January 1, 2017**
- No year found → Uses **current date**

**Why this helps:**
- Many Google Photos exports lose original timestamps during the takeout process
- Google Photos takeout typically creates folders like "Photos from 2017", "Photos from 2018", etc.
- Photos without metadata get assigned to January 1st of that year
- Provides a reasonable fallback date for organization by approximate time period
- Much better than leaving photos with random or missing dates
- Ensures all photos from a year folder stay grouped together chronologically

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
│   └── Photos from 2017/
│       ├── IMG_0001.jpg (no metadata)
│       └── IMG_0002.jpg (has EXIF date: June 15, 2017)

After Processing (with Date Guessing enabled)/
├── Organized Photos/
│   └── 2017/
│       ├── 01-January/
│       │   └── IMG_0001_20170101_000000.jpg (guessed from "Photos from 2017")
│       └── 06-June/
│           └── IMG_0002_20170615_143022.jpg (from EXIF data)
```

## 📦 Downloads & Installation

### 🚀 Pre-built Releases

Download the latest version for your platform from our [GitHub Releases](https://github.com/your-username/takeout-timefix/releases) page:

**Desktop Applications:**
- **Windows**: Download `takeout-timefix-windows-x64.zip`
- **macOS**: Download `takeout-timefix-macos.tar.gz`
- **Linux**: Download `takeout-timefix-linux-x64.tar.gz`

**Mobile Applications:**
- **Android**: Download `takeout-timefix-android.apk`

**Web Application:**
- **Web**: Download `takeout-timefix-web.tar.gz` (for self-hosting)

### 🔧 Installation Instructions

#### Windows
1. Download `takeout-timefix-windows-x64.zip`
2. Extract the archive to a folder of your choice
3. Run `takeout_timefix.exe`

#### macOS
1. Download `takeout-timefix-macos.tar.gz`
2. Extract the archive: `tar -xzf takeout-timefix-macos.tar.gz`
3. Move `takeout_timefix.app` to your Applications folder
4. Right-click the app and select "Open" (first time only, due to Gatekeeper)

#### Linux
1. Download `takeout-timefix-linux-x64.tar.gz`
2. Extract the archive: `tar -xzf takeout-timefix-linux-x64.tar.gz`
3. Make executable: `chmod +x takeout_timefix`
4. Run: `./takeout_timefix`

#### Android
1. Download `takeout-timefix-android.apk`
2. Enable "Install from unknown sources" in your device settings
3. Install the APK file

### 🛠️ Development Setup

#### Prerequisites
- Flutter SDK (3.24.0 or higher)
- Dart SDK (compatible with Flutter version)
- Platform-specific development tools:
  - **Windows**: Visual Studio 2022 with C++ tools
  - **macOS**: Xcode
  - **Linux**: Clang, CMake, GTK development libraries
  - **Android**: Android Studio or Android SDK
  - **Web**: Chrome browser

#### Building from Source
1. Clone the repository:
```bash
git clone https://github.com/your-username/takeout-timefix.git
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

#### Building for Release
Use our automated release preparation script:

**Linux/macOS:**
```bash
chmod +x scripts/prepare-release.sh
./scripts/prepare-release.sh
```

**Windows:**
```cmd
scripts\prepare-release.bat
```

### 🏗️ Platform Support
- ✅ **Windows** (Windows 10+)
- ✅ **macOS** (macOS 10.14+)
- ✅ **Linux** (64-bit)
- ✅ **Android** (API 21+)
- ✅ **Web** (Modern browsers)
- ⚠️ **iOS** (Development build only)

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

## 🚀 Automated Releases

This project uses GitHub Actions for automated building and releasing:

### 🏷️ Creating a Release

**Method 1: Automatic Version Bump (Recommended)**
1. Go to the [Actions tab](https://github.com/your-username/takeout-timefix/actions)
2. Select "Version Bump" workflow
3. Click "Run workflow"
4. Choose version bump type (patch/minor/major) or enter custom version
5. The workflow will automatically:
   - Update version in `pubspec.yaml`
   - Generate changelog entry
   - Create git tag
   - Trigger release build

**Method 2: Manual Tag**
1. Create and push a git tag: `git tag v1.0.0 && git push origin v1.0.0`
2. The release workflow will automatically build for all platforms

### 🔄 Continuous Integration

Every push and pull request triggers:
- Code formatting verification
- Static analysis (Flutter analyze)
- Unit tests
- Build verification for all platforms

### 📋 Release Assets

Each release automatically includes:
- **Windows**: `.zip` archive with executable
- **macOS**: `.tar.gz` archive with `.app` bundle  
- **Linux**: `.tar.gz` archive with executable
- **Android**: `.apk` file for sideloading
- **Android**: `.aab` file for Play Store
- **Web**: `.tar.gz` archive for web hosting

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines for details on:
- Reporting bugs
- Suggesting features
- Submitting pull requests

### Development Workflow
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and test thoroughly
4. Run the preparation script: `./scripts/prepare-release.sh`
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Google Photos for the takeout export feature
- Flutter community for excellent documentation and packages
- Contributors and testers who help improve the application

---

**Made with ❤️ for Google Photos users who want better organization control**
