@echo off
title HealthKeeper - Test Notifications Debug

echo 🐛 HealthKeeper - Testing Notifications
echo =========================================

REM Set proper PATH
set PATH=D:\Flutter\flutter\bin;D:\Git\cmd;%PATH%

REM Go to project directory
cd /d "d:\Code\School\Mobile\HealthKeeper"

echo 🧹 Clean project first...
flutter clean

echo 📦 Get dependencies...
flutter pub get

echo 🔨 Build debug APK for testing...
flutter build apk --debug

echo 📱 Running app with notification debugging...
echo.
echo 🔍 Things to test when app launches:
echo    1. Go to Settings ^> Thông báo
echo    2. Tap "Test Instant Notification"
echo    3. Create a reminder 1 minute in future
echo    4. Check if notification appears
echo    5. Check app logs in terminal
echo.

flutter run --verbose

pause
