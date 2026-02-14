@echo off
REM Navigate to the breedly directory and stay there
cd /d "%~dp0"

echo.
echo ========================================
echo Breedly - Running Flutter App
echo ========================================
echo.

REM Show available devices
echo Checking available devices...
flutter devices
echo.

REM Run on Chrome
echo Running on Chrome...
flutter run -d chrome

pause
