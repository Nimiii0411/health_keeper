// screens/login_screen.dart
import 'package:flutter/material.dart';
import '../database/mongodb_service.dart';
import '../service/user_service.dart';
import '../models/user_model.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isConnected = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _connectToDatabase();
  }

  // Kết nối tới database khi khởi tạo
  Future<void> _connectToDatabase() async {
    try {
      print('🔌 Đang kiểm tra kết nối');
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
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Xử lý đăng nhập
  Future<void> _handleLogin() async {
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
      String username = _usernameController.text.trim();
      String password = _passwordController.text;

      User? user = await UserService.loginUser(username, password);

      if (user != null) {
        _showSuccessDialog(user);
        _clearForm();
      } else {
        _showErrorDialog('Sai tên đăng nhập hoặc mật khẩu!');
      }
    } catch (e) {
      _showErrorDialog('Lỗi đăng nhập: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Xóa form
  void _clearForm() {
    _usernameController.clear();
    _passwordController.clear();
  }

  // Hiển thị dialog thành công
  void _showSuccessDialog(User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Đăng nhập thành công!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chào mừng bạn trở lại!'),
              SizedBox(height: 8),
              Text(
                'Họ tên: ${user.fullName}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Username: ${user.username}'),
              Text('Email: ${user.email}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to home screen
                // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(user: user)));
              },
              child: Text('Tiếp tục'),
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
        title: Text('Đăng nhập'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
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
                  // Logo hoặc hình ảnh app
                  Container(
                    height: 120,
                    child: Icon(
                      Icons.health_and_safety,
                      size: 80,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Tiêu đề
                  Text(
                    'Health App',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Chăm sóc sức khỏe của bạn',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 32),

                  // Trạng thái kết nối
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          _isConnected
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            _isConnected
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isConnected ? Icons.wifi : Icons.wifi_off,
                          color:
                              _isConnected
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _isConnected
                              ? 'Đã kết nối'
                              : 'Mất kết nối',
                          style: TextStyle(
                            color:
                                _isConnected
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Username field
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Tên đăng nhập',
                      prefixIcon: Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên đăng nhập';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: Icon(Icons.lock, color: Colors.blue),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 8),

                  // Quên mật khẩu
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password
                        _showErrorDialog(
                          'Chức năng quên mật khẩu đang được phát triển',
                        );
                      },
                      child: Text(
                        'Quên mật khẩu?',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Nút đăng nhập
                  ElevatedButton(
                    onPressed:
                        (_isLoading || !_isConnected) ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child:
                        _isLoading
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
                                Text('Đang đăng nhập...'),
                              ],
                            )
                            : Text(
                              'Đăng nhập',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                  SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'hoặc',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Nút đăng ký
                  OutlinedButton(
                    onPressed: () {
                      // TODO: Navigate to register screen
                      Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.blue),
                    ),
                    child: Text(
                      'Tạo tài khoản mới',
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
    );
  }
}
