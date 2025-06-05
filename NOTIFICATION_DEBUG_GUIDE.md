📱 **DEBUGGING NOTIFICATION ISSUES** 📱

## ✅ **CÁCH TEST NOTIFICATION:**

### **1. Chạy App Debug:**
```cmd
test_notifications_debug.bat
```

### **2. Kiểm tra từng bước:**

**🔧 Step 1: Check Permissions**
- Mở app → Settings → Thông báo  
- Tap "Check Permissions"
- Đảm bảo cả 2 permissions = `true`

**🧪 Step 2: Test Instant Notification**
- Tap "Test Instant Notification"
- Notification phải xuất hiện ngay lập tức
- Nếu không xuất hiện → Vấn đề về permissions hoặc channel

**⏰ Step 3: Test Schedule Notification**
- Tap "Test Schedule (5s)"
- Chờ 5 giây → Notification phải xuất hiện
- Nếu không xuất hiện → Vấn đề về scheduling

**📋 Step 4: Check Pending**
- Tạo reminder từ ReminderScreen
- Quay lại test screen
- Tap "Show Pending" → Phải thấy reminder được schedule

### **3. Common Issues & Solutions:**

**❌ Không có notification nào:**
- Check Android notification settings
- Settings → Apps → HealthKeeper → Notifications → Enable

**❌ App crash khi đến thời gian:**
- Kiểm tra logs trong terminal
- Có thể do timezone issue hoặc permission

**❌ Notification không hoạt động đúng thời gian:**
- Kiểm tra device timezone
- Kiểm tra exactAlarms permission

### **4. Debug Commands:**
```cmd
# Xem logs realtime
flutter logs

# Build release version test
flutter build apk --release

# Install on device
flutter install
```

### **5. Android Settings to Check:**
1. **Device Settings → Apps → HealthKeeper:**
   - Notifications: ✅ Enabled
   - Battery optimization: ❌ Disabled
   
2. **Device Settings → Apps → Special access:**
   - Alarms & reminders: ✅ HealthKeeper enabled

---
**💡 TIP:** Nếu vẫn có vấn đề, thử tắt app hoàn toàn và mở lại!
