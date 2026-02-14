#!/bin/bash
# Breedly App - Quick Start Script

echo "🚀 Starting Breedly App..."
echo ""

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter from https://flutter.dev"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version)"
echo ""

# Navigate to project
cd "$(dirname "$0")" || exit

# Clean and setup
echo "🧹 Cleaning project..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo ""
echo "✅ Setup complete!"
echo ""
echo "📱 Available devices:"
flutter devices

echo ""
echo "🎯 To run the app, use one of these commands:"
echo ""
echo "  # Default (first device)"
echo "  flutter run"
echo ""
echo "  # Android emulator"
echo "  flutter run -d emulator-5554"
echo ""
echo "  # iOS simulator"
echo "  flutter run -d ios"
echo ""
echo "  # Chrome browser"
echo "  flutter run -d chrome"
echo ""
echo "  # With verbose logging"
echo "  flutter run -v"
echo ""

echo "📚 Documentation:"
echo "  - QUICK_START.md - Quick start guide"
echo "  - APP_STATUS.md - Complete overview"
echo "  - APP_STATUS_SUMMARY.md - This summary"
echo "  - FIREBASE_SETUP.md - Firebase configuration"
echo ""

echo "✨ Ready to start! Run: flutter run"
