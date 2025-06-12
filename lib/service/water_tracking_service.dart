import 'package:mongo_dart/mongo_dart.dart';
import '../database/mongodb_service.dart';
import '../models/water_tracking_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

class WaterTrackingService {
  static final WaterTrackingService _instance = WaterTrackingService._internal();
  factory WaterTrackingService() => _instance;
  WaterTrackingService._internal();

  static const String COLLECTION_NAME = 'water_logs';
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  // Lấy collection
  static DbCollection? get _collection {
    return DatabaseConnection.getCollection(COLLECTION_NAME);
  }

  // Khởi tạo service
  Future<void> initialize() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = 
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();
  }

  // Lấy water tracking theo ngày
  Future<WaterTracking?> getWaterTrackingByDate(int userId, String date) async {
    try {
      final collection = _collection;
      if (collection == null) {
        print('❌ Database chưa được kết nối');
        return null;
      }
      
      final result = await collection.findOne(where.eq('user_id', userId).eq('date', date));
      
      if (result != null) {
        return WaterTracking.fromMap(result);
      }
      return null;
    } catch (e) {
      print('❌ Lỗi lấy water tracking: $e');
      return null;
    }
  }

  // Tạo water tracking mới cho ngày hiện tại
  Future<WaterTracking?> createWaterTrackingForToday(int userId) async {
    try {
      final now = DateTime.now();
      final date = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
      
      // Kiểm tra đã tồn tại chưa
      final existing = await getWaterTrackingByDate(userId, date);
      if (existing != null) {
        return existing;
      }

      // Lấy thông tin sức khỏe để tính target
      final healthInfo = await _getUserHealthInfo(userId);
      double targetAmount = WaterTracking.calculateDailyWaterTarget(
        weight: healthInfo['weight'] ?? 70.0,
        height: healthInfo['height'] ?? 170.0,
        age: healthInfo['age'] ?? 25,
        gender: healthInfo['gender'] ?? 'nam',
        activityLevel: 'moderate',
      );

      final waterTracking = WaterTracking(
        userId: userId,
        date: date,
        targetAmount: targetAmount,
        currentAmount: 0,
        isCompleted: false,
        intakes: [],
        createdAt: now,
        updatedAt: now,
      );

      final collection = _collection;
      if (collection == null) {
        print('❌ Database chưa được kết nối');
        return null;
      }
      
      final result = await collection.insertOne(waterTracking.toMap());
      
      if (result.isSuccess) {
        // Tạo lịch nhắc nhở uống nước
        await _scheduleWaterReminders(userId, targetAmount);
        return waterTracking.copyWith(id: result.id);
      }
      
      return null;
    } catch (e) {
      print('❌ Lỗi tạo water tracking: $e');
      return null;
    }
  }

  // Thêm lượng nước đã uống
  Future<bool> addWaterIntake(int userId, String date, double amount, {String note = ''}) async {
    try {
      final waterTracking = await getWaterTrackingByDate(userId, date);
      if (waterTracking == null) {
        print('❌ Không tìm thấy water tracking cho ngày $date');
        return false;
      }

      final newIntake = WaterIntake(
        amount: amount,
        time: DateTime.now(),
        note: note,
      );

      final updatedIntakes = [...waterTracking.intakes, newIntake];
      final newCurrentAmount = waterTracking.currentAmount + amount;
      final isCompleted = newCurrentAmount >= waterTracking.targetAmount;

      final updatedWaterTracking = waterTracking.copyWith(
        currentAmount: newCurrentAmount,
        isCompleted: isCompleted,
        intakes: updatedIntakes,
        updatedAt: DateTime.now(),
      );

      final collection = _collection;
      if (collection == null) {
        print('❌ Database chưa được kết nối');
        return false;
      }
      
      final result = await collection.replaceOne(
        where.eq('_id', waterTracking.id),
        updatedWaterTracking.toMap(),
      );

      if (result.isSuccess && isCompleted) {
        // Hiển thị thông báo hoàn thành mục tiêu
        await _showCompletionNotification(waterTracking.targetAmount);
      }

      return result.isSuccess;
    } catch (e) {
      print('❌ Lỗi thêm water intake: $e');
      return false;
    }
  }

  // Lấy lịch sử water tracking
  Future<List<WaterTracking>> getWaterTrackingHistory(int userId, {int limit = 30}) async {
    try {
      final collection = _collection;
      if (collection == null) {
        print('❌ Database chưa được kết nối');
        return [];
      }
        final results = await collection
          .find(where.eq('user_id', userId))
          .toList();
      
      // Sort manually by date in descending order
      results.sort((a, b) {
        final dateA = a['date'] as String;
        final dateB = b['date'] as String;
        return dateB.compareTo(dateA);
      });
      
      // Apply limit manually
      final limitedResults = results.take(limit).toList();
      
      return limitedResults.map((result) => WaterTracking.fromMap(result)).toList();
    } catch (e) {
      print('❌ Lỗi lấy lịch sử water tracking: $e');
      return [];
    }
  }

  // Tính water streak
  Future<WaterStreak> getWaterStreak(int userId) async {
    try {
      final history = await getWaterTrackingHistory(userId, limit: 100);
      return WaterStreak.fromList(history);
    } catch (e) {
      print('❌ Lỗi tính water streak: $e');
      return WaterStreak(
        currentStreak: 0,
        longestStreak: 0,
        lastCompletedDate: '',
        recentCompletedDates: [],
      );
    }
  }

  // Xóa water intake
  Future<bool> removeWaterIntake(int userId, String date, int intakeIndex) async {
    try {
      final waterTracking = await getWaterTrackingByDate(userId, date);
      if (waterTracking == null || intakeIndex >= waterTracking.intakes.length) {
        return false;
      }

      final removedIntake = waterTracking.intakes[intakeIndex];
      final updatedIntakes = [...waterTracking.intakes];
      updatedIntakes.removeAt(intakeIndex);

      final newCurrentAmount = waterTracking.currentAmount - removedIntake.amount;
      final isCompleted = newCurrentAmount >= waterTracking.targetAmount;

      final updatedWaterTracking = waterTracking.copyWith(
        currentAmount: newCurrentAmount,
        isCompleted: isCompleted,
        intakes: updatedIntakes,
        updatedAt: DateTime.now(),
      );

      final collection = _collection;
      if (collection == null) {
        print('❌ Database chưa được kết nối');
        return false;
      }
      
      final result = await collection.replaceOne(
        where.eq('_id', waterTracking.id),
        updatedWaterTracking.toMap(),
      );

      return result.isSuccess;
    } catch (e) {
      print('❌ Lỗi xóa water intake: $e');
      return false;
    }
  }

  // Tạo lịch nhắc nhở uống nước
  Future<void> _scheduleWaterReminders(int userId, double targetAmount) async {
    try {
      // Hủy các reminder cũ cho user này
      for (int i = 0; i < 7; i++) {
        await _flutterLocalNotificationsPlugin.cancel(userId * 10 + i);
      }

      // Tính số lần nhắc nhở (mỗi 2 tiếng, từ 7h sáng đến 21h tối)
      final reminderTimes = [
        8, 10, 12, 14, 16, 18, 20, // 8AM, 10AM, 12PM, 2PM, 4PM, 6PM, 8PM
      ];

      final perIntakeAmount = (targetAmount / reminderTimes.length).round();

      for (int i = 0; i < reminderTimes.length; i++) {
        await _flutterLocalNotificationsPlugin.show(
          userId * 10 + i, // Unique ID
          '💧 Đã đến giờ uống nước!',
          'Hãy uống ${perIntakeAmount}ml nước để đạt mục tiêu hôm nay 🎯',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'water_reminder',
              'Nhắc nhở uống nước',
              channelDescription: 'Nhắc nhở uống nước định kỳ',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Lỗi tạo lịch nhắc nhở: $e');
    }
  }

  // Hiển thị thông báo hoàn thành mục tiêu
  Future<void> _showCompletionNotification(double targetAmount) async {
    try {
      await _flutterLocalNotificationsPlugin.show(
        999999, // Unique ID for completion
        '🎉 Chúc mừng!',
        'Bạn đã hoàn thành mục tiêu uống ${(targetAmount/1000).toStringAsFixed(1)}L nước hôm nay! 💪',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_completion',
            'Hoàn thành mục tiêu nước',
            channelDescription: 'Thông báo khi hoàn thành mục tiêu uống nước',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      print('❌ Lỗi hiển thị thông báo hoàn thành: $e');
    }
  }

  // Lấy thông tin sức khỏe của user để tính target
  Future<Map<String, dynamic>> _getUserHealthInfo(int userId) async {
    try {
      final collection = DatabaseConnection.getCollection('health_diary');
      if (collection == null) {
        print('❌ Không thể truy cập collection health_diary');
        return _getDefaultHealthInfo();
      }
      
      final result = await collection.findOne(
        where.eq('user_id', userId).sortBy('entry_date', descending: true)
      );
      
      if (result != null) {
        return {
          'weight': (result['weight'] as num?)?.toDouble() ?? 70.0,
          'height': (result['height'] as num?)?.toDouble() ?? 170.0,
          'age': _calculateAge(result['birth_date'] as String?),
          'gender': _normalizeGender(result['gender'] as String?),
        };
      }
      
      // Thử lấy từ collection users
      final userCollection = DatabaseConnection.getCollection('users');
      if (userCollection != null) {
        final userResult = await userCollection.findOne(where.eq('id_user', userId));
        if (userResult != null) {
          return {
            'weight': 70.0,
            'height': 170.0,
            'age': _calculateAge(userResult['birth_date'] as String?),
            'gender': _normalizeGender(userResult['gender'] as String?),
          };
        }
      }
      
      return _getDefaultHealthInfo();
    } catch (e) {
      print('❌ Lỗi lấy thông tin sức khỏe: $e');
      return _getDefaultHealthInfo();
    }
  }

  // Thông tin sức khỏe mặc định
  Map<String, dynamic> _getDefaultHealthInfo() {
    return {
      'weight': 70.0,
      'height': 170.0,
      'age': 25,
      'gender': 'nam',
    };
  }

  // Chuẩn hóa giới tính
  String _normalizeGender(String? gender) {
    if (gender == null || gender.isEmpty) return 'nam';
    
    final normalized = gender.toLowerCase();
    if (normalized.contains('nữ') || normalized.contains('female') || normalized.contains('woman')) {
      return 'nữ';
    }
    return 'nam';
  }

  // Tính tuổi từ ngày sinh
  int _calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null || dateOfBirth.isEmpty) return 25;
    
    try {
      final parts = dateOfBirth.split('/');
      if (parts.length == 3) {
        final birthDate = DateTime(
          int.parse(parts[2]), // year
          int.parse(parts[1]), // month
          int.parse(parts[0]), // day
        );
        final now = DateTime.now();
        int age = now.year - birthDate.year;
        if (now.month < birthDate.month || 
            (now.month == birthDate.month && now.day < birthDate.day)) {
          age--;
        }
        return age;
      }
    } catch (e) {
      print('❌ Lỗi tính tuổi: $e');
    }
    
    return 25; // Default age
  }

  // Hủy tất cả reminder
  Future<void> cancelAllReminders() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      print('❌ Lỗi hủy reminder: $e');
    }
  }

  // Cập nhật target amount
  Future<bool> updateWaterTarget(int userId, String date, double newTarget) async {
    try {
      final waterTracking = await getWaterTrackingByDate(userId, date);
      if (waterTracking == null) return false;

      final isCompleted = waterTracking.currentAmount >= newTarget;
      
      final updatedWaterTracking = waterTracking.copyWith(
        targetAmount: newTarget,
        isCompleted: isCompleted,
        updatedAt: DateTime.now(),
      );

      final collection = _collection;
      if (collection == null) {
        print('❌ Database chưa được kết nối');
        return false;
      }
      
      final result = await collection.replaceOne(
        where.eq('_id', waterTracking.id),
        updatedWaterTracking.toMap(),
      );

      return result.isSuccess;
    } catch (e) {
      print('❌ Lỗi cập nhật target: $e');
      return false;
    }
  }
}
