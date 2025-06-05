# HealthKeeper Project Test Script
# Test NotificationService integration mà không cần Flutter run

Write-Host "🔔 HealthKeeper Notification Integration Test" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra file structure
Write-Host "📁 Kiểm tra cấu trúc project..." -ForegroundColor Yellow

$projectPath = "d:\Code\School\Mobile\HealthKeeper"
$requiredFiles = @(
    "lib\main.dart",
    "lib\service\notification_service.dart",
    "lib\screen\reminder_screen.dart",
    "lib\screen\notification_test_screen.dart",
    "lib\providers\theme_provider.dart",
    "lib\widgets\theme_toggle.dart",
    "android\app\src\main\AndroidManifest.xml"
)

$allFilesExist = $true
foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $projectPath $file
    if (Test-Path $fullPath) {
        Write-Host "  ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $file" -ForegroundColor Red
        $allFilesExist = $false
    }
}

Write-Host ""

# Kiểm tra dependencies trong pubspec.yaml
Write-Host "📦 Kiểm tra dependencies..." -ForegroundColor Yellow

$pubspecPath = Join-Path $projectPath "pubspec.yaml"
if (Test-Path $pubspecPath) {
    $pubspecContent = Get-Content $pubspecPath -Raw
    
    $requiredDeps = @(
        "flutter_local_notifications",
        "timezone", 
        "provider",
        "shared_preferences"
    )
    
    foreach ($dep in $requiredDeps) {
        if ($pubspecContent -match $dep) {
            Write-Host "  ✅ $dep" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $dep" -ForegroundColor Red
            $allFilesExist = $false
        }
    }
}

Write-Host ""

# Kiểm tra Android permissions
Write-Host "🤖 Kiểm tra Android permissions..." -ForegroundColor Yellow

$manifestPath = Join-Path $projectPath "android\app\src\main\AndroidManifest.xml"
if (Test-Path $manifestPath) {
    $manifestContent = Get-Content $manifestPath -Raw
    
    $requiredPermissions = @(
        "android.permission.INTERNET",
        "android.permission.WAKE_LOCK",
        "android.permission.VIBRATE",
        "android.permission.POST_NOTIFICATIONS",
        "android.permission.SCHEDULE_EXACT_ALARM"
    )
    
    foreach ($permission in $requiredPermissions) {
        if ($manifestContent -match $permission) {
            Write-Host "  ✅ $permission" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $permission" -ForegroundColor Red
        }
    }
}

Write-Host ""

# Kiểm tra code structure
Write-Host "🔍 Kiểm tra code integration..." -ForegroundColor Yellow

# Kiểm tra main.dart có NotificationService.initialize()
$mainPath = Join-Path $projectPath "lib\main.dart"
if (Test-Path $mainPath) {
    $mainContent = Get-Content $mainPath -Raw
    
    if ($mainContent -match "NotificationService\.initialize") {
        Write-Host "  ✅ NotificationService.initialize() trong main.dart" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Thiếu NotificationService.initialize() trong main.dart" -ForegroundColor Red
    }
    
    if ($mainContent -match "createNotificationChannel") {
        Write-Host "  ✅ createNotificationChannel() trong main.dart" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Thiếu createNotificationChannel() trong main.dart" -ForegroundColor Red
    }
}

# Kiểm tra ReminderScreen có NotificationService integration
$reminderPath = Join-Path $projectPath "lib\screen\reminder_screen.dart"
if (Test-Path $reminderPath) {
    $reminderContent = Get-Content $reminderPath -Raw
    
    if ($reminderContent -match "_scheduleNotification") {
        Write-Host "  ✅ _scheduleNotification() trong ReminderScreen" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Thiếu _scheduleNotification() trong ReminderScreen" -ForegroundColor Red
    }
    
    if ($reminderContent -match "_cancelNotification") {
        Write-Host "  ✅ _cancelNotification() trong ReminderScreen" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Thiếu _cancelNotification() trong ReminderScreen" -ForegroundColor Red
    }
    
    if ($reminderContent -match "ThemeToggleButton") {
        Write-Host "  ✅ Dark mode integration" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Thiếu dark mode integration" -ForegroundColor Red
    }
}

Write-Host ""

# Tổng kết
if ($allFilesExist) {
    Write-Host "🎉 KẾT QUẢ: Project đã sẵn sàng!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📱 Để chạy app:" -ForegroundColor Cyan
    Write-Host "   1. Chạy: run_healthkeeper.bat" -ForegroundColor White
    Write-Host "   2. Hoặc fix Git PATH và dùng: flutter run" -ForegroundColor White
    Write-Host ""
    Write-Host "🧪 Test features:" -ForegroundColor Cyan
    Write-Host "   • ReminderScreen: Home → Nhắc Nhở" -ForegroundColor White
    Write-Host "   • NotificationTest: Settings → Thông báo" -ForegroundColor White
    Write-Host "   • Dark mode: Toggle button ở góc phải" -ForegroundColor White
    Write-Host ""
    Write-Host "🔔 Notifications sẽ hoạt động khi:" -ForegroundColor Cyan
    Write-Host "   • App được chạy trên Android device/emulator" -ForegroundColor White
    Write-Host "   • User cấp quyền notifications" -ForegroundColor White
    Write-Host "   • Thêm/edit reminders với thời gian tương lai" -ForegroundColor White
} else {
    Write-Host "❌ Có vấn đề với project structure!" -ForegroundColor Red
    Write-Host "Vui lòng kiểm tra các file bị thiếu ở trên." -ForegroundColor Red
}

Write-Host ""
Write-Host "Nhấn Enter để thoát..." -ForegroundColor Gray
Read-Host
