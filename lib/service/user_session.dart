import '../models/user_model.dart';

class UserSession {
  static User? _currentUser;
  static bool _isLoggedIn = false;

  // Getter cho user hiện tại
  static User? get currentUser => _currentUser;
  static bool get isLoggedIn => _isLoggedIn;
  static int? get currentUserId => _currentUser?.idUser;

  // Đăng nhập
  static void login(User user) {
    _currentUser = user;
    _isLoggedIn = true;
    print('✅ User đăng nhập: ${user.username} (ID: ${user.idUser})');
  }

  // Đăng xuất
  static void logout() {
    print('👋 User đăng xuất: ${_currentUser?.username}');
    _currentUser = null;
    _isLoggedIn = false;
  }

  // Cập nhật thông tin user
  static void updateUser(User user) {
    _currentUser = user;
    print('🔄 Cập nhật thông tin user: ${user.username}');
  }

  // Kiểm tra quyền truy cập
  static bool hasAccess() {
    return _isLoggedIn && _currentUser != null;
  }

  // Lấy tên hiển thị
  static String getDisplayName() {
    if (_currentUser != null) {
      return _currentUser!.fullName.isNotEmpty 
          ? _currentUser!.fullName 
          : _currentUser!.username;
    }
    return 'Guest';
  }

  // Lấy email
  static String getEmail() {
    return _currentUser?.email ?? '';
  }

  // Kiểm tra có phải admin không (có thể mở rộng sau)
  static bool isAdmin() {
    // TODO: Implement admin check logic
    return false;
  }
}
