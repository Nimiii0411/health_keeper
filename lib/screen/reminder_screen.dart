import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reminder_model.dart';
import '../service/reminder_service.dart';
import '../service/notification_service.dart';
import '../providers/theme_provider.dart';

class ReminderScreen extends StatefulWidget {
  final int userId;
  
  const ReminderScreen({super.key, required this.userId});

  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  List<Reminder> reminders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }
  Future<void> _loadReminders() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Lấy TẤT CẢ reminders của user (cả active và inactive)
      final userReminders = await ReminderService.getUserReminders(widget.userId);
      setState(() {
        reminders = userReminders;
        isLoading = false;
      });
      
      // Lên lịch thông báo cho các reminder active
      _scheduleActiveReminders();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('❌ Lỗi tải reminders: $e');
    }
  }

  void _scheduleActiveReminders() {
    for (var reminder in reminders) {
      if (reminder.isActive && reminder.isFuture) {
        _scheduleNotification(reminder);
      }
    }
  }

  Future<void> _scheduleNotification(Reminder reminder) async {
    try {
      await NotificationService.scheduleNotification(
        id: reminder.id.hashCode,
        title: 'Nhắc nhở HealthKeeper',
        body: reminder.message,
        scheduledDate: reminder.fullDateTime,
      );
    } catch (e) {
      print('❌ Lỗi lên lịch thông báo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nhắc nhở',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: isDark ? Color(0xFF2D2D44) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      backgroundColor: isDark ? Color(0xFF1A1A2E) : Color(0xFFF5F7FA),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? Colors.white : Color(0xFF667eea),
              ),
            )
          : reminders.isEmpty
              ? _buildEmptyState(isDark)
              : _buildReminderList(isDark),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminderDialog(),
        backgroundColor: Color(0xFF667eea),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Chưa có nhắc nhở nào',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Thêm nhắc nhở để không bỏ lỡ\ncác hoạt động quan trọng',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddReminderDialog(),
            icon: Icon(Icons.add),
            label: Text('Thêm nhắc nhở đầu tiên'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderList(bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: isDark ? 8 : 4,
          color: isDark ? Color(0xFF2D2D44) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: reminder.isActive 
                    ? Color(0xFF667eea).withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications,
                color: reminder.isActive ? Color(0xFF667eea) : Colors.grey,
              ),
            ),            title: Text(
              reminder.message,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: reminder.isActive 
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.white54 : Colors.grey),
                decoration: reminder.isActive ? null : TextDecoration.lineThrough,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  '${reminder.formattedDate} lúc ${reminder.formattedTime}',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),                if (reminder.isToday)
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Hôm nay',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (!reminder.isActive)
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Tạm dừng',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditReminderDialog(reminder);
                    break;
                  case 'delete':
                    _deleteReminder(reminder);
                    break;
                  case 'toggle':
                    _toggleReminderStatus(reminder);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Chỉnh sửa'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        reminder.isActive ? Icons.pause : Icons.play_arrow,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(reminder.isActive ? 'Tạm dừng' : 'Kích hoạt'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddReminderDialog() {
    final messageController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Thêm nhắc nhở mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    labelText: 'Nội dung nhắc nhở',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                ListTile(
                  title: Text('Ngày'),
                  subtitle: Text(
                    "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                  ),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
                ListTile(
                  title: Text('Thời gian'),
                  subtitle: Text(selectedTime.format(context)),
                  trailing: Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() {
                        selectedTime = time;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (messageController.text.isNotEmpty) {
                  final reminder = Reminder(
                    userId: widget.userId,
                    message: messageController.text,
                    reminderDate: selectedDate,
                    remindTime: "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
                  );                  final success = await ReminderService.createReminder(reminder);
                  if (success) {
                    if (mounted) {
                      Navigator.pop(context);
                      _loadReminders();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã thêm nhắc nhở thành công!')),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi thêm nhắc nhở!')),
                      );
                    }
                  }
                }
              },
              child: Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditReminderDialog(Reminder reminder) {
    final messageController = TextEditingController(text: reminder.message);
    DateTime selectedDate = reminder.reminderDate;
    final timeParts = reminder.remindTime.split(':');
    TimeOfDay selectedTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Chỉnh sửa nhắc nhở'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    labelText: 'Nội dung nhắc nhở',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                ListTile(
                  title: Text('Ngày'),
                  subtitle: Text(
                    "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                  ),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
                ListTile(
                  title: Text('Thời gian'),
                  subtitle: Text(selectedTime.format(context)),
                  trailing: Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() {
                        selectedTime = time;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (messageController.text.isNotEmpty) {
                  final updatedReminder = reminder.copyWith(
                    message: messageController.text,
                    reminderDate: selectedDate,
                    remindTime: "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
                  );                  final success = await ReminderService.updateReminder(
                    reminder.id!,
                    updatedReminder,
                  );
                  
                  if (success) {
                    if (mounted) {
                      Navigator.pop(context);
                      _loadReminders();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã cập nhật nhắc nhở thành công!')),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi cập nhật nhắc nhở!')),
                      );
                    }
                  }
                }
              },
              child: Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa nhắc nhở này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Xóa'),
          ),
        ],
      ),
    );    if (confirmed == true) {
      final success = await ReminderService.deleteReminder(reminder.id!);
      if (success) {
        _loadReminders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã xóa nhắc nhở thành công!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa nhắc nhở!')),
          );
        }
      }
    }
  }

  Future<void> _toggleReminderStatus(Reminder reminder) async {
    final updatedReminder = reminder.copyWith(isActive: !reminder.isActive);
    final success = await ReminderService.updateReminder(
      reminder.id!,
      updatedReminder,    );
    
    if (success) {
      _loadReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reminder.isActive 
                  ? 'Đã tạm dừng nhắc nhở' 
                  : 'Đã kích hoạt nhắc nhở',
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật trạng thái nhắc nhở!')),
        );
      }
    }
  }
}
