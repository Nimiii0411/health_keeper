import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../models/food_model.dart';
import '../database/mongodb_service.dart';

class FoodManageScreen extends StatefulWidget {
  @override
  _FoodManageScreenState createState() => _FoodManageScreenState();
}

class _FoodManageScreenState extends State<FoodManageScreen> {
  List<Food> foods = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Food> filteredFoods = [];

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
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

      print('🔍 Đang tải dữ liệu foods...');
      
      // Thử với các tên collection khác nhau
      List<String> possibleCollectionNames = [
        'foods',
        'foods_catalog', 
        'food',
        'Food',
        'thucpham'
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
            if (count >= 0) { // Thay đổi từ > 0 thành >= 0 để chấp nhận collection rỗng
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
        print('❌ Không tìm thấy collection foods');
        _showSnackBar('Không tìm thấy collection foods. Sẽ tạo mới khi thêm dữ liệu.');
        // Tạo collection mặc định
        collection = DatabaseConnection.getCollection('foods');
        workingCollectionName = 'foods';
      }

      print('✅ Sử dụng collection: $workingCollectionName');

      // Lấy dữ liệu
      final result = await collection!.find().toList();
      print('📋 Lấy được ${result.length} documents');

      if (result.isNotEmpty) {
        print('🔍 Dữ liệu mẫu: ${result.first}');
        
        foods = [];
        for (var data in result) {
          try {
            var food = Food.fromMap(data);
            foods.add(food);
          } catch (e) {
            print('❌ Lỗi parse food: $e');
            print('📄 Data: $data');
          }
        }

        filteredFoods = foods;
        print('✅ Parse thành công ${foods.length} foods');
      } else {
        print('📭 Collection rỗng hoặc chưa có dữ liệu');
        foods = [];
        filteredFoods = [];
        _showSnackBar('Chưa có dữ liệu. Hãy thêm thực phẩm mới.');
      }

    } catch (e) {
      print('❌ Lỗi tải dữ liệu: $e');
      _showSnackBar('Lỗi tải dữ liệu: $e');
      foods = [];
      filteredFoods = [];
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _filterFoods(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredFoods = foods;
      } else {
        filteredFoods = foods.where((food) =>
          food.foodName.toLowerCase().contains(query.toLowerCase()) ||
          food.mealType.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  Future<void> _deleteFood(Food food) async {
    final confirm = await _showConfirmDialog('Xóa thực phẩm', 'Bạn có chắc muốn xóa ${food.foodName}?');
    if (confirm) {
      try {
        final collection = DatabaseConnection.getCollection('foods');
        await collection?.deleteOne({'_id': food.id});
        _showSnackBar('Đã xóa thực phẩm thành công');
        _loadFoods();
      } catch (e) {
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
        title: Text(isEdit ? 'Sửa thực phẩm' : 'Thêm thực phẩm'),
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
                final collection = DatabaseConnection.getCollection('foods');
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
                };

                if (isEdit) {
                  await collection?.updateOne(
                    {'_id': food!.id},
                    {'\$set': foodData}
                  );
                  _showSnackBar('Cập nhật thành công');
                } else {
                  await collection?.insertOne(foodData);
                  _showSnackBar('Thêm thực phẩm thành công');
                }

                Navigator.pop(context);
                _loadFoods();
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
        title: Text('Quản lý thực phẩm'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadFoods,
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
                  'Thực phẩm: ${foods.length}',
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
                labelText: 'Tìm kiếm thực phẩm',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _filterFoods,
            ),
          ),
          
          // Food list
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.green),
                        SizedBox(height: 16),
                        Text('Đang tải dữ liệu...'),
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
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredFoods.length,
                        itemBuilder: (context, index) {
                          final food = filteredFoods[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('🍎'),
                                backgroundColor: Colors.green[100],
                              ),
                              title: Text(
                                food.foodName,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text('Loại: ${food.mealType}'),
                                  Text('Calories: ${food.calories} cal'),
                                  Text('Khẩu phần: ${food.servingSize} ${food.servingUnit}'),
                                  Text('P: ${food.protein}g | F: ${food.fat}g | C: ${food.carbs}g'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.orange),
                                    onPressed: () => _showFoodDialog(food: food),
                                    tooltip: 'Chỉnh sửa',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteFood(food),
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
        onPressed: () => _showFoodDialog(),
        icon: Icon(Icons.add),
        label: Text('Thêm'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }
}