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
