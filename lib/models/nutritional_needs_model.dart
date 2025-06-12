// Nutritional needs calculation model based on scientific formulas

class NutritionalNeeds {
  final double calories;
  final double protein;    // grams
  final double fat;        // grams
  final double carbs;      // grams
  final double fiber;      // grams
    // Calories per meal type (percentage of total) - NO SNACKS
  final double breakfastCalories;  // 30%
  final double lunchCalories;      // 40%
  final double dinnerCalories;     // 30%

  NutritionalNeeds({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
  }) : breakfastCalories = calories * 0.30,
       lunchCalories = calories * 0.40,
       dinnerCalories = calories * 0.30;
  // Helper methods để lấy nutritional target cho từng bữa ăn
  MealNutritionalTarget getBreakfastTarget() {
    return MealNutritionalTarget(
      calories: breakfastCalories,
      protein: protein * 0.30,
      fat: fat * 0.30,
      carbs: carbs * 0.30,
      fiber: fiber * 0.30,
    );
  }

  MealNutritionalTarget getLunchTarget() {
    return MealNutritionalTarget(
      calories: lunchCalories,
      protein: protein * 0.40,
      fat: fat * 0.40,
      carbs: carbs * 0.40,
      fiber: fiber * 0.40,
    );
  }

  MealNutritionalTarget getDinnerTarget() {
    return MealNutritionalTarget(
      calories: dinnerCalories,
      protein: protein * 0.30,
      fat: fat * 0.30,
      carbs: carbs * 0.30,
      fiber: fiber * 0.30,
    );
  }

  @override
  String toString() {
    return 'NutritionalNeeds(calories: ${calories.toStringAsFixed(0)}, '
           'protein: ${protein.toStringAsFixed(1)}g, '
           'fat: ${fat.toStringAsFixed(1)}g, '
           'carbs: ${carbs.toStringAsFixed(1)}g, '
           'fiber: ${fiber.toStringAsFixed(1)}g)';
  }
}

class MealNutritionalTarget {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;

  MealNutritionalTarget({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
  });

  @override
  String toString() {
    return 'Target(${calories.toStringAsFixed(0)}cal, ${protein.toStringAsFixed(1)}g protein)';
  }
}

// Food selection algorithms
class FoodSelectionAlgorithm {
  // Tính điểm phù hợp của một món ăn với target dinh dưỡng
  static double calculateFoodScore(
    dynamic food,
    MealNutritionalTarget target,
    double multiplier,
  ) {
    final foodCalories = food['calories'] * multiplier;
    final foodProtein = food['protein'] * multiplier;
    final foodFat = food['fat'] * multiplier;
    final foodCarbs = food['carbs'] * multiplier;
    final foodFiber = food['fiber'] * multiplier;

    // Tính độ lệch so với target (lower is better)
    final calorieDeviation = (foodCalories - target.calories).abs() / target.calories;
    final proteinDeviation = (foodProtein - target.protein).abs() / target.protein;
    final fatDeviation = (foodFat - target.fat).abs() / target.fat;
    final carbDeviation = (foodCarbs - target.carbs).abs() / target.carbs;
    final fiberDeviation = (foodFiber - target.fiber).abs() / target.fiber;

    // Weighted score (calories có trọng số cao nhất)
    final score = (calorieDeviation * 0.4) + 
                  (proteinDeviation * 0.25) +
                  (fatDeviation * 0.15) +
                  (carbDeviation * 0.15) +
                  (fiberDeviation * 0.05);

    return 1.0 / (1.0 + score); // Convert to score (higher is better)
  }
  // Tìm combination tối ưu của foods cho một bữa ăn với số lượng món tự động
  static List<Map<String, dynamic>> selectOptimalFoodCombination(
    List<dynamic> availableFoods,
    MealNutritionalTarget target,
    List<String> recentlyUsedFoodIds,
  ) {
    if (availableFoods.isEmpty) return [];

    // Thử các strategy khác nhau: 1 món, 2 món, 3 món
    final strategies = [
      _tryOneItemStrategy(availableFoods, target, recentlyUsedFoodIds),
      _tryTwoItemStrategy(availableFoods, target, recentlyUsedFoodIds),
      _tryThreeItemStrategy(availableFoods, target, recentlyUsedFoodIds),
    ];

    // Chọn strategy có điểm cao nhất
    Map<String, dynamic>? bestStrategy;
    double bestScore = 0.0;

    for (final strategy in strategies) {
      if (strategy != null && strategy['score'] > bestScore) {
        bestScore = strategy['score'];
        bestStrategy = strategy;
      }
    }

    if (bestStrategy != null) {
      print('🎯 Selected ${bestStrategy['combination'].length}-item strategy with score: ${bestScore.toStringAsFixed(3)}');
      return bestStrategy['combination'];
    }

    return [];
  }

  // Strategy 1: Thử với 1 món đủ dinh dưỡng
  static Map<String, dynamic>? _tryOneItemStrategy(
    List<dynamic> availableFoods,
    MealNutritionalTarget target,
    List<String> recentlyUsedFoodIds,
  ) {
    double bestScore = 0.0;
    Map<String, dynamic>? bestFood;

    for (final food in availableFoods) {
      final foodId = food['_id'].toString();
      double diversityPenalty = recentlyUsedFoodIds.contains(foodId) ? 0.3 : 0.0;

      // Thử các multiplier để tìm best fit
      for (double multiplier = 0.8; multiplier <= 2.5; multiplier += 0.1) {
        final score = calculateFoodScore(food, target, multiplier) - diversityPenalty;
        
        // Bonus cho món có thể đáp ứng được ≥85% nhu cầu dinh dưỡng
        final caloriesCoverage = (food['calories'] * multiplier) / target.calories;
        if (caloriesCoverage >= 0.85 && caloriesCoverage <= 1.15) {
          final adjustedScore = score * 1.2; // Bonus 20% cho single complete meal
          if (adjustedScore > bestScore) {
            bestScore = adjustedScore;
            bestFood = {
              'food': food,
              'multiplier': multiplier,
              'calories': food['calories'] * multiplier,
              'protein': food['protein'] * multiplier,
              'fat': food['fat'] * multiplier,
              'carbs': food['carbs'] * multiplier,
              'fiber': food['fiber'] * multiplier,
            };
          }
        }
      }
    }

    return bestFood != null 
        ? {'combination': [bestFood], 'score': bestScore}
        : null;
  }

  // Strategy 2: Thử với 2 món kết hợp
  static Map<String, dynamic>? _tryTwoItemStrategy(
    List<dynamic> availableFoods,
    MealNutritionalTarget target,
    List<String> recentlyUsedFoodIds,
  ) {
    double bestScore = 0.0;
    List<Map<String, dynamic>>? bestCombination;

    for (int i = 0; i < availableFoods.length; i++) {
      for (int j = i + 1; j < availableFoods.length; j++) {
        final food1 = availableFoods[i];
        final food2 = availableFoods[j];

        // Thử các multiplier combinations
        for (double mult1 = 0.5; mult1 <= 2.0; mult1 += 0.25) {
          for (double mult2 = 0.5; mult2 <= 2.0; mult2 += 0.25) {
            final combination = [
              {
                'food': food1,
                'multiplier': mult1,
                'calories': food1['calories'] * mult1,
                'protein': food1['protein'] * mult1,
                'fat': food1['fat'] * mult1,
                'carbs': food1['carbs'] * mult1,
                'fiber': food1['fiber'] * mult1,
              },
              {
                'food': food2,
                'multiplier': mult2,
                'calories': food2['calories'] * mult2,
                'protein': food2['protein'] * mult2,
                'fat': food2['fat'] * mult2,
                'carbs': food2['carbs'] * mult2,
                'fiber': food2['fiber'] * mult2,
              }
            ];

            final score = _calculateCombinationScore(combination, target, recentlyUsedFoodIds);
            if (score > bestScore) {
              bestScore = score;
              bestCombination = combination;
            }
          }
        }
      }
    }

    return bestCombination != null 
        ? {'combination': bestCombination, 'score': bestScore}
        : null;
  }

  // Strategy 3: Thử với 3 món kết hợp
  static Map<String, dynamic>? _tryThreeItemStrategy(
    List<dynamic> availableFoods,
    MealNutritionalTarget target,
    List<String> recentlyUsedFoodIds,
  ) {
    if (availableFoods.length < 3) return null;

    double bestScore = 0.0;
    List<Map<String, dynamic>>? bestCombination;

    // Giới hạn số combination để tránh quá chậm
    final maxCombinations = 100;
    int combinations = 0;

    for (int i = 0; i < availableFoods.length && combinations < maxCombinations; i++) {
      for (int j = i + 1; j < availableFoods.length && combinations < maxCombinations; j++) {
        for (int k = j + 1; k < availableFoods.length && combinations < maxCombinations; k++) {
          combinations++;
          
          final food1 = availableFoods[i];
          final food2 = availableFoods[j];
          final food3 = availableFoods[k];

          // Thử multiplier đơn giản hơn cho 3 món
          for (double mult1 = 0.5; mult1 <= 1.5; mult1 += 0.5) {
            for (double mult2 = 0.5; mult2 <= 1.5; mult2 += 0.5) {
              for (double mult3 = 0.5; mult3 <= 1.5; mult3 += 0.5) {
                final combination = [
                  {
                    'food': food1,
                    'multiplier': mult1,
                    'calories': food1['calories'] * mult1,
                    'protein': food1['protein'] * mult1,
                    'fat': food1['fat'] * mult1,
                    'carbs': food1['carbs'] * mult1,
                    'fiber': food1['fiber'] * mult1,
                  },
                  {
                    'food': food2,
                    'multiplier': mult2,
                    'calories': food2['calories'] * mult2,
                    'protein': food2['protein'] * mult2,
                    'fat': food2['fat'] * mult2,
                    'carbs': food2['carbs'] * mult2,
                    'fiber': food2['fiber'] * mult2,
                  },
                  {
                    'food': food3,
                    'multiplier': mult3,
                    'calories': food3['calories'] * mult3,
                    'protein': food3['protein'] * mult3,
                    'fat': food3['fat'] * mult3,
                    'carbs': food3['carbs'] * mult3,
                    'fiber': food3['fiber'] * mult3,
                  }
                ];

                final score = _calculateCombinationScore(combination, target, recentlyUsedFoodIds);
                if (score > bestScore) {
                  bestScore = score;
                  bestCombination = combination;
                }
              }
            }
          }
        }
      }
    }

    return bestCombination != null 
        ? {'combination': bestCombination, 'score': bestScore}
        : null;
  }

  // Tính điểm cho một combination
  static double _calculateCombinationScore(
    List<Map<String, dynamic>> combination,
    MealNutritionalTarget target,
    List<String> recentlyUsedFoodIds,
  ) {
    // Tính tổng dinh dưỡng của combination
    double totalCalories = 0, totalProtein = 0, totalFat = 0, totalCarbs = 0, totalFiber = 0;
    double diversityPenalty = 0.0;
    
    for (final item in combination) {
      totalCalories += item['calories'];
      totalProtein += item['protein'];
      totalFat += item['fat'];
      totalCarbs += item['carbs'];
      totalFiber += item['fiber'];

      // Penalty cho recently used foods
      final foodId = item['food']['_id'].toString();
      if (recentlyUsedFoodIds.contains(foodId)) {
        diversityPenalty += 0.15; // 15% penalty per recently used food
      }
    }

    // Tính độ lệch so với target
    final calorieDeviation = (totalCalories - target.calories).abs() / target.calories;
    final proteinDeviation = (totalProtein - target.protein).abs() / target.protein;
    final fatDeviation = (totalFat - target.fat).abs() / target.fat;
    final carbDeviation = (totalCarbs - target.carbs).abs() / target.carbs;
    final fiberDeviation = (totalFiber - target.fiber).abs() / target.fiber;

    // Calculate weighted score
    final nutritionScore = 1.0 / (1.0 + (
      calorieDeviation * 0.4 + 
      proteinDeviation * 0.25 +
      fatDeviation * 0.15 +
      carbDeviation * 0.15 +
      fiberDeviation * 0.05
    ));

    // Bonus cho variety (nhiều món = nhiều dưỡng chất khác nhau)
    final varietyBonus = combination.length > 1 ? 0.1 : 0.0;

    return nutritionScore + varietyBonus - diversityPenalty;
  }
}

// Enhanced algorithm with strict diversity control
class FoodSelectionAlgorithmWithDiversity {
  // Tìm combination tối ưu với kiểm soát đa dạng nghiêm ngặt
  static List<Map<String, dynamic>> selectOptimalFoodCombination(
    List<dynamic> availableFoods,
    MealNutritionalTarget target,
    List<String> yesterdayFoodNames,
  ) {
    if (availableFoods.isEmpty) return [];

    // Thử các strategy khác nhau: 1 món, 2 món, 3 món
    final strategies = [
      _tryOneItemStrategyWithDiversity(availableFoods, target, yesterdayFoodNames),
      _tryTwoItemStrategyWithDiversity(availableFoods, target, yesterdayFoodNames),
      _tryThreeItemStrategyWithDiversity(availableFoods, target, yesterdayFoodNames),
    ];

    // Chọn strategy có điểm cao nhất
    Map<String, dynamic>? bestStrategy;
    double bestScore = 0.0;

    for (final strategy in strategies) {
      if (strategy != null && strategy['score'] > bestScore) {
        bestScore = strategy['score'];
        bestStrategy = strategy;
      }
    }

    if (bestStrategy != null) {
      final combination = bestStrategy['combination'] as List<Map<String, dynamic>>;
      final diversityCount = _countDiversityMatches(combination, yesterdayFoodNames);
      
      print('🎯 Selected ${combination.length}-item strategy with score: ${bestScore.toStringAsFixed(3)}');
      print('🔄 Diversity: ${combination.length - diversityCount}/${combination.length} new foods (${diversityCount} repeated from yesterday)');
      
      return combination;
    }

    return [];
  }

  // Strategy 1: Thử với 1 món với diversity check
  static Map<String, dynamic>? _tryOneItemStrategyWithDiversity(
    List<dynamic> availableFoods,
    MealNutritionalTarget target,
    List<String> yesterdayFoodNames,
  ) {
    double bestScore = 0.0;
    Map<String, dynamic>? bestFood;

    for (final food in availableFoods) {
      final foodName = food['food_name'].toString().toLowerCase();
      
      // Penalty cho món ăn của ngày hôm qua
      double diversityPenalty = yesterdayFoodNames.contains(foodName) ? 0.4 : 0.0;

      // Thử các multiplier để tìm best fit
      for (double multiplier = 0.8; multiplier <= 2.5; multiplier += 0.1) {
        final nutritionScore = FoodSelectionAlgorithm.calculateFoodScore(food, target, multiplier);
        
        // Bonus cho món có thể đáp ứng được ≥85% nhu cầu dinh dưỡng
        final caloriesCoverage = (food['calories'] * multiplier) / target.calories;
        if (caloriesCoverage >= 0.85 && caloriesCoverage <= 1.15) {
          final adjustedScore = (nutritionScore * 1.2) - diversityPenalty; // Bonus 20% nhưng trừ penalty
          if (adjustedScore > bestScore) {
            bestScore = adjustedScore;
            bestFood = {
              'food': food,
              'multiplier': multiplier,
              'calories': food['calories'] * multiplier,
              'protein': food['protein'] * multiplier,
              'fat': food['fat'] * multiplier,
              'carbs': food['carbs'] * multiplier,
              'fiber': food['fiber'] * multiplier,
            };
          }
        }
      }
    }

    return bestFood != null 
        ? {'combination': [bestFood], 'score': bestScore}
        : null;
  }

  // Strategy 2: Thử với 2 món với diversity check
  static Map<String, dynamic>? _tryTwoItemStrategyWithDiversity(
    List<dynamic> availableFoods,
    MealNutritionalTarget target,
    List<String> yesterdayFoodNames,
  ) {
    double bestScore = 0.0;
    List<Map<String, dynamic>>? bestCombination;

    for (int i = 0; i < availableFoods.length; i++) {
      for (int j = i + 1; j < availableFoods.length; j++) {
        final food1 = availableFoods[i];
        final food2 = availableFoods[j];

        // Thử các multiplier combinations
        for (double mult1 = 0.5; mult1 <= 2.0; mult1 += 0.25) {
          for (double mult2 = 0.5; mult2 <= 2.0; mult2 += 0.25) {
            final combination = [
              {
                'food': food1,
                'multiplier': mult1,
                'calories': food1['calories'] * mult1,
                'protein': food1['protein'] * mult1,
                'fat': food1['fat'] * mult1,
                'carbs': food1['carbs'] * mult1,
                'fiber': food1['fiber'] * mult1,
              },
              {
                'food': food2,
                'multiplier': mult2,
                'calories': food2['calories'] * mult2,
                'protein': food2['protein'] * mult2,
                'fat': food2['fat'] * mult2,
                'carbs': food2['carbs'] * mult2,
                'fiber': food2['fiber'] * mult2,
              }
            ];

            final score = _calculateCombinationScoreWithDiversity(combination, target, yesterdayFoodNames);
            if (score > bestScore) {
              bestScore = score;
              bestCombination = combination;
            }
          }
        }
      }
    }

    return bestCombination != null 
        ? {'combination': bestCombination, 'score': bestScore}
        : null;
  }

  // Strategy 3: Thử với 3 món với diversity check
  static Map<String, dynamic>? _tryThreeItemStrategyWithDiversity(
    List<dynamic> availableFoods,
    MealNutritionalTarget target,
    List<String> yesterdayFoodNames,
  ) {
    if (availableFoods.length < 3) return null;

    double bestScore = 0.0;
    List<Map<String, dynamic>>? bestCombination;

    // Giới hạn số combination để tránh quá chậm
    final maxCombinations = 100;
    int combinations = 0;

    for (int i = 0; i < availableFoods.length && combinations < maxCombinations; i++) {
      for (int j = i + 1; j < availableFoods.length && combinations < maxCombinations; j++) {
        for (int k = j + 1; k < availableFoods.length && combinations < maxCombinations; k++) {
          combinations++;
          
          final food1 = availableFoods[i];
          final food2 = availableFoods[j];
          final food3 = availableFoods[k];

          // Thử multiplier đơn giản hơn cho 3 món
          for (double mult1 = 0.5; mult1 <= 1.5; mult1 += 0.5) {
            for (double mult2 = 0.5; mult2 <= 1.5; mult2 += 0.5) {
              for (double mult3 = 0.5; mult3 <= 1.5; mult3 += 0.5) {
                final combination = [
                  {
                    'food': food1,
                    'multiplier': mult1,
                    'calories': food1['calories'] * mult1,
                    'protein': food1['protein'] * mult1,
                    'fat': food1['fat'] * mult1,
                    'carbs': food1['carbs'] * mult1,
                    'fiber': food1['fiber'] * mult1,
                  },
                  {
                    'food': food2,
                    'multiplier': mult2,
                    'calories': food2['calories'] * mult2,
                    'protein': food2['protein'] * mult2,
                    'fat': food2['fat'] * mult2,
                    'carbs': food2['carbs'] * mult2,
                    'fiber': food2['fiber'] * mult2,
                  },
                  {
                    'food': food3,
                    'multiplier': mult3,
                    'calories': food3['calories'] * mult3,
                    'protein': food3['protein'] * mult3,
                    'fat': food3['fat'] * mult3,
                    'carbs': food3['carbs'] * mult3,
                    'fiber': food3['fiber'] * mult3,
                  }
                ];

                final score = _calculateCombinationScoreWithDiversity(combination, target, yesterdayFoodNames);
                if (score > bestScore) {
                  bestScore = score;
                  bestCombination = combination;
                }
              }
            }
          }
        }
      }
    }

    return bestCombination != null 
        ? {'combination': bestCombination, 'score': bestScore}
        : null;
  }

  // Tính điểm cho một combination với diversity check
  static double _calculateCombinationScoreWithDiversity(
    List<Map<String, dynamic>> combination,
    MealNutritionalTarget target,
    List<String> yesterdayFoodNames,
  ) {
    // Tính tổng dinh dưỡng của combination
    double totalCalories = 0, totalProtein = 0, totalFat = 0, totalCarbs = 0, totalFiber = 0;
    double diversityPenalty = 0.0;
    
    for (final item in combination) {
      totalCalories += item['calories'];
      totalProtein += item['protein'];
      totalFat += item['fat'];
      totalCarbs += item['carbs'];
      totalFiber += item['fiber'];

      // Penalty cho món ăn của ngày hôm qua
      final foodName = item['food']['food_name'].toString().toLowerCase();
      if (yesterdayFoodNames.contains(foodName)) {
        diversityPenalty += 0.2; // 20% penalty per repeated food từ hôm qua
      }
    }

    // Tính độ lệch so với target
    final calorieDeviation = (totalCalories - target.calories).abs() / target.calories;
    final proteinDeviation = (totalProtein - target.protein).abs() / target.protein;
    final fatDeviation = (totalFat - target.fat).abs() / target.fat;
    final carbDeviation = (totalCarbs - target.carbs).abs() / target.carbs;
    final fiberDeviation = (totalFiber - target.fiber).abs() / target.fiber;

    // Calculate weighted nutrition score
    final nutritionScore = 1.0 / (1.0 + (
      calorieDeviation * 0.4 + 
      proteinDeviation * 0.25 +
      fatDeviation * 0.15 +
      carbDeviation * 0.15 +
      fiberDeviation * 0.05
    ));

    // Bonus cho variety (nhiều món = nhiều dưỡng chất khác nhau)
    final varietyBonus = combination.length > 1 ? 0.1 : 0.0;

    // Bonus lớn cho diversity (món mới hoàn toàn)
    final diversityCount = _countDiversityMatches(combination, yesterdayFoodNames);
    final diversityBonus = (combination.length - diversityCount) * 0.15; // 15% bonus per new food

    return nutritionScore + varietyBonus + diversityBonus - diversityPenalty;
  }

  // Đếm số món trùng với ngày hôm qua
  static int _countDiversityMatches(List<Map<String, dynamic>> combination, List<String> yesterdayFoodNames) {
    int matches = 0;
    for (final item in combination) {
      final foodName = item['food']['food_name'].toString().toLowerCase();
      if (yesterdayFoodNames.contains(foodName)) {
        matches++;
      }
    }
    return matches;
  }
}
