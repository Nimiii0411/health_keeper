import 'package:mongo_dart/mongo_dart.dart';

class Reminder {
  ObjectId? id;
  int userId;
  String title;
  String description;
  String time; // Lưu dưới dạng "HH:mm"
  bool isActive;
  String type; // "medicine", "exercise", "doctor", "meal", "water"
  List<String>? repeatDays; // ["monday", "tuesday", ...] hoặc null nếu không lặp
  String? medicineDetails;
  String? exerciseDetails;

  Reminder({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.time,
    required this.isActive,
    required this.type,
    this.repeatDays,
    this.medicineDetails,
    this.exerciseDetails,
  });

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['_id'],
      userId: map['user_id'],
      title: map['title'],
      description: map['description'],
      time: map['time'],
      isActive: map['is_active'],
      type: map['type'],
      repeatDays: map['repeat_days']?.cast<String>(),
      medicineDetails: map['medicine_details'],
      exerciseDetails: map['exercise_details'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'time': time,
      'is_active': isActive,
      'type': type,
      'repeat_days': repeatDays,
      'medicine_details': medicineDetails,
      'exercise_details': exerciseDetails,
    };
  }
}

class Goal {
  ObjectId? id;
  int userId;
  String goalType; // "weight_loss", "weight_gain", "exercise", "water", "steps"
  String title;
  String description;
  double targetValue;
  double currentValue;
  String unit;
  String deadline; // "YYYY-MM-DD"
  bool isActive;
  DateTime createdAt;

  Goal({
    this.id,
    required this.userId,
    required this.goalType,
    required this.title,
    required this.description,
    required this.targetValue,
    this.currentValue = 0.0,
    required this.unit,
    required this.deadline,
    this.isActive = true,
    required this.createdAt,
  });

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['_id'],
      userId: map['user_id'],
      goalType: map['goal_type'],
      title: map['title'],
      description: map['description'],
      targetValue: map['target_value'].toDouble(),
      currentValue: map['current_value']?.toDouble() ?? 0.0,
      unit: map['unit'],
      deadline: map['deadline'],
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'goal_type': goalType,
      'title': title,
      'description': description,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'deadline': deadline,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Tính phần trăm hoàn thành
  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return (currentValue / targetValue * 100).clamp(0.0, 100.0);
  }
}
