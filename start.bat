@echo off
REM Breedly App - Quick Start Script for Windows

echo 🚀 Starting Breedly App...
echo.

REM Check Flutter installation
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter not found. Please install Flutter from https://flutter.dev
    pause
    exit /b 1
)

echo ✅ Flutter found:
flutter --version
echo.

REM Navigate to project directory
cd /d "%~dp0"

REM Clean and setup
echo 🧹 Cleaning project...
call flutter clean

echo 📦 Getting dependencies...
call flutter pub get

echo.
echo ✅ Setup complete!
echo.
echo 📱 Available devices:
call flutter devices

echo.
echo 🎯 To run the app, use one of these commands:
echo.
echo   # Default (first device)
echo   flutter run
echo.
echo   # Android emulator
echo   flutter run -d emulator-5554
echo.
echo   # With verbose logging
echo   flutter run -v
echo.

echo 📚 Documentation:
echo   - QUICK_START.md - Quick start guide
echo   - APP_STATUS.md - Complete overview
echo   - APP_STATUS_SUMMARY.md - This summary
echo   - FIREBASE_SETUP.md - Firebase configuration
echo.

echo ✨ Ready to start! Run: flutter run
echo.
pause
