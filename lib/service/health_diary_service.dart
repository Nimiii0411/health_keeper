import 'package:mongo_dart/mongo_dart.dart';
import '../database/mongodb_service.dart';
import '../models/health_diary_model.dart';
import '../models/bmi_catalog_model.dart';

class HealthDiaryService {
  static const String _collectionName = 'health_diary';
  static const String _bmiCatalogCollectionName = 'bmi_catalog';

  static DbCollection? get _collection =>
      DatabaseConnection.getCollection(_collectionName);
  
  static DbCollection? get _bmiCatalogCollection =>
      DatabaseConnection.getCollection(_bmiCatalogCollectionName);

  // Thêm bản ghi sức khỏe mới
  static Future<bool> addHealthEntry(HealthDiary entry) async {
    try {
      var collection = _collection;
      if (collection == null) {
        throw Exception('Database chưa được kết nối');
      }

      // Tính BMI
      entry.bmi = entry.calculateBMI();
      
      // Tìm BMI label từ bmi_catalog
      entry.bmiLabel = await _getBMILabel(entry.bmi!);

      var result = await collection.insertOne(entry.toMap());
      print('✅ Thêm health diary thành công: ${result.id}');
      return true;
    } catch (e) {
      print('❌ Lỗi khi thêm health diary: $e');
      return false;
    }
  }

  // Lấy BMI label từ catalog
  static Future<String> _getBMILabel(double bmi) async {
    try {
      var collection = _bmiCatalogCollection;
      if (collection == null) return 'Không xác định';

      var catalogs = await collection.find().toList();
      for (var doc in catalogs) {
        var catalog = BMICatalog.fromMap(doc);
        if (catalog.isInRange(bmi)) {
          return catalog.label;
        }
      }
      return 'Không xác định';
    } catch (e) {
      print('❌ Lỗi khi lấy BMI label: $e');
      return 'Không xác định';
    }
  }

  // Lấy tất cả bản ghi của một user
  static Future<List<HealthDiary>> getUserHealthDiary(int userId) async {
    try {
      var collection = _collection;
      if (collection == null) {
        throw Exception('Database chưa được kết nối');
      }

      var results = await collection
          .find(where.eq('user_id', userId))
          .toList();

      return results.map((doc) => HealthDiary.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy health diary: $e');
      return [];
    }
  }

  // Lấy bản ghi theo ngày
  static Future<HealthDiary?> getHealthDiaryByDate(int userId, String date) async {
    try {
      var collection = _collection;
      if (collection == null) return null;

      var result = await collection.findOne(
        where.eq('user_id', userId).eq('entry_date', date)
      );

      if (result != null) {
        return HealthDiary.fromMap(result);
      }
      return null;
    } catch (e) {
      print('❌ Lỗi khi lấy health diary theo ngày: $e');
      return null;
    }
  }

  // Cập nhật bản ghi
  static Future<bool> updateHealthEntry(ObjectId id, HealthDiary entry) async {
    try {
      var collection = _collection;
      if (collection == null) return false;

      // Tính lại BMI
      entry.bmi = entry.calculateBMI();
      entry.bmiLabel = await _getBMILabel(entry.bmi!);

      var result = await collection.updateOne(
        where.id(id),
        modify.set('weight', entry.weight.toString())
              .set('height', entry.height.toString())
              .set('content', entry.content)
              .set('bmi', entry.bmi)
              .set('bmi_label', entry.bmiLabel),
      );

      return result.nModified > 0;
    } catch (e) {
      print('❌ Lỗi khi cập nhật health diary: $e');
      return false;
    }
  }

  // Xóa bản ghi
  static Future<bool> deleteHealthEntry(ObjectId id) async {
    try {
      var collection = _collection;
      if (collection == null) return false;

      var result = await collection.deleteOne(where.id(id));
      return result.isSuccess;
    } catch (e) {
      print('❌ Lỗi khi xóa health diary: $e');
      return false;
    }
  }

  // Lấy BMI catalog
  static Future<List<BMICatalog>> getBMICatalog() async {
    try {
      var collection = _bmiCatalogCollection;
      if (collection == null) return [];

      var results = await collection.find().toList();
      return results.map((doc) => BMICatalog.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy BMI catalog: $e');
      return [];
    }
  }
}
