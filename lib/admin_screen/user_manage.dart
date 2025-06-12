import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../models/user_model.dart';
import '../database/mongodb_service.dart';

class UserManageScreen extends StatefulWidget {
  const UserManageScreen({super.key});

  @override
  _UserManageScreenState createState() => _UserManageScreenState();
}

class _UserManageScreenState extends State<UserManageScreen> {
  List<User> users = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<User> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => isLoading = true);
      
      // Debug: Kiểm tra kết nối database
      if (!DatabaseConnection.isConnected) {
        print('❌ Database chưa kết nối');
        _showSnackBar('Database chưa kết nối. Đang thử kết nối lại...');
        
        // Thử kết nối lại
        try {
          await DatabaseConnection.connect();
          print('✅ Kết nối lại thành công');
        } catch (e) {
          _showSnackBar('Không thể kết nối database: $e');
          return;
        }
      }

      print('🔍 Đang tải dữ liệu users...');
      
      // Thử với các tên collection khác nhau
      List<String> possibleCollectionNames = [
        'users',
        'user',
        'User',
        'nguoidung'
      ];

      mongo.DbCollection? collection;
      String? workingCollectionName;

      // Tìm collection tồn tại
      for (String collectionName in possibleCollectionNames) {
        try {
          collection = DatabaseConnection.getCollection(collectionName);
          if (collection != null) {
            var count = await collection.count();
            print('📊 Collection "$collectionName" có $count documents');
            if (count >= 0) {
              workingCollectionName = collectionName;
              break;
            }
          }
        } catch (e) {
          print('❌ Lỗi kiểm tra collection "$collectionName": $e');
          continue;
        }
      }

      if (collection == null) {
        print('❌ Không tìm thấy collection users');
        _showSnackBar('Không tìm thấy collection users. Sẽ tạo mới khi thêm dữ liệu.');
        collection = DatabaseConnection.getCollection('users');
        workingCollectionName = 'users';
      }

      print('✅ Sử dụng collection: $workingCollectionName');

      // Lấy dữ liệu
      final result = await collection!.find().toList();
      print('📋 Lấy được ${result.length} documents');

      if (result.isNotEmpty) {
        print('🔍 Dữ liệu mẫu: ${result.first}');
        
        users = [];
        for (var data in result) {
          try {
            var user = User.fromMap(data);
            users.add(user);
          } catch (e) {
            print('❌ Lỗi parse user: $e');
            print('📄 Data: $data');
          }
        }

        filteredUsers = users;
        print('✅ Parse thành công ${users.length} users');
      } else {
        print('📭 Collection rỗng hoặc chưa có dữ liệu');
        users = [];
        filteredUsers = [];
        _showSnackBar('Chưa có dữ liệu. Hãy thêm người dùng mới.');
      }

    } catch (e) {
      print('❌ Lỗi tải dữ liệu: $e');
      _showSnackBar('Lỗi tải dữ liệu: $e');
      users = [];
      filteredUsers = [];
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users.where((user) =>
          user.fullName.toLowerCase().contains(query.toLowerCase()) ||
          user.email.toLowerCase().contains(query.toLowerCase()) ||
          user.username.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await _showConfirmDialog('Xóa người dùng', 'Bạn có chắc muốn xóa ${user.fullName}?');
    if (confirm) {
      try {
        final collection = DatabaseConnection.getCollection('users');
        await collection?.deleteOne({'_id': user.id});
        _showSnackBar('Đã xóa người dùng thành công');
        _loadUsers();
      } catch (e) {
        _showSnackBar('Lỗi xóa người dùng: $e');
      }
    }
  }

  void _showUserDialog({User? user}) {
    final isEdit = user != null;
    final fullNameController = TextEditingController(text: user?.fullName ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final usernameController = TextEditingController(text: user?.username ?? '');
    final passwordController = TextEditingController(text: user?.password ?? '');
    final birthDateController = TextEditingController(text: user?.birthDate ?? '');
    String selectedGender = user?.gender ?? 'Nam';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Sửa người dùng' : 'Thêm người dùng'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Họ tên
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Họ tên *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                ),
                
                // Email
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                      hintText: 'example@gmail.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                
                // Username và Password
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 8, bottom: 16),
                        child: TextField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            labelText: 'Tên đăng nhập',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.account_circle),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 16),
                        child: TextField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Ngày sinh
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: birthDateController,
                    decoration: InputDecoration(
                      labelText: 'Ngày sinh',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                      hintText: 'YYYY-MM-DD',
                    ),
                    onTap: () async {
                      DateTime? date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        birthDateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      }
                    },
                    readOnly: true,
                  ),
                ),
                
                // Giới tính
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: InputDecoration(
                      labelText: 'Giới tính',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people),
                    ),
                    items: ['Nam', 'Nữ'].map((gender) => 
                      DropdownMenuItem(value: gender, child: Text(gender))
                    ).toList(),
                    onChanged: (value) => selectedGender = value!,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (fullNameController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
                _showSnackBar('Vui lòng điền đầy đủ thông tin bắt buộc');
                return;
              }

              try {
                final collection = DatabaseConnection.getCollection('users');
                final userData = {
                  'id_user': user?.idUser ?? DateTime.now().millisecondsSinceEpoch,
                  'full_name': fullNameController.text.trim(),
                  'email': emailController.text.trim(),
                  'username': usernameController.text.trim(),
                  'password': passwordController.text.trim(),
                  'birth_date': birthDateController.text.trim(),
                  'gender': selectedGender,
                };

                if (isEdit) {
                  await collection?.updateOne(
                    {'_id': user.id},
                    {'\$set': userData}
                  );
                  _showSnackBar('Cập nhật thành công');
                } else {
                  await collection?.insertOne(userData);
                  _showSnackBar('Thêm người dùng thành công');
                }

                Navigator.pop(context);
                _loadUsers();
              } catch (e) {
                print('❌ Lỗi lưu user: $e');
                _showSnackBar('Lỗi: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(isEdit ? 'Cập nhật' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Xác nhận'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý người dùng'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Tải lại dữ liệu',
          ),
        ],
      ),
      body: Column(
        children: [
          // Debug info bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Icon(
                  DatabaseConnection.isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: DatabaseConnection.isConnected ? Colors.green : Colors.red,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'DB: ${DatabaseConnection.isConnected ? "Kết nối" : "Mất kết nối"}',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(width: 16),
                Text(
                  'Người dùng: ${users.length}',
                  style: TextStyle(fontSize: 12),
                ),
                Spacer(),
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          
          // Search field
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tìm kiếm người dùng',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _filterUsers,
            ),
          ),
          
          // User list
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.blue),
                        SizedBox(height: 16),
                        Text('Đang tải dữ liệu...'),
                      ],
                    ),
                  )
                : filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              users.isEmpty ? 'Chưa có người dùng nào' : 'Không tìm thấy kết quả',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showUserDialog(),
                              icon: Icon(Icons.add),
                              label: Text('Thêm người dùng đầu tiên'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Text(user.fullName.isNotEmpty ? user.fullName[0] : '?'),
                              ),
                              title: Text(
                                user.fullName,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text('Email: ${user.email}'),
                                  Text('Username: ${user.username}'),
                                  Text('Giới tính: ${user.gender}'),
                                  if (user.birthDate.isNotEmpty)
                                    Text('Sinh: ${user.birthDate}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.orange),
                                    onPressed: () => _showUserDialog(user: user),
                                    tooltip: 'Chỉnh sửa',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteUser(user),
                                    tooltip: 'Xóa',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        icon: Icon(Icons.add),
        label: Text('Thêm'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}