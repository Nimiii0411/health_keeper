import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../models/exercise_model.dart';
import '../database/mongodb_service.dart';

class ExerciseManageScreen extends StatefulWidget {
  @override
  _ExerciseManageScreenState createState() => _ExerciseManageScreenState();
}

class _ExerciseManageScreenState extends State<ExerciseManageScreen> {
  List<Exercise> exercises = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Exercise> filteredExercises = [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
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

      print('🔍 Đang tải dữ liệu exercises...');
      
      // Thử với các tên collection khác nhau
      List<String> possibleCollectionNames = [
        'exercises',
        'exercise',
        'Exercise',
        'baitap'
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
        print('❌ Không tìm thấy collection exercises');
        _showSnackBar('Không tìm thấy collection exercises. Sẽ tạo mới khi thêm dữ liệu.');
        collection = DatabaseConnection.getCollection('exercises');
        workingCollectionName = 'exercises';
      }

      print('✅ Sử dụng collection: $workingCollectionName');

      // Lấy dữ liệu
      final result = await collection!.find().toList();
      print('📋 Lấy được ${result.length} documents');

      if (result.isNotEmpty) {
        print('🔍 Dữ liệu mẫu: ${result.first}');
        
        exercises = [];
        for (var data in result) {
          try {
            var exercise = Exercise.fromMap(data);
            exercises.add(exercise);
          } catch (e) {
            print('❌ Lỗi parse exercise: $e');
            print('📄 Data: $data');
          }
        }

        filteredExercises = exercises;
        print('✅ Parse thành công ${exercises.length} exercises');
      } else {
        print('📭 Collection rỗng hoặc chưa có dữ liệu');
        exercises = [];
        filteredExercises = [];
        _showSnackBar('Chưa có dữ liệu. Hãy thêm bài tập mới.');
      }

    } catch (e) {
      print('❌ Lỗi tải dữ liệu: $e');
      _showSnackBar('Lỗi tải dữ liệu: $e');
      exercises = [];
      filteredExercises = [];
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _filterExercises(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredExercises = exercises;
      } else {
        filteredExercises = exercises.where((exercise) =>
          exercise.exerciseName.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  Future<void> _deleteExercise(Exercise exercise) async {
    final confirm = await _showConfirmDialog('Xóa bài tập', 'Bạn có chắc muốn xóa ${exercise.exerciseName}?');
    if (confirm) {
      try {
        final collection = DatabaseConnection.getCollection('exercises');
        await collection?.deleteOne({'_id': exercise.id});
        _showSnackBar('Đã xóa bài tập thành công');
        _loadExercises();
      } catch (e) {
        _showSnackBar('Lỗi xóa bài tập: $e');
      }
    }
  }

  void _showExerciseDialog({Exercise? exercise}) {
    final isEdit = exercise != null;
    final exerciseNameController = TextEditingController(text: exercise?.exerciseName ?? '');
    final caloriesPerSetController = TextEditingController(text: exercise?.caloriesPerSet.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Sửa bài tập' : 'Thêm bài tập'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tên bài tập
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: exerciseNameController,
                  decoration: InputDecoration(
                    labelText: 'Tên bài tập *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.fitness_center),
                    hintText: 'VD: Push up, Squat...',
                  ),
                ),
              ),
              
              // Calories mỗi set
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: caloriesPerSetController,
                  decoration: InputDecoration(
                    labelText: 'Calories mỗi set',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_fire_department),
                    suffixText: 'cal',
                    hintText: 'Số calories tiêu thụ mỗi set',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              
              // Ghi chú
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Calories sẽ được tính dựa trên số set và reps mà người dùng thực hiện',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
              if (exerciseNameController.text.trim().isEmpty) {
                _showSnackBar('Vui lòng nhập tên bài tập');
                return;
              }

              try {
                final collection = DatabaseConnection.getCollection('exercises');
                final exerciseData = {
                  'exercise_name': exerciseNameController.text.trim(),
                  'calories_per_set': int.tryParse(caloriesPerSetController.text) ?? 0,
                };

                if (isEdit) {
                  await collection?.updateOne(
                    {'_id': exercise!.id},
                    {'\$set': exerciseData}
                  );
                  _showSnackBar('Cập nhật thành công');
                } else {
                  await collection?.insertOne(exerciseData);
                  _showSnackBar('Thêm bài tập thành công');
                }

                Navigator.pop(context);
                _loadExercises();
              } catch (e) {
                print('❌ Lỗi lưu exercise: $e');
                _showSnackBar('Lỗi: $e');
              }
            },
            child: Text(isEdit ? 'Cập nhật' : 'Thêm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
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
        title: Text('Quản lý bài tập'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadExercises,
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
                  'Bài tập: ${exercises.length}',
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
                labelText: 'Tìm kiếm bài tập',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _filterExercises,
            ),
          ),
          
          // Exercise list
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.orange),
                        SizedBox(height: 16),
                        Text('Đang tải dữ liệu...'),
                      ],
                    ),
                  )
                : filteredExercises.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              exercises.isEmpty ? 'Chưa có bài tập nào' : 'Không tìm thấy kết quả',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showExerciseDialog(),
                              icon: Icon(Icons.add),
                              label: Text('Thêm bài tập đầu tiên'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = filteredExercises[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('💪'),
                                backgroundColor: Colors.orange[100],
                              ),
                              title: Text(
                                exercise.exerciseName,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text('${exercise.caloriesPerSet} calories/set'),
                                  Text(
                                    'Tổng calories = ${exercise.caloriesPerSet} × số set',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.orange),
                                    onPressed: () => _showExerciseDialog(exercise: exercise),
                                    tooltip: 'Chỉnh sửa',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteExercise(exercise),
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
        onPressed: () => _showExerciseDialog(),
        icon: Icon(Icons.add),
        label: Text('Thêm'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }
}