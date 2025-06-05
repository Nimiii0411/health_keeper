# HealthKeeper - Ứng Dụng Quản Lý Sức Khỏe

## 🎯 Tổng Quan
HealthKeeper là ứng dụng di động giúp người dùng theo dõi và quản lý sức khỏe cá nhân một cách hiệu quả.

## ✨ Tính Năng Chính

### 🔐 Xác Thực Người Dùng
- **Màn hình đăng nhập**: Xác thực với email/username và mật khẩu
- **Màn hình đăng ký**: Tạo tài khoản mới với thông tin đầy đủ
- **Splash Screen**: Màn hình chào mừng với animation
- **Kết nối MongoDB**: Lưu trữ dữ liệu người dùng an toàn

### 🏠 Trang Chủ (HomeScreen)
- **Dashboard tổng quan**: Hiển thị thông tin sức khỏe cơ bản
- **Quick Actions**: 4 nút chức năng nhanh
  - 👤 Tài Khoản
  - 📖 Nhật Ký
  - 💪 Tập Luyện  
  - 🔔 Nhắc Nhở
- **Navigation Drawer**: Menu bên với điều hướng dễ dàng

### 👤 Quản Lý Tài Khoản (AccountScreen)
- Hiển thị thông tin cá nhân
- Chỉnh sửa profile
- Cài đặt ứng dụng
- Đăng xuất

### 📖 Nhật Ký Sức Khỏe (DiaryScreen)
- Ghi chép hoạt động hàng ngày
- Theo dõi tâm trạng
- Lưu trữ các sự kiện sức khỏe quan trọng
- Tìm kiếm và lọc entries

### 💪 Tập Luyện (ExerciseScreen)
- **Danh sách bài tập**: Chạy bộ, Đẩy tạ, Yoga, Bơi lội
- **Theo dõi thời gian**: Duration cho mỗi bài tập
- **Đếm calories**: Tính toán lượng calo tiêu thụ
- **Lịch sử tập luyện**: Xem các session đã hoàn thành
- **Progress tracking**: Theo dõi tiến độ

### 🔔 Nhắc Nhở (ReminderScreen)
- **Loại nhắc nhở**:
  - 💊 Thuốc (Medicine)
  - 🏃 Tập luyện (Exercise)  
  - 👨‍⚕️ Bác sĩ (Doctor)
  - 📝 Khác (Other)
- **Quản lý thời gian**: Đặt giờ nhắc nhở
- **Bật/tắt**: Toggle on/off cho từng reminder
- **Chỉnh sửa**: Edit thông tin nhắc nhở

## 🛠️ Công Nghệ Sử Dụng

### Frontend
- **Flutter**: Framework UI cross-platform
- **Dart**: Ngôn ngữ lập trình
- **Material Design**: UI/UX hiện đại

### Backend & Database
- **MongoDB**: NoSQL database cloud
- **MongoDB Atlas**: Cloud database service
- **User Service**: Service layer cho quản lý người dùng

### Architecture
- **MVC Pattern**: Model-View-Controller
- **Widget-based UI**: Cấu trúc component
- **State Management**: StatefulWidget và setState

## 📱 Platforms Hỗ Trợ
- ✅ **Windows Desktop**
- ✅ **Android** (Ready)
- ✅ **Web Browser**
- ✅ **iOS** (Ready)

## 🚀 Cách Chạy Ứng Dụng

### Prerequisites
```bash
# Cài đặt Flutter SDK
# Cài đặt Android Studio / Xcode (nếu cần)
# Thiết lập MongoDB connection
```

### Build & Run
```bash
# Clone project
cd HealthKeeper

# Get dependencies
flutter pub get

# Run on Windows
flutter run -d windows

# Run on Android
flutter run -d android

# Run on Web
flutter run -d chrome
```

## 🔧 Development Tools
- **Hot Reload**: Instant UI updates
- **DevTools**: Debugging và profiling
- **Flutter Inspector**: Widget tree analysis

## 📊 Database Schema

### User Model
```dart
class User {
  String id;
  String username;
  String email;
  String fullName;
  String password; // Encrypted
  DateTime createdAt;
  Map<String, dynamic> healthData;
}
```

## 🎨 UI Features
- **Responsive Design**: Tự động điều chỉnh theo màn hình
- **Dark/Light Theme**: Material Design theming
- **Smooth Navigation**: Transition animations
- **Touch-friendly**: Optimized cho mobile

## 🔒 Bảo Mật
- Mã hóa password
- Secure MongoDB connection
- Input validation
- Session management

## 📈 Tương Lai
- [ ] Push notifications
- [ ] Health data sync với Google Fit
- [ ] Social features
- [ ] AI health recommendations
- [ ] Wearable device integration

---
**Phát triển bởi**: KunN21  
**Ngày**: June 2025  
**Version**: 1.0.0
