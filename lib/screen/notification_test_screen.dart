import 'package:flutter/material.dart';
import '../service/notification_service.dart';

class NotificationTestScreen extends StatelessWidget {
  const NotificationTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Notifications'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '🔔 Notification Test Dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 32),
            
            // Test Instant Notification
            ElevatedButton.icon(
              onPressed: () async {
                await NotificationService.showInstantNotification(
                  id: 999,
                  title: '🎉 Test Instant Notification',
                  body: 'Đây là notification test ngay lập tức!',
                  payload: 'instant_test',
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Instant notification sent!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: Icon(Icons.notifications_active),
              label: Text('Test Instant Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Test Scheduled Notification (5 seconds)
            ElevatedButton.icon(
              onPressed: () async {
                final scheduledTime = DateTime.now().add(Duration(seconds: 5));
                
                await NotificationService.scheduleNotification(
                  id: 998,
                  title: '⏰ Test Scheduled Notification',
                  body: 'Notification này được lên lịch sau 5 giây!',
                  scheduledDate: scheduledTime,
                  payload: 'scheduled_test',
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⏰ Notification scheduled for 5 seconds!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              icon: Icon(Icons.schedule),
              label: Text('Test Scheduled (5s)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Test Daily Notification
            ElevatedButton.icon(
              onPressed: () async {
                final now = TimeOfDay.now();
                final testTime = TimeOfDay(
                  hour: now.hour,
                  minute: now.minute + 1, // 1 minute from now
                );
                
                await NotificationService.scheduleDailyNotification(
                  id: 997,
                  title: '📅 Test Daily Notification',
                  body: 'Đây là notification lặp lại hàng ngày!',
                  scheduledTime: testTime,
                  payload: 'daily_test',
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📅 Daily notification scheduled!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              icon: Icon(Icons.repeat),
              label: Text('Test Daily Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Test Schedule Notification (5 seconds)
            ElevatedButton.icon(
              onPressed: () async {
                DateTime scheduleTime = DateTime.now().add(Duration(seconds: 5));
                await NotificationService.scheduleNotification(
                  id: 888,
                  title: '⏰ Test Schedule Notification',
                  body: 'Notification này được lên lịch 5 giây trước!',
                  scheduledDate: scheduleTime,
                  payload: 'schedule_test',
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Notification scheduled for 5 seconds!'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              icon: Icon(Icons.schedule),
              label: Text('Test Schedule (5s)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 16),
            
            // Test Permission Check
            ElevatedButton.icon(
              onPressed: () async {
                bool enabled = await NotificationService.areNotificationsEnabled();
                bool permissionGranted = await NotificationService.requestPermissions();
                
                String message = 'Notifications enabled: $enabled\nPermissions granted: $permissionGranted';
                
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('🔍 Permission Status'),
                    content: Text(message),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.security),
              label: Text('Check Permissions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 16),
            
            // Show Pending Notifications
            ElevatedButton.icon(
              onPressed: () async {
                var pending = await NotificationService.getPendingNotifications();
                
                String message = pending.isEmpty 
                  ? 'Không có notification nào đang pending'
                  : 'Pending notifications:\n${pending.map((n) => '• ID: ${n.id}, Title: ${n.title}').join('\n')}';
                
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('📋 Pending Notifications'),
                    content: Text(message),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.list),
              label: Text('Show Pending'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 16),
            
            // Cancel All Notifications
            ElevatedButton.icon(
              onPressed: () async {
                await NotificationService.cancelAllNotifications();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🗑️ All notifications cancelled!'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              icon: Icon(Icons.clear_all),
              label: Text('Cancel All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            SizedBox(height: 32),
            
            // Cancel All Test Notifications
            ElevatedButton.icon(
              onPressed: () async {
                await NotificationService.cancelNotification(999);
                await NotificationService.cancelNotification(998);
                await NotificationService.cancelNotification(997);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🗑️ All test notifications cancelled!'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              icon: Icon(Icons.cancel),
              label: Text('Cancel All Test Notifications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            SizedBox(height: 32),
            
            // Check Pending Notifications
            ElevatedButton.icon(
              onPressed: () async {
                final pendingNotifications = 
                    await NotificationService.getPendingNotifications();
                
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('📋 Pending Notifications'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total: ${pendingNotifications.length}'),
                        SizedBox(height: 8),
                        if (pendingNotifications.isNotEmpty)
                          ...pendingNotifications.map((notification) => 
                            Text('• ID: ${notification.id} - ${notification.title}'))
                        else
                          Text('No pending notifications'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.list),
              label: Text('Check Pending Notifications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            Spacer(),
            
            // Instructions
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📖 Hướng dẫn Test:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('1. Test Instant: Notification xuất hiện ngay'),
                  Text('2. Test Scheduled: Đợi 5 giây để thấy notification'),
                  Text('3. Test Daily: Notification sẽ lặp lại hàng ngày'),
                  Text('4. Check Pending: Xem danh sách notifications đã đặt'),
                  Text('5. Cancel All: Hủy tất cả test notifications'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
