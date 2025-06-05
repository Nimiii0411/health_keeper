import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/notification_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/theme_toggle.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  List<Reminder> reminders = [
    Reminder(
      id: 1,
      title: 'Uống thuốc',
      description: 'Uống thuốc huyết áp',
      time: TimeOfDay(hour: 8, minute: 0),
      isActive: true,
      type: ReminderType.medicine,
    ),
    Reminder(
      id: 2,
      title: 'Tập thể dục',
      description: 'Chạy bộ buổi sáng',
      time: TimeOfDay(hour: 6, minute: 30),
      isActive: true,
      type: ReminderType.exercise,
    ),
    Reminder(
      id: 3,
      title: 'Khám bác sĩ',
      description: 'Khám tim mạch định kỳ',
      time: TimeOfDay(hour: 14, minute: 0),
      isActive: false,
      type: ReminderType.doctor,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scheduleActiveReminders();
  }

  void _scheduleActiveReminders() {
    for (var reminder in reminders) {
      if (reminder.isActive) {
        _scheduleNotification(reminder);
      }
    }
  }

  void _scheduleNotification(Reminder reminder) async {
    // Tạo DateTime cho ngày hôm nay với thời gian từ reminder
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      reminder.time.hour,
      reminder.time.minute,
    );

    // Nếu thời gian đã qua trong ngày hôm nay, lên lịch cho ngày mai
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(Duration(days: 1));
    }

    await NotificationService.scheduleNotification(
      id: reminder.id,
      title: reminder.title,
      body: reminder.description,
      scheduledDate: scheduledDate,
    );
  }

  void _cancelNotification(int id) async {
    await NotificationService.cancelNotification(id);
  }

  void _toggleReminder(Reminder reminder) async {
    setState(() {
      reminder.isActive = !reminder.isActive;
    });

    if (reminder.isActive) {
      _scheduleNotification(reminder);
    } else {
      _cancelNotification(reminder.id);
    }
  }

  int _generateReminderId() {
    return reminders.isEmpty ? 1 : reminders.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: themeProvider.isDarkMode
                ? [Colors.grey[900]!, Colors.grey[800]!]
                : [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nhắc nhở của bạn',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  ThemeToggleButton(),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      elevation: themeProvider.isDarkMode ? 8 : 4,
                      color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getReminderColor(reminder.type),
                          child: Icon(
                            _getReminderIcon(reminder.type),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          reminder.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reminder.description,
                              style: TextStyle(
                                color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${reminder.time.hour.toString().padLeft(2, '0')}:${reminder.time.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Switch(
                          value: reminder.isActive,
                          onChanged: (value) {
                            _toggleReminder(reminder);
                          },
                        ),
                        onTap: () => _showEditReminderDialog(reminder, index),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminderDialog(),
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
      ),
    );
  }

  Color _getReminderColor(ReminderType type) {
    switch (type) {
      case ReminderType.medicine:
        return Colors.red;
      case ReminderType.exercise:
        return Colors.green;
      case ReminderType.doctor:
        return Colors.blue;
      case ReminderType.other:
        return Colors.orange;
    }
  }

  IconData _getReminderIcon(ReminderType type) {
    switch (type) {
      case ReminderType.medicine:
        return Icons.medication;
      case ReminderType.exercise:
        return Icons.fitness_center;
      case ReminderType.doctor:
        return Icons.local_hospital;
      case ReminderType.other:
        return Icons.notifications;
    }
  }

  void _showAddReminderDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    ReminderType selectedType = ReminderType.other;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Thêm nhắc nhở mới'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Mô tả',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<ReminderType>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Loại nhắc nhở',
                        border: OutlineInputBorder(),
                      ),
                      items: ReminderType.values
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(_getReminderTypeName(type)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text('Thời gian'),
                      subtitle: Text(
                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setState(() {
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
                  child: Text('Hủy'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Thêm'),
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final newReminder = Reminder(
                        id: _generateReminderId(),
                        title: titleController.text,
                        description: descriptionController.text,
                        time: selectedTime,
                        isActive: true,
                        type: selectedType,
                      );
                      setState(() {
                        reminders.add(newReminder);
                      });
                      // Schedule notification for new active reminder
                      if (newReminder.isActive) {
                        _scheduleNotification(newReminder);
                      }
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  void _showEditReminderDialog(Reminder reminder, int index) {
    final titleController = TextEditingController(text: reminder.title);
    final descriptionController = TextEditingController(text: reminder.description);
    TimeOfDay selectedTime = reminder.time;
    ReminderType selectedType = reminder.type;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Chỉnh sửa nhắc nhở'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Mô tả',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<ReminderType>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Loại nhắc nhở',
                        border: OutlineInputBorder(),
                      ),
                      items: ReminderType.values
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(_getReminderTypeName(type)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text('Thời gian'),
                      subtitle: Text(
                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setState(() {
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
                  child: Text('Xóa', style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    // Cancel notification before deleting
                    _cancelNotification(reminder.id);
                    setState(() {
                      reminders.removeAt(index);
                    });
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Hủy'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Lưu'),
                  onPressed: () {
                    // Cancel existing notification
                    _cancelNotification(reminder.id);
                    
                    // Update reminder
                    final updatedReminder = Reminder(
                      id: reminder.id,
                      title: titleController.text,
                      description: descriptionController.text,
                      time: selectedTime,
                      isActive: reminder.isActive,
                      type: selectedType,
                    );
                    
                    setState(() {
                      reminders[index] = updatedReminder;
                    });
                    
                    // Schedule notification if active
                    if (updatedReminder.isActive) {
                      _scheduleNotification(updatedReminder);
                    }
                    
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  String _getReminderTypeName(ReminderType type) {
    switch (type) {
      case ReminderType.medicine:
        return 'Thuốc';
      case ReminderType.exercise:
        return 'Tập luyện';
      case ReminderType.doctor:
        return 'Bác sĩ';
      case ReminderType.other:
        return 'Khác';
    }
  }
}

class Reminder {
  int id;
  String title;
  String description;
  TimeOfDay time;
  bool isActive;
  ReminderType type;

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.isActive,
    required this.type,
  });
}

enum ReminderType {
  medicine,
  exercise,
  doctor,
  other,
}
