import 'package:mongo_dart/mongo_dart.dart';
import '../database/mongodb_service.dart';
import '../models/reminder_goal_model.dart';

class ReminderService {
  static const String _collectionName = 'reminders';

  static DbCollection? get _collection =>
      DatabaseConnection.getCollection(_collectionName);

  // Thêm reminder mới
  static Future<bool> addReminder(Reminder reminder) async {
    try {
      var collection = _collection;
      if (collection == null) return false;

      var result = await collection.insertOne(reminder.toMap());
      print('✅ Thêm reminder thành công: ${result.id}');
      return true;
    } catch (e) {
      print('❌ Lỗi khi thêm reminder: $e');
      return false;
    }
  }

  // Lấy tất cả reminders của user
  static Future<List<Reminder>> getUserReminders(int userId) async {
    try {
      var collection = _collection;
      if (collection == null) return [];

      var results = await collection
          .find(where.eq('user_id', userId))
          .toList();

      return results.map((doc) => Reminder.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy reminders: $e');
      return [];
    }
  }

  // Lấy reminders đang hoạt động
  static Future<List<Reminder>> getActiveReminders(int userId) async {
    try {
      var collection = _collection;
      if (collection == null) return [];

      var results = await collection
          .find(where.eq('user_id', userId).eq('is_active', true))
          .toList();

      return results.map((doc) => Reminder.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy active reminders: $e');
      return [];
    }
  }

  // Lấy reminders theo loại
  static Future<List<Reminder>> getRemindersByType(int userId, String type) async {
    try {
      var collection = _collection;
      if (collection == null) return [];

      var results = await collection
          .find(where.eq('user_id', userId).eq('type', type))
          .toList();

      return results.map((doc) => Reminder.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy reminders theo type: $e');
      return [];
    }
  }

  // Cập nhật reminder
  static Future<bool> updateReminder(ObjectId id, Reminder reminder) async {
    try {
      var collection = _collection;
      if (collection == null) return false;

      var result = await collection.updateOne(
        where.id(id),
        modify.set('title', reminder.title)
              .set('description', reminder.description)
              .set('time', reminder.time)
              .set('is_active', reminder.isActive)
              .set('type', reminder.type)
              .set('repeat_days', reminder.repeatDays)
              .set('medicine_details', reminder.medicineDetails)
              .set('exercise_details', reminder.exerciseDetails),
      );

      return result.nModified > 0;
    } catch (e) {
      print('❌ Lỗi khi cập nhật reminder: $e');
      return false;
    }
  }

  // Bật/tắt reminder
  static Future<bool> toggleReminder(ObjectId id, bool isActive) async {
    try {
      var collection = _collection;
      if (collection == null) return false;

      var result = await collection.updateOne(
        where.id(id),
        modify.set('is_active', isActive),
      );

      return result.nModified > 0;
    } catch (e) {
      print('❌ Lỗi khi toggle reminder: $e');
      return false;
    }
  }

  // Xóa reminder
  static Future<bool> deleteReminder(ObjectId id) async {
    try {
      var collection = _collection;
      if (collection == null) return false;

      var result = await collection.deleteOne(where.id(id));
      return result.nRemoved > 0;
    } catch (e) {
      print('❌ Lỗi khi xóa reminder: $e');
      return false;
    }
  }
}

class GoalService {
  static const String _collectionName = 'goals';

  static DbCollection? get _collection =>
      DatabaseConnection.getCollection(_collectionName);

  // Thêm goal mới
  static Future<bool> addGoal(Goal goal) async {
    try {
      var collection = _collection;
      if (collection == null) return false;

      var result = await collection.insertOne(goal.toMap());
      print('✅ Thêm goal thành công: ${result.id}');
      return true;
    } catch (e) {
      print('❌ Lỗi khi thêm goal: $e');
      return false;
    }
  }

  // Lấy tất cả goals của user
  static Future<List<Goal>> getUserGoals(int userId) async {
    try {
      var collection = _collection;
      if (collection == null) return [];

      var results = await collection
          .find(where.eq('user_id', userId))
          .toList();

      return results.map((doc) => Goal.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy goals: $e');
      return [];
    }
  }

  // Lấy goals đang hoạt động
  static Future<List<Goal>> getActiveGoals(int userId) async {
    try {
      var collection = _collection;
      if (collection == null) return [];

      var results = await collection
          .find(where.eq('user_id', userId).eq('is_active', true))
          .toList();

      return results.map((doc) => Goal.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy active goals: $e');
      return [];
    }
  }

  // Lấy goals theo loại
  static Future<List<Goal>> getGoalsByType(int userId, String goalType) async {
    try {
      var collection = _collection;
      if (collection == null) return [];

      var results = await collection
          .find(where.eq('user_id', userId).eq('goal_type', goalType))
          .toList();

      return results.map((doc) => Goal.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy goals theo type: $e');
      return [];
    }
  }

  // Cập nhật tiến độ goal
  static Future<bool> updateGoalProgress(ObjectId id, double currentValue) async {
    try {
      var collection = _collection;
      if (collection == null) return false;

      var result = await collection.updateOne(
        where.id(id),
        modify.set('current_value', currentValue),
      );

      return result.nModified > 0;
    } catch (e) {
      print('❌ Lỗi khi cập nhật goal progress: $e');
      return false;
    }
  }

  // Cập nhật goal
  static Future<bool> updateGoal(ObjectId id, Goal goal) async {
    try {
      var collection = _collection;
      if (collection == null) return false;

      var result = await collection.updateOne(
        where.id(id),
        modify.set('title', goal.title)
              .set('description', goal.description)
              .set('target_value', goal.targetValue)
              .set('current_value', goal.currentValue)
              .set('unit', goal.unit)
              .set('deadline', goal.deadline)
              .set('is_active', goal.isActive),
      );

      return result.nModified > 0;
    } catch (e) {
      print('❌ Lỗi khi cập nhật goal: $e');
      return false;
    }
  }

  // Xóa goal
  static Future<bool> deleteGoal(ObjectId id) async {
    try {
      var collection = _collection;
      if (collection == null) return false;

      var result = await collection.deleteOne(where.id(id));
      return result.nRemoved > 0;
    } catch (e) {
      print('❌ Lỗi khi xóa goal: $e');
      return false;
    }
  }
}
