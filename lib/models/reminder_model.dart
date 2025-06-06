import 'package:mongo_dart/mongo_dart.dart';

class Reminder {
  ObjectId? id;
  int userId;
  String message;
  DateTime reminderDate;
  String remindTime; // Lưu dưới dạng "HH:mm"
  bool isActive;
  DateTime? createdAt;
  DateTime? updatedAt;

  Reminder({
    this.id,
    required this.userId,
    required this.message,
    required this.reminderDate,
    required this.remindTime,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['_id'],
      userId: map['user_id'],
      message: map['message'] ?? '',
      reminderDate: map['reminder_date'] is String 
          ? DateTime.parse(map['reminder_date'])
          : map['reminder_date'],
      remindTime: map['remind_time'] ?? '',
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at'] != null 
          ? (map['created_at'] is String 
              ? DateTime.parse(map['created_at'])
              : map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null 
          ? (map['updated_at'] is String 
              ? DateTime.parse(map['updated_at'])
              : map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'message': message,
      'reminder_date': reminderDate.toIso8601String().split('T')[0], // Chỉ lấy ngày YYYY-MM-DD
      'remind_time': remindTime,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Tạo DateTime từ reminderDate và remindTime
  DateTime get fullDateTime {
    final timeParts = remindTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    return DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      hour,
      minute,
    );
  }

  // Kiểm tra xem reminder có trong tương lai không
  bool get isFuture {
    return fullDateTime.isAfter(DateTime.now());
  }

  // Kiểm tra xem reminder có hôm nay không
  bool get isToday {
    final now = DateTime.now();
    return reminderDate.year == now.year &&
           reminderDate.month == now.month &&
           reminderDate.day == now.day;
  }

  // Format hiển thị ngày
  String get formattedDate {
    return "${reminderDate.day.toString().padLeft(2, '0')}/"
           "${reminderDate.month.toString().padLeft(2, '0')}/"
           "${reminderDate.year}";
  }

  // Format hiển thị thời gian
  String get formattedTime {
    return remindTime;
  }

  // Copy với thay đổi một số thuộc tính
  Reminder copyWith({
    ObjectId? id,
    int? userId,
    String? message,
    DateTime? reminderDate,
    String? remindTime,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      reminderDate: reminderDate ?? this.reminderDate,
      remindTime: remindTime ?? this.remindTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
