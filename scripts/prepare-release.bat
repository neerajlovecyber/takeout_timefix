@echo off
REM Prepare Release Script for Takeout TimeFix (Windows)
REM This script helps prepare a new release by running tests and checks

echo 🚀 Preparing Takeout TimeFix Release
echo ==================================

REM Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo ❌ Error: pubspec.yaml not found. Please run this script from the project root.
    exit /b 1
)

REM Get current version
for /f "tokens=2 delims= " %%a in ('findstr "version:" pubspec.yaml') do set CURRENT_VERSION=%%a
for /f "tokens=1 delims=+" %%a in ("%CURRENT_VERSION%") do set CURRENT_VERSION=%%a
echo 📦 Current version: %CURRENT_VERSION%

REM Clean previous builds
echo 🧹 Cleaning previous builds...
flutter clean
flutter pub get

REM Run code formatting
echo 🎨 Formatting code...
dart format .

REM Run static analysis
echo 🔍 Running static analysis...
flutter analyze --fatal-infos

REM Run tests
echo 🧪 Running tests...
flutter test

REM Build for different platforms to verify
echo 🏗️  Testing builds...

REM Test Android build
echo   📱 Testing Android build...
flutter build apk --debug

REM Test Windows build
echo   🪟 Testing Windows build...
flutter build windows --debug

REM Test Web build
echo   🌐 Testing Web build...
flutter build web --debug

echo.
echo ✅ All checks passed! Ready for release.
echo.
echo 📋 Next steps:
echo 1. Update CHANGELOG.md with release notes
echo 2. Commit your changes
echo 3. Use GitHub Actions to create a release:
echo    - Go to Actions → Version Bump → Run workflow
echo    - Choose version bump type (patch/minor/major)
echo    - The release will be created automatically
echo.
echo 🏷️  Current version: %CURRENT_VERSION%

REM Get repository URL for GitHub Actions link
for /f "tokens=*" %%a in ('git config --get remote.origin.url') do set REPO_URL=%%a
echo 🔗 GitHub Actions: https://github.com/%REPO_URL:~19,-4%/actions

pause