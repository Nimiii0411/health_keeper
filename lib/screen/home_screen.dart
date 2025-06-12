import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'account_screen.dart';
import 'diary_screen.dart';
import 'exercise_screen.dart';
import 'reminder_screen.dart';
import 'food_screen.dart';
import 'login_screen.dart';
import '../providers/theme_provider.dart';
import '../service/user_session.dart';
import '../widgets/dashboard_home_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  List<Widget> get _screens => [
    DashboardHomeContent(onNavigate: _navigateToScreen),
    AccountScreen(),
    DiaryScreen(),
    FoodScreen(initialDate: DateTime.now()),
    ExerciseScreen(),
    ReminderScreen(userId: UserSession.currentUserId ?? 1),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Tài Khoản',
    'Nhật Ký',
    'Thực Đơn',
    'Tập Luyện',
    'Nhắc Nhở',
  ];

  void _navigateToScreen(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),      drawer: Drawer(
        backgroundColor: theme.drawerTheme.backgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor.withOpacity(0.8), 
                    theme.primaryColor
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: theme.primaryColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    UserSession.getDisplayName(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    UserSession.getEmail().isNotEmpty 
                        ? UserSession.getEmail()
                        : 'Chào mừng bạn!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),            ListTile(
              leading: Icon(Icons.dashboard, color: theme.primaryColor),
              title: Text('Dashboard'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.account_circle, color: Colors.orange),
              title: Text('Tài Khoản'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.book, color: Colors.green),
              title: Text('Nhật Ký'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.restaurant_menu, color: Colors.amber),
              title: Text('Thực Đơn'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.fitness_center, color: Colors.purple),
              title: Text('Tập Luyện'),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() {
                  _selectedIndex = 4;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications, color: Colors.red),
              title: Text('Nhắc Nhở'),
              selected: _selectedIndex == 5,
              onTap: () {
                setState(() {
                  _selectedIndex = 5;
                });
                Navigator.pop(context);
              },
            ),
            Divider(),            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  title: Text('Chế độ tối'),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                    activeColor: theme.primaryColor,
                  ),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Đăng Xuất',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận đăng xuất'),
          content: Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'),
          actions: [
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Đăng xuất'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog first
                _performLogout(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _performLogout(BuildContext context) async {
    try {
      // Clear user session
      UserSession.logout();
      
      // Navigate to login screen and clear the entire navigation stack
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print('❌ Lỗi khi đăng xuất: $e');
      // Fallback: force navigate to login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }
}
