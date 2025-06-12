import 'package:mongo_dart/mongo_dart.dart';
import '../database/mongodb_service.dart';
import '../models/exercise_model.dart';
import '../service/health_diary_service.dart';
import '../service/user_service.dart';

class ExerciseService {
  static const String _exercisesCatalogCollectionName = 'exercises_catalog';
  static const String _exerciseDailyCollectionName = 'exercise_daily';

  static DbCollection? get _exercisesCatalogCollection =>
      DatabaseConnection.getCollection(_exercisesCatalogCollectionName);
  
  static DbCollection? get _exerciseDailyCollection =>
      DatabaseConnection.getCollection(_exerciseDailyCollectionName);

  // Calculate daily exercise needs based on user's health data
  static ExerciseNeeds calculateDailyExerciseNeeds({
    required double weight,      // kg
    required double height,      // cm
    required int age,           // years
    required String gender,     // "Nam" or "Nữ"
    required double bmi,
    String fitnessLevel = 'beginner', // beginner, intermediate, advanced
  }) {
    // Calculate BMR (Basal Metabolic Rate) using Mifflin-St Jeor equation
    double bmr;
    if (gender.toLowerCase() == 'nam' || gender.toLowerCase() == 'male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // Calculate recommended exercise duration and intensity based on BMI and fitness level
    int recommendedDuration; // minutes per day
    int targetCaloriesToBurn;
    List<String> recommendedTypes;

    // Base recommendations on BMI category
    if (bmi < 18.5) {
      // Underweight: Focus on strength training and muscle building
      recommendedDuration = 30;
      targetCaloriesToBurn = (bmr * 0.15).round(); // 15% of BMR
      recommendedTypes = ['Strength Training', 'Yoga', 'Light Cardio'];
    } else if (bmi >= 18.5 && bmi < 25.0) {
      // Normal weight: Balanced routine
      recommendedDuration = 45;
      targetCaloriesToBurn = (bmr * 0.20).round(); // 20% of BMR
      recommendedTypes = ['Cardio', 'Strength Training', 'Flexibility'];
    } else if (bmi >= 25.0 && bmi < 30.0) {
      // Overweight: Focus on cardio and weight loss
      recommendedDuration = 60;
      targetCaloriesToBurn = (bmr * 0.25).round(); // 25% of BMR
      recommendedTypes = ['Cardio', 'HIIT', 'Swimming'];
    } else {
      // Obese: Gradual weight loss with low-impact exercises
      recommendedDuration = 45;
      targetCaloriesToBurn = (bmr * 0.30).round(); // 30% of BMR
      recommendedTypes = ['Walking', 'Swimming', 'Cycling'];
    }

    // Adjust based on fitness level
    switch (fitnessLevel.toLowerCase()) {
      case 'beginner':
        recommendedDuration = (recommendedDuration * 0.7).round();
        targetCaloriesToBurn = (targetCaloriesToBurn * 0.7).round();
        break;
      case 'intermediate':
        // Keep default values
        break;
      case 'advanced':
        recommendedDuration = (recommendedDuration * 1.3).round();
        targetCaloriesToBurn = (targetCaloriesToBurn * 1.3).round();
        break;
    }

    // Adjust for age
    if (age > 50) {
      recommendedDuration = (recommendedDuration * 0.8).round();
      targetCaloriesToBurn = (targetCaloriesToBurn * 0.8).round();
    } else if (age < 25) {
      recommendedDuration = (recommendedDuration * 1.1).round();
      targetCaloriesToBurn = (targetCaloriesToBurn * 1.1).round();
    }

    return ExerciseNeeds(
      targetCaloriesToBurn: targetCaloriesToBurn,
      recommendedDuration: recommendedDuration,
      recommendedTypes: recommendedTypes,
      intensity: _getIntensityLevel(bmi, fitnessLevel),
      sessionsPerWeek: _getRecommendedSessionsPerWeek(bmi, fitnessLevel),
    );
  }
  static String _getIntensityLevel(double bmi, String fitnessLevel) {
    if (bmi < 18.5) {
      return 'Low'; // Underweight should start with low intensity
    } else if (bmi >= 18.5 && bmi < 25.0) {
      switch (fitnessLevel.toLowerCase()) {
        case 'beginner':
          return 'Moderate';
        case 'intermediate':
          return 'Moderate';
        case 'advanced':
          return 'High';
        default:
          return 'Moderate';
      }
    } else if (bmi >= 25.0 && bmi < 30.0) {
      switch (fitnessLevel.toLowerCase()) {
        case 'beginner':
          return 'Low';
        case 'intermediate':
          return 'Moderate';
        case 'advanced':
          return 'Moderate';
        default:
          return 'Moderate';
      }
    } else {
      return 'Low'; // Obese should start with low intensity
    }
  }

  static int _getRecommendedSessionsPerWeek(double bmi, String fitnessLevel) {
    if (bmi < 18.5) {
      return 3; // Underweight: focus on strength building
    } else if (bmi >= 18.5 && bmi < 25.0) {
      switch (fitnessLevel.toLowerCase()) {
        case 'beginner':
          return 3;
        case 'intermediate':
          return 4;
        case 'advanced':
          return 5;
        default:
          return 4;
      }
    } else if (bmi >= 25.0 && bmi < 30.0) {
      return 5; // Overweight: more frequent sessions for weight loss
    } else {
      return 4; // Obese: regular but not overwhelming
    }
  }
  // Generate automatic exercise plan based on user's health data
  static Future<DailyExercisePlan?> generateAutoExercisePlan(int userId, String date) async {
    try {
      print('🏃 Generating auto exercise plan for user $userId on date $date');

      // Get user data
      final user = await UserService.getUserById(userId);
      if (user == null) {
        print('❌ User not found');
        return null;
      }

      // Validation 1: Check if health diary exists for the specific date
      final healthDataForDate = await _getHealthDiaryForDate(userId, date);
      if (healthDataForDate == null) {
        print('❌ No health diary found for date $date. Please create health diary first.');
        return null;
      }

      if (healthDataForDate.bmi == null) {
        print('❌ No BMI data found for date $date');
        return null;
      }

      // Validation 2: Check if exercise plan should be different from previous day
      final previousDayPlan = await _getPreviousDayExercisePlan(userId, date);
      print('📋 Previous day plan: ${previousDayPlan?.exercises.length ?? 0} exercises');      // Calculate age
      final age = _calculateAge(user.birthDate);

      // Calculate exercise needs
      final exerciseNeeds = calculateDailyExerciseNeeds(
        weight: healthDataForDate.weight,
        height: healthDataForDate.height,
        age: age,
        gender: user.gender,
        bmi: healthDataForDate.bmi!,
        fitnessLevel: 'beginner', // Could be stored in user profile
      );print('🎯 Exercise needs: ${exerciseNeeds.targetCaloriesToBurn} cal, ${exerciseNeeds.recommendedDuration} min');

      // Get exercises from catalog based on user's needs
      final availableExercises = await _getRecommendedExercises(exerciseNeeds);
      if (availableExercises.isEmpty) {
        print('❌ No exercises found in catalog');
        return null;
      }

      print('📋 Found ${availableExercises.length} available exercises');      // Generate exercise plan with variation check
      final exerciseItems = _generateOptimalExerciseItems(
        availableExercises, 
        exerciseNeeds,
        previousDayExercises: previousDayPlan?.exercises.map((e) => e.exerciseName).toList() ?? [],
      );      if (exerciseItems.isEmpty) {
        print('❌ Failed to generate exercise items');
        return null;
      }

      // Validation 3: Ensure at least one exercise is different from previous day
      final currentExerciseNames = exerciseItems.map((e) => e.exerciseName).toList();
      final previousExerciseNames = previousDayPlan?.exercises.map((e) => e.exerciseName).toList() ?? [];
      
      if (!_validateExercisePlanDifference(currentExerciseNames, previousExerciseNames)) {
        print('❌ Exercise plan must have at least one different exercise from previous day');
        return null;
      }

      final totalCaloriesBurned = exerciseItems.fold(0, (sum, item) => sum + item.caloriesBurned);
      final totalDuration = exerciseItems.fold(0, (sum, item) => sum + item.durationMinutes);

      print('✅ Generated ${exerciseItems.length} exercises: ${totalCaloriesBurned} cal, ${totalDuration} min');

      final dailyExercisePlan = DailyExercisePlan(
        userId: userId,
        date: date,
        exercises: exerciseItems,
        totalCaloriesBurned: totalCaloriesBurned,
        totalDuration: totalDuration,
        planType: 'auto',
        isCompleted: false,
        completedExercises: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await saveDailyExercisePlan(dailyExercisePlan);
    } catch (e) {
      print('❌ Error generating auto exercise plan: $e');
      return null;
    }
  }

  // Get recommended exercises from catalog based on needs
  static Future<List<Exercise>> _getRecommendedExercises(ExerciseNeeds needs) async {
    try {
      final collection = _exercisesCatalogCollection;
      if (collection == null) return [];

      // For now, get all exercises and filter client-side
      // In a real app, you might have exercise types stored in the database
      final results = await collection.find().toList();
      return results.map((doc) => Exercise.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Error getting recommended exercises: $e');
      return [];
    }
  }  // Generate optimal exercise items based on needs
  static List<ExerciseItem> _generateOptimalExerciseItems(
    List<Exercise> availableExercises,
    ExerciseNeeds needs, {
    List<String> previousDayExercises = const [],
  }) {
    final exerciseItems = <ExerciseItem>[];
    int remainingCalories = needs.targetCaloriesToBurn;
    int remainingDuration = needs.recommendedDuration;

    // Ensure we have minimum targets
    if (remainingCalories < 10 || remainingDuration < 5) {
      print('⚠️ Exercise targets too low: ${remainingCalories} cal, ${remainingDuration} min');
      remainingCalories = remainingCalories < 10 ? 50 : remainingCalories;
      remainingDuration = remainingDuration < 5 ? 15 : remainingDuration;
    }

    // Create exercise mapping based on recommended types
    final exerciseMapping = {
      'Cardio': ['Chạy bộ', 'Bơi lội', 'Cycling'],
      'Strength Training': ['Đẩy tạ', 'Pull-ups', 'Squats'],
      'Flexibility': ['Yoga', 'Stretching'],
      'HIIT': ['Burpees', 'Mountain climbers'],
      'Walking': ['Đi bộ', 'Walking'],
      'Swimming': ['Bơi lội'],
      'Light Cardio': ['Đi bộ', 'Cycling nhẹ'],
    };

    print('🔄 Previous day exercises: ${previousDayExercises.join(", ")}');    for (final recommendedType in needs.recommendedTypes) {
      if (remainingCalories <= 0 || remainingDuration <= 0) break;

      final typeExercises = exerciseMapping[recommendedType] ?? [];
      final matchingExercises = availableExercises.where(
        (exercise) => typeExercises.any(
          (type) => exercise.exerciseName.toLowerCase().contains(type.toLowerCase()),
        ),
      ).toList();

      if (matchingExercises.isNotEmpty) {
        // Prioritize exercises that are different from previous day
        Exercise? selectedExercise;
        
        // First try to find an exercise not used yesterday
        final newExercises = matchingExercises.where(
          (exercise) => !previousDayExercises.contains(exercise.exerciseName),
        ).toList();
        
        if (newExercises.isNotEmpty) {
          selectedExercise = newExercises.first;
          print('✅ Selected new exercise: ${selectedExercise.exerciseName}');
        } else {
          // If all exercises were used yesterday, pick the first one
          selectedExercise = matchingExercises.first;
          print('⚠️ Reusing exercise from yesterday: ${selectedExercise.exerciseName}');
        }
        
        // Calculate duration and sets based on remaining targets with safety checks
        int duration = (remainingDuration * 0.3).round();
        duration = duration.clamp(5, remainingDuration.clamp(5, 30)); // Ensure valid range
        
        int sets = recommendedType == 'Cardio' ? 1 : (duration / 5).round().clamp(1, 5);
        int reps = recommendedType == 'Cardio' ? 0 : 10;
        
        // Calculate calories burned with safety checks
        int baseCalories = (selectedExercise.caloriesPerSet * sets).clamp(1, 500);
        int maxAllowedCalories = (remainingCalories * 0.6).round();
        
        int caloriesBurned;
        if (maxAllowedCalories < 1) {
          caloriesBurned = baseCalories.clamp(1, remainingCalories);
        } else {
          caloriesBurned = baseCalories.clamp(1, maxAllowedCalories);
        }

        final exerciseItem = ExerciseItem(
          exerciseId: selectedExercise.id!,
          exerciseName: selectedExercise.exerciseName,
          exerciseType: recommendedType,
          sets: sets,
          repsPerSet: reps,
          durationMinutes: duration,
          caloriesBurned: caloriesBurned,
          intensity: needs.intensity,
        );

        exerciseItems.add(exerciseItem);
        remainingCalories -= caloriesBurned;
        remainingDuration -= duration;
      }
    }

    return exerciseItems;
  }
  // Save daily exercise plan
  static Future<DailyExercisePlan?> saveDailyExercisePlan(DailyExercisePlan plan) async {
    try {
      // Validation 1: Check if health diary exists for the date
      final healthDataForDate = await _getHealthDiaryForDate(plan.userId, plan.date);
      if (healthDataForDate == null) {
        print('❌ Cannot save exercise plan: No health diary found for date ${plan.date}');
        return null;
      }

      // Validation 2: For new plans, check difference from previous day
      if (plan.id == null) {
        final previousDayPlan = await _getPreviousDayExercisePlan(plan.userId, plan.date);
        final currentExerciseNames = plan.exercises.map((e) => e.exerciseName).toList();
        final previousExerciseNames = previousDayPlan?.exercises.map((e) => e.exerciseName).toList() ?? [];
        
        if (!_validateExercisePlanDifference(currentExerciseNames, previousExerciseNames)) {
          print('❌ Cannot save exercise plan: Must have at least one different exercise from previous day');
          return null;
        }
      }

      final collection = DatabaseConnection.getCollection('daily_exercise_plans');
      if (collection == null) return null;

      if (plan.id != null) {
        // Update existing plan
        final result = await collection.updateOne(
          where.eq('_id', plan.id),
          modify.set('exercises', plan.exercises.map((e) => e.toMap()).toList())
                .set('total_calories_burned', plan.totalCaloriesBurned)
                .set('total_duration', plan.totalDuration)
                .set('is_completed', plan.isCompleted)
                .set('completed_exercises', plan.completedExercises)
                .set('updated_at', DateTime.now().toIso8601String()),
        );

        if (result.isSuccess) {
          return plan;
        }
      } else {
        // Check if plan already exists for this user and date
        final existingPlan = await getDailyExercisePlan(plan.userId, plan.date);
        if (existingPlan != null) {
          final updatedPlan = plan.copyWith(id: existingPlan.id);
          return await saveDailyExercisePlan(updatedPlan);
        } else {
          // Create new plan
          final result = await collection.insertOne(plan.toMap());
          if (result.isSuccess && result.document != null) {
            return DailyExercisePlan.fromMap(result.document!);
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ Error saving daily exercise plan: $e');
      return null;
    }
  }

  // Get daily exercise plan by user and date
  static Future<DailyExercisePlan?> getDailyExercisePlan(int userId, String date) async {
    try {
      final collection = DatabaseConnection.getCollection('daily_exercise_plans');
      if (collection == null) return null;

      final result = await collection.findOne(
        where.eq('user_id', userId).eq('date', date),
      );

      if (result != null) {
        return DailyExercisePlan.fromMap(result);
      }

      return null;
    } catch (e) {
      print('❌ Error getting daily exercise plan: $e');
      return null;
    }
  }

  // Mark exercise as completed
  static Future<bool> markExerciseCompleted(ObjectId planId, String exerciseName) async {
    try {
      final collection = DatabaseConnection.getCollection('daily_exercise_plans');
      if (collection == null) return false;

      final plan = await collection.findOne(where.eq('_id', planId));
      if (plan == null) return false;

      List<String> completedExercises = List<String>.from(plan['completed_exercises'] ?? []);
      if (!completedExercises.contains(exerciseName)) {
        completedExercises.add(exerciseName);
      }

      final totalExercises = (plan['exercises'] as List).length;
      final isCompleted = completedExercises.length >= totalExercises;

      final result = await collection.updateOne(
        where.eq('_id', planId),
        modify.set('completed_exercises', completedExercises)
              .set('is_completed', isCompleted)
              .set('updated_at', DateTime.now().toIso8601String()),
      );

      return result.isSuccess;
    } catch (e) {
      print('❌ Error marking exercise completed: $e');
      return false;
    }
  }

  // Delete exercise plan
  static Future<bool> deleteExercisePlan(ObjectId planId) async {
    try {
      final collection = DatabaseConnection.getCollection('daily_exercise_plans');
      if (collection == null) return false;

      final result = await collection.deleteOne(where.eq('_id', planId));
      return result.isSuccess;
    } catch (e) {
      print('❌ Error deleting exercise plan: $e');
      return false;
    }
  }
  // Get all exercises from catalog
  static Future<List<Exercise>> getAllExercises() async {
    try {
      var collection = _exercisesCatalogCollection;
      if (collection == null) return [];

      var results = await collection.find().toList();
      return results.map((doc) => Exercise.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Error getting exercises: $e');
      return [];
    }
  }

  // Search exercises by name
  static Future<List<Exercise>> searchExercisesByName(String searchTerm) async {
    try {
      var collection = _exercisesCatalogCollection;
      if (collection == null) return [];

      var results = await collection
          .find(where.match('exercise_name', searchTerm))
          .toList();

      return results.map((doc) => Exercise.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Error searching exercises: $e');
      return [];
    }
  }

  // Get exercise by name
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
      print('❌ Error getting exercise by name: $e');
      return null;
    }
  }

  // Add daily exercise
  static Future<bool> addExerciseDaily(ExerciseDaily exerciseDaily) async {
    try {
      var collection = _exerciseDailyCollection;
      if (collection == null) return false;

      var result = await collection.insertOne(exerciseDaily.toMap());
      print('✅ Exercise daily added successfully: ${result.id}');
      return true;
    } catch (e) {
      print('❌ Error adding exercise daily: $e');
      return false;
    }
  }

  // Get daily exercises by user and date
  static Future<List<ExerciseDaily>> getExercisesByUserAndDate(int userId, String date) async {
    try {
      var collection = _exerciseDailyCollection;
      if (collection == null) return [];

      var results = await collection
          .find(where.eq('user_id', userId).eq('entry_date', date))
          .toList();

      return results.map((doc) => ExerciseDaily.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Error getting exercises by user and date: $e');
      return [];
    }
  }

  // Get all user exercises
  static Future<List<ExerciseDaily>> getUserExercises(int userId) async {
    try {
      var collection = _exerciseDailyCollection;
      if (collection == null) return [];

      var results = await collection
          .find(where.eq('user_id', userId))
          .toList();

      return results.map((doc) => ExerciseDaily.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Error getting user exercises: $e');
      return [];
    }
  }

  // Calculate total calories burned for date
  static Future<int> getTotalCaloriesBurnedForDate(int userId, String date) async {
    try {
      var exercises = await getExercisesByUserAndDate(userId, date);
      int totalCalories = 0;

      for (var exercise in exercises) {
        totalCalories += exercise.totalCaloriesBurned;
      }

      return totalCalories;
    } catch (e) {
      print('❌ Error calculating total calories burned: $e');
      return 0;
    }
  }

  // Calculate calories burned for exercise
  static int calculateCaloriesBurned(int caloriesPerSet, int sets) {
    return caloriesPerSet * sets;
  }

  // Update daily exercise
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
      print('❌ Error updating exercise daily: $e');
      return false;
    }
  }

  // Delete daily exercise
  static Future<bool> deleteExerciseDaily(ObjectId id) async {
    try {
      var collection = _exerciseDailyCollection;
      if (collection == null) return false;

      var result = await collection.deleteOne(where.id(id));
      return result.nRemoved > 0;
    } catch (e) {
      print('❌ Error deleting exercise daily: $e');
      return false;
    }
  }

  // Add exercise to catalog (admin function)
  static Future<bool> addExerciseToCatalog(Exercise exercise) async {
    try {
      var collection = _exercisesCatalogCollection;
      if (collection == null) return false;

      var result = await collection.insertOne(exercise.toMap());
      print('✅ Exercise added to catalog successfully: ${result.id}');
      return true;
    } catch (e) {
      print('❌ Error adding exercise to catalog: $e');
      return false;
    }
  }
  static int _calculateAge(String birthDate) {
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
      print('❌ Error calculating age: $e');
      return 25; // default age
    }
  }

  // Get health diary for specific date
  static Future<dynamic> _getHealthDiaryForDate(int userId, String date) async {
    try {
      final healthData = await HealthDiaryService.getUserHealthDiary(userId);
      
      // Find health data for the specific date
      final healthForDate = healthData.where((health) => health.entryDate == date).toList();
      
      if (healthForDate.isEmpty) {
        print('❌ No health diary found for date: $date');
        return null;
      }
      
      return healthForDate.first;
    } catch (e) {
      print('❌ Error getting health diary for date: $e');
      return null;
    }
  }

  // Get previous day exercise plan
  static Future<DailyExercisePlan?> _getPreviousDayExercisePlan(int userId, String currentDate) async {
    try {
      // Parse current date and get previous day
      final parts = currentDate.split('/');
      if (parts.length != 3) return null;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      final currentDateTime = DateTime(year, month, day);
      final previousDateTime = currentDateTime.subtract(const Duration(days: 1));
      
      // Format previous date back to string
      final previousDate = '${previousDateTime.day.toString().padLeft(2, '0')}/${previousDateTime.month.toString().padLeft(2, '0')}/${previousDateTime.year}';
      
      print('🔍 Looking for previous day plan: $previousDate');
      
      // Get previous day's exercise plan
      return await getDailyExercisePlan(userId, previousDate);
    } catch (e) {
      print('❌ Error getting previous day exercise plan: $e');
      return null;
    }
  }

  // Validate exercise plan differences
  static bool _validateExercisePlanDifference(List<String> currentExercises, List<String> previousExercises) {
    if (previousExercises.isEmpty) return true; // No previous plan, allow creation
    
    // Count how many exercises are different
    final differentExercises = currentExercises.where(
      (exercise) => !previousExercises.contains(exercise),
    ).toList();
    
    print('📊 Current exercises: ${currentExercises.length}, Different from yesterday: ${differentExercises.length}');
    
    // Must have at least 1 different exercise
    return differentExercises.isNotEmpty;
  }
}
