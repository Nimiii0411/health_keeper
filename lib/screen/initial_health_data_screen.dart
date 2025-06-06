import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/health_diary_model.dart';
import '../models/user_model.dart';
import '../service/health_diary_service.dart';
import '../service/user_session.dart';
import '../providers/theme_provider.dart';
import 'home_screen.dart';

class InitialHealthDataScreen extends StatefulWidget {
  const InitialHealthDataScreen({super.key});

  @override
  _InitialHealthDataScreenState createState() => _InitialHealthDataScreenState();
}

class _InitialHealthDataScreenState extends State<InitialHealthDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  int _calculateAge(String birthDateString) {
    try {
      List<String> parts = birthDateString.split('/');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        
        DateTime birthDate = DateTime(year, month, day);
        DateTime today = DateTime.now();
        
        int age = today.year - birthDate.year;
        if (today.month < birthDate.month || 
            (today.month == birthDate.month && today.day < birthDate.day)) {
          age--;
        }
        
        return age;
      }
    } catch (e) {
      print('❌ Lỗi khi tính tuổi: $e');
    }
    return 25; // Default age nếu không tính được
  }

  Future<void> _saveHealthData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    User? currentUser = UserSession.currentUser;
    if (currentUser == null) {
      _showErrorDialog('Không tìm thấy thông tin người dùng');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Tạo entry mới với ngày hiện tại
      String today = "${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}";
      
      HealthDiary healthEntry = HealthDiary(
        userId: currentUser.idUser,
        entryDate: today,
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        content: 'Thông tin sức khỏe ban đầu',
      );

      // Lưu vào database
      bool success = await HealthDiaryService.addHealthEntry(healthEntry);

      if (success) {
        _showSuccessDialog();
      } else {
        throw Exception('Không thể lưu thông tin sức khỏe');
      }

    } catch (e) {
      _showErrorDialog('Lỗi khi lưu dữ liệu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Hoàn thành!'),
            ],
          ),
          content: Text('Thông tin sức khỏe của bạn đã được lưu thành công.\n\nBạn có thể xem và cập nhật thông tin này trong phần Nhật ký sức khỏe.'),          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
                // Điều hướng đến HomeScreen thay vì quay về LoginScreen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
              child: Text('Tiếp tục'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Lỗi!'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final currentUser = UserSession.currentUser;

    return WillPopScope(
      onWillPop: () async => false, // Không cho phép back
      child: Scaffold(
        appBar: AppBar(
          title: Text('Thông tin sức khỏe ban đầu'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false, // Ẩn nút back
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark 
                ? [Colors.grey.shade900, Colors.grey.shade800]
                : [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 60,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Chào mừng ${currentUser?.fullName ?? "bạn"}!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Để HealthKeeper có thể hỗ trợ bạn tốt nhất, vui lòng nhập thông tin cân nặng và chiều cao hiện tại.',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32),

                    // User Info
                    if (currentUser != null) ...[
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thông tin cá nhân',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.person, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Tuổi: ${_calculateAge(currentUser.birthDate)} tuổi'),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    currentUser.gender == 'Nam' 
                                      ? Icons.male 
                                      : currentUser.gender == 'Nữ'
                                        ? Icons.female
                                        : Icons.person,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Giới tính: ${currentUser.gender}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                    ],

                    // Cân nặng
                    Text(
                      'Cân nặng hiện tại (kg)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: 65.5',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                        ),
                        prefixIcon: Icon(Icons.monitor_weight, color: Colors.blue),
                        suffixText: 'kg',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập cân nặng';
                        }
                        
                        double? weight = double.tryParse(value);
                        if (weight == null) {
                          return 'Cân nặng phải là số';
                        }
                        
                        if (weight < 20 || weight > 300) {
                          return 'Cân nặng phải từ 20kg đến 300kg';
                        }
                        
                        return null;
                      },
                    ),
                    SizedBox(height: 24),

                    // Chiều cao
                    Text(
                      'Chiều cao (cm)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: 170',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                        ),
                        prefixIcon: Icon(Icons.height, color: Colors.blue),
                        suffixText: 'cm',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập chiều cao';
                        }
                        
                        double? height = double.tryParse(value);
                        if (height == null) {
                          return 'Chiều cao phải là số';
                        }
                        
                        if (height < 100 || height > 250) {
                          return 'Chiều cao phải từ 100cm đến 250cm';
                        }
                        
                        return null;
                      },
                    ),
                    SizedBox(height: 32),

                    // Info Card
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Thông tin quan trọng',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• BMI sẽ được tự động tính toán dựa trên cân nặng và chiều cao\n'
                            '• Phân loại BMI sẽ được gán tự động theo tiêu chuẩn WHO\n'
                            '• Bạn có thể cập nhật thông tin này bất cứ lúc nào trong Nhật ký sức khỏe\n'
                            '• Thông tin này sẽ giúp ứng dụng đưa ra lời khuyên phù hợp',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),

                    // Nút lưu
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveHealthData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Đang lưu...'),
                              ],
                            )
                          : Text(
                              'Lưu thông tin và tiếp tục',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
