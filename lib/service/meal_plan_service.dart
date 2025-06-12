import 'package:mongo_dart/mongo_dart.dart';
import '../database/mongodb_service.dart';
import '../models/food_model.dart';
import '../models/daily_meal_model.dart';
import '../models/nutritional_needs_model.dart';
import '../service/health_diary_service.dart';
import '../service/user_service.dart';

class MealPlanService {
  static const String foodCatalogCollection = 'foods_catalog';
  static const String dailyMealsCollection = 'daily_meals';

  // Tính nhu cầu dinh dưỡng hàng ngày dựa trên khoa học dinh dưỡng
  static NutritionalNeeds calculateDailyNutritionalNeeds({
    required double weight,      // kg
    required double height,      // cm
    required int age,           // years
    required String gender,     // "Nam" or "Nữ"
    required double bmi,
    String activityLevel = 'moderate', // sedentary, light, moderate, active, very_active
  }) {
    // 1. Tính BMR (Basal Metabolic Rate) sử dụng công thức Mifflin-St Jeor
    double bmr;
    if (gender.toLowerCase() == 'nam' || gender.toLowerCase() == 'male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // 2. Tính TDEE (Total Daily Energy Expenditure) dựa trên mức độ hoạt động
    double activityMultiplier;
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        activityMultiplier = 1.2;   // Ít hoạt động
        break;
      case 'light':
        activityMultiplier = 1.375; // Hoạt động nhẹ 1-3 ngày/tuần
        break;
      case 'moderate':
        activityMultiplier = 1.55;  // Hoạt động vừa 3-5 ngày/tuần
        break;
      case 'active':
        activityMultiplier = 1.725; // Hoạt động nhiều 6-7 ngày/tuần
        break;
      case 'very_active':
        activityMultiplier = 1.9;   // Hoạt động rất nhiều, công việc nặng
        break;
      default:
        activityMultiplier = 1.55;  // Mặc định: moderate
    }

    double tdee = bmr * activityMultiplier;

    // 3. Điều chỉnh calories dựa trên mục tiêu BMI
    double targetCalories = tdee;
    if (bmi < 18.5) {
      // Thiếu cân: tăng 300-500 calories để tăng cân
      targetCalories = tdee + 400;
    } else if (bmi >= 25.0 && bmi < 30.0) {
      // Thừa cân: giảm 300-500 calories để giảm cân
      targetCalories = tdee - 400;
    } else if (bmi >= 30.0) {
      // Béo phì: giảm 500-750 calories để giảm cân
      targetCalories = tdee - 600;
    }
    // BMI bình thường (18.5-24.9): giữ nguyên TDEE

    // 4. Tính toán macro nutrients dựa trên khuyến nghị khoa học
    // Protein: 0.8-2.2g/kg body weight (tùy mức độ hoạt động)
    double proteinGrams;
    if (activityLevel == 'sedentary') {
      proteinGrams = weight * 0.8;
    } else if (activityLevel == 'light') {
      proteinGrams = weight * 1.0;
    } else if (activityLevel == 'moderate') {
      proteinGrams = weight * 1.2;
    } else {
      proteinGrams = weight * 1.6;
    }

    // Fat: 20-35% total calories (khuyến nghị 25-30%)
    double fatPercentage = 0.28; // 28%
    double fatCalories = targetCalories * fatPercentage;
    double fatGrams = fatCalories / 9; // 1g fat = 9 calories

    // Protein calories
    double proteinCalories = proteinGrams * 4; // 1g protein = 4 calories

    // Carbs: phần còn lại của calories
    double carbCalories = targetCalories - proteinCalories - fatCalories;
    double carbGrams = carbCalories / 4; // 1g carb = 4 calories

    // Fiber: 14g per 1000 calories (khuyến nghị của WHO)
    double fiberGrams = (targetCalories / 1000) * 14;

    return NutritionalNeeds(
      calories: targetCalories,
      protein: proteinGrams,
      fat: fatGrams,
      carbs: carbGrams,
      fiber: fiberGrams,
    );
  }

  // Lấy danh sách tên món ăn của ngày hôm qua để đảm bảo đa dạng
  static Future<List<String>> getYesterdayMealFoodNames(int userId, String date) async {
    try {
      final collection = DatabaseConnection.getCollection(dailyMealsCollection);
      if (collection == null) return [];

      final meal = await collection.findOne(
        where.eq('user_id', userId).eq('date', date)
      );
      
      if (meal != null) {
        final List<String> foodNames = [];
          // Collect food names from all meals
        final breakfast = meal['breakfast'] as List? ?? [];
        final lunch = meal['lunch'] as List? ?? [];
        final dinner = meal['dinner'] as List? ?? [];
        
        for (final item in [...breakfast, ...lunch, ...dinner]) {
          if (item['food_name'] != null) {
            foodNames.add(item['food_name'].toString().toLowerCase());
          }
        }
        
        return foodNames;
      }
      
      return [];
    } catch (e) {
      print('❌ Error getting yesterday food names: $e');
      return [];
    }
  }

  // Lấy danh sách foods đã sử dụng gần đây để tránh trùng lặp
  static Future<List<String>> getRecentlyUsedFoodIds(int userId, int daysBefore) async {
    try {
      final collection = DatabaseConnection.getCollection(dailyMealsCollection);
      if (collection == null) return [];      final endDate = DateTime.now();
      
      final List<String> usedFoodIds = [];
      
      for (int i = 0; i < daysBefore; i++) {
        final checkDate = endDate.subtract(Duration(days: i + 1));
        final dateStr = '${checkDate.day.toString().padLeft(2, '0')}/${checkDate.month.toString().padLeft(2, '0')}/${checkDate.year}';
        
        final meal = await collection.findOne(
          where.eq('user_id', userId).eq('date', dateStr)
        );
        
        if (meal != null) {          // Collect food IDs from all meals
          final breakfast = meal['breakfast'] as List? ?? [];
          final lunch = meal['lunch'] as List? ?? [];
          final dinner = meal['dinner'] as List? ?? [];
          
          for (final item in [...breakfast, ...lunch, ...dinner]) {
            if (item['food_id'] != null) {
              usedFoodIds.add(item['food_id'].toString());
            }
          }
        }
      }
      
      return usedFoodIds;
    } catch (e) {
      print('❌ Error getting recently used foods: $e');
      return [];
    }
  }

  // Lấy toàn bộ catalog thực phẩm
  static Future<List<Food>> getAllFoodCatalog() async {
    try {
      final collection = DatabaseConnection.getCollection(foodCatalogCollection);
      if (collection == null) {
        print('Cannot get collection: $foodCatalogCollection');
        return [];
      }
      final List<Map<String, dynamic>> results = await collection.find().toList();
      return results.map((json) => Food.fromMap(json)).toList();
    } catch (e) {
      print('Error getting food catalog: $e');
      return [];
    }
  }

  // Tìm kiếm thực phẩm
  static Future<List<Food>> searchFoods(String searchTerm, {double? bmi}) async {
    try {
      final collection = DatabaseConnection.getCollection(foodCatalogCollection);
      if (collection == null) return [];
      
      var query = where.match('food_name', searchTerm, caseInsensitive: true);
      
      if (bmi != null) {
        final bmiCategory = await Food.getBMICategoryFromValue(bmi);
        query = query.and(where.oneFrom('bmi_id', [0, bmiCategory]));
      }
      
      final List<Map<String, dynamic>> results = await collection.find(query).toList();
      return results.map((json) => Food.fromMap(json)).toList();
    } catch (e) {
      print('Error searching foods: $e');
      return [];
    }
  }

  // Kiểm tra xem ngày đó đã có nhật ký hay chưa
  static Future<bool> hasHealthDiaryForDate(int userId, String date) async {
    try {
      final healthData = await HealthDiaryService.getUserHealthDiary(userId);
      return healthData.any((entry) => entry.entryDate == date);
    } catch (e) {
      print('Error checking health diary for date: $e');
      return false;
    }
  }

  // Tạo thực đơn tự động thông minh dựa trên khoa học dinh dưỡng
  static Future<DailyMeal?> generateAutoMealPlan(int userId, String date) async {
    try {
      // Kiểm tra xem ngày này đã có nhật ký hay chưa
      final hasHealthDiary = await hasHealthDiaryForDate(userId, date);
      if (!hasHealthDiary) {
        print('No health diary found for user $userId on $date');
        return null;
      }

      // Kiểm tra xem đã có meal plan cho ngày này chưa
      final existingMeal = await getDailyMealByUserId(userId, date);
      if (existingMeal != null) {
        print('Meal plan for user $userId on $date already exists');
        return existingMeal;
      }

      // Lấy thông tin user
      final user = await UserService.getUserById(userId);
      if (user == null) {
        print('❌ User not found: $userId');
        return null;
      }

      // Lấy thông tin sức khỏe mới nhất
      final healthData = await HealthDiaryService.getUserHealthDiary(userId);
      if (healthData.isEmpty) {
        print('❌ No health data found for user $userId');
        return null;
      }

      final latestHealth = healthData.first; // Assume sorted by date
      if (latestHealth.bmi == null) {
        print('❌ No BMI data found for user $userId');
        return null;
      }

      final age = Food.calculateAge(user.birthDate);
      print('🔍 Generating intelligent meal plan for user ${user.fullName}');
      print('📊 BMI: ${latestHealth.bmi}, Category: ${latestHealth.bmiLabel}');
      print('👤 Gender: ${user.gender}, Age: $age');

      // Tính nhu cầu dinh dưỡng khoa học
      final nutritionalNeeds = calculateDailyNutritionalNeeds(
        weight: latestHealth.weight,
        height: latestHealth.height,
        age: age,
        gender: user.gender,
        bmi: latestHealth.bmi!,
        activityLevel: 'moderate', // Có thể thêm field này vào user profile
      );

      print('🥗 Daily nutritional needs: $nutritionalNeeds');
      print('🍽️ Meal targets:');      print('   Breakfast: ${nutritionalNeeds.getBreakfastTarget()}');
      print('   Lunch: ${nutritionalNeeds.getLunchTarget()}');
      print('   Dinner: ${nutritionalNeeds.getDinnerTarget()}');

      // Lấy BMI category cho food selection
      final bmiCategoryId = await Food.getBMICategoryFromValue(latestHealth.bmi!);
      
      // Lấy danh sách thực phẩm phù hợp
      final collection = DatabaseConnection.getCollection(foodCatalogCollection);
      if (collection == null) {
        print('❌ Cannot access food catalog');
        return null;
      }      // Lấy thực đơn ngày hôm qua để đảm bảo đa dạng
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      final yesterdayStr = '${yesterday.day.toString().padLeft(2, '0')}/${yesterday.month.toString().padLeft(2, '0')}/${yesterday.year}';
      final yesterdayFoodNames = await getYesterdayMealFoodNames(userId, yesterdayStr);
      print('🔄 Yesterday foods (${yesterdayFoodNames.length}): ${yesterdayFoodNames.take(5).join(', ')}');

      // Lấy foods theo BMI category
      final allFoods = await collection.find(where.eq('bmi_id', bmiCategoryId)).toList();
      if (allFoods.isEmpty) {
        print('❌ No foods found for BMI category $bmiCategoryId');
        return null;
      }      // Nhóm thực phẩm theo meal type (NO SNACKS)
      final breakfastFoods = allFoods.where((f) => f['meal_type'] == 'Sáng').toList();
      final lunchFoods = allFoods.where((f) => f['meal_type'] == 'Trưa').toList();
      final dinnerFoods = allFoods.where((f) => f['meal_type'] == 'Tối').toList();
      
      print('🍽️ Available foods - Breakfast: ${breakfastFoods.length}, Lunch: ${lunchFoods.length}, Dinner: ${dinnerFoods.length}');

      // Tạo meal items thông minh với kiểm soát đa dạng
      final selectedFoodNames = <String>{}; // Track tên món đã chọn trong ngày
      
      final breakfast = _generateOptimalMealItemsWithDiversity(
        breakfastFoods, 
        nutritionalNeeds.getBreakfastTarget(), 
        yesterdayFoodNames,
        selectedFoodNames
      );
      
      final lunch = _generateOptimalMealItemsWithDiversity(
        lunchFoods, 
        nutritionalNeeds.getLunchTarget(), 
        yesterdayFoodNames,
        selectedFoodNames
      );
        final dinner = _generateOptimalMealItemsWithDiversity(
        dinnerFoods, 
        nutritionalNeeds.getDinnerTarget(), 
        yesterdayFoodNames,
        selectedFoodNames
      );
      
      // Tính tổng dinh dưỡng thực tế (NO SNACKS)
      final allMealItems = [...breakfast, ...lunch, ...dinner];
      final actualCalories = allMealItems.fold(0.0, (sum, item) => sum + item.totalCalories);
      final actualProtein = allMealItems.fold(0.0, (sum, item) => sum + item.totalProtein);
      final actualFat = allMealItems.fold(0.0, (sum, item) => sum + item.totalFat);
      final actualFiber = allMealItems.fold(0.0, (sum, item) => sum + item.totalFiber);
      final actualCarbs = allMealItems.fold(0.0, (sum, item) => sum + item.totalCarbs);

      // Kiểm tra diversity requirement: ít nhất 2 món khác với ngày hôm qua
      final todayFoodNames = allMealItems.map((item) => item.foodName.toLowerCase()).toSet();
      final duplicateCount = todayFoodNames.where((name) => yesterdayFoodNames.contains(name)).length;
      final diversityScore = todayFoodNames.length - duplicateCount;
      
      print('✅ Generated intelligent meal plan:');
      print('   Target vs Actual calories: ${nutritionalNeeds.calories.toStringAsFixed(0)} vs ${actualCalories.toStringAsFixed(0)}');
      print('   Target vs Actual protein: ${nutritionalNeeds.protein.toStringAsFixed(1)}g vs ${actualProtein.toStringAsFixed(1)}g');
      print('   Total items: ${allMealItems.length}');
      print('   🔄 Diversity: ${diversityScore}/${todayFoodNames.length} new foods, ${duplicateCount} repeated from yesterday');
      
      if (duplicateCount > (allMealItems.length - 2)) {
        print('⚠️ Warning: Meal plan has too many repeated foods from yesterday (requirement: at least 2 different)');
      } else {
        print('✅ Diversity requirement met: At least 2 foods are different from yesterday');
      }      // Tạo DailyMeal với thực phẩm được tối ưu hóa (NO SNACKS)
      final dailyMeal = DailyMeal(
        userId: userId,
        date: date,
        breakfast: breakfast,
        lunch: lunch,
        dinner: dinner,
        snacks: [], // Empty list for snacks
        totalCalories: actualCalories,
        totalProtein: actualProtein,
        totalFat: actualFat,
        totalFiber: actualFiber,
        totalCarbs: actualCarbs,
        mealPlanType: 'auto',
        isCompleted: false,
        completedMeals: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await saveDailyMeal(dailyMeal);
    } catch (e) {
      print('Error generating auto meal plan: $e');
      return null;
    }
  }
  // Helper method để tạo meal items tối ưu với kiểm soát đa dạng
  static List<MealItem> _generateOptimalMealItemsWithDiversity(
    List<dynamic> availableFoods,
    MealNutritionalTarget target,
    List<String> yesterdayFoodNames,
    Set<String> selectedFoodNames,
  ) {
    if (availableFoods.isEmpty) return [];

    // Filter foods để tránh trùng lặp trong ngày và với ngày hôm qua
    final filteredFoods = availableFoods.where((food) {
      final foodName = food['food_name'].toString().toLowerCase();
      
      // Không chọn món đã có trong ngày hôm nay
      if (selectedFoodNames.contains(foodName)) {
        return false;
      }
      
      // Có thể chọn món đã có hôm qua, nhưng sẽ bị penalty
      return true;
    }).toList();

    if (filteredFoods.isEmpty) {
      print('⚠️ No available foods after filtering duplicates');
      return [];
    }

    // Convert yesterday food names thành penalty list
    final yesterdayPenaltyList = yesterdayFoodNames;

    // Sử dụng thuật toán selection với diversity control
    final selectedFoodData = FoodSelectionAlgorithmWithDiversity.selectOptimalFoodCombination(
      filteredFoods,
      target,
      yesterdayPenaltyList,
    );

    print('🍽️ Selected ${selectedFoodData.length} items for meal target: ${target.calories.toStringAsFixed(0)} cal');

    // Convert sang MealItem và track selected food names
    final mealItems = <MealItem>[];
    for (final foodData in selectedFoodData) {
      final food = Food.fromMap(foodData['food']);
      final multiplier = foodData['multiplier'];
      
      // Track tên món đã chọn trong ngày
      selectedFoodNames.add(food.foodName.toLowerCase());
      
      final mealItem = MealItem(
        foodId: food.id!,
        foodName: food.foodName,
        mealType: food.mealType,
        quantity: food.servingSize * multiplier,
        unit: food.servingUnit,
        totalCalories: food.calories * multiplier,
        totalProtein: food.protein * multiplier,
        totalFat: food.fat * multiplier,
        totalFiber: food.fiber * multiplier,
        totalCarbs: food.carbs * multiplier,
      );
      
      mealItems.add(mealItem);
      print('   📍 ${food.foodName} x${multiplier.toStringAsFixed(1)}: ${(food.calories * multiplier).toStringAsFixed(0)} cal');
    }

    return mealItems;
  }  // Lưu thực đơn hàng ngày (Create or Update)
  static Future<DailyMeal?> saveDailyMeal(DailyMeal dailyMeal) async {
    try {
      final collection = DatabaseConnection.getCollection(dailyMealsCollection);
      if (collection == null) return null;
      
      // Nếu có ID, đây là update operation
      if (dailyMeal.id != null) {
        print('🔄 Updating existing meal plan with ID: ${dailyMeal.id}');
        
        final result = await collection.replaceOne(
          where.eq('_id', dailyMeal.id),
          dailyMeal.toJson(),
        );
        
        if (result.isSuccess) {
          print('✅ Successfully updated meal plan');
          return dailyMeal;
        } else {
          print('❌ Failed to update meal plan');
          return null;
        }
      } else {
        // Nếu không có ID, kiểm tra xem đã có meal plan cho user và date này chưa
        print('🆕 Creating new meal plan or updating existing one');
        
        final existingMeal = await getDailyMealByUserId(dailyMeal.userId, dailyMeal.date);
        
        if (existingMeal != null) {
          // Có meal plan rồi, update nó
          print('🔄 Found existing meal plan, updating...');
          final updatedMeal = dailyMeal.copyWith(id: existingMeal.id);
          return await saveDailyMeal(updatedMeal); // Recursive call với ID
        } else {
          // Chưa có meal plan, tạo mới
          print('🆕 No existing meal plan found, creating new one');
          final result = await collection.insertOne(dailyMeal.toJson());
          if (result.isSuccess && result.document != null) {
            print('✅ Successfully created meal plan with ID: ${result.document!['_id']}');
            return dailyMeal.copyWith(id: result.document!['_id']);
          } else {
            print('❌ Failed to create meal plan');
            return null;
          }
        }
      }
    } catch (e) {
      print('❌ Error saving daily meal: $e');
      return null;
    }
  }

  // Lấy thực đơn theo ngày và user ID (int)
  static Future<DailyMeal?> getDailyMealByUserId(int userId, String date) async {
    try {
      final collection = DatabaseConnection.getCollection(dailyMealsCollection);
      if (collection == null) return null;
      
      // Tìm kiếm với cả hai định dạng: int userId và ObjectId userId
      var result = await collection.findOne(
        where.eq('user_id', userId).eq('date', date)
      );
      
      // Nếu không tìm thấy với int, thử với ObjectId format
      if (result == null) {
        // Convert int userId thành ObjectId format (pad với 0)
        final userObjectId = ObjectId.fromHexString(userId.toString().padLeft(24, '0'));
        result = await collection.findOne(
          where.eq('user_id', userObjectId).eq('date', date)
        );
      }
      
      if (result != null) {
        return DailyMeal.fromJson(result);
      }
      return null;
    } catch (e) {
      print('Error getting daily meal by user ID: $e');
      return null;
    }
  }

  // Đánh dấu bữa ăn đã hoàn thành
  static Future<bool> markMealCompleted(ObjectId mealId, String mealType) async {
    try {
      final collection = DatabaseConnection.getCollection(dailyMealsCollection);
      if (collection == null) return false;
      
      final meal = await collection.findOne(where.eq('_id', mealId));
      if (meal == null) return false;
      
      List<String> completedMeals = List<String>.from(meal['completed_meals'] ?? []);
      if (!completedMeals.contains(mealType)) {
        completedMeals.add(mealType);
      }
      
      final isCompleted = completedMeals.length >= 3; // breakfast, lunch, dinner
      
      final result = await collection.updateOne(
        where.eq('_id', mealId),
        modify.set('completed_meals', completedMeals)
              .set('is_completed', isCompleted)
              .set('updated_at', DateTime.now().toIso8601String()),
      );
      
      return result.isSuccess;
    } catch (e) {
      print('Error marking meal completed: $e');
      return false;
    }
  }
  // Delete meal plan
  static Future<bool> deleteMealPlan(ObjectId mealId) async {
    try {
      final collection = DatabaseConnection.getCollection(dailyMealsCollection);
      if (collection == null) return false;

      final result = await collection.deleteOne(where.eq('_id', mealId));
      return result.isSuccess;
    } catch (e) {
      print('❌ Error deleting meal plan: $e');
      return false;
    }
  }

  // Delete meal plan by user and date
  static Future<bool> deleteMealPlanByUserAndDate(int userId, String date) async {
    try {
      final collection = DatabaseConnection.getCollection(dailyMealsCollection);
      if (collection == null) return false;

      var result = await collection.deleteOne(
        where.eq('user_id', userId).eq('date', date)
      );
      
      // If not found with int, try with ObjectId format
      if (!result.isSuccess) {
        final userObjectId = ObjectId.fromHexString(userId.toString().padLeft(24, '0'));
        result = await collection.deleteOne(
          where.eq('user_id', userObjectId).eq('date', date)
        );
      }

      return result.isSuccess;
    } catch (e) {
      print('❌ Error deleting meal plan by user and date: $e');
      return false;
    }
  }

  // Debug method - kiểm tra dữ liệu meal trong database
  static Future<void> debugDailyMeals(int userId, String date) async {
    try {
      final collection = DatabaseConnection.getCollection(dailyMealsCollection);
      if (collection == null) {
        print('❌ Cannot get collection: $dailyMealsCollection');
        return;
      }
      
      print('🔍 Searching for meals with userId: $userId, date: $date');
      
      // Tìm với int userId
      var allUserMeals = await collection.find(where.eq('user_id', userId)).toList();
      print('📋 Found ${allUserMeals.length} meal plans for user $userId (int format)');
      
      // Nếu không tìm thấy, thử với ObjectId format  
      if (allUserMeals.isEmpty) {
        final userObjectId = ObjectId.fromHexString(userId.toString().padLeft(24, '0'));
        allUserMeals = await collection.find(where.eq('user_id', userObjectId)).toList();
        print('📋 Found ${allUserMeals.length} meal plans for user $userId (ObjectId format)');
      }
      
      for (var meal in allUserMeals) {
        print('📅 Date: ${meal['date']}, Calories: ${meal['total_calories']}, UserId: ${meal['user_id']} (${meal['user_id'].runtimeType})');
      }
      
      // Tìm meal plan cho ngày cụ thể
      var specificMeal = await collection.findOne(
        where.eq('user_id', userId).eq('date', date)
      );
      
      if (specificMeal == null) {
        final userObjectId = ObjectId.fromHexString(userId.toString().padLeft(24, '0'));
        specificMeal = await collection.findOne(
          where.eq('user_id', userObjectId).eq('date', date)
        );
      }
      
      if (specificMeal != null) {
        print('✅ Found meal for date $date');
        print('🍽️ Breakfast items: ${specificMeal['breakfast']?.length ?? 0}');
        print('🍽️ Lunch items: ${specificMeal['lunch']?.length ?? 0}');
        print('🍽️ Dinner items: ${specificMeal['dinner']?.length ?? 0}');
        print('🍽️ Total calories: ${specificMeal['total_calories']}');
        print('👤 User ID in DB: ${specificMeal['user_id']} (${specificMeal['user_id'].runtimeType})');
      } else {
        print('❌ No meal found for date $date');
      }
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  // Helper method để kiểm tra structure database hiện tại
  static Future<void> debugDatabaseStructure() async {
    try {
      final collection = DatabaseConnection.getCollection(dailyMealsCollection);
      if (collection == null) {
        print('❌ Cannot get collection: $dailyMealsCollection');
        return;
      }
      
      // Lấy một document để xem structure
      final sample = await collection.findOne({});
      if (sample != null) {
        print('📊 Database structure:');
        print('   _id: ${sample['_id']} (${sample['_id'].runtimeType})');
        print('   user_id: ${sample['user_id']} (${sample['user_id'].runtimeType})');
        print('   date: ${sample['date']} (${sample['date'].runtimeType})');
        
        // Kiểm tra xem user_id có phải ObjectId không
        if (sample['user_id'] is ObjectId) {
          final objectId = sample['user_id'] as ObjectId;
          print('   user_id as hex: ${objectId.toHexString()}');
          // Có thể convert về int nếu cần
          final userIdAsInt = int.tryParse(objectId.toHexString().substring(18), radix: 16) ?? 0;
          print('   user_id as int: $userIdAsInt');
        }
      } else {
        print('❌ No documents found in collection');
      }
    } catch (e) {
      print('❌ Error checking database structure: $e');
    }
  }

  // Validate diversity requirements cho meal plan
  static ValidationResult validateMealPlanDiversity(
    List<MealItem> todayMealItems,
    List<String> yesterdayFoodNames,
  ) {
    final todayFoodNames = todayMealItems.map((item) => item.foodName.toLowerCase()).toSet();
    
    // Check 1: No duplicate food names within the same day
    final uniqueFoodsToday = todayFoodNames.length;
    final totalFoodsToday = todayMealItems.length;
    
    if (uniqueFoodsToday != totalFoodsToday) {
      return ValidationResult(false, 
        'Same-day duplicate detected: $totalFoodsToday foods but only $uniqueFoodsToday unique names');
    }
    
    // Check 2: At least 2 foods different from yesterday
    final duplicateFromYesterday = todayFoodNames.where((name) => 
      yesterdayFoodNames.contains(name)).length;
    final newFoodsCount = uniqueFoodsToday - duplicateFromYesterday;
    
    if (newFoodsCount < 2 && todayFoodNames.length >= 2) {
      return ValidationResult(false, 
        'Insufficient diversity: Only $newFoodsCount new foods (requirement: at least 2)');
    }
    
    return ValidationResult(true, 
      'Diversity requirements met: $newFoodsCount new foods, $duplicateFromYesterday repeated from yesterday');
  }

  // Debug method để test diversity system
  static Future<void> testDiversitySystem(int userId) async {
    print('\n🧪 TESTING DIVERSITY SYSTEM');
    print('============================');
    
    try {
      // Simulate dates
      final today = DateTime.now();
      final yesterday = today.subtract(Duration(days: 1));
      
      final todayStr = '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';
      final yesterdayStr = '${yesterday.day.toString().padLeft(2, '0')}/${yesterday.month.toString().padLeft(2, '0')}/${yesterday.year}';
      
      print('📅 Testing for user $userId');
      print('   Today: $todayStr');
      print('   Yesterday: $yesterdayStr');
      
      // Get yesterday's foods
      final yesterdayFoods = await getYesterdayMealFoodNames(userId, yesterdayStr);
      print('\n🔄 Yesterday foods (${yesterdayFoods.length}):');
      for (int i = 0; i < yesterdayFoods.length; i++) {
        print('   ${i+1}. ${yesterdayFoods[i]}');
      }
      
      // Generate today's meal plan
      print('\n🍽️ Generating today meal plan...');
      final todayMeal = await generateAutoMealPlan(userId, todayStr);
        if (todayMeal != null) {
        final allTodayItems = [
          ...todayMeal.breakfast,
          ...todayMeal.lunch,
          ...todayMeal.dinner,
          // NO SNACKS
        ];
        
        print('\n📋 Today foods (${allTodayItems.length}):');
        for (int i = 0; i < allTodayItems.length; i++) {
          final item = allTodayItems[i];
          final isRepeated = yesterdayFoods.contains(item.foodName.toLowerCase());
          print('   ${i+1}. ${item.foodName} (${item.mealType}) ${isRepeated ? "🔄 REPEATED" : "🆕 NEW"}');
        }
        
        // Validate diversity
        final validation = validateMealPlanDiversity(allTodayItems, yesterdayFoods);
        print('\n✅ DIVERSITY VALIDATION:');
        print('   Result: ${validation.isValid ? "PASSED" : "FAILED"}');
        print('   Message: ${validation.message}');
          // Analyze by meal type (NO SNACKS)
        print('\n📊 MEAL-BY-MEAL ANALYSIS:');
        _analyzeMealDiversity('Breakfast', todayMeal.breakfast, yesterdayFoods);
        _analyzeMealDiversity('Lunch', todayMeal.lunch, yesterdayFoods);
        _analyzeMealDiversity('Dinner', todayMeal.dinner, yesterdayFoods);
        
      } else {
        print('❌ Failed to generate meal plan');
      }
      
    } catch (e) {
      print('❌ Error testing diversity system: $e');
    }
  }
  
  static void _analyzeMealDiversity(String mealType, List<MealItem> items, List<String> yesterdayFoods) {
    if (items.isEmpty) return;
    
    print('   $mealType (${items.length} items):');
    for (final item in items) {
      final isRepeated = yesterdayFoods.contains(item.foodName.toLowerCase());
      final calories = item.totalCalories.toStringAsFixed(0);
      print('     - ${item.foodName}: ${calories} cal ${isRepeated ? "🔄" : "🆕"}');
    }
  }

  // Get foods by BMI category for custom meal planning
  static Future<List<Food>> getFoodsByBMICategory(int bmiCategoryId) async {
    try {
      final collection = DatabaseConnection.getCollection(foodCatalogCollection);
      if (collection == null) {
        print('❌ Cannot access food catalog');
        return [];
      }

      final results = await collection.find(where.eq('bmi_id', bmiCategoryId)).toList();
      return results.map((doc) => Food.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Error getting foods by BMI category: $e');
      return [];
    }
  }
}

class ValidationResult {
  final bool isValid;
  final String message;

  ValidationResult(this.isValid, this.message);
}
