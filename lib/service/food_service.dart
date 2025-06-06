import 'package:mongo_dart/mongo_dart.dart';
import '../database/mongodb_service.dart';
import '../models/food_model.dart';

class FoodService {
  static const String _foodsCatalogCollectionName = 'foods_catalog';
  static const String _mealDailyCollectionName = 'meal_daily';

  static DbCollection? get _foodsCatalogCollection =>
      DatabaseConnection.getCollection(_foodsCatalogCollectionName);
  
  static DbCollection? get _mealDailyCollection =>
      DatabaseConnection.getCollection(_mealDailyCollectionName);

  // Lấy danh sách thức ăn theo BMI và loại bữa ăn
  static Future<List<Food>> getFoodsByBMIAndMealType(int bmiId, String mealType) async {
    try {
      var collection = _foodsCatalogCollection;
      if (collection == null) return [];

      var results = await collection
          .find(where.eq('bmi_id', bmiId).eq('meal_type', mealType))
          .toList();

      return results.map((doc) => Food.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy foods: $e');
      return [];
    }
  }

  // Lấy tất cả thức ăn theo BMI
  static Future<List<Food>> getFoodsByBMI(int bmiId) async {
    try {
      var collection = _foodsCatalogCollection;
      if (collection == null) return [];

      var results = await collection
          .find(where.eq('bmi_id', bmiId))
          .toList();

      return results.map((doc) => Food.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy foods theo BMI: $e');
      return [];
    }
  }

  // Lấy tất cả thức ăn
  static Future<List<Food>> getAllFoods() async {
    try {
      var collection = _foodsCatalogCollection;
      if (collection == null) return [];

      var results = await collection.find().toList();
      return results.map((doc) => Food.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy tất cả foods: $e');
      return [];
    }
  }

  // Tìm kiếm thức ăn theo tên
  static Future<List<Food>> searchFoodsByName(String searchTerm) async {
    try {
      var collection = _foodsCatalogCollection;
      if (collection == null) return [];

      var results = await collection
          .find(where.match('food_name', searchTerm))
          .toList();

      return results.map((doc) => Food.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi tìm kiếm foods: $e');
      return [];
    }
  }

  // Thêm bữa ăn hàng ngày
  static Future<bool> addMealDaily(MealDaily meal) async {
    try {
      var collection = _mealDailyCollection;
      if (collection == null) return false;

      var result = await collection.insertOne(meal.toMap());
      print('✅ Thêm meal daily thành công: ${result.id}');
      return true;
    } catch (e) {
      print('❌ Lỗi khi thêm meal daily: $e');
      return false;
    }
  }

  // Lấy bữa ăn theo user và ngày
  static Future<List<MealDaily>> getMealsByUserAndDate(int userId, String date) async {
    try {
      var collection = _mealDailyCollection;
      if (collection == null) return [];

      var results = await collection
          .find(where.eq('user_id', userId).eq('entry_date', date))
          .toList();

      return results.map((doc) => MealDaily.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy meals theo user và ngày: $e');
      return [];
    }
  }

  // Lấy bữa ăn theo loại trong ngày
  static Future<List<MealDaily>> getMealsByUserDateAndType(
      int userId, String date, String mealType) async {
    try {
      var collection = _mealDailyCollection;
      if (collection == null) return [];

      var results = await collection
          .find(where.eq('user_id', userId)
                     .eq('entry_date', date)
                     .eq('meal_type', mealType))
          .toList();

      return results.map((doc) => MealDaily.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy meals theo type: $e');
      return [];
    }
  }

  // Tính tổng calories trong ngày
  static Future<int> getTotalCaloriesForDate(int userId, String date) async {
    try {
      var meals = await getMealsByUserAndDate(userId, date);
      int totalCalories = 0;

      for (var meal in meals) {
        // Lấy thông tin food từ catalog
        var food = await getFoodById(meal.foodId);
        if (food != null) {
          // Tính calories theo serving
          double caloriesPerGram = food.calories / food.servingSize;
          totalCalories += (caloriesPerGram * meal.serving).round();
        }
      }

      return totalCalories;
    } catch (e) {
      print('❌ Lỗi khi tính tổng calories: $e');
      return 0;
    }
  }

  // Lấy thông tin food theo ID
  static Future<Food?> getFoodById(ObjectId foodId) async {
    try {
      var collection = _foodsCatalogCollection;
      if (collection == null) return null;

      var result = await collection.findOne(where.id(foodId));
      if (result != null) {
        return Food.fromMap(result);
      }
      return null;
    } catch (e) {
      print('❌ Lỗi khi lấy food theo ID: $e');
      return null;
    }
  }

  // Xóa meal daily
  static Future<bool> deleteMealDaily(ObjectId id) async {
    try {
      var collection = _mealDailyCollection;
      if (collection == null) return false;

      var result = await collection.deleteOne(where.id(id));
      return result.isSuccess;
    } catch (e) {
      print('❌ Lỗi khi xóa meal daily: $e');
      return false;
    }
  }
}
