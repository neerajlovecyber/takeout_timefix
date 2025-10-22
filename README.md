# Takeout TimeFix 📸

A Flutter desktop application to organize Google Photos takeout exports by date with intelligent timestamp extraction.

## ✨ Features

- **Smart Organization**: Organize photos by year/month or single folder
- **Metadata Extraction**: Extract dates from EXIF, JSON metadata, and folder names
- **Date Guessing**: Automatically assign dates to photos without metadata based on folder names
- **Cross-platform**: Windows, macOS, Linux, and Android support
- **Modern UI**: Material Design 3 interface with real-time progress tracking

## 🚀 Quick Start

1. **Download**: Get the latest release for your platform from [GitHub Releases](https://github.com/your-username/takeout-timefix/releases)
2. **Extract**: Unzip the downloaded archive
3. **Run**: Launch the application
4. **Select Folders**: Choose your Google Photos takeout folder and output directory
5. **Process**: Click "Start Processing" to organize your photos

## 📦 Downloads

### Desktop Applications
- **Windows**: `takeout-timefix-windows-x64.zip`
- **macOS**: `takeout-timefix-macos.tar.gz`
- **Linux**: `takeout-timefix-linux-x64.tar.gz`

### Mobile
- **Android**: `takeout-timefix-android.apk` (for sideloading)

## 🔧 How It Works

### Input Structure
```
Google Photos Takeout/
├── Photos from 2017/
│   ├── IMG_0001.jpg (no metadata)
│   └── IMG_0002.jpg (has EXIF date)
└── Photos from 2018/
    └── IMG_0003.jpg
```

### Output Structure
```
Organized Photos/
├── 2017/
│   ├── 01-January/
│   │   └── IMG_0001_20170101_000000.jpg (guessed from folder name)
│   └── 06-June/
│       └── IMG_0002_20170615_143022.jpg (from EXIF)
└── 2018/
    └── 01-January/
        └── IMG_0003_20180101_000000.jpg
```

### Date Sources (Priority Order)
1. **EXIF metadata** from image files
2. **JSON metadata** from Google Photos export
3. **Folder name guessing** (e.g., "Photos from 2017" → Jan 1, 2017)
4. **File system dates** as last resort

## 🛠️ Development

### Prerequisites
- Flutter 3.24.0+
- Platform-specific build tools

### Setup
```bash
git clone https://github.com/your-username/takeout-timefix.git
cd takeout_timefix
flutter pub get
flutter run
```

### Building
```bash
# Desktop builds
flutter build windows
flutter build linux
flutter build macos

# Android
flutter build apk
```

## 📋 License

MIT License - see LICENSE file for details.

---

**Built with Flutter for photo organization workflows**
