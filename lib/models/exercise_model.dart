import 'package:mongo_dart/mongo_dart.dart';

class Exercise {
  ObjectId? id;
  String exerciseName;
  int caloriesPerSet;

  Exercise({
    this.id,
    required this.exerciseName,
    required this.caloriesPerSet,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['_id'],
      exerciseName: map['exercise_name'],
      caloriesPerSet: map['calories_per_set'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exercise_name': exerciseName,
      'calories_per_set': caloriesPerSet,
    };
  }
}

class ExerciseDaily {
  ObjectId? id;
  int userId;
  String entryDate;
  String exerciseName;
  int sets;
  int repsPerSet;
  int? durationMinutes;
  int totalCaloriesBurned;

  ExerciseDaily({
    this.id,
    required this.userId,
    required this.entryDate,
    required this.exerciseName,
    required this.sets,
    required this.repsPerSet,
    this.durationMinutes,
    required this.totalCaloriesBurned,
  });

  factory ExerciseDaily.fromMap(Map<String, dynamic> map) {
    return ExerciseDaily(
      id: map['_id'],
      userId: map['user_id'],
      entryDate: map['entry_date'],
      exerciseName: map['exercise_name'],
      sets: map['sets'],
      repsPerSet: map['reps_per_set'],
      durationMinutes: map['duration_minutes'],
      totalCaloriesBurned: map['total_calories_burned'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'entry_date': entryDate,
      'exercise_name': exerciseName,
      'sets': sets,
      'reps_per_set': repsPerSet,
      'duration_minutes': durationMinutes,
      'total_calories_burned': totalCaloriesBurned,
    };
  }
}

// Daily exercise plan model similar to DailyMeal
class DailyExercisePlan {
  final ObjectId? id;
  final int userId;
  final String date; // Format: "dd/MM/yyyy"
  final List<ExerciseItem> exercises;
  final int totalCaloriesBurned;
  final int totalDuration; // minutes
  final String planType; // "auto", "custom"
  final bool isCompleted;
  final List<String> completedExercises;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyExercisePlan({
    this.id,
    required this.userId,
    required this.date,
    required this.exercises,
    required this.totalCaloriesBurned,
    required this.totalDuration,
    required this.planType,
    required this.isCompleted,
    required this.completedExercises,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyExercisePlan.fromMap(Map<String, dynamic> map) {
    return DailyExercisePlan(
      id: map['_id'],
      userId: map['user_id'],
      date: map['date'],
      exercises: (map['exercises'] as List<dynamic>)
          .map((item) => ExerciseItem.fromMap(item))
          .toList(),
      totalCaloriesBurned: map['total_calories_burned'] ?? 0,
      totalDuration: map['total_duration'] ?? 0,
      planType: map['plan_type'] ?? 'auto',
      isCompleted: map['is_completed'] ?? false,
      completedExercises: List<String>.from(map['completed_exercises'] ?? []),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'date': date,
      'exercises': exercises.map((item) => item.toMap()).toList(),
      'total_calories_burned': totalCaloriesBurned,
      'total_duration': totalDuration,
      'plan_type': planType,
      'is_completed': isCompleted,
      'completed_exercises': completedExercises,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DailyExercisePlan copyWith({
    ObjectId? id,
    int? userId,
    String? date,
    List<ExerciseItem>? exercises,
    int? totalCaloriesBurned,
    int? totalDuration,
    String? planType,
    bool? isCompleted,
    List<String>? completedExercises,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyExercisePlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      exercises: exercises ?? this.exercises,
      totalCaloriesBurned: totalCaloriesBurned ?? this.totalCaloriesBurned,
      totalDuration: totalDuration ?? this.totalDuration,
      planType: planType ?? this.planType,
      isCompleted: isCompleted ?? this.isCompleted,
      completedExercises: completedExercises ?? this.completedExercises,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Individual exercise item in a plan
class ExerciseItem {
  final ObjectId exerciseId;
  final String exerciseName;
  final String exerciseType; // "Cardio", "Strength", "Flexibility", etc.
  final int sets;
  final int repsPerSet;
  final int durationMinutes;
  final int caloriesBurned;
  final String intensity; // "Low", "Moderate", "High"

  ExerciseItem({
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseType,
    required this.sets,
    required this.repsPerSet,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.intensity,
  });

  factory ExerciseItem.fromMap(Map<String, dynamic> map) {
    return ExerciseItem(
      exerciseId: map['exercise_id'],
      exerciseName: map['exercise_name'],
      exerciseType: map['exercise_type'],
      sets: map['sets'] ?? 1,
      repsPerSet: map['reps_per_set'] ?? 0,
      durationMinutes: map['duration_minutes'] ?? 0,
      caloriesBurned: map['calories_burned'] ?? 0,
      intensity: map['intensity'] ?? 'Moderate',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'exercise_type': exerciseType,
      'sets': sets,
      'reps_per_set': repsPerSet,
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
      'intensity': intensity,
    };
  }

  ExerciseItem copyWith({
    ObjectId? exerciseId,
    String? exerciseName,
    String? exerciseType,
    int? sets,
    int? repsPerSet,
    int? durationMinutes,
    int? caloriesBurned,
    String? intensity,
  }) {
    return ExerciseItem(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      exerciseType: exerciseType ?? this.exerciseType,
      sets: sets ?? this.sets,
      repsPerSet: repsPerSet ?? this.repsPerSet,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      intensity: intensity ?? this.intensity,
    );
  }
}

// Exercise needs calculation model
class ExerciseNeeds {
  final int targetCaloriesToBurn;
  final int recommendedDuration; // minutes
  final List<String> recommendedTypes;
  final String intensity; // "Low", "Moderate", "High"
  final int sessionsPerWeek;

  ExerciseNeeds({
    required this.targetCaloriesToBurn,
    required this.recommendedDuration,
    required this.recommendedTypes,
    required this.intensity,
    required this.sessionsPerWeek,
  });
}
