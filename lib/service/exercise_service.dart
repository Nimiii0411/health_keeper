import 'package:mongo_dart/mongo_dart.dart';
import '../database/mongodb_service.dart';
import '../models/exercise_model.dart';

class ExerciseService {
  static const String _exercisesCatalogCollectionName = 'exercises_catalog';
  static const String _exerciseDailyCollectionName = 'exercise_daily';

  static DbCollection? get _exercisesCatalogCollection =>
      DatabaseConnection.getCollection(_exercisesCatalogCollectionName);
  
  static DbCollection? get _exerciseDailyCollection =>
      DatabaseConnection.getCollection(_exerciseDailyCollectionName);

  // Lấy tất cả bài tập từ catalog
  static Future<List<Exercise>> getAllExercises() async {
    try {
      var collection = _exercisesCatalogCollection;
      if (collection == null) return [];

      var results = await collection.find().toList();
      return results.map((doc) => Exercise.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy exercises: $e');
      return [];
    }
  }

  // Tìm kiếm bài tập theo tên
  static Future<List<Exercise>> searchExercisesByName(String searchTerm) async {
    try {
      var collection = _exercisesCatalogCollection;
      if (collection == null) return [];

      var results = await collection
          .find(where.match('exercise_name', searchTerm))
          .toList();

      return results.map((doc) => Exercise.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi tìm kiếm exercises: $e');
      return [];
    }
  }

  // Lấy bài tập theo tên
  static Future<Exercise?> getExerciseByName(String exerciseName) async {
    try {
      var collection = _exercisesCatalogCollection;
      if (collection == null) return null;

      var result = await collection.findOne(where.eq('exercise_name', exerciseName));
      if (result != null) {
        return Exercise.fromMap(result);
      }
      return null;
    } catch (e) {
      print('❌ Lỗi khi lấy exercise theo tên: $e');
      return null;
    }
  }

  // Thêm bài tập hàng ngày
  static Future<bool> addExerciseDaily(ExerciseDaily exerciseDaily) async {
    try {
      var collection = _exerciseDailyCollection;
      if (collection == null) return false;

      var result = await collection.insertOne(exerciseDaily.toMap());
      print('✅ Thêm exercise daily thành công: ${result.id}');
      return true;
    } catch (e) {
      print('❌ Lỗi khi thêm exercise daily: $e');
      return false;
    }
  }

  // Lấy bài tập hàng ngày theo user và ngày
  static Future<List<ExerciseDaily>> getExercisesByUserAndDate(int userId, String date) async {
    try {
      var collection = _exerciseDailyCollection;
      if (collection == null) return [];

      var results = await collection
          .find(where.eq('user_id', userId).eq('entry_date', date))
          .toList();

      return results.map((doc) => ExerciseDaily.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy exercises theo user và ngày: $e');
      return [];
    }
  }

  // Lấy tất cả bài tập của user
  static Future<List<ExerciseDaily>> getUserExercises(int userId) async {
    try {
      var collection = _exerciseDailyCollection;
      if (collection == null) return [];

      var results = await collection
          .find(where.eq('user_id', userId))
          .toList();

      return results.map((doc) => ExerciseDaily.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy user exercises: $e');
      return [];
    }
  }

  // Tính tổng calories đốt cháy trong ngày
  static Future<int> getTotalCaloriesBurnedForDate(int userId, String date) async {
    try {
      var exercises = await getExercisesByUserAndDate(userId, date);
      int totalCalories = 0;

      for (var exercise in exercises) {
        totalCalories += exercise.totalCaloriesBurned;
      }

      return totalCalories;
    } catch (e) {
      print('❌ Lỗi khi tính tổng calories burned: $e');
      return 0;
    }
  }

  // Tính calories cho bài tập
  static int calculateCaloriesBurned(int caloriesPerSet, int sets) {
    return caloriesPerSet * sets;
  }

  // Cập nhật bài tập hàng ngày
  static Future<bool> updateExerciseDaily(ObjectId id, ExerciseDaily exerciseDaily) async {
    try {
      var collection = _exerciseDailyCollection;
      if (collection == null) return false;

      var result = await collection.updateOne(
        where.id(id),
        modify.set('sets', exerciseDaily.sets)
              .set('reps_per_set', exerciseDaily.repsPerSet)
              .set('duration_minutes', exerciseDaily.durationMinutes)
              .set('total_calories_burned', exerciseDaily.totalCaloriesBurned),
      );

      return result.nModified > 0;
    } catch (e) {
      print('❌ Lỗi khi cập nhật exercise daily: $e');
      return false;
    }
  }

  // Xóa bài tập hàng ngày
  static Future<bool> deleteExerciseDaily(ObjectId id) async {
    try {
      var collection = _exerciseDailyCollection;
      if (collection == null) return false;

      var result = await collection.deleteOne(where.id(id));
      return result.nRemoved > 0;
    } catch (e) {
      print('❌ Lỗi khi xóa exercise daily: $e');
      return false;
    }
  }

  // Thêm bài tập mới vào catalog (admin function)
  static Future<bool> addExerciseToCatalog(Exercise exercise) async {
    try {
      var collection = _exercisesCatalogCollection;
      if (collection == null) return false;

      var result = await collection.insertOne(exercise.toMap());
      print('✅ Thêm exercise vào catalog thành công: ${result.id}');
      return true;
    } catch (e) {
      print('❌ Lỗi khi thêm exercise vào catalog: $e');
      return false;
    }
  }
}
