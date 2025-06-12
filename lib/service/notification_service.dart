import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Khởi tạo notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      
      // Set local timezone
      final String timeZoneName = 'Asia/Ho_Chi_Minh';
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
      );

      await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      _initialized = true;
      print('✅ NotificationService initialized successfully');
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
      _initialized = false;
    }
  }

  // Xử lý khi user tap vào notification
  static void _onNotificationResponse(NotificationResponse response) {
    try {
      print('Notification tapped: ${response.payload}');
      
      if (response.actionId != null) {
        switch (response.actionId) {
          case 'mark_done':
            print('User marked reminder as done');
            break;
          case 'snooze':
            print('User chose to snooze reminder');
            _handleSnooze(response);
            break;
        }
      }
    } catch (e) {
      print('❌ Error handling notification response: $e');
    }
  }

  static void _handleSnooze(NotificationResponse response) {
    // Implement snooze logic here
    print('Snoozing reminder for 10 minutes');
  }

  // Request permission (Android 13+)
  static Future<bool> requestPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? grantedNotificationPermission =
            await androidImplementation.requestNotificationsPermission();
        final bool? grantedSchedulePermission =
            await androidImplementation.requestExactAlarmsPermission();

        print('Notification permission: $grantedNotificationPermission');
        print('Schedule permission: $grantedSchedulePermission');

        return grantedNotificationPermission == true && 
               grantedSchedulePermission == true;
      }
      return false;
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      return false;
    }
  }

  // Tạo notification channel
  static Future<void> createNotificationChannel() async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'reminder_channel',
        'Nhắc nhở sức khỏe',
        description: 'Kênh thông báo cho các nhắc nhở sức khỏe',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(channel);
      print('✅ Notification channel created successfully');
    } catch (e) {
      print('❌ Error creating notification channel: $e');
    }
  }

  // Hiển thị notification ngay lập tức
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'reminder_channel',
        'Nhắc nhở sức khỏe',
        channelDescription: 'Kênh thông báo cho các nhắc nhở sức khỏe',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Nhắc nhở sức khỏe',
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2196F3),
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      print('✅ Instant notification shown: $title');
    } catch (e) {
      print('❌ Error showing instant notification: $e');
    }
  }

  // Lên lịch notification
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      // Kiểm tra xem thời gian có hợp lệ không
      if (scheduledDate.isBefore(DateTime.now())) {
        print('❌ Cannot schedule notification in the past');
        return;
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'reminder_channel',
        'Nhắc nhở sức khỏe',
        channelDescription: 'Kênh thông báo cho các nhắc nhở sức khỏe',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Nhắc nhở sức khỏe',
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2196F3),
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);
      
      print('📅 Scheduling notification:');
      print('   ID: $id');
      print('   Title: $title');
      print('   Time: $scheduledTZ');

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZ,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      print('✅ Notification scheduled successfully');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
    }
  }

  // Lên lịch notification lặp lại hàng ngày
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay scheduledTime,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'reminder_channel',
        'Nhắc nhở sức khỏe',
        channelDescription: 'Kênh thông báo cho các nhắc nhở sức khỏe',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Nhắc nhở sức khỏe',
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2196F3),
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(scheduledTime),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print('✅ Daily notification scheduled successfully');
    } catch (e) {
      print('❌ Error scheduling daily notification: $e');
    }
  }

  // Tính toán thời gian tiếp theo cho notification
  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Hủy notification theo ID
  static Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      print('✅ Notification $id cancelled successfully');
    } catch (e) {
      print('❌ Error cancelling notification $id: $e');
    }
  }

  // Hủy tất cả notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      print('✅ All notifications cancelled successfully');
    } catch (e) {
      print('❌ Error cancelling all notifications: $e');
    }
  }

  // Lấy danh sách pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      print('❌ Error getting pending notifications: $e');
      return [];
    }
  }

  // Kiểm tra xem notification có được enable không
  static Future<bool> areNotificationsEnabled() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? enabled = await androidImplementation.areNotificationsEnabled();
        return enabled ?? false;
      }
      return false;
    } catch (e) {
      print('❌ Error checking notification status: $e');
      return false;
    }
  }

  // Snooze notification (nhắc lại sau 10 phút)
  static Future<void> snoozeNotification(int originalId, String title, String body) async {
    try {
      // Cancel original notification
      await cancelNotification(originalId);
      
      // Schedule new notification 10 minutes later
      final DateTime snoozeTime = DateTime.now().add(Duration(minutes: 10));
      await scheduleNotification(
        id: originalId,
        title: '🔔 $title (Nhắc lại)',
        body: body,
        scheduledDate: snoozeTime,
      );

      print('✅ Notification snoozed for 10 minutes');
    } catch (e) {
      print('❌ Error snoozing notification: $e');
    }
  }

  // Test notification (để debug)
  static Future<void> testNotification() async {
    try {
      await showInstantNotification(
        id: 999,
        title: '🧪 Test Notification',
        body: 'This is a test notification from HealthKeeper!',
        payload: 'test',
      );
      print('✅ Test notification sent');
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }
}
