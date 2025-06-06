import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../service/health_diary_service.dart';
import '../service/user_session.dart';
import '../models/health_diary_model.dart';

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
        child: Icon(Icons.add),
        tooltip: 'Thêm nhật ký hôm nay',
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
