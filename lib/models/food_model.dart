import 'package:mongo_dart/mongo_dart.dart';
import '../service/health_diary_service.dart';

class Food {
  ObjectId? id;
  int bmiId;
  String foodName;
  String mealType;
  double servingSize;  // Changed to double for precision
  String servingUnit;
  double calories;     // Changed to double for precision
  double protein;      // Changed to double for precision
  double fat;          // Changed to double for precision
  double fiber;        // Changed to double for precision
  double carbs;        // Changed to double for precision
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
      servingSize: (map['serving_size'] ?? 0).toDouble(),
      servingUnit: map['serving_unit'] ?? 'g',
      calories: (map['calories'] ?? 0).toDouble(),
      protein: (map['protein'] ?? 0).toDouble(),
      fat: (map['fat'] ?? 0).toDouble(),
      fiber: (map['fiber'] ?? 0).toDouble(),
      carbs: (map['carbs'] ?? 0).toDouble(),
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

  // Helper methods
  String get mealTypeDisplayName {
    switch (mealType) {
      case 'Sáng':
        return 'Bữa sáng';
      case 'Trưa':
        return 'Bữa trưa';
      case 'Tối':
        return 'Bữa tối';
      case 'Phụ':
        return 'Bữa phụ';
      default:
        return mealType;
    }
  }
  String get bmiCategoryDisplayName {
    switch (bmiId) {
      case 1:
        return 'Thiếu cân';
      case 2:
        return 'Bình thường';
      case 3:
        return 'Thừa cân';
      case 4:
        return 'Béo phì';
      default:
        return 'Tất cả';
    }
  }
  Future<bool> isSuitableForBMI(double bmi) async {
    int bmCategory = await getBMICategoryFromValue(bmi);
    return bmiId == bmCategory || bmiId == 0; // 0 = suitable for all
  }

  static Future<int> getBMICategoryFromValue(double bmi) async {
    try {
      final bmiCatalogs = await HealthDiaryService.getBMICatalog();
      for (final catalog in bmiCatalogs) {
        if (catalog.isInRange(bmi)) {
          return catalog.bmiId;
        }
      }
      // Fallback to hardcoded values if BMI catalog is not available
      if (bmi < 18.5) return 1; // Thiếu cân
      if (bmi < 25) return 2;   // Bình thường  
      if (bmi < 30) return 3;   // Thừa cân
      return 4;                 // Béo phì
    } catch (e) {
      print('Error getting BMI category from value: $e');
      // Fallback to hardcoded values
      if (bmi < 18.5) return 1; // Thiếu cân
      if (bmi < 25) return 2;   // Bình thường
      if (bmi < 30) return 3;   // Thừa cân
      return 4;                 // Béo phì
    }
  }

  static Future<String> getBMICategoryName(double bmi) async {
    try {
      final bmiCatalogs = await HealthDiaryService.getBMICatalog();
      for (final catalog in bmiCatalogs) {
        if (catalog.isInRange(bmi)) {
          return catalog.label;
        }
      }
      // Fallback to hardcoded labels
      if (bmi < 18.5) return 'Thiếu cân';
      if (bmi < 25) return 'Bình thường';
      if (bmi < 30) return 'Thừa cân';
      return 'Béo phì';
    } catch (e) {
      print('Error getting BMI category name: $e');
      // Fallback to hardcoded labels
      if (bmi < 18.5) return 'Thiếu cân';
      if (bmi < 25) return 'Bình thường';
      if (bmi < 30) return 'Thừa cân';
      return 'Béo phì';
    }
  }

  Food copyWith({
    ObjectId? id,
    int? bmiId,
    String? foodName,
    String? mealType,
    double? servingSize,
    String? servingUnit,
    double? calories,
    double? protein,
    double? fat,
    double? fiber,
    double? carbs,
    String? image,
  }) {
    return Food(
      id: id ?? this.id,
      bmiId: bmiId ?? this.bmiId,
      foodName: foodName ?? this.foodName,
      mealType: mealType ?? this.mealType,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      carbs: carbs ?? this.carbs,
      image: image ?? this.image,
    );
  }

  // Calculate nutrition per 100g for comparison
  double get caloriesPer100g => (calories / servingSize) * 100;
  double get proteinPer100g => (protein / servingSize) * 100;
  double get fatPer100g => (fat / servingSize) * 100;
  double get fiberPer100g => (fiber / servingSize) * 100;
  double get carbsPer100g => (carbs / servingSize) * 100;
  
  // Helper method để tính tuổi từ birthDate
  static int calculateAge(String birthDate) {
    try {
      // birthDate format: "dd/MM/yyyy"
      final parts = birthDate.split('/');
      if (parts.length != 3) return 25; // default age
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      final birth = DateTime(year, month, day);
      final now = DateTime.now();
      
      int age = now.year - birth.year;
      if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      
      return age;
    } catch (e) {
      print('❌ Lỗi tính tuổi: $e');
      return 25; // default age
    }
  }
}