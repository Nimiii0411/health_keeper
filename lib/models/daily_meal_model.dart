import 'package:mongo_dart/mongo_dart.dart';
import 'food_model.dart';

class DailyMeal {
  final ObjectId? id;
  final int userId;  // Changed from ObjectId to int
  final String date; // Format: "dd/MM/yyyy"
  final List<MealItem> breakfast;
  final List<MealItem> lunch;
  final List<MealItem> dinner;
  final List<MealItem> snacks;
  final double totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalFiber;
  final double totalCarbs;
  final String mealPlanType; // "auto", "custom", "recommended"
  final bool isCompleted;
  final List<String> completedMeals; // ["breakfast", "lunch", "dinner", "snacks"]
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyMeal({
    this.id,
    required this.userId,
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snacks,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalFiber,
    required this.totalCarbs,
    required this.mealPlanType,
    this.isCompleted = false,
    this.completedMeals = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });  factory DailyMeal.fromJson(Map<String, dynamic> json) {
    // Convert user_id từ ObjectId hoặc int sang int
    int parsedUserId;
    final userIdField = json['user_id'];
    
    if (userIdField is ObjectId) {
      // Lấy hex string và convert phần cuối thành int
      final hexString = userIdField.toHexString();
      // Lấy 6 ký tự cuối của hex string
      final lastPart = hexString.substring(hexString.length - 6);
      parsedUserId = int.parse(lastPart, radix: 16);
    } else if (userIdField is int) {
      parsedUserId = userIdField;
    } else {
      // Fallback: try to parse as string or default to 0
      parsedUserId = int.tryParse(userIdField.toString()) ?? 0;
    }
    
    return DailyMeal(
      id: json['_id'] as ObjectId?,
      userId: parsedUserId,
      date: json['date'] ?? '',
      breakfast: (json['breakfast'] as List<dynamic>?)
          ?.map((item) => MealItem.fromJson(item))
          .toList() ?? [],
      lunch: (json['lunch'] as List<dynamic>?)
          ?.map((item) => MealItem.fromJson(item))
          .toList() ?? [],
      dinner: (json['dinner'] as List<dynamic>?)
          ?.map((item) => MealItem.fromJson(item))
          .toList() ?? [],
      snacks: (json['snacks'] as List<dynamic>?)
          ?.map((item) => MealItem.fromJson(item))
          .toList() ?? [],
      totalCalories: (json['total_calories'] ?? 0).toDouble(),
      totalProtein: (json['total_protein'] ?? 0).toDouble(),
      totalFat: (json['total_fat'] ?? 0).toDouble(),
      totalFiber: (json['total_fiber'] ?? 0).toDouble(),
      totalCarbs: (json['total_carbs'] ?? 0).toDouble(),
      mealPlanType: json['meal_plan_type'] ?? 'custom',
      isCompleted: json['is_completed'] ?? false,
      completedMeals: List<String>.from(json['completed_meals'] ?? []),
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'user_id': userId,
      'date': date,
      'breakfast': breakfast.map((item) => item.toJson()).toList(),
      'lunch': lunch.map((item) => item.toJson()).toList(),
      'dinner': dinner.map((item) => item.toJson()).toList(),
      'snacks': snacks.map((item) => item.toJson()).toList(),
      'total_calories': totalCalories,
      'total_protein': totalProtein,
      'total_fat': totalFat,
      'total_fiber': totalFiber,
      'total_carbs': totalCarbs,
      'meal_plan_type': mealPlanType,
      'is_completed': isCompleted,
      'completed_meals': completedMeals,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get mealPlanTypeDisplayName {
    switch (mealPlanType) {
      case 'auto':
        return 'Tự động tạo';
      case 'custom':
        return 'Tùy chỉnh';
      case 'recommended':
        return 'Gợi ý';
      default:
        return mealPlanType;
    }
  }
  double get completionPercentage {
    if (completedMeals.isEmpty) return 0.0;
    return (completedMeals.length / 3.0) * 100; // 3 meals: breakfast, lunch, dinner (NO SNACKS)
  }
  // Calculate total nutrition from all meals (NO SNACKS)
  static DailyMeal calculateTotals(DailyMeal meal) {
    List<MealItem> allItems = [...meal.breakfast, ...meal.lunch, ...meal.dinner];
    
    double totalCal = allItems.fold(0, (sum, item) => sum + item.totalCalories);
    double totalProt = allItems.fold(0, (sum, item) => sum + item.totalProtein);
    double totalFat = allItems.fold(0, (sum, item) => sum + item.totalFat);
    double totalFiber = allItems.fold(0, (sum, item) => sum + item.totalFiber);
    double totalCarbs = allItems.fold(0, (sum, item) => sum + item.totalCarbs);

    return meal.copyWith(
      totalCalories: totalCal,
      totalProtein: totalProt,
      totalFat: totalFat,
      totalFiber: totalFiber,
      totalCarbs: totalCarbs,
    );
  }
  DailyMeal copyWith({
    ObjectId? id,
    int? userId,  // Changed from ObjectId to int
    String? date,
    List<MealItem>? breakfast,
    List<MealItem>? lunch,
    List<MealItem>? dinner,
    List<MealItem>? snacks,
    double? totalCalories,
    double? totalProtein,
    double? totalFat,
    double? totalFiber,
    double? totalCarbs,
    String? mealPlanType,
    bool? isCompleted,
    List<String>? completedMeals,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyMeal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
      snacks: snacks ?? this.snacks,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalFat: totalFat ?? this.totalFat,
      totalFiber: totalFiber ?? this.totalFiber,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      mealPlanType: mealPlanType ?? this.mealPlanType,
      isCompleted: isCompleted ?? this.isCompleted,
      completedMeals: completedMeals ?? this.completedMeals,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MealItem {
  final ObjectId foodId;
  final String foodName;
  final String mealType;
  final double quantity;
  final String unit;
  final double totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalFiber;
  final double totalCarbs;

  MealItem({
    required this.foodId,
    required this.foodName,
    required this.mealType,
    required this.quantity,
    required this.unit,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalFiber,
    required this.totalCarbs,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      foodId: json['food_id'] as ObjectId,
      foodName: json['food_name'] ?? '',
      mealType: json['meal_type'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'g',
      totalCalories: (json['total_calories'] ?? 0).toDouble(),
      totalProtein: (json['total_protein'] ?? 0).toDouble(),
      totalFat: (json['total_fat'] ?? 0).toDouble(),
      totalFiber: (json['total_fiber'] ?? 0).toDouble(),
      totalCarbs: (json['total_carbs'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_id': foodId,
      'food_name': foodName,
      'meal_type': mealType,
      'quantity': quantity,
      'unit': unit,
      'total_calories': totalCalories,
      'total_protein': totalProtein,
      'total_fat': totalFat,
      'total_fiber': totalFiber,
      'total_carbs': totalCarbs,
    };
  }
  factory MealItem.fromFood(Food food, double multiplier) {
    return MealItem(
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
  }

  MealItem copyWith({
    ObjectId? foodId,
    String? foodName,
    String? mealType,
    double? quantity,
    String? unit,
    double? totalCalories,
    double? totalProtein,
    double? totalFat,
    double? totalFiber,
    double? totalCarbs,
  }) {
    return MealItem(
      foodId: foodId ?? this.foodId,
      foodName: foodName ?? this.foodName,
      mealType: mealType ?? this.mealType,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalFat: totalFat ?? this.totalFat,
      totalFiber: totalFiber ?? this.totalFiber,
      totalCarbs: totalCarbs ?? this.totalCarbs,
    );
  }
}
