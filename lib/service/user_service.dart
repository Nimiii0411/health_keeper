// services/user_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../database/mongodb_service.dart';
import '../models/user_model.dart';

class UserService {
  static const String _collectionName = 'users';

  // Lấy collection users
  static DbCollection? get _collection =>
      DatabaseConnection.getCollection(_collectionName);

  // Lấy ID user tiếp theo (tăng tự động)
  static Future<int> _getNextUserId() async {
    try {
      var collection = _collection;
      if (collection == null) {
        throw Exception('Không thể truy cập collection users');
      }

      var result = await collection.find().toList();
      if (result.isEmpty) {
        return 1; // Bắt đầu từ 1 nếu chưa có user nào
      }

      int maxId = 0;
      for (var doc in result) {
        int currentId = doc['id_user'] ?? 0;
        if (currentId > maxId) {
          maxId = currentId;
        }
      }
      return maxId + 1;
    } catch (e) {
      print('❌ Lỗi khi lấy next user ID: $e');
      return 1; // Fallback
    }
  }

  // Đăng ký user mới
  static Future<bool> registerUser(User user) async {
    try {
      var collection = _collection;
      if (collection == null) {
        throw Exception('Database chưa được kết nối');
      }

      print('📝 Bắt đầu đăng ký user: ${user.username}');

      // Kiểm tra username đã tồn tại chưa
      print('🔍 Kiểm tra username...');
      var existingUser = await collection.findOne({'username': user.username});
      if (existingUser != null) {
        throw Exception('Username "${user.username}" đã tồn tại!');
      }

      // Kiểm tra email đã tồn tại chưa
      print('📧 Kiểm tra email...');
      var existingEmail = await collection.findOne({'email': user.email});
      if (existingEmail != null) {
        throw Exception('Email "${user.email}" đã tồn tại!');
      }

      // Lấy ID user tiếp theo
      print('🔢 Lấy next user ID...');
      user.idUser = await _getNextUserId();
      print('✅ Next ID: ${user.idUser}');

      // Thêm user vào database
      print('💾 Đang lưu vào database...');
      var result = await collection.insertOne(user.toMap());

      if (result.isSuccess) {
        print('✅ Đăng ký thành công! User ID: ${user.idUser}');
        return true;
      } else {
        print('❌ Đăng ký thất bại!');
        return false;
      }
    } catch (e) {
      print('❌ Lỗi đăng ký user: $e');
      rethrow;
    }
  }

  // Đăng nhập user
  static Future<User?> loginUser(String username, String password) async {
    try {
      var collection = _collection;
      if (collection == null) {
        throw Exception('Database chưa được kết nối');
      }

      print('🔐 Đang kiểm tra đăng nhập cho: $username');

      var result = await collection.findOne({
        'username': username,
        'password': password,
      });

      if (result != null) {
        var user = User.fromMap(result);
        print('✅ Đăng nhập thành công! Welcome ${user.fullName}');
        return user;
      } else {
        print('❌ Sai username hoặc password');
        return null;
      }
    } catch (e) {
      print('❌ Lỗi đăng nhập: $e');
      return null;
    }
  }

  // Lấy thông tin user theo username
  static Future<User?> getUserByUsername(String username) async {
    try {
      var collection = _collection;
      if (collection == null) {
        throw Exception('Database chưa được kết nối');
      }

      var result = await collection.findOne({'username': username});
      if (result != null) {
        return User.fromMap(result);
      }
      return null;
    } catch (e) {
      print('❌ Lỗi lấy thông tin user: $e');
      return null;
    }
  }

  // Lấy thông tin user theo email
  static Future<User?> getUserByEmail(String email) async {
    try {
      var collection = _collection;
      if (collection == null) {
        throw Exception('Database chưa được kết nối');
      }

      var result = await collection.findOne({'email': email});
      if (result != null) {
        return User.fromMap(result);
      }
      return null;
    } catch (e) {
      print('❌ Lỗi lấy thông tin user: $e');
      return null;
    }
  }

  // Lấy tất cả users (cho admin hoặc debug)
  static Future<List<User>> getAllUsers() async {
    try {
      var collection = _collection;
      if (collection == null) {
        throw Exception('Database chưa được kết nối');
      }

      var result = await collection.find().toList();
      return result.map((doc) => User.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi lấy danh sách users: $e');
      return [];
    }
  }

  // Đếm số lượng users
  static Future<int> getUserCount() async {
    try {
      var collection = _collection;
      if (collection == null) {
        return 0;
      }

      return await collection.count();
    } catch (e) {
      print('❌ Lỗi đếm users: $e');
      return 0;
    }
  }

  // Cập nhật thông tin user
  static Future<bool> updateUser(User user) async {
    try {
      var collection = _collection;
      if (collection == null) {
        throw Exception('Database chưa được kết nối');
      }

      print('🔄 Đang cập nhật user: ${user.username}');      var result = await collection.updateOne(
        where.eq('id_user', user.idUser),
        modify
          .set('full_name', user.fullName)
          .set('email', user.email)
          .set('gender', user.gender)
          .set('birth_date', user.birthDate),
      );

      if (result.isSuccess) {
        print('✅ Cập nhật thành công!');
        return true;
      } else {
        print('❌ Không có thay đổi nào được cập nhật');
        return false;
      }
    } catch (e) {
      print('❌ Lỗi cập nhật user: $e');
      return false;
    }
  }

  // Đổi mật khẩu
  static Future<bool> changePassword(int userId, String oldPassword, String newPassword) async {
    try {
      var collection = _collection;
      if (collection == null) {
        throw Exception('Database chưa được kết nối');
      }

      print('🔐 Đang đổi mật khẩu cho user ID: $userId');

      // Kiểm tra mật khẩu cũ
      var user = await collection.findOne({
        'id_user': userId,
        'password': oldPassword,
      });

      if (user == null) {
        throw Exception('Mật khẩu cũ không đúng!');
      }      // Cập nhật mật khẩu mới
      var result = await collection.updateOne(
        where.eq('id_user', userId),
        modify.set('password', newPassword),
      );

      if (result.isSuccess) {
        print('✅ Đổi mật khẩu thành công!');
        return true;
      } else {
        print('❌ Đổi mật khẩu thất bại');
        return false;
      }
    } catch (e) {
      print('❌ Lỗi đổi mật khẩu: $e');
      rethrow;
    }
  }

  // Kiểm tra username có tồn tại không (trừ user hiện tại)
  static Future<bool> isUsernameAvailable(String username, int currentUserId) async {
    try {
      var collection = _collection;
      if (collection == null) {
        return false;
      }

      var result = await collection.findOne({
        'username': username,
        'id_user': {'\$ne': currentUserId}
      });

      return result == null; // null means username is available
    } catch (e) {
      print('❌ Lỗi kiểm tra username: $e');
      return false;
    }
  }

  // Kiểm tra email có tồn tại không (trừ user hiện tại)
  static Future<bool> isEmailAvailable(String email, int currentUserId) async {
    try {
      var collection = _collection;
      if (collection == null) {
        return false;
      }

      var result = await collection.findOne({
        'email': email,
        'id_user': {'\$ne': currentUserId}
      });

      return result == null; // null means email is available
    } catch (e) {
      print('❌ Lỗi kiểm tra email: $e');
      return false;
    }
  }
}
