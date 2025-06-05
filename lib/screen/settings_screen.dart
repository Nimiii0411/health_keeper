import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'notification_test_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cài đặt'),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Theme Settings Section
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Giao diện',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            color: Colors.blue,
                          ),
                          title: Text('Chế độ tối'),
                          subtitle: Text(
                            themeProvider.isDarkMode 
                              ? 'Đang sử dụng chế độ tối' 
                              : 'Đang sử dụng chế độ sáng',
                          ),
                          trailing: Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (value) {
                              themeProvider.toggleTheme();
                            },
                            activeColor: Colors.blue,
                          ),
                        ),
                        Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.palette, color: Colors.blue),
                          title: Text('Chủ đề'),
                          subtitle: Text('Tùy chỉnh màu sắc'),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            _showThemeOptions(context);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // App Settings Section
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Ứng dụng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),                ListTile(
                  leading: Icon(Icons.notifications, color: Colors.orange),
                  title: Text('Thông báo'),
                  subtitle: Text('Quản lý thông báo'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NotificationTestScreen()),
                    );
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.language, color: Colors.green),
                  title: Text('Ngôn ngữ'),
                  subtitle: Text('Tiếng Việt'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to language settings
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.storage, color: Colors.purple),
                  title: Text('Dữ liệu'),
                  subtitle: Text('Quản lý dữ liệu ứng dụng'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showDataOptions(context);
                  },
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // About Section
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Thông tin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.info, color: Colors.blue),
                  title: Text('Về ứng dụng'),
                  subtitle: Text('HealthKeeper v1.0.0'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.help, color: Colors.teal),
                  title: Text('Trợ giúp'),
                  subtitle: Text('Hướng dẫn sử dụng'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to help screen
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.feedback, color: Colors.amber),
                  title: Text('Phản hồi'),
                  subtitle: Text('Gửi ý kiến đóng góp'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to feedback screen
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn chủ đề',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.light_mode),
                        title: Text('Chế độ sáng'),
                        trailing: themeProvider.isDarkMode ? null : Icon(Icons.check),
                        onTap: () {
                          if (themeProvider.isDarkMode) {
                            themeProvider.toggleTheme();
                          }
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.dark_mode),
                        title: Text('Chế độ tối'),
                        trailing: themeProvider.isDarkMode ? Icon(Icons.check) : null,
                        onTap: () {
                          if (!themeProvider.isDarkMode) {
                            themeProvider.toggleTheme();
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDataOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Quản lý dữ liệu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.backup),
                title: Text('Sao lưu dữ liệu'),
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar(context, 'Đang sao lưu dữ liệu...');
                },
              ),
              ListTile(
                leading: Icon(Icons.restore),
                title: Text('Khôi phục dữ liệu'),
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar(context, 'Đang khôi phục dữ liệu...');
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red),
                title: Text('Xóa tất cả dữ liệu', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa tất cả dữ liệu? Hành động này không thể hoàn tác.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showSnackBar(context, 'Đã xóa tất cả dữ liệu');
              },
              child: Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'HealthKeeper',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(Icons.health_and_safety, size: 48, color: Colors.blue),
      children: [
        Text('Ứng dụng quản lý sức khỏe cá nhân'),
        SizedBox(height: 8),
        Text('Phát triển bởi KunN21'),
        Text('© 2025 HealthKeeper'),
      ],
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
