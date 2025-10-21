#!/bin/bash

# Prepare Release Script for Takeout TimeFix
# This script helps prepare a new release by running tests and checks

set -e

echo "🚀 Preparing Takeout TimeFix Release"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Please run this script from the project root."
    exit 1
fi

# Get current version
CURRENT_VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
echo "📦 Current version: $CURRENT_VERSION"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Run code formatting
echo "🎨 Formatting code..."
dart format .

# Run static analysis
echo "🔍 Running static analysis..."
flutter analyze --fatal-infos

# Run tests
echo "🧪 Running tests..."
flutter test

# Build for different platforms to verify
echo "🏗️  Testing builds..."

# Test Android build
echo "  📱 Testing Android build..."
flutter build apk --debug

# Test Windows build (if on Windows)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo "  🪟 Testing Windows build..."
    flutter build windows --debug
fi

# Test macOS build (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "  🍎 Testing macOS build..."
    flutter build macos --debug
fi

# Test Linux build (if on Linux)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "  🐧 Testing Linux build..."
    flutter build linux --debug
fi

# Test Web build
echo "  🌐 Testing Web build..."
flutter build web --debug

echo ""
echo "✅ All checks passed! Ready for release."
echo ""
echo "📋 Next steps:"
echo "1. Update CHANGELOG.md with release notes"
echo "2. Commit your changes"
echo "3. Use GitHub Actions to create a release:"
echo "   - Go to Actions → Version Bump → Run workflow"
echo "   - Choose version bump type (patch/minor/major)"
echo "   - The release will be created automatically"
echo ""
echo "🏷️  Current version: $CURRENT_VERSION"
echo "🔗 GitHub Actions: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions"