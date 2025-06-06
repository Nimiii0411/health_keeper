// screens/register_screen.dart (Updated)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/mongodb_service.dart';
import '../service/user_service.dart';
import '../models/user_model.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

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
    final now = DateTime.now();
    final minDate = DateTime(now.year - 100); // 100 tuổi
    final maxDate = DateTime(now.year - 5);   // 5 tuổi
    
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: minDate,  // Từ 100 tuổi trước
      lastDate: maxDate,   // Đến 5 tuổi trước
      helpText: 'Chọn ngày sinh (từ 5-100 tuổi)',
    );
    
    if (pickedDate != null) {
      setState(() {
        _birthDateController.text = 
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Tính tuổi từ ngày sinh
  int _calculateAge(String birthDateString) {
    try {
      final birthDate = DateTime.parse(birthDateString);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month || 
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  // Validate email mạnh hơn
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  // Validate mật khẩu mạnh
  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (password.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Mật khẩu phải có ít nhất 1 chữ hoa';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Mật khẩu phải có ít nhất 1 chữ thường';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Mật khẩu phải có ít nhất 1 số';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt';
    }
    return null;
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween(begin: Offset(-1.0, 0.0), end: Offset.zero),
                        ),
                        child: child,
                      );
                    },
                  ),
                );
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
    
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ]
              : [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                  Color(0xFFf093fb),
                ],
          ),
        ),
        child: SafeArea(          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  SizedBox(height: 20),
                    // Compact Header
                  _buildCompactHeader(isDark),
                  
                  SizedBox(height: 20),
                  
                  // Form container với glass morphism effect
                  Container(
                    decoration: BoxDecoration(
                      color: isDark 
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Connection status
                            _buildConnectionStatus(isDark),
                            
                            SizedBox(height: 16),
                            
                            // Full name field
                            _buildTextField(
                              controller: _fullNameController,
                              hintText: 'Họ và tên',
                              icon: Icons.person_outline,
                              isDark: isDark,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập họ và tên';
                                }
                                return null;
                              },
                            ),
                            
                            SizedBox(height: 12),                            // Row with birth date and gender
                            Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: _buildTextField(
                                    controller: _birthDateController,
                                    hintText: 'Ngày sinh',
                                    icon: Icons.calendar_today_outlined,
                                    isDark: isDark,
                                    readOnly: true,
                                    onTap: _selectDate,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        Icons.date_range,
                                        color: isDark ? Colors.white70 : Color(0xFF667eea),
                                      ),
                                      onPressed: _selectDate,
                                    ),                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Chọn ngày sinh';
                                      }
                                      
                                      // Kiểm tra tuổi
                                      final age = _calculateAge(value);
                                      if (age < 5) {
                                        return 'Tuổi tối thiểu là 5 tuổi';
                                      }
                                      if (age > 100) {
                                        return 'Tuổi tối đa là 100 tuổi';
                                      }
                                      
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: _buildGenderDropdown(isDark),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: 12),
                            
                            // Email field
                            _buildTextField(
                              controller: _emailController,
                              hintText: 'Email',
                              icon: Icons.email_outlined,
                              isDark: isDark,
                              keyboardType: TextInputType.emailAddress,                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập email';
                                }
                                if (!_isValidEmail(value.trim())) {
                                  return 'Email không hợp lệ (VD: user@example.com)';
                                }
                                return null;
                              },
                            ),
                            
                            SizedBox(height: 12),
                            
                            // Username field
                            _buildTextField(
                              controller: _usernameController,
                              hintText: 'Tên đăng nhập',
                              icon: Icons.account_circle_outlined,
                              isDark: isDark,                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập tên đăng nhập';
                                }
                                if (value.length < 3) {
                                  return 'Tên đăng nhập phải có ít nhất 3 ký tự';
                                }
                                if (value.length > 20) {
                                  return 'Tên đăng nhập không được quá 20 ký tự';
                                }
                                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                                  return 'Tên đăng nhập chỉ chứa chữ, số và dấu gạch dưới';
                                }
                                return null;
                              },
                            ),
                            
                            SizedBox(height: 12),
                              // Password field
                            _buildTextField(
                              controller: _passwordController,
                              hintText: 'Mật khẩu',
                              icon: Icons.lock_outline,
                              isDark: isDark,
                              isPassword: true,                              validator: (value) {
                                if (value == null) {
                                  return 'Vui lòng nhập mật khẩu';
                                }
                                return _validatePassword(value);
                              },
                            ),
                            
                            // Password requirement info
                            Container(
                              margin: EdgeInsets.only(top: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? Colors.blue.withOpacity(0.3) : Colors.blue.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Yêu cầu mật khẩu:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.blue[300] : Colors.blue[700],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  _buildPasswordRequirement('• Ít nhất 8 ký tự', isDark),
                                  _buildPasswordRequirement('• Có chữ hoa (A-Z)', isDark),
                                  _buildPasswordRequirement('• Có chữ thường (a-z)', isDark),
                                  _buildPasswordRequirement('• Có số (0-9)', isDark),
                                  _buildPasswordRequirement('• Có ký tự đặc biệt (!@#\$%^&*)', isDark),
                                ],
                              ),
                            ),
                            
                            SizedBox(height: 20),
                            
                            // Register button
                            _buildRegisterButton(isDark),
                            
                            SizedBox(height: 16),
                            
                            // Divider
                            _buildDivider(isDark),
                            
                            SizedBox(height: 16),
                            
                            // Login button
                            _buildLoginButton(isDark),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Theme toggle
                  _buildThemeToggle(themeProvider, isDark),
                  
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }  Widget _buildCompactHeader(bool isDark) {
    return Column(
      children: [
        // Compact logo and title in row
        Row(
          children: [
            // Smaller logo
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.person_add_rounded,
                size: 30,
                color: Colors.white,
              ),
            ),
            
            SizedBox(width: 16),
            
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tạo tài khoản',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tham gia cùng HealthKeeper',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionStatus(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isConnected
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isConnected
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isConnected ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(width: 12),
          Text(
            _isConnected ? 'Đã kết nối' : 'Mất kết nối',
            style: TextStyle(
              color: _isConnected ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDark 
                ? Colors.white.withOpacity(0.6)
                : Colors.black.withOpacity(0.6),
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.all(16),
            child: Icon(
              icon,
              color: isDark ? Colors.white70 : Color(0xFF667eea),
              size: 24,
            ),
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        validator: validator,
      ),
    );
  }  Widget _buildGenderDropdown(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 13,
        ),
        dropdownColor: isDark ? Color(0xFF2D2D44) : Colors.white,
        decoration: InputDecoration(
          hintText: 'Giới tính',
          hintStyle: TextStyle(
            color: isDark 
                ? Colors.white.withOpacity(0.6)
                : Colors.black.withOpacity(0.6),
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        ),
        items: ['Nam', 'Nữ', 'Khác'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 13,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedGender = newValue!;
          });
        },
      ),
    );
  }

  Widget _buildRegisterButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLoading || !_isConnected
              ? [Colors.grey, Colors.grey]
              : [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (_isLoading || !_isConnected) ? null : _registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                  Text(
                    'Đang đăng ký...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                'Đăng ký',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isDark 
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'hoặc',
            style: TextStyle(
              color: isDark 
                  ? Colors.white.withOpacity(0.7)
                  : Colors.black.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isDark 
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.3) : Color(0xFF667eea),
          width: 2,
        ),
      ),
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: animation.drive(
                    Tween(begin: Offset(-1.0, 0.0), end: Offset.zero),
                  ),
                  child: child,
                );
              },
            ),
          );
        },
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Đã có tài khoản? Đăng nhập',
          style: TextStyle(
            color: isDark ? Colors.white : Color(0xFF667eea),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(ThemeProvider themeProvider, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.light_mode_outlined,
            color: !isDark ? Colors.white : Colors.white.withOpacity(0.5),
            size: 20,
          ),
          SizedBox(width: 8),
          Switch(
            value: isDark,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
            activeColor: Colors.white,
            inactiveThumbColor: Colors.white.withOpacity(0.8),
            activeTrackColor: Colors.white.withOpacity(0.3),
            inactiveTrackColor: Colors.white.withOpacity(0.2),
          ),
          SizedBox(width: 8),
          Icon(
            Icons.dark_mode_outlined,
            color: isDark ? Colors.white : Colors.white.withOpacity(0.5),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirement(String text, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(top: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.blue[200] : Colors.blue[600],
        ),
      ),
    );
  }
}