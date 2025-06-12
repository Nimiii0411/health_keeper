import 'package:flutter/material.dart';
import '../service/user_session.dart';
import '../service/health_diary_service.dart';
import '../service/food_service.dart';
import '../service/exercise_service.dart';
import '../service/reminder_goal_service.dart';
import '../models/health_diary_model.dart';
import '../screen/food_screen.dart';

class EnhancedHomeContent extends StatefulWidget {
  final Function(int) onNavigate;

  const EnhancedHomeContent({super.key, required this.onNavigate});

  @override
  _EnhancedHomeContentState createState() => _EnhancedHomeContentState();
}

class _EnhancedHomeContentState extends State<EnhancedHomeContent> {
  HealthDiary? todayHealthData;
  HealthDiary? latestHealthData; // Thêm dữ liệu sức khỏe mới nhất
  int todayCaloriesConsumed = 0;
  int todayCaloriesBurned = 0;
  int activeReminders = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  // Helper method để parse ngày từ string
  DateTime _parseDate(String dateStr) {
    try {
      // Format: dd/MM/yyyy
      List<String> parts = dateStr.split('/');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('❌ Lỗi parse date: $e');
    }
    return DateTime.now(); // Fallback
  }

  Future<void> _loadTodayData() async {
    if (!UserSession.hasAccess()) return;

    final userId = UserSession.currentUserId!;
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";    try {
      // Load today's health diary
      final healthDiary = await HealthDiaryService.getHealthDiaryByDate(userId, todayStr);
      
      // Load latest health data (cân nặng và chiều cao mới nhất)
      final userHealthHistory = await HealthDiaryService.getUserHealthDiary(userId);
      HealthDiary? latestHealth;
      if (userHealthHistory.isNotEmpty) {
        // Sắp xếp theo ngày mới nhất
        userHealthHistory.sort((a, b) {
          DateTime dateA = _parseDate(a.entryDate);
          DateTime dateB = _parseDate(b.entryDate);
          return dateB.compareTo(dateA);
        });
        latestHealth = userHealthHistory.first;
      }
      
      // Load today's calories consumed
      final caloriesConsumed = await FoodService.getTotalCaloriesForDate(userId, todayStr);
      
      // Load today's calories burned
      final caloriesBurned = await ExerciseService.getTotalCaloriesBurnedForDate(userId, todayStr);
      
      // Load active reminders count
      final reminders = await ReminderService.getActiveReminders(userId);

      setState(() {
        todayHealthData = healthDiary;
        latestHealthData = latestHealth;
        todayCaloriesConsumed = caloriesConsumed;
        todayCaloriesBurned = caloriesBurned;
        activeReminders = reminders.length;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Lỗi khi load dữ liệu home: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadTodayData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chào ${UserSession.getDisplayName()}!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Hôm nay bạn thế nào?',
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

            // Today's Summary
            Text(
              'Tóm tắt hôm nay',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            if (isLoading)
              Center(child: CircularProgressIndicator())
            else
              _buildTodaySummary(),

            SizedBox(height: 20),

            // Quick Actions
            Text(
              'Chức năng nhanh',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }
  Widget _buildTodaySummary() {
    // Sử dụng dữ liệu mới nhất cho cân nặng, chiều cao và BMI
    final displayData = latestHealthData ?? todayHealthData;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Cân nặng',
                displayData?.weight.toString() ?? '--',
                'kg',
                Icons.monitor_weight,
                Colors.blue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Chiều cao',
                displayData?.height.toString() ?? '--',
                'cm',
                Icons.height,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'BMI',
                displayData?.bmi?.toStringAsFixed(1) ?? '--',
                displayData?.bmiLabel ?? '',
                Icons.analytics,
                _getBMIColor(displayData?.bmiLabel),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Ngày cập nhật',
                displayData?.entryDate ?? '--',
                '',
                Icons.calendar_today,
                Colors.purple,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Calories nạp',
                todayCaloriesConsumed.toString(),
                'kcal',
                Icons.restaurant,
                Colors.orange,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Calories đốt',
                todayCaloriesBurned.toString(),
                'kcal',
                Icons.local_fire_department,
                Colors.red,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Nhắc nhở',
                activeReminders.toString(),
                'hoạt động',
                Icons.notifications_active,
                Colors.purple,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Cân bằng',
                (todayCaloriesConsumed - todayCaloriesBurned).toString(),
                'kcal',
                Icons.balance,
                _getBalanceColor(todayCaloriesConsumed - todayCaloriesBurned),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: [
        _buildQuickActionCard(
          icon: Icons.account_circle,
          title: 'Tài Khoản',
          color: Colors.orange,
          onTap: () => widget.onNavigate(1),
        ),
        _buildQuickActionCard(
          icon: Icons.book,
          title: 'Nhật Ký',
          color: Colors.green,
          onTap: () => widget.onNavigate(2),
        ),
        _buildQuickActionCard(
          icon: Icons.restaurant_menu,
          title: 'Thực Đơn',
          color: Colors.teal,
          onTap: () => _navigateToFoodScreen(),
        ),
        _buildQuickActionCard(
          icon: Icons.fitness_center,
          title: 'Tập Luyện',
          color: Colors.purple,
          onTap: () => widget.onNavigate(3),
        ),
        _buildQuickActionCard(
          icon: Icons.notifications,
          title: 'Nhắc Nhở',
          color: Colors.red,
          onTap: () => widget.onNavigate(4),
        ),
      ],
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

  Color _getBMIColor(String? bmiLabel) {
    switch (bmiLabel) {
      case 'Thiếu cân':
        return Colors.blue;
      case 'Bình thường':
        return Colors.green;
      case 'Thừa cân':
        return Colors.orange;
      case 'Béo phì':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getBalanceColor(int balance) {
    if (balance > 500) return Colors.red;
    if (balance > 0) return Colors.orange;
    if (balance > -500) return Colors.green;
    return Colors.blue;
  }

  // Method để navigate đến food screen
  void _navigateToFoodScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodScreen(),
      ),
    );
  }
}
