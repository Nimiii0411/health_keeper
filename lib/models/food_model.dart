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

  // Chuyển từ Map sang Food object - QUAN TRỌNG!
  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      id: map['_id'] as ObjectId?,
      bmiId: map['bmi_id'] ?? 0,
      foodName: map['food_name'] ?? '',
      mealType: map['meal_type'] ?? '',
      servingSize: map['serving_size'] ?? 0,
      servingUnit: map['serving_unit'] ?? '',
      calories: map['calories'] ?? 0,
      protein: map['protein'] ?? 0,
      fat: map['fat'] ?? 0,
      fiber: map['fiber'] ?? 0,
      carbs: map['carbs'] ?? 0,
      image: map['image'],
    );
  }

  // Chuyển từ Food object sang Map
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