import 'package:mongo_dart/mongo_dart.dart';
import '../database/mongodb_service.dart';
import '../models/reminder_model.dart';

class ReminderService {
  static const String collectionName = 'reminders';

  // Lấy collection
  static DbCollection? get _collection {
    return DatabaseConnection.getCollection(collectionName);
  }

  // Tạo reminder mới
  static Future<bool> createReminder(Reminder reminder) async {
    try {
      var collection = _collection;
      if (collection == null) {
        print('❌ Database chưa được kết nối');
        return false;
      }

      final reminderData = reminder.toMap();
      reminderData['created_at'] = DateTime.now().toIso8601String();
      reminderData['updated_at'] = DateTime.now().toIso8601String();

      final result = await collection.insertOne(reminderData);
      
      if (result.isSuccess) {
        print('✅ Tạo reminder thành công: ${reminder.message}');
        return true;
      } else {
        print('❌ Lỗi tạo reminder: ${result.errmsg}');
        return false;
      }
    } catch (e) {
      print('❌ Exception tạo reminder: $e');
      return false;
    }
  }

  // Lấy tất cả reminders của user
  static Future<List<Reminder>> getUserReminders(int userId) async {
    try {
      var collection = _collection;
      if (collection == null) return [];

      final reminders = await collection
          .find(where.eq('user_id', userId))
          .toList();

      return reminders.map((doc) => Reminder.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi lấy reminders: $e');
      return [];
    }
  }

  // Lấy reminders active của user
  static Future<List<Reminder>> getActiveUserReminders(int userId) async {
    try {
      var collection = _collection;
      if (collection == null) return [];

      final reminders = await collection
          .find(where.eq('user_id', userId).eq('is_active', true))
          .toList();

      return reminders.map((doc) => Reminder.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi lấy active reminders: $e');
      return [];
    }
  }

  // Lấy reminders của ngày hôm nay
  static Future<List<Reminder>> getTodayReminders(int userId) async {
    try {
      var collection = _collection;
      if (collection == null) return [];

      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final reminders = await collection
          .find(where.eq('user_id', userId)
              .eq('reminder_date', todayString)
              .eq('is_active', true))
          .toList();

      return reminders.map((doc) => Reminder.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi lấy today reminders: $e');
      return [];
    }
  }

  // Lấy reminders sắp tới
  static Future<List<Reminder>> getUpcomingReminders(int userId) async {
    try {
      var collection = _collection;
      if (collection == null) return [];

      final today = DateTime.now();
      final startDateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final reminders = await collection
          .find(where.eq('user_id', userId)
              .gte('reminder_date', startDateString)
              .eq('is_active', true))
          .toList();

      return reminders.map((doc) => Reminder.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi lấy upcoming reminders: $e');
      return [];
    }
  }

  // Cập nhật reminder
  static Future<bool> updateReminder(ObjectId id, Reminder reminder) async {
    try {
      var collection = _collection;
      if (collection == null) return false;

      final updateData = reminder.toMap();
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final result = await collection.updateOne(
        where.id(id),
        modify.set('message', updateData['message'])
              .set('reminder_date', updateData['reminder_date'])
              .set('remind_time', updateData['remind_time'])
              .set('is_active', updateData['is_active'])
              .set('updated_at', updateData['updated_at']),
      );

      if (result.nModified > 0) {
        print('✅ Cập nhật reminder thành công');
        return true;
      } else {
        print('❌ Không có reminder nào được cập nhật');
        return false;
      }
    } catch (e) {
      print('❌ Lỗi cập nhật reminder: $e');
      return false;
    }
  }

  // Bật/tắt reminder
  static Future<bool> toggleReminder(ObjectId id, bool isActive) async {
    try {
      var collection = _collection;
      if (collection == null) return false;

      final result = await collection.updateOne(
        where.id(id),
        modify.set('is_active', isActive)
              .set('updated_at', DateTime.now().toIso8601String()),
      );

      return result.nModified > 0;
    } catch (e) {
      print('❌ Lỗi toggle reminder: $e');
      return false;
    }
  }

  // Vô hiệu hóa reminder (thay vì xóa)
  static Future<bool> disableReminder(ObjectId id) async {
    try {
      var collection = _collection;
      if (collection == null) return false;

      final result = await collection.updateOne(
        where.id(id),
        modify.set('is_active', false)
              .set('updated_at', DateTime.now().toIso8601String()),
      );

      if (result.nModified > 0) {
        print('✅ Vô hiệu hóa reminder thành công');
        return true;
      } else {
        print('❌ Không có reminder nào được vô hiệu hóa');
        return false;
      }
    } catch (e) {
      print('❌ Lỗi vô hiệu hóa reminder: $e');
      return false;
    }
  }

  // Xóa reminder
  static Future<bool> deleteReminder(ObjectId id) async {
    try {
      var collection = _collection;
      if (collection == null) return false;

      final result = await collection.deleteOne(where.id(id));
      
      if (result.isSuccess) {
        print('✅ Xóa reminder thành công');
        return true;
      } else {
        print('❌ Lỗi xóa reminder');
        return false;
      }
    } catch (e) {
      print('❌ Exception xóa reminder: $e');
      return false;
    }
  }

  // Lấy reminder theo ID
  static Future<Reminder?> getReminderById(ObjectId id) async {
    try {
      var collection = _collection;
      if (collection == null) return null;

      final result = await collection.findOne(where.id(id));
      
      if (result != null) {
        return Reminder.fromMap(result);
      }
      return null;
    } catch (e) {
      print('❌ Lỗi lấy reminder theo ID: $e');
      return null;
    }
  }

  // Đếm số reminder active của user
  static Future<int> countActiveReminders(int userId) async {
    try {
      var collection = _collection;
      if (collection == null) return 0;

      return await collection.count(
        where.eq('user_id', userId).eq('is_active', true),
      );
    } catch (e) {
      print('❌ Lỗi đếm active reminders: $e');
      return 0;
    }
  }

  // Lấy reminders đã hết hạn
  static Future<List<Reminder>> getExpiredReminders(int userId) async {
    try {
      var collection = _collection;
      if (collection == null) return [];

      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final reminders = await collection
          .find(where.eq('user_id', userId)
              .lt('reminder_date', todayString)
              .eq('is_active', true))
          .toList();

      return reminders.map((doc) => Reminder.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi lấy expired reminders: $e');
      return [];
    }
  }

  // Tìm kiếm reminders theo message
  static Future<List<Reminder>> searchReminders(int userId, String searchText) async {
    try {
      var collection = _collection;
      if (collection == null) return [];

      final reminders = await collection
          .find(where.eq('user_id', userId)
              .match('message', searchText, caseInsensitive: true))
          .toList();

      return reminders.map((doc) => Reminder.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi tìm kiếm reminders: $e');
      return [];
    }
  }
}
