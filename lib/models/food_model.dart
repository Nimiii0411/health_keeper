import 'package:mongo_dart/mongo_dart.dart';

class Food {
  ObjectId? id;
  int bmiId;
  String foodName;
  String mealType;
  int servingSize;
  String servingUnit;
  int calories;
  int protein;
  int fat;
  int fiber;
  int carbs;
  String? image;

  Food({
    this.id,
    required this.bmiId,
    required this.foodName,
    required this.mealType,
    required this.servingSize,
    required this.servingUnit,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.fiber,
    required this.carbs,
    this.image,
  });

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      id: map['_id'],
      bmiId: map['bmi_id'],
      foodName: map['food_name'],
      mealType: map['meal_type'],
      servingSize: map['serving_size'],
      servingUnit: map['serving_unit'],
      calories: map['calories'],
      protein: map['protein'],
      fat: map['fat'],
      fiber: map['fiber'],
      carbs: map['carbs'],
      image: map['image'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bmi_id': bmiId,
      'food_name': foodName,
      'meal_type': mealType,
      'serving_size': servingSize,
      'serving_unit': servingUnit,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'fiber': fiber,
      'carbs': carbs,
      'image': image,
    };
  }
}

class MealDaily {
  ObjectId? id;
  int userId;
  String entryDate;
  String mealType;
  ObjectId foodId;
  double serving;

  MealDaily({
    this.id,
    required this.userId,
    required this.entryDate,
    required this.mealType,
    required this.foodId,
    required this.serving,
  });

  factory MealDaily.fromMap(Map<String, dynamic> map) {
    return MealDaily(
      id: map['_id'],
      userId: map['user_id'],
      entryDate: map['entry_date'],
      mealType: map['meal_type'],
      foodId: map['food_id'],
      serving: map['serving'].toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'entry_date': entryDate,
      'meal_type': mealType,
      'food_id': foodId,
      'serving': serving,
    };
  }
}
