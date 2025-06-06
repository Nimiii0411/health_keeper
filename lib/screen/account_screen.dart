import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../service/user_session.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  void _refreshUserData() {
    setState(() {
      // Trigger rebuild to get updated user data
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = UserSession.currentUser;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  UserSession.getDisplayName(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  UserSession.getEmail(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                if (currentUser != null) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          currentUser.gender == 'Nam' 
                              ? Icons.male 
                              : currentUser.gender == 'Nữ'
                                  ? Icons.female
                                  : Icons.person,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          currentUser.gender,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        if (currentUser.birthDate.isNotEmpty) ...[
                          SizedBox(width: 12),
                          Icon(
                            Icons.cake,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            currentUser.birthDate,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 24),
          
          // Quick Stats (you can expand this later with real data)
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.favorite,
                  title: 'Sức khỏe',
                  value: 'Tốt',
                  color: Colors.red,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.fitness_center,
                  title: 'Hoạt động',
                  value: 'Hôm nay',
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star,
                  title: 'Mục tiêu',
                  value: '80%',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Account Settings
          Card(
            child: Column(
              children: [                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Chỉnh sửa thông tin'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfileScreen()),
                    );
                    
                    // Nếu có kết quả trả về (cập nhật thành công), refresh data
                    if (result == true) {
                      _refreshUserData();
                    }
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Đổi mật khẩu'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
                    );
                  },
                ),
                Divider(height: 1),                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Cài đặt'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    );
                  },
                ),
                Divider(height: 1),
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
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.help),
                  title: Text('Trợ giúp'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to help
                  },
                ),
              ],
            ),
          ),
        ],      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
