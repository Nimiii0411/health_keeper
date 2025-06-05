import 'package:mongo_dart/mongo_dart.dart';
import 'dart:async';
import '../models/user_model.dart';

class MongoDBService {
  static Db? _db;
  static DbCollection? _collection;

  // MongoDB Atlas connection string
  static const String _connectionString =
      'mongodb+srv://Nimiii:tmnt14121@healthapp.nt16qqk.mongodb.net/healthapp?retryWrites=true&w=majority&appName=HealthApp';
  static const String _collectionName = 'users';

  // Kết nối tới MongoDB với timeout và retry
  static Future<void> connect() async {
    int maxRetries = 3;
    int currentRetry = 0;

    while (currentRetry < maxRetries) {
      try {
        print(
          'Đang kết nối MongoDB... (Lần thử ${currentRetry + 1}/$maxRetries)',
        );

        _db = await Db.create(_connectionString);

        // Thêm timeout 30 giây
        await _db!.open().timeout(Duration(seconds: 30));

        _collection = _db!.collection(_collectionName);

        // Test connection bằng cách ping
        await _db!.serverStatus();

        print('Kết nối MongoDB thành công!');
        return;
      } catch (e) {
        currentRetry++;
        print('Lỗi kết nối MongoDB (Lần ${currentRetry}): $e');

        if (currentRetry >= maxRetries) {
          throw Exception(
            'Không thể kết nối MongoDB sau $maxRetries lần thử: $e',
          );
        }

        // Đợi 2 giây trước khi thử lại
        await Future.delayed(Duration(seconds: 2));
      }
    }
  }

  // Đóng kết nối
  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      print('Đã đóng kết nối MongoDB');
    }
  }

  // Lấy ID user tiếp theo (tăng tự động)
  static Future<int> getNextUserId() async {
    try {
      // Tìm user có id_user lớn nhất
      var result = await _collection!.find().toList();
      if (result.isEmpty) {
        return 1; // Nếu chưa có user nào, bắt đầu từ 1
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
      print('Lỗi khi lấy next user ID: $e');
      return 9; // Fallback: bắt đầu từ 9 (vì hiện tại có 8)
    }
  }

  // Đăng ký user mới
  static Future<bool> registerUser(User user) async {
    try {
      // Kiểm tra username đã tồn tại chưa
      var existingUser = await _collection!.findOne({
        'username': user.username,
      });
      if (existingUser != null) {
        throw Exception('Username đã tồn tại!');
      }

      // Kiểm tra email đã tồn tại chưa
      var existingEmail = await _collection!.findOne({'email': user.email});
      if (existingEmail != null) {
        throw Exception('Email đã tồn tại!');
      }

      // Lấy ID user tiếp theo
      user.idUser = await getNextUserId();

      // Thêm user vào database
      var result = await _collection!.insertOne(user.toMap());
      return result.isSuccess;
    } catch (e) {
      print('Lỗi đăng ký user: $e');
      rethrow;
    }
  }

  // Lấy tất cả users (để test)
  static Future<List<User>> getAllUsers() async {
    try {
      var result = await _collection!.find().toList();
      return result.map((doc) => User.fromMap(doc)).toList();
    } catch (e) {
      print('Lỗi lấy danh sách users: $e');
      return [];
    }
  }

  // Kiểm tra đăng nhập (bonus function)
  static Future<User?> loginUser(String username, String password) async {
    try {
      var result = await _collection!.findOne({
        'username': username,
        'password': password,
      });

      if (result != null) {
        return User.fromMap(result);
      }
      return null;
    } catch (e) {
      print('Lỗi đăng nhập: $e');
      return null;
    }
  }
}
