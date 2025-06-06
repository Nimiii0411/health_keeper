import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'account_screen.dart';
import 'diary_screen.dart';
import 'exercise_screen.dart';
import 'reminder_screen.dart';
import 'login_screen.dart';
import '../providers/theme_provider.dart';
import '../service/user_session.dart';
import '../widgets/enhanced_home_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {  int _selectedIndex = 0;
    List<Widget> get _screens => [
    EnhancedHomeContent(onNavigate: _navigateToScreen),
    AccountScreen(),
    DiaryScreen(),
    ExerciseScreen(),
    ReminderScreen(userId: UserSession.currentUserId ?? 1),
  ];

  final List<String> _titles = [
    'Trang Chủ',
    'Tài Khoản',
    'Nhật Ký',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
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
                      color: Colors.blue,
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
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Trang Chủ'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
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
              leading: Icon(Icons.book),
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
              leading: Icon(Icons.fitness_center),
              title: Text('Tập Luyện'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Nhắc Nhở'),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() {
                  _selectedIndex = 4;
                });
                Navigator.pop(context);
              },            ),
            Divider(),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  ),
                  title: Text('Chế độ tối'),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                    activeColor: Colors.blue,
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
          actions: [            TextButton(
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

class HomeContent extends StatelessWidget {
  final Function(int) onNavigate;

  const HomeContent({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chào mừng đến với HealthKeeper!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Theo dõi sức khỏe của bạn mỗi ngày',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Chức năng nhanh',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildQuickActionCard(
                  icon: Icons.account_circle,
                  title: 'Tài Khoản',
                  color: Colors.orange,
                  onTap: () => onNavigate(1),
                ),
                _buildQuickActionCard(
                  icon: Icons.book,
                  title: 'Nhật Ký',
                  color: Colors.green,
                  onTap: () => onNavigate(2),
                ),
                _buildQuickActionCard(
                  icon: Icons.fitness_center,
                  title: 'Tập Luyện',
                  color: Colors.purple,
                  onTap: () => onNavigate(3),
                ),
                _buildQuickActionCard(
                  icon: Icons.notifications,
                  title: 'Nhắc Nhở',
                  color: Colors.red,
                  onTap: () => onNavigate(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
