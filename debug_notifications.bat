@echo off
title HealthKeeper - Debug Notifications

echo 🐛 HealthKeeper - Debug Notification Issues
echo ==============================================

REM Set proper PATH
set PATH=D:\Flutter\flutter\bin;D:\Git\cmd;%PATH%

REM Go to project directory
cd /d "d:\Code\School\Mobile\HealthKeeper"

echo 📱 Running app with verbose logging...
flutter run --verbose

pause
