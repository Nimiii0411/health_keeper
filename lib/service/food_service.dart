import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../database/mongodb_service.dart';
import '../models/food_model.dart';

class MealDaily {
  mongo.ObjectId? id;
  int userId;
  String entryDate;
  mongo.ObjectId foodId;
  String mealType;
  double serving;
  int totalCalories;

  MealDaily({
    this.id,
    required this.userId,
    required this.entryDate,
    required this.foodId,
    required this.mealType,
    required this.serving,
    required this.totalCalories,
  });

  factory MealDaily.fromMap(Map<String, dynamic> map) {
    return MealDaily(
      id: map['_id'] as mongo.ObjectId?,
      userId: map['user_id'] ?? 0,
      entryDate: map['entry_date'] ?? '',
      foodId: map['food_id'] as mongo.ObjectId,
      mealType: map['meal_type'] ?? '',
      serving: (map['serving'] ?? 0).toDouble(),
      totalCalories: map['total_calories'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'entry_date': entryDate,
      'food_id': foodId,
      'meal_type': mealType,
      'serving': serving,
      'total_calories': totalCalories,
    };
  }
}

class FoodService {
  static const String _foodsCatalogCollectionName = 'foods_catalog';
  static const String _mealDailyCollectionName = 'meal_daily';

  static mongo.DbCollection? get _foodsCatalogCollection =>
      DatabaseConnection.getCollection(_foodsCatalogCollectionName);
  
  static mongo.DbCollection? get _mealDailyCollection =>
      DatabaseConnection.getCollection(_mealDailyCollectionName);

  // Lấy danh sách thức ăn theo BMI và loại bữa ăn
  static Future<List<Food>> getFoodsByBMIAndMealType(int bmiId, String mealType) async {
    try {
      var collection = _foodsCatalogCollection;
      if (collection == null) {
        print('❌ Collection foods_catalog không tồn tại');
        return [];
      }

      var results = await collection
          .find({'bmi_id': bmiId, 'meal_type': mealType})
          .toList();

      return results.map((doc) => Food.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy foods theo BMI và meal type: $e');
      return [];
    }
  }

  // Lấy tất cả thức ăn theo BMI
  static Future<List<Food>> getFoodsByBMI(int bmiId) async {
    try {
      var collection = _foodsCatalogCollection;
      if (collection == null) {
        print('❌ Collection foods_catalog không tồn tại');
        return [];
      }

      var results = await collection
          .find({'bmi_id': bmiId})
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
      // Thử nhiều tên collection khả thi
      List<String> possibleCollectionNames = [
        'foods',
        'foods_catalog',
        'food',
        'Food'
      ];

      mongo.DbCollection? collection;
      
      for (String collectionName in possibleCollectionNames) {
        collection = DatabaseConnection.getCollection(collectionName);
        if (collection != null) {
          try {
            var count = await collection.count();
            if (count >= 0) {
              print('✅ Sử dụng collection: $collectionName');
              break;
            }
          } catch (e) {
            print('❌ Lỗi kiểm tra collection $collectionName: $e');
            continue;
          }
        }
      }

      if (collection == null) {
        print('❌ Không tìm thấy collection foods');
        return [];
      }

      var results = await collection.find().toList();
      print('📋 Lấy được ${results.length} foods');
      
      return results.map((doc) => Food.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy tất cả foods: $e');
      return [];
    }
  }

  // Tìm kiếm thức ăn theo tên
  static Future<List<Food>> searchFoodsByName(String searchTerm) async {
    try {
      var collection = _foodsCatalogCollection ?? DatabaseConnection.getCollection('foods');
      if (collection == null) return [];

      // Sử dụng regex để tìm kiếm không phân biệt hoa thường
      var results = await collection
          .find({
            'food_name': {
              '\$regex': searchTerm,
              '\$options': 'i'
            }
          })
          .toList();

      return results.map((doc) => Food.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi tìm kiếm foods: $e');
      return [];
    }
  }

  // Thêm thực phẩm mới
  static Future<bool> addFood(Food food) async {
    try {
      var collection = DatabaseConnection.getCollection('foods');
      if (collection == null) return false;

      var result = await collection.insertOne(food.toMap());
      print('✅ Thêm food thành công: ${result.id}');
      return true;
    } catch (e) {
      print('❌ Lỗi khi thêm food: $e');
      return false;
    }
  }

  // Cập nhật thực phẩm
  static Future<bool> updateFood(mongo.ObjectId id, Food food) async {
    try {
      var collection = DatabaseConnection.getCollection('foods');
      if (collection == null) return false;

      var result = await collection.updateOne(
        {'_id': id},
        {'\$set': food.toMap()}
      );
      print('✅ Cập nhật food thành công');
      return result.isSuccess;
    } catch (e) {
      print('❌ Lỗi khi cập nhật food: $e');
      return false;
    }
  }

  // Xóa thực phẩm
  static Future<bool> deleteFood(mongo.ObjectId id) async {
    try {
      var collection = DatabaseConnection.getCollection('foods');
      if (collection == null) return false;

      var result = await collection.deleteOne({'_id': id});
      print('✅ Xóa food thành công');
      return result.isSuccess;
    } catch (e) {
      print('❌ Lỗi khi xóa food: $e');
      return false;
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
          .find({'user_id': userId, 'entry_date': date})
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
          .find({
            'user_id': userId,
            'entry_date': date,
            'meal_type': mealType
          })
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
  static Future<Food?> getFoodById(mongo.ObjectId foodId) async {
    try {
      var collection = _foodsCatalogCollection ?? DatabaseConnection.getCollection('foods');
      if (collection == null) return null;

      var result = await collection.findOne({'_id': foodId});
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
  static Future<bool> deleteMealDaily(mongo.ObjectId id) async {
    try {
      var collection = _mealDailyCollection;
      if (collection == null) return false;

      var result = await collection.deleteOne({'_id': id});
      return result.isSuccess;
    } catch (e) {
      print('❌ Lỗi khi xóa meal daily: $e');
      return false;
    }
  }

  // Lấy danh sách foods theo nhiều BMI IDs
  static Future<List<Food>> getFoodsByMultipleBMI(List<int> bmiIds) async {
    try {
      var collection = _foodsCatalogCollection ?? DatabaseConnection.getCollection('foods');
      if (collection == null) return [];

      var results = await collection
          .find({'bmi_id': {'\$in': bmiIds}})
          .toList();

      return results.map((doc) => Food.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy foods theo multiple BMI: $e');
      return [];
    }
  }

  // Debug: Liệt kê tất cả collections
  static Future<void> listAllCollections() async {
    try {
      if (!DatabaseConnection.isConnected || DatabaseConnection.database == null) {
        print('❌ Database chưa kết nối');
        return;
      }

      // var collections = await DatabaseConnection.database!.listCollections();
      // print('📋 Danh sách collections:');
      // // for (var collection in collections) {
      // //   print('  - ${collection['name']}');
      // // }
    } catch (e) {
      print('❌ Lỗi khi list collections: $e');
    }
  }
}