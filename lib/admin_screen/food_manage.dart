import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../database/mongodb_service.dart';

class FoodManageScreen extends StatefulWidget {
  const FoodManageScreen({Key? key}) : super(key: key);

  @override
  _FoodManageScreenState createState() => _FoodManageScreenState();
}

class _FoodManageScreenState extends State<FoodManageScreen> {
  List<Food> foods = [];
  bool isLoading = true;
  String loadingMessage = 'Đang tải dữ liệu...';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Food> filteredFoods = [];
  String selectedMealTypeFilter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFoods() async {
    try {
      setState(() {
        isLoading = true;
        foods.clear();
        loadingMessage = 'Đang kiểm tra kết nối...';
      });
      
      // Kiểm tra kết nối database
      if (!DatabaseConnection.isConnected) {
        print('❌ Database chưa kết nối');
        setState(() => loadingMessage = 'Đang kết nối database...');
        _showSnackBar('Database chưa kết nối. Đang thử kết nối lại...');
        
        try {
          await DatabaseConnection.connect();
          print('✅ Kết nối lại thành công');
        } catch (e) {
          _showSnackBar('Không thể kết nối database: $e');
          return;
        }
      }

      setState(() => loadingMessage = 'Đang truy vấn dữ liệu...');
      print('🔍 Đang tải toàn bộ dữ liệu foods...');
      
      // Sử dụng collection foods để đồng bộ với CRUD operations
      final collection = DatabaseConnection.getCollection('foods_catalog');
      if (collection == null) {
        throw Exception('Không thể truy cập collection foods');
      }

      // Tải toàn bộ dữ liệu cùng một lúc
      final result = await collection.find().toList();
      
      print('📋 Lấy được ${result.length} documents');

      if (result.isNotEmpty) {
        setState(() => loadingMessage = 'Đang xử lý dữ liệu...');
        
        List<Food> newFoods = [];
        int processed = 0;
        int total = result.length;
        
        for (var data in result) {
          try {
            var food = Food.fromMap(data);
            newFoods.add(food);
            processed++;
            
            // Cập nhật UI mỗi 50 items để hiển thị progress
            if (processed % 50 == 0 && mounted) {
              setState(() {
                loadingMessage = 'Đã xử lý $processed/$total thực phẩm...';
              });
              await Future.delayed(Duration(milliseconds: 1)); // Cho UI breathe
            }
          } catch (e) {
            print('❌ Lỗi parse food: $e');
            print('📄 Data: $data');
          }
        }

        // Gán dữ liệu mới
        foods = newFoods;
        
        setState(() => loadingMessage = 'Đang áp dụng bộ lọc...');
        _applyFilters();
        print('✅ Parse thành công ${newFoods.length} foods');
      } else {
        print('📭 Collection rỗng hoặc chưa có dữ liệu');
        filteredFoods = [];
      }

    } catch (e) {
      print('❌ Lỗi tải dữ liệu: $e');
      _showSnackBar('Lỗi tải dữ liệu: $e');
      foods = [];
      filteredFoods = [];
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          loadingMessage = 'Đang tải dữ liệu...';
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      filteredFoods = foods.where((food) {
        // Lọc theo loại bữa ăn
        bool matchesMealType = selectedMealTypeFilter == 'Tất cả' || 
                              food.mealType == selectedMealTypeFilter;
        
        // Lọc theo từ khóa tìm kiếm
        bool matchesSearch = _searchController.text.isEmpty ||
                           food.foodName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                           food.mealType.toLowerCase().contains(_searchController.text.toLowerCase());
        
        return matchesMealType && matchesSearch;
      }).toList();

      // Sắp xếp theo tên
      filteredFoods.sort((a, b) => a.foodName.compareTo(b.foodName));
    });
  }

  Future<void> _deleteFood(Food food) async {
    final confirm = await _showConfirmDialog('Xóa thực phẩm', 'Bạn có chắc muốn xóa ${food.foodName}?');
    if (confirm) {
      try {
        final collection = DatabaseConnection.getCollection('foods_catalog');
        if (collection == null) {
          _showSnackBar('Lỗi: Không thể truy cập database');
          return;
        }
        
        // Sử dụng ObjectId để xóa
        await collection.deleteOne({'_id': food.id});
        _showSnackBar('Đã xóa thực phẩm thành công');
        _loadFoods(); // Reload để cập nhật danh sách
      } catch (e) {
        print('❌ Lỗi xóa thực phẩm: $e');
        _showSnackBar('Lỗi xóa thực phẩm: $e');
      }
    }
  }

  void _showFoodDialog({Food? food}) {
    final isEdit = food != null;
    final foodNameController = TextEditingController(text: food?.foodName ?? '');
    final servingSizeController = TextEditingController(text: food?.servingSize.toString() ?? '');
    final servingUnitController = TextEditingController(text: food?.servingUnit ?? '');
    final caloriesController = TextEditingController(text: food?.calories.toString() ?? '');
    final proteinController = TextEditingController(text: food?.protein.toString() ?? '');
    final fatController = TextEditingController(text: food?.fat.toString() ?? '');
    final fiberController = TextEditingController(text: food?.fiber.toString() ?? '');
    final carbsController = TextEditingController(text: food?.carbs.toString() ?? '');
    final imageController = TextEditingController(text: food?.image ?? '');
    final bmiIdController = TextEditingController(text: food?.bmiId.toString() ?? '');
    String selectedMealType = food?.mealType ?? 'Sáng';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isEdit ? Icons.edit : Icons.add,
              color: Colors.green,
            ),
            SizedBox(width: 8),
            Text(isEdit ? 'Sửa thực phẩm' : 'Thêm thực phẩm'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tên thực phẩm
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: foodNameController,
                    decoration: InputDecoration(
                      labelText: 'Tên thực phẩm *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.restaurant_menu),
                    ),
                  ),
                ),
                
                // Loại bữa ăn
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: selectedMealType,
                    decoration: InputDecoration(
                      labelText: 'Loại bữa ăn',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    items: ['Sáng', 'Trưa', 'Tối', 'Snack'].map((type) => 
                      DropdownMenuItem(value: type, child: Text(type))
                    ).toList(),
                    onChanged: (value) => selectedMealType = value!,
                  ),
                ),
                
                // Khẩu phần và đơn vị
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 8, bottom: 16),
                        child: TextField(
                          controller: servingSizeController,
                          decoration: InputDecoration(
                            labelText: 'Khẩu phần',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.straighten),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 16),
                        child: TextField(
                          controller: servingUnitController,
                          decoration: InputDecoration(
                            labelText: 'Đơn vị',
                            border: OutlineInputBorder(),
                            hintText: 'g, ml, cái...',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Calories
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: caloriesController,
                    decoration: InputDecoration(
                      labelText: 'Calories',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_fire_department),
                      suffixText: 'cal',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                
                // Protein và Chất béo
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 8, bottom: 16),
                        child: TextField(
                          controller: proteinController,
                          decoration: InputDecoration(
                            labelText: 'Protein',
                            border: OutlineInputBorder(),
                            suffixText: 'g',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 16),
                        child: TextField(
                          controller: fatController,
                          decoration: InputDecoration(
                            labelText: 'Chất béo',
                            border: OutlineInputBorder(),
                            suffixText: 'g',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Chất xơ và Carbs
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 8, bottom: 16),
                        child: TextField(
                          controller: fiberController,
                          decoration: InputDecoration(
                            labelText: 'Chất xơ',
                            border: OutlineInputBorder(),
                            suffixText: 'g',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 16),
                        child: TextField(
                          controller: carbsController,
                          decoration: InputDecoration(
                            labelText: 'Carbs',
                            border: OutlineInputBorder(),
                            suffixText: 'g',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // BMI ID
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: bmiIdController,
                    decoration: InputDecoration(
                      labelText: 'BMI ID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.fitness_center),
                      hintText: 'ID phân loại BMI',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                
                // URL hình ảnh
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: imageController,
                    decoration: InputDecoration(
                      labelText: 'URL hình ảnh (tùy chọn)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.image),
                      hintText: 'https://...',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (foodNameController.text.trim().isEmpty) {
                _showSnackBar('Vui lòng nhập tên thực phẩm');
                return;
              }

              try {
                final collection = DatabaseConnection.getCollection('foods_catalog');
                if (collection == null) {
                  _showSnackBar('Lỗi: Không thể truy cập database');
                  return;
                }
                
                final foodData = {
                  'food_name': foodNameController.text.trim(),
                  'meal_type': selectedMealType,
                  'serving_size': int.tryParse(servingSizeController.text) ?? 0,
                  'serving_unit': servingUnitController.text.trim(),
                  'calories': int.tryParse(caloriesController.text) ?? 0,
                  'protein': int.tryParse(proteinController.text) ?? 0,
                  'fat': int.tryParse(fatController.text) ?? 0,
                  'fiber': int.tryParse(fiberController.text) ?? 0,
                  'carbs': int.tryParse(carbsController.text) ?? 0,
                  'bmi_id': int.tryParse(bmiIdController.text) ?? 0,
                  'image': imageController.text.trim().isEmpty ? null : imageController.text.trim(),
                };                if (isEdit) {
                  // Cập nhật thực phẩm
                  await collection.updateOne(
                    {'_id': food.id},
                    {'\$set': foodData}
                  );
                  _showSnackBar('Cập nhật thành công');
                } else {
                  // Thêm thực phẩm mới
                  await collection.insertOne(foodData);
                  _showSnackBar('Thêm thực phẩm thành công');
                }

                Navigator.pop(context);
                _loadFoods(); // Reload để cập nhật danh sách
              } catch (e) {
                print('❌ Lỗi lưu food: $e');
                _showSnackBar('Lỗi: $e');
              }
            },
            child: Text(isEdit ? 'Cập nhật' : 'Thêm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
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
            child: Text('Xác nhận'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade600,
                Colors.green.shade800,
                Colors.teal.shade700,
              ],
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.restaurant_menu, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Quản lý thực phẩm',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadFoods,
              tooltip: 'Tải lại dữ liệu',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Debug info bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[100]!, Colors.grey[50]!],
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DatabaseConnection.isConnected ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DatabaseConnection.isConnected ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        DatabaseConnection.isConnected ? Icons.cloud_done : Icons.cloud_off,
                        color: DatabaseConnection.isConnected ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        DatabaseConnection.isConnected ? "Kết nối" : "Mất kết nối",
                        style: TextStyle(
                          fontSize: 12,
                          color: DatabaseConnection.isConnected ? Colors.green[800] : Colors.red[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant_menu, color: Colors.blue, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '${foods.length} thực phẩm',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
              ],
            ),
          ),
          
          // Search and filter section
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Tìm kiếm thực phẩm',
                    prefixIcon: Icon(Icons.search, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => _applyFilters(),
                ),
                
                SizedBox(height: 12),
                
                // Meal type filter
                Row(
                  children: [
                    Text(
                      'Lọc theo bữa ăn: ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedMealTypeFilter,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: ['Tất cả', 'Sáng', 'Trưa', 'Tối', 'Snack'].map((type) => 
                          DropdownMenuItem(value: type, child: Text(type))
                        ).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMealTypeFilter = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Food list
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.green,
                                strokeWidth: 3,
                              ),
                              SizedBox(height: 16),
                              Text(
                                loadingMessage,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Vui lòng đợi...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : filteredFoods.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              foods.isEmpty ? 'Chưa có thực phẩm nào' : 'Không tìm thấy kết quả',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showFoodDialog(),
                              icon: Icon(Icons.add),
                              label: Text('Thêm thực phẩm đầu tiên'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16),
                        itemCount: filteredFoods.length,
                        itemBuilder: (context, index) {
                          final food = filteredFoods[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 0,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _getMealTypeColor(food.mealType).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getMealTypeColor(food.mealType).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: food.image != null && food.image!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: Image.network(
                                          food.image!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.restaurant_menu,
                                              color: _getMealTypeColor(food.mealType),
                                              size: 24,
                                            );
                                          },
                                        ),
                                      )
                                    : Icon(
                                        Icons.restaurant_menu,
                                        color: _getMealTypeColor(food.mealType),
                                        size: 24,
                                      ),
                              ),
                              title: Text(
                                food.foodName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getMealTypeColor(food.mealType).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: _getMealTypeColor(food.mealType),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            food.mealType,
                                            style: TextStyle(
                                              color: _getMealTypeColor(food.mealType),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Flexible(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.local_fire_department, 
                                                color: Colors.orange, size: 16),
                                              Text(' ${food.calories} cal',
                                                style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6),
                                    Text('Khẩu phần: ${food.servingSize} ${food.servingUnit}',
                                      style: TextStyle(color: Colors.grey[600]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 2,
                                      children: [
                                        _buildNutrientTag('P', '${food.protein}g', Colors.blue),
                                        _buildNutrientTag('F', '${food.fat}g', Colors.red),
                                        _buildNutrientTag('C', '${food.carbs}g', Colors.green),
                                        _buildNutrientTag('Fiber', '${food.fiber}g', Colors.purple),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              trailing: SizedBox(
                                width: 88,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.orange[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(Icons.edit, color: Colors.orange[700], size: 18),
                                        onPressed: () => _showFoodDialog(food: food),
                                        tooltip: 'Chỉnh sửa',
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.red[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(Icons.delete, color: Colors.red[700], size: 18),
                                        onPressed: () => _deleteFood(food),
                                        tooltip: 'Xóa',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFoodDialog(),
        icon: Icon(Icons.add),
        label: Text('Thêm thực phẩm'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'Sáng':
        return Colors.orange;
      case 'Trưa':
        return Colors.blue;
      case 'Tối':
        return Colors.indigo;
      case 'Snack':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildNutrientTag(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
