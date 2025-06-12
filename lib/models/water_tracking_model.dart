
import 'package:mongo_dart/mongo_dart.dart';

/// Model cho việc theo dõi lượng nước uống hàng ngày
class WaterTracking {
  final ObjectId? id;
  final int userId;
  final String date; // Format: DD/MM/YYYY
  final double targetAmount; // Mục tiêu lượng nước (ml)
  final double currentAmount; // Lượng nước đã uống (ml)
  final bool isCompleted; // Đã hoàn thành mục tiêu
  final List<WaterIntake> intakes; // Danh sách các lần uống nước
  final DateTime createdAt;
  final DateTime updatedAt;

  WaterTracking({
    this.id,
    required this.userId,
    required this.date,
    required this.targetAmount,
    required this.currentAmount,
    required this.isCompleted,
    required this.intakes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Tạo bản sao với các thay đổi
  WaterTracking copyWith({
    ObjectId? id,
    int? userId,
    String? date,
    double? targetAmount,
    double? currentAmount,
    bool? isCompleted,
    List<WaterIntake>? intakes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WaterTracking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      isCompleted: isCompleted ?? this.isCompleted,
      intakes: intakes ?? this.intakes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Chuyển đổi từ Map (MongoDB document) sang WaterTracking
  factory WaterTracking.fromMap(Map<String, dynamic> map) {
    return WaterTracking(
      id: map['_id'] as ObjectId?,
      userId: map['user_id'] as int,
      date: map['date'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num).toDouble(),
      isCompleted: map['is_completed'] as bool,
      intakes: (map['intakes'] as List<dynamic>?)
          ?.map((intake) => WaterIntake.fromMap(intake as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: map['created_at'] is DateTime 
          ? map['created_at'] as DateTime 
          : DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] is DateTime 
          ? map['updated_at'] as DateTime 
          : DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Chuyển đổi từ WaterTracking sang Map (MongoDB document)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'user_id': userId,
      'date': date,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'is_completed': isCompleted,
      'intakes': intakes.map((intake) => intake.toMap()).toList(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Tính toán mục tiêu nước uống hàng ngày dựa trên thông tin sức khỏe
  static double calculateDailyWaterTarget({
    required double weight, // kg
    required double height, // cm
    required int age,
    required String gender,
    String activityLevel = 'moderate',
  }) {
    // Công thức cơ bản: 35ml/kg thể trọng
    double baseAmount = weight * 35;
    
    // Điều chỉnh theo giới tính
    if (gender.toLowerCase().contains('nữ') || 
        gender.toLowerCase().contains('female')) {
      baseAmount *= 0.9; // Phụ nữ cần ít nước hơn 10%
    }
    
    // Điều chỉnh theo tuổi
    if (age > 65) {
      baseAmount *= 0.85; // Người cao tuổi giảm 15%
    } else if (age < 18) {
      baseAmount *= 1.1; // Trẻ em/thanh thiếu niên tăng 10%
    }
    
    // Điều chỉnh theo mức độ hoạt động
    switch (activityLevel.toLowerCase()) {
      case 'low':
        baseAmount *= 0.9;
        break;
      case 'high':
        baseAmount *= 1.3;
        break;
      case 'very_high':
        baseAmount *= 1.5;
        break;
      default: // moderate
        baseAmount *= 1.1;
    }
    
    // Đảm bảo trong khoảng hợp lý (1.5L - 4L)
    return baseAmount.clamp(1500.0, 4000.0);
  }

  /// Tính phần trăm hoàn thành
  double get completionPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount * 100).clamp(0.0, 100.0);
  }

  /// Lượng nước còn thiếu để đạt mục tiêu
  double get remainingAmount {
    final remaining = targetAmount - currentAmount;
    return remaining > 0 ? remaining : 0;
  }

  @override
  String toString() {
    return 'WaterTracking(userId: $userId, date: $date, '
           'current: ${currentAmount}ml, target: ${targetAmount}ml, '
           'completed: $isCompleted, intakes: ${intakes.length})';
  }
}

/// Model cho từng lần uống nước
class WaterIntake {
  final double amount; // Lượng nước (ml)
  final DateTime time; // Thời gian uống
  final String note; // Ghi chú (tùy chọn)

  WaterIntake({
    required this.amount,
    required this.time,
    this.note = '',
  });

  /// Chuyển đổi từ Map sang WaterIntake
  factory WaterIntake.fromMap(Map<String, dynamic> map) {
    return WaterIntake(
      amount: (map['amount'] as num).toDouble(),
      time: map['time'] is DateTime 
          ? map['time'] as DateTime 
          : DateTime.parse(map['time'] as String),
      note: map['note'] as String? ?? '',
    );
  }

  /// Chuyển đổi từ WaterIntake sang Map
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'time': time,
      'note': note,
    };
  }

  /// Định dạng thời gian hiển thị
  String get formattedTime {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}';
  }

  /// Định dạng lượng nước hiển thị
  String get formattedAmount {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}L';
    }
    return '${amount.toInt()}ml';
  }

  @override
  String toString() {
    return 'WaterIntake(amount: ${amount}ml, time: $formattedTime, note: $note)';
  }
}

/// Model cho streak (chuỗi ngày liên tiếp hoàn thành mục tiêu)
class WaterStreak {
  final int currentStreak; // Chuỗi hiện tại
  final int longestStreak; // Chuỗi dài nhất từng đạt được
  final String lastCompletedDate; // Ngày hoàn thành cuối cùng
  final List<String> recentCompletedDates; // Các ngày hoàn thành gần đây

  WaterStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCompletedDate,
    required this.recentCompletedDates,
  });

  /// Tính toán streak từ danh sách lịch sử water tracking
  factory WaterStreak.fromList(List<WaterTracking> history) {
    if (history.isEmpty) {
      return WaterStreak(
        currentStreak: 0,
        longestStreak: 0,
        lastCompletedDate: '',
        recentCompletedDates: [],
      );
    }

    // Sắp xếp theo ngày giảm dần
    final sortedHistory = [...history];
    sortedHistory.sort((a, b) => _compareDates(b.date, a.date));

    // Tìm các ngày hoàn thành
    final completedDates = sortedHistory
        .where((tracking) => tracking.isCompleted)
        .map((tracking) => tracking.date)
        .toList();

    if (completedDates.isEmpty) {
      return WaterStreak(
        currentStreak: 0,
        longestStreak: 0,
        lastCompletedDate: '',
        recentCompletedDates: [],
      );
    }

    // Tính current streak
    int currentStreak = 0;
    final today = _formatDate(DateTime.now());
    final yesterday = _formatDate(DateTime.now().subtract(const Duration(days: 1)));

    // Kiểm tra nếu hôm nay hoặc hôm qua đã hoàn thành
    if (completedDates.contains(today) || completedDates.contains(yesterday)) {
      DateTime checkDate = completedDates.contains(today) 
          ? DateTime.now() 
          : DateTime.now().subtract(const Duration(days: 1));

      while (true) {
        final dateStr = _formatDate(checkDate);
        if (completedDates.contains(dateStr)) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    // Tính longest streak
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;

    for (final dateStr in completedDates.reversed) {
      final currentDate = _parseDate(dateStr);
      
      if (lastDate == null) {
        tempStreak = 1;
      } else {
        final daysDiff = currentDate.difference(lastDate).inDays;
        if (daysDiff == 1) {
          tempStreak++;
        } else {
          longestStreak = longestStreak > tempStreak ? longestStreak : tempStreak;
          tempStreak = 1;
        }
      }
      
      lastDate = currentDate;
    }
    longestStreak = longestStreak > tempStreak ? longestStreak : tempStreak;

    return WaterStreak(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastCompletedDate: completedDates.isNotEmpty ? completedDates.first : '',
      recentCompletedDates: completedDates.take(30).toList(),
    );
  }

  /// So sánh hai ngày theo định dạng DD/MM/YYYY
  static int _compareDates(String date1, String date2) {
    final d1 = _parseDate(date1);
    final d2 = _parseDate(date2);
    return d1.compareTo(d2);
  }

  /// Chuyển đổi string DD/MM/YYYY sang DateTime
  static DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('/');
    return DateTime(
      int.parse(parts[2]), // year
      int.parse(parts[1]), // month
      int.parse(parts[0]), // day
    );
  }

  /// Định dạng DateTime thành DD/MM/YYYY
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }

  /// Kiểm tra có đang trong streak không
  bool get isActiveStreak {
    if (lastCompletedDate.isEmpty) return false;
    
    final today = _formatDate(DateTime.now());
    final yesterday = _formatDate(DateTime.now().subtract(const Duration(days: 1)));
    
    return lastCompletedDate == today || lastCompletedDate == yesterday;
  }

  /// Văn bản mô tả streak
  String get streakDescription {
    if (currentStreak == 0) {
      return 'Chưa có streak nào';
    } else if (currentStreak == 1) {
      return '1 ngày liên tiếp';
    } else {
      return '$currentStreak ngày liên tiếp';
    }
  }

  /// Văn bản động viên
  String get motivationText {
    if (currentStreak == 0) {
      return 'Hãy bắt đầu streak mới hôm nay! 💪';
    } else if (currentStreak < 7) {
      return 'Tuyệt vời! Tiếp tục duy trì nhé! 🔥';
    } else if (currentStreak < 30) {
      return 'Streak xuất sắc! Bạn đang rất tốt! 🏆';
    } else {
      return 'Streak huyền thoại! Bạn là champion! 👑';
    }
  }

  @override
  String toString() {
    return 'WaterStreak(current: $currentStreak, longest: $longestStreak, '
           'lastCompleted: $lastCompletedDate)';
  }
}