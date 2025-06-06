import 'dart:async';
import '../database/mongodb_service.dart';
import '../models/food_model.dart';

class OptimizedFoodService {
  static const int _defaultPageSize = 50;
  static const int _maxCacheSize = 500; // Giới hạn cache để tránh memory issues
  
  // Cache để lưu dữ liệu đã tải
  static final List<Food> _cachedFoods = [];
  static int _currentPage = 0;
  static bool _hasMoreData = true;
  static bool _isLoading = false;
  
  // Stream controller để notify UI về updates
  static final StreamController<List<Food>> _foodStreamController = 
      StreamController<List<Food>>.broadcast();
  
  static final StreamController<String> _statusStreamController = 
      StreamController<String>.broadcast();
  
  // Getters cho streams
  static Stream<List<Food>> get foodStream => _foodStreamController.stream;
  static Stream<String> get statusStream => _statusStreamController.stream;
  
  // Getters cho state
  static List<Food> get cachedFoods => List.unmodifiable(_cachedFoods);
  static bool get hasMoreData => _hasMoreData;
  static bool get isLoading => _isLoading;
  
  /// Tải dữ liệu foods với phân trang tối ưu
  static Future<List<Food>> loadFoods({
    bool refresh = false,
    int pageSize = _defaultPageSize,
  }) async {
    if (_isLoading) return _cachedFoods;
    
    try {
      _isLoading = true;
      
      if (refresh) {
        _currentPage = 0;
        _cachedFoods.clear();
        _hasMoreData = true;
        _statusStreamController.add('Đang làm mới dữ liệu...');
      } else {
        _statusStreamController.add('Đang tải thêm dữ liệu...');
      }
      
      // Kiểm tra kết nối
      if (!DatabaseConnection.isConnected) {
        _statusStreamController.add('Đang kết nối database...');
        await DatabaseConnection.connect();
      }
      
      final collection = DatabaseConnection.getCollection('foods_catalog');
      if (collection == null) {
        throw Exception('Không thể truy cập collection foods_catalog');
      }
      
      _statusStreamController.add('Đang truy vấn dữ liệu...');
      
      // Tải dữ liệu với skip và take để phân trang
      final result = await collection
          .find()
          .skip(_currentPage * pageSize)
          .take(pageSize)
          .toList();
      
      if (result.isNotEmpty) {
        _statusStreamController.add('Đang xử lý ${result.length} thực phẩm...');
        
        // Xử lý dữ liệu theo batch nhỏ
        final newFoods = <Food>[];
        for (int i = 0; i < result.length; i++) {
          try {
            final food = Food.fromMap(result[i]);
            newFoods.add(food);
            
            // Yield control mỗi 10 items
            if (i % 10 == 0 && i > 0) {
              await Future.delayed(Duration.zero);
              _statusStreamController.add('Đã xử lý ${i}/${result.length} thực phẩm...');
            }
          } catch (e) {
            print('❌ Lỗi parse food: $e');
          }
        }
        
        // Thêm vào cache với giới hạn size
        _cachedFoods.addAll(newFoods);
        
        // Giới hạn cache size để tránh memory issues
        if (_cachedFoods.length > _maxCacheSize) {
          _cachedFoods.removeRange(0, _cachedFoods.length - _maxCacheSize);
        }
        
        _currentPage++;
        
        // Kiểm tra còn dữ liệu không
        if (result.length < pageSize) {
          _hasMoreData = false;
        }
        
        _statusStreamController.add('Hoàn thành! Tổng: ${_cachedFoods.length} thực phẩm');
        
        // Emit dữ liệu mới
        _foodStreamController.add(_cachedFoods);
        
        print('✅ Tải thành công ${newFoods.length} foods mới, tổng: ${_cachedFoods.length}');
      } else {
        _hasMoreData = false;
        _statusStreamController.add(_cachedFoods.isEmpty ? 'Không có dữ liệu' : 'Đã tải hết dữ liệu');
      }
      
      return _cachedFoods;
      
    } catch (e) {
      print('❌ Lỗi tải foods: $e');
      _statusStreamController.add('Lỗi tải dữ liệu: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }
  
  /// Tìm kiếm foods với cache
  static List<Food> searchFoods(String query, {String? mealType}) {
    if (query.isEmpty && mealType == null) return _cachedFoods;
    
    return _cachedFoods.where((food) {
      final matchesQuery = query.isEmpty || 
          food.foodName.toLowerCase().contains(query.toLowerCase()) ||
          food.mealType.toLowerCase().contains(query.toLowerCase());
      
      final matchesMealType = mealType == null || 
          mealType == 'Tất cả' || 
          food.mealType == mealType;
      
      return matchesQuery && matchesMealType;
    }).toList();
  }
  
  /// Thêm food mới
  static Future<bool> addFood(Map<String, dynamic> foodData) async {
    try {
      final collection = DatabaseConnection.getCollection('foods_catalog');
      if (collection == null) return false;
      
      final result = await collection.insertOne(foodData);
      
      if (result.isSuccess) {
        // Refresh cache
        await loadFoods(refresh: true);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Lỗi thêm food: $e');
      return false;
    }
  }
  
  /// Cập nhật food
  static Future<bool> updateFood(String foodId, Map<String, dynamic> foodData) async {
    try {
      final collection = DatabaseConnection.getCollection('foods_catalog');
      if (collection == null) return false;
      
      final result = await collection.updateOne(
        {'_id': foodId}, 
        {'\$set': foodData}
      );
      
      if (result.isAcknowledged == true) {
        // Refresh cache
        await loadFoods(refresh: true);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Lỗi cập nhật food: $e');
      return false;
    }
  }
  
  /// Xóa food
  static Future<bool> deleteFood(String foodId) async {
    try {
      final collection = DatabaseConnection.getCollection('foods_catalog');
      if (collection == null) return false;
      
      final result = await collection.deleteOne({'_id': foodId});
      
      if (result.isAcknowledged == true) {
        // Xóa khỏi cache
        _cachedFoods.removeWhere((food) => food.id.toString() == foodId);
        _foodStreamController.add(_cachedFoods);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Lỗi xóa food: $e');
      return false;
    }
  }
  
  /// Reset cache và state
  static void reset() {
    _cachedFoods.clear();
    _currentPage = 0;
    _hasMoreData = true;
    _isLoading = false;
    _foodStreamController.add(_cachedFoods);
    _statusStreamController.add('Đã reset dữ liệu');
  }
  
  /// Dispose streams
  static void dispose() {
    _foodStreamController.close();
    _statusStreamController.close();
  }
}
