// database/database_connection.dart
import 'package:mongo_dart/mongo_dart.dart';
import 'dart:async';

class DatabaseConnection {
  static Db? _db;
  static bool _isConnected = false;

  // MongoDB Atlas connection string
  static const String _connectionString =
      'mongodb+srv://Nimiii:tmnt14121@healthapp.nt16qqk.mongodb.net/Healthkeeper?retryWrites=true&w=majority&appName=HealthApp';

  // Getter để các service khác sử dụng
  static Db? get database => _db;
  static bool get isConnected => _isConnected;

  // Kết nối tới MongoDB với timeout và retry
  static Future<void> connect() async {
    if (_isConnected && _db != null) {
      print('Database đã được kết nối trước đó');
      return;
    }

    int maxRetries = 3;
    int currentRetry = 0;

    while (currentRetry < maxRetries) {
      try {
        print('Đang kết nối MongoDB... (Lần thử ${currentRetry + 1}/$maxRetries)');

        _db = await Db.create(_connectionString);
        await _db!.open().timeout(Duration(seconds: 30));

        // Test connection
        await _db!.serverStatus();

        _isConnected = true;
        print('✅ Kết nối MongoDB thành công!');
        print('📍 Cluster: HealthApp');
        print('📍 Database: Healthkeeper');
        return;
      } catch (e) {
        currentRetry++;
        print('❌ Lỗi kết nối MongoDB (Lần ${currentRetry}): $e');

        if (currentRetry >= maxRetries) {
          _isConnected = false;
          throw Exception('Không thể kết nối MongoDB sau $maxRetries lần thử: $e');
        }

        await Future.delayed(Duration(seconds: 2));
      }
    }
  }

  // Đóng kết nối
  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _isConnected = false;
      print('🔐 Đã đóng kết nối MongoDB');
    }
  }

  // Test connection
  static Future<void> testConnection() async {
    try {
      if (!_isConnected || _db == null) {
        throw Exception('Chưa kết nối database');
      }

      print('=== Test Connection ===');
      print('Status: ${_isConnected ? "Connected" : "Disconnected"}');
      print('Database name: ${_db!.databaseName}');

      // Test với collection users
      var usersCollection = _db!.collection('users');
      var count = await usersCollection.count();
      print('Số users trong collection: $count');
      
    } catch (e) {
      print('❌ Test connection failed: $e');
    }
  }

  // Lấy collection theo tên
  static DbCollection? getCollection(String collectionName) {
    if (!_isConnected || _db == null) {
      print('❌ Database chưa được kết nối');
      return null;
    }
    return _db!.collection(collectionName);
  }
}