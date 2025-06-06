import 'package:flutter/material.dart';
import 'user_manage.dart';
import 'food_manage.dart';
import 'exercise_manage.dart';
// import 'meal_manage.dart'; // Nếu bạn muốn thêm quản lý meal daily

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildDashboardCard(
              context,
              'Quản lý người dùng',
              Icons.people,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserManageScreen()),
              ),
            ),
            _buildDashboardCard(
              context,
              'Quản lý thực phẩm',
              Icons.restaurant,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FoodManageScreen()),
              ),
            ),
            _buildDashboardCard(
              context,
              'Quản lý bài tập',
              Icons.fitness_center,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ExerciseManageScreen()),
              ),
            ),
            _buildDashboardCard(
              context,
              'Thống kê',
              Icons.analytics,
              Colors.purple,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chức năng đang phát triển')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}