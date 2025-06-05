// screens/register_screen.dart (Updated)
import 'package:flutter/material.dart';
import '../database/mongodb_service.dart';
import '../service/user_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedGender = 'Nam';
  bool _isLoading = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectToDatabase();
  }

  // Kết nối tới database khi khởi tạo
  Future<void> _connectToDatabase() async {
    try {
      print('🔌 Bắt đầu kết nối database...');
      await DatabaseConnection.connect();
      setState(() {
        _isConnected = true;
      });
      print('✅ Kết nối thành công!');
    } catch (e) {
      print('❌ Chi tiết lỗi kết nối: $e');
      setState(() {
        _isConnected = false;
      });
      _showErrorDialog('Không thể kết nối tới database: $e');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Chọn ngày sinh
  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    
    if (pickedDate != null) {
      setState(() {
        _birthDateController.text = 
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Đăng ký user (sử dụng UserService)
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isConnected) {
      _showErrorDialog('Chưa kết nối tới database!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User newUser = User(
        idUser: 0, // Sẽ được tự động tăng trong UserService
        fullName: _fullNameController.text.trim(),
        birthDate: _birthDateController.text,
        gender: _selectedGender,
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      bool success = await UserService.registerUser(newUser);
      
      if (success) {
        _showSuccessDialog();
        _clearForm();
      } else {
        _showErrorDialog('Đăng ký thất bại!');
      }
    } catch (e) {
      _showErrorDialog('Lỗi: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Xóa form
  void _clearForm() {
    _fullNameController.clear();
    _birthDateController.clear();
    _emailController.clear();
    _usernameController.clear();
    _passwordController.clear();
    setState(() {
      _selectedGender = 'Nam';
    });
  }

  // Hiển thị dialog thành công
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Thành công!'),
            ],
          ),
          content: Text('Đã đăng ký tài khoản thành công!\nBạn có thể đăng nhập ngay bây giờ.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Hiển thị dialog lỗi
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng ký tài khoản'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Trạng thái kết nối
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _isConnected ? 'Đã kết nối' : 'Mất kết nối',
                  style: TextStyle(
                    color: _isConnected ? Colors.green[800] : Colors.red[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),

              // Họ và tên
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Họ và tên',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Ngày sinh
              TextFormField(
                controller: _birthDateController,
                decoration: InputDecoration(
                  labelText: 'Ngày sinh',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.date_range),
                    onPressed: _selectDate,
                  ),
                ),
                readOnly: true,
                onTap: _selectDate,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng chọn ngày sinh';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Giới tính
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Giới tính',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc),
                ),
                items: ['Nam', 'Nữ', 'Khác'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue!;
                  });
                },
              ),
              SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Username
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Tên đăng nhập',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_circle),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên đăng nhập';
                  }
                  if (value.length < 3) {
                    return 'Tên đăng nhập phải có ít nhất 3 ký tự';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value.length < 5) {
                    return 'Mật khẩu phải có ít nhất 5 ký tự';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Nút đăng ký
              ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Đăng ký',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}