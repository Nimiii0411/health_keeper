import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../service/health_diary_service.dart';
import '../service/user_session.dart';
import '../service/meal_plan_service.dart';
import '../models/health_diary_model.dart';
import '../models/daily_meal_model.dart';
import 'food_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  _DiaryScreenState createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<HealthDiary> healthEntries = [];
  bool isLoading = true;
  bool hasTodayEntry = false;

  @override
  void initState() {
    super.initState();
    _loadHealthDiary();
  }

  Future<void> _loadHealthDiary() async {
    if (!UserSession.hasAccess()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final userId = UserSession.currentUserId!;
      final entries = await HealthDiaryService.getUserHealthDiary(userId);
      
      // Sắp xếp theo ngày mới nhất
      entries.sort((a, b) {
        DateTime dateA = _parseDate(a.entryDate);
        DateTime dateB = _parseDate(b.entryDate);
        return dateB.compareTo(dateA);
      });

      // Kiểm tra xem hôm nay đã có entry chưa
      final today = _formatDate(DateTime.now());
      bool todayExists = entries.any((entry) => entry.entryDate == today);

      setState(() {
        healthEntries = entries;
        hasTodayEntry = todayExists;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Lỗi khi load health diary: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper method để parse ngày từ string
  DateTime _parseDate(String dateStr) {
    try {
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
    return DateTime.now();
  }

  // Helper method để format ngày thành string
  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      body: Column(
        children: [
          // Header với background gradient
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                  ? [Colors.grey.shade800, Colors.grey.shade700]
                  : [Colors.blue.shade50, Colors.blue.shade100],
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.book,
                  size: 24,
                  color: isDark ? Colors.blue.shade300 : Colors.blue,
                ),
                SizedBox(width: 8),
                Text(
                  'Nhật ký sức khỏe',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                ),
              ],
            ),
          ),
            // Nội dung chính
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : healthEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 64,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Chưa có nhật ký nào',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Thêm nhật ký sức khỏe đầu tiên của bạn!',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey[500] : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: healthEntries.length,
                        itemBuilder: (context, index) {
                          final entry = healthEntries[index];
                          return _buildHealthEntryCard(entry, isDark);
                        },
                      ),
          ),        ],
      ),
      floatingActionButton: !hasTodayEntry ? FloatingActionButton(
        onPressed: () => _showAddEntryDialog(),
        tooltip: 'Thêm nhật ký hôm nay',
        child: Icon(Icons.add),
      ) : null,
    );
  }
  // Dialog thêm entry mới (chỉ cho ngày hôm nay)
  void _showAddEntryDialog() {
    final weightController = TextEditingController();
    final heightController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Thêm nhật ký hôm nay'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: weightController,
                  decoration: InputDecoration(
                    labelText: 'Cân nặng (kg)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monitor_weight),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: heightController,
                  decoration: InputDecoration(
                    labelText: 'Chiều cao (cm)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.height),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú (tùy chọn)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Thêm'),
              onPressed: () => _saveNewEntry(
                weightController.text,
                heightController.text,
                contentController.text,
              ),
            ),
          ],
        );
      },
    );
  }

  // Dialog chỉnh sửa entry (chỉ weight và height)
  void _showEditEntryDialog(HealthDiary entry) {
    final weightController = TextEditingController(text: entry.weight.toString());
    final heightController = TextEditingController(text: entry.height.toString());
    final contentController = TextEditingController(text: entry.content ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chỉnh sửa nhật ký ${entry.entryDate}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: weightController,
                  decoration: InputDecoration(
                    labelText: 'Cân nặng (kg)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monitor_weight),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: heightController,
                  decoration: InputDecoration(
                    labelText: 'Chiều cao (cm)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.height),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú (tùy chọn)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Lưu'),
              onPressed: () => _updateEntry(
                entry,
                weightController.text,
                heightController.text,
                contentController.text,
              ),
            ),
          ],
        );
      },
    );
  }

  // Lưu entry mới
  Future<void> _saveNewEntry(String weight, String height, String content) async {
    if (weight.isEmpty || height.isEmpty) {
      _showErrorDialog('Vui lòng nhập đầy đủ cân nặng và chiều cao');
      return;
    }

    try {
      final weightValue = double.parse(weight);
      final heightValue = double.parse(height);
      
      if (weightValue <= 0 || heightValue <= 0) {
        _showErrorDialog('Cân nặng và chiều cao phải lớn hơn 0');
        return;
      }

      final userId = UserSession.currentUserId!;
      final today = _formatDate(DateTime.now());
      
      final newEntry = HealthDiary(
        userId: userId,
        entryDate: today,
        weight: weightValue,
        height: heightValue,
        content: content.isNotEmpty ? content : null,
      );

      // Tính BMI
      newEntry.bmi = newEntry.calculateBMI();
      newEntry.bmiLabel = _getBMILabel(newEntry.bmi!);

      await HealthDiaryService.addHealthEntry(newEntry);
      
      Navigator.of(context).pop();
      _loadHealthDiary(); // Reload data
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm nhật ký thành công!')),
      );
    } catch (e) {
      _showErrorDialog('Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.');
    }
  }

  // Cập nhật entry
  Future<void> _updateEntry(HealthDiary entry, String weight, String height, String content) async {
    if (weight.isEmpty || height.isEmpty) {
      _showErrorDialog('Vui lòng nhập đầy đủ cân nặng và chiều cao');
      return;
    }

    try {
      final weightValue = double.parse(weight);
      final heightValue = double.parse(height);
      
      if (weightValue <= 0 || heightValue <= 0) {
        _showErrorDialog('Cân nặng và chiều cao phải lớn hơn 0');
        return;
      }

      entry.weight = weightValue;
      entry.height = heightValue;
      entry.content = content.isNotEmpty ? content : null;
      entry.bmi = entry.calculateBMI();
      entry.bmiLabel = _getBMILabel(entry.bmi!);

      await HealthDiaryService.updateHealthEntry(entry.id!, entry);
      
      Navigator.of(context).pop();
      _loadHealthDiary(); // Reload data
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật nhật ký thành công!')),
      );
    } catch (e) {
      _showErrorDialog('Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.');
    }
  }

  // Hiển thị dialog lỗi
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Dialog xác nhận xóa entry
  void _showDeleteConfirmDialog(HealthDiary entry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa nhật ký ngày ${entry.entryDate}?\n\nHành động này không thể hoàn tác.'),
          actions: [
            TextButton(
              child: Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () => _deleteEntry(entry),
            ),
          ],
        );
      },
    );
  }

  // Xóa entry
  Future<void> _deleteEntry(HealthDiary entry) async {
    try {
      await HealthDiaryService.deleteHealthEntry(entry.id!);
      
      Navigator.of(context).pop(); // Đóng dialog
      _loadHealthDiary(); // Reload data
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa nhật ký thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Đóng dialog nếu có lỗi
      _showErrorDialog('Không thể xóa nhật ký. Vui lòng thử lại.');
    }
  }

  // Widget để hiển thị từng health entry
  Widget _buildHealthEntryCard(HealthDiary entry, bool isDark) {
    double bmi = entry.bmi ?? entry.calculateBMI();
    String bmiLabel = _getBMILabel(bmi);
    Color bmiColor = _getBMIColor(bmi, isDark);
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: isDark ? 8 : 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isDark 
            ? LinearGradient(
                colors: [Colors.grey.shade800, Colors.grey.shade700],
              )
            : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với ngày và nút edit
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: isDark ? Colors.blue.shade300 : Colors.blue,
                      ),
                      SizedBox(width: 8),
                      Text(
                        entry.entryDate,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: isDark ? Colors.blue.shade300 : Colors.blue,
                        ),
                        onPressed: () => _showEditEntryDialog(entry),
                        tooltip: 'Chỉnh sửa',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: isDark ? Colors.red.shade300 : Colors.red,
                        ),
                        onPressed: () => _showDeleteConfirmDialog(entry),
                        tooltip: 'Xóa',                      ),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Thông tin sức khỏe trong grid
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Cân nặng',
                      '${entry.weight.toStringAsFixed(1)} kg',
                      Icons.monitor_weight,
                      Colors.green,
                      isDark,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      'Chiều cao',
                      '${entry.height.toStringAsFixed(0)} cm',
                      Icons.height,
                      Colors.blue,
                      isDark,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // BMI info
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bmiColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: bmiColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: bmiColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'BMI: ${bmi.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: bmiColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        bmiLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                // Ghi chú nếu có
              if (entry.content != null && entry.content!.isNotEmpty) ...[
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.note,
                            size: 16,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Ghi chú:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        entry.content!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Meal Plan Section
              SizedBox(height: 12),
              _buildMealPlanSection(entry, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // Widget để hiển thị thông tin nhỏ
  Widget _buildInfoCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade700 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Widget để hiển thị meal plan cho mỗi diary entry
  Widget _buildMealPlanSection(HealthDiary entry, bool isDark) {
    return FutureBuilder<DailyMeal?>(
      future: _getMealPlanForDate(entry.entryDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.grey.shade600 : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.orange.shade300 : Colors.orange
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Đang tải thực đơn...',
                  style: TextStyle(
                    color: isDark ? Colors.orange.shade300 : Colors.orange.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return _buildMealPlanInfo(snapshot.data!, isDark);
        } else {
          return _buildNoMealPlan(entry.entryDate, isDark);
        }
      },
    );
  }

  // Widget hiển thị thông tin meal plan
  Widget _buildMealPlanInfo(DailyMeal mealPlan, bool isDark) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade700 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey.shade600 : Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 16,
                color: isDark ? Colors.green.shade300 : Colors.green.shade700,
              ),
              SizedBox(width: 6),
              Text(
                'Thực đơn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.green.shade300 : Colors.green.shade700,
                  fontSize: 14,
                ),
              ),
              Spacer(),
              if (mealPlan.isCompleted)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Hoàn thành',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildNutritionSummaryItem(
                  'Calories',
                  mealPlan.totalCalories.toStringAsFixed(0),
                  'kcal',
                  Colors.orange,
                  isDark,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildNutritionSummaryItem(
                  'Protein',
                  mealPlan.totalProtein.toStringAsFixed(1),
                  'g',
                  Colors.red,
                  isDark,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildNutritionSummaryItem(
                  'Carbs',
                  mealPlan.totalCarbs.toStringAsFixed(1),
                  'g',
                  Colors.blue,
                  isDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _viewMealPlanDetails(mealPlan),
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('Xem chi tiết', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.green.shade600 : Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    minimumSize: Size(0, 32),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editMealPlan(mealPlan),
                  icon: Icon(Icons.edit, size: 16),
                  label: Text('Chỉnh sửa', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.green.shade300 : Colors.green,
                    side: BorderSide(
                      color: isDark ? Colors.green.shade300 : Colors.green,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    minimumSize: Size(0, 32),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget khi chưa có meal plan
  Widget _buildNoMealPlan(String date, bool isDark) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade700 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 16,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              SizedBox(width: 6),
              Text(
                'Thực đơn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Chưa có thực đơn cho ngày này',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _createMealPlanForDate(date),
              icon: Icon(Icons.add, size: 16),
              label: Text('Tạo thực đơn', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.blue.shade600 : Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 8),
                minimumSize: Size(0, 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị thông tin dinh dưỡng nhỏ
  Widget _buildNutritionSummaryItem(String label, String value, String unit, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }  // Method để lấy meal plan cho ngày cụ thể
  Future<DailyMeal?> _getMealPlanForDate(String date) async {    if (!UserSession.hasAccess()) return null;
    
    try {
      final userId = UserSession.currentUserId!;
      return await MealPlanService.getDailyMealByUserId(userId, date);
    } catch (e) {
      print('❌ Lỗi khi lấy meal plan: $e');
      return null;
    }
  }  // Method để xem chi tiết meal plan
  void _viewMealPlanDetails(DailyMeal mealPlan) {
    // Parse the meal plan date to DateTime
    DateTime mealDate = _parseDate(mealPlan.date);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodScreen(
          initialDate: mealDate,
          showBackButton: true,
        ),
      ),
    ).then((result) {
      // Refresh data when returning from meal editing screens
      _loadHealthDiary();
    });
  }  // Method để chỉnh sửa meal plan
  void _editMealPlan(DailyMeal mealPlan) {
    // Parse the meal plan date to DateTime
    DateTime mealDate = _parseDate(mealPlan.date);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodScreen(
          initialDate: mealDate,
          showBackButton: true,
        ),
      ),
    ).then((result) {
      // Refresh data when returning from meal editing screens
      _loadHealthDiary();
    });
  }  // Method để tạo meal plan cho ngày cụ thể
  void _createMealPlanForDate(String date) {
    // Parse the date string to DateTime
    DateTime targetDate = _parseDate(date);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodScreen(
          initialDate: targetDate,
          showBackButton: true,
        ),
      ),
    ).then((result) {
      // Refresh data when returning from meal creation screens
      _loadHealthDiary();
    });
  }

  // Helper methods cho BMI
  String _getBMILabel(double bmi) {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25) return 'Bình thường';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }
  Color _getBMIColor(double bmi, bool isDark) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}
