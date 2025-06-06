import 'package:flutter_test/flutter_test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../lib/models/health_diary_model.dart';

// Helper functions for health diary validation
String? _validateWeight(String weightStr) {
  if (weightStr.trim().isEmpty) {
    return 'Vui lòng nhập cân nặng';
  }
  
  double? weight = double.tryParse(weightStr);
  if (weight == null) {
    return 'Cân nặng phải là số';
  }
  
  if (weight <= 0) {
    return 'Cân nặng phải lớn hơn 0';
  }
  
  if (weight < 20) {
    return 'Cân nặng quá thấp (tối thiểu 20kg)';
  }
  
  if (weight > 300) {
    return 'Cân nặng quá cao (tối đa 300kg)';
  }
  
  return null;
}

String? _validateHeight(String heightStr) {
  if (heightStr.trim().isEmpty) {
    return 'Vui lòng nhập chiều cao';
  }
  
  double? height = double.tryParse(heightStr);
  if (height == null) {
    return 'Chiều cao phải là số';
  }
  
  if (height <= 0) {
    return 'Chiều cao phải lớn hơn 0';
  }
  
  if (height < 100) {
    return 'Chiều cao quá thấp (tối thiểu 100cm)';
  }
  
  if (height > 250) {
    return 'Chiều cao quá cao (tối đa 250cm)';
  }
  
  return null;
}

String? _validateDate(String dateStr) {
  if (dateStr.trim().isEmpty) {
    return 'Vui lòng chọn ngày';
  }
  
  // Check for valid ISO format (YYYY-MM-DD)
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr.trim())) {
    return 'Định dạng ngày không hợp lệ';
  }
  
  try {
    DateTime date = DateTime.parse(dateStr);
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    
    // Additional validation for impossible dates
    List<String> parts = dateStr.split('-');
    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    int day = int.parse(parts[2]);
    
    if (month < 1 || month > 12) {
      return 'Định dạng ngày không hợp lệ';
    }
    
    if (day < 1 || day > 31) {
      return 'Định dạng ngày không hợp lệ';
    }
    
    // Check if the parsed date matches the input (catches invalid dates like 2024-02-30)
    if (date.year != year || date.month != month || date.day != day) {
      return 'Định dạng ngày không hợp lệ';
    }
    
    if (date.isAfter(today)) {
      return 'Không thể chọn ngày trong tương lai';
    }
    
    DateTime oneYearAgo = today.subtract(Duration(days: 365));
    if (date.isBefore(oneYearAgo)) {
      return 'Ngày quá xa (chỉ được trong vòng 1 năm)';
    }
    
    return null;
  } catch (e) {
    return 'Định dạng ngày không hợp lệ';
  }
}

String? _validateContent(String content) {
  if (content.trim().length > 500) {
    return 'Nội dung không được quá 500 ký tự';
  }
  return null;
}

String? _validateUserId(int? userId) {
  if (userId == null || userId <= 0) {
    return 'ID người dùng không hợp lệ';
  }
  return null;
}

double _calculateBMI(double weight, double height) {
  if (height <= 0) return 0.0;
  return weight / ((height / 100) * (height / 100));
}

String _getBMILabel(double bmi) {
  if (bmi < 18.5) return 'Thiếu cân';
  if (bmi < 25) return 'Bình thường';
  if (bmi < 30) return 'Thừa cân';
  return 'Béo phì';
}

bool _isValidHealthDiary(HealthDiary diary) {
  return _validateWeight(diary.weight.toString()) == null &&
         _validateHeight(diary.height.toString()) == null &&
         _validateDate(diary.entryDate) == null &&
         _validateContent(diary.content ?? '') == null &&
         _validateUserId(diary.userId) == null;
}

void main() {
  group('1. Weight Validation Tests', () {
    test('PASS - Valid weights', () {
      expect(_validateWeight('50'), isNull);
      expect(_validateWeight('65.5'), isNull);
      expect(_validateWeight('80'), isNull);
      expect(_validateWeight('100.25'), isNull);
      expect(_validateWeight('150'), isNull);
    });

    test('1.2 Invalid weights - Empty/null', () {
      expect(_validateWeight(''), equals('Vui lòng nhập cân nặng'));
      expect(_validateWeight('   '), equals('Vui lòng nhập cân nặng'));
      expect(_validateWeight('\t\n'), equals('Vui lòng nhập cân nặng'));
    });

    test('1.3 Invalid weights - Not numbers', () {
      expect(_validateWeight('abc'), equals('Cân nặng phải là số'));
      expect(_validateWeight('50kg'), equals('Cân nặng phải là số'));
      expect(_validateWeight('không biết'), equals('Cân nặng phải là số'));
      expect(_validateWeight('50.5.5'), equals('Cân nặng phải là số'));
      expect(_validateWeight('--50'), equals('Cân nặng phải là số'));
    });

    test('1.4 Invalid weights - Zero/negative', () {
      expect(_validateWeight('0'), equals('Cân nặng phải lớn hơn 0'));
      expect(_validateWeight('-10'), equals('Cân nặng phải lớn hơn 0'));
      expect(_validateWeight('-0.5'), equals('Cân nặng phải lớn hơn 0'));
    });

    test('1.5 Invalid weights - Too low', () {
      expect(_validateWeight('5'), equals('Cân nặng quá thấp (tối thiểu 20kg)'));
      expect(_validateWeight('19.9'), equals('Cân nặng quá thấp (tối thiểu 20kg)'));
      expect(_validateWeight('10'), equals('Cân nặng quá thấp (tối thiểu 20kg)'));
    });

    test('1.6 Invalid weights - Too high', () {
      expect(_validateWeight('301'), equals('Cân nặng quá cao (tối đa 300kg)'));
      expect(_validateWeight('500'), equals('Cân nặng quá cao (tối đa 300kg)'));
      expect(_validateWeight('999.9'), equals('Cân nặng quá cao (tối đa 300kg)'));
    });

    test('1.7 Boundary weight values', () {
      expect(_validateWeight('20'), isNull); // Minimum valid
      expect(_validateWeight('19.9'), isNotNull); // Just below minimum
      expect(_validateWeight('300'), isNull); // Maximum valid
      expect(_validateWeight('300.1'), isNotNull); // Just above maximum
    });
  });

  group('2. Height Validation Tests', () {
    test('2.1 Valid heights', () {
      expect(_validateHeight('150'), isNull);
      expect(_validateHeight('165.5'), isNull);
      expect(_validateHeight('180'), isNull);
      expect(_validateHeight('200.25'), isNull);
      expect(_validateHeight('170'), isNull);
    });

    test('2.2 Invalid heights - Empty/null', () {
      expect(_validateHeight(''), equals('Vui lòng nhập chiều cao'));
      expect(_validateHeight('   '), equals('Vui lòng nhập chiều cao'));
      expect(_validateHeight('\t'), equals('Vui lòng nhập chiều cao'));
    });

    test('2.3 Invalid heights - Not numbers', () {
      expect(_validateHeight('abc'), equals('Chiều cao phải là số'));
      expect(_validateHeight('170cm'), equals('Chiều cao phải là số'));
      expect(_validateHeight('một mét bảy'), equals('Chiều cao phải là số'));
      expect(_validateHeight('1.70m'), equals('Chiều cao phải là số'));
      expect(_validateHeight('++170'), equals('Chiều cao phải là số'));
    });

    test('2.4 Invalid heights - Zero/negative', () {
      expect(_validateHeight('0'), equals('Chiều cao phải lớn hơn 0'));
      expect(_validateHeight('-170'), equals('Chiều cao phải lớn hơn 0'));
      expect(_validateHeight('-1.5'), equals('Chiều cao phải lớn hơn 0'));
    });

    test('2.5 Invalid heights - Too low', () {
      expect(_validateHeight('50'), equals('Chiều cao quá thấp (tối thiểu 100cm)'));
      expect(_validateHeight('99.9'), equals('Chiều cao quá thấp (tối thiểu 100cm)'));
      expect(_validateHeight('80'), equals('Chiều cao quá thấp (tối thiểu 100cm)'));
    });

    test('2.6 Invalid heights - Too high', () {
      expect(_validateHeight('251'), equals('Chiều cao quá cao (tối đa 250cm)'));
      expect(_validateHeight('300'), equals('Chiều cao quá cao (tối đa 250cm)'));
      expect(_validateHeight('999'), equals('Chiều cao quá cao (tối đa 250cm)'));
    });

    test('2.7 Boundary height values', () {
      expect(_validateHeight('100'), isNull); // Minimum valid
      expect(_validateHeight('99.9'), isNotNull); // Just below minimum
      expect(_validateHeight('250'), isNull); // Maximum valid
      expect(_validateHeight('250.1'), isNotNull); // Just above maximum
    });
  });

  group('3. Date Validation Tests', () {
    test('3.1 Valid dates', () {
      DateTime now = DateTime.now();
      String today = DateTime(now.year, now.month, now.day).toString().split(' ')[0];
      String yesterday = DateTime(now.year, now.month, now.day - 1).toString().split(' ')[0];
      String lastWeek = DateTime(now.year, now.month, now.day - 7).toString().split(' ')[0];
      
      expect(_validateDate(today), isNull);
      expect(_validateDate(yesterday), isNull);
      expect(_validateDate(lastWeek), isNull);
    });

    test('3.2 Invalid dates - Empty', () {
      expect(_validateDate(''), equals('Vui lòng chọn ngày'));
      expect(_validateDate('   '), equals('Vui lòng chọn ngày'));
    });

    test('3.3 Invalid dates - Wrong format', () {
      expect(_validateDate('31/12/2024'), equals('Định dạng ngày không hợp lệ'));
      expect(_validateDate('2024/12/31'), equals('Định dạng ngày không hợp lệ'));
      expect(_validateDate('ngày hôm nay'), equals('Định dạng ngày không hợp lệ'));
      expect(_validateDate('2024-13-01'), equals('Định dạng ngày không hợp lệ'));
      expect(_validateDate('2024-12-32'), equals('Định dạng ngày không hợp lệ'));
    });

    test('3.4 Invalid dates - Future dates', () {
      DateTime tomorrow = DateTime.now().add(Duration(days: 1));
      DateTime nextWeek = DateTime.now().add(Duration(days: 7));
      DateTime nextMonth = DateTime.now().add(Duration(days: 30));
      
      String tomorrowStr = DateTime(tomorrow.year, tomorrow.month, tomorrow.day).toString().split(' ')[0];
      String nextWeekStr = DateTime(nextWeek.year, nextWeek.month, nextWeek.day).toString().split(' ')[0];
      String nextMonthStr = DateTime(nextMonth.year, nextMonth.month, nextMonth.day).toString().split(' ')[0];
      
      expect(_validateDate(tomorrowStr), equals('Không thể chọn ngày trong tương lai'));
      expect(_validateDate(nextWeekStr), equals('Không thể chọn ngày trong tương lai'));
      expect(_validateDate(nextMonthStr), equals('Không thể chọn ngày trong tương lai'));
    });

    test('3.5 Invalid dates - Too old', () {
      DateTime twoYearsAgo = DateTime.now().subtract(Duration(days: 730));
      DateTime threeYearsAgo = DateTime.now().subtract(Duration(days: 1095));
      
      String twoYearsStr = DateTime(twoYearsAgo.year, twoYearsAgo.month, twoYearsAgo.day).toString().split(' ')[0];
      String threeYearsStr = DateTime(threeYearsAgo.year, threeYearsAgo.month, threeYearsAgo.day).toString().split(' ')[0];
      
      expect(_validateDate(twoYearsStr), equals('Ngày quá xa (chỉ được trong vòng 1 năm)'));
      expect(_validateDate(threeYearsStr), equals('Ngày quá xa (chỉ được trong vòng 1 năm)'));
    });

    test('3.6 Boundary date values', () {
      DateTime now = DateTime.now();
      DateTime exactlyOneYearAgo = DateTime(now.year - 1, now.month, now.day);
      DateTime justOverOneYear = exactlyOneYearAgo.subtract(Duration(days: 1));
      
      String oneYearStr = exactlyOneYearAgo.toString().split(' ')[0];
      String overYearStr = justOverOneYear.toString().split(' ')[0];
      
      expect(_validateDate(oneYearStr), isNull); // Exactly one year should be valid
      expect(_validateDate(overYearStr), isNotNull); // Just over one year should fail
    });
  });

  group('4. Content Validation Tests', () {
    test('4.1 Valid content', () {
      expect(_validateContent(''), isNull); // Empty content is allowed
      expect(_validateContent('Hôm nay cảm thấy khỏe mạnh'), isNull);
      expect(_validateContent('Đã tập thể dục 30 phút'), isNull);
      expect(_validateContent('a' * 500), isNull); // Maximum length
    });

    test('4.2 Invalid content - Too long', () {
      expect(_validateContent('a' * 501), equals('Nội dung không được quá 500 ký tự'));
      expect(_validateContent('a' * 1000), equals('Nội dung không được quá 500 ký tự'));
      
      String longContent = 'Hôm nay tôi đã thực hiện rất nhiều hoạt động thể thao và ăn uống lành mạnh. ' * 10;
      expect(_validateContent(longContent), equals('Nội dung không được quá 500 ký tự'));
    });

    test('4.3 Content boundary values', () {
      expect(_validateContent('a' * 499), isNull); // Just under limit
      expect(_validateContent('a' * 500), isNull); // Exactly at limit
      expect(_validateContent('a' * 501), isNotNull); // Just over limit
    });
  });

  group('5. User ID Validation Tests', () {
    test('5.1 Valid user IDs', () {
      expect(_validateUserId(1), isNull);
      expect(_validateUserId(100), isNull);
      expect(_validateUserId(999999), isNull);
    });

    test('5.2 Invalid user IDs', () {
      expect(_validateUserId(null), equals('ID người dùng không hợp lệ'));
      expect(_validateUserId(0), equals('ID người dùng không hợp lệ'));
      expect(_validateUserId(-1), equals('ID người dùng không hợp lệ'));
      expect(_validateUserId(-100), equals('ID người dùng không hợp lệ'));
    });
  });

  group('6. BMI Calculation Tests', () {
    test('6.1 Correct BMI calculations', () {
      expect(_calculateBMI(70, 170), closeTo(24.22, 0.01));
      expect(_calculateBMI(60, 160), closeTo(23.44, 0.01));
      expect(_calculateBMI(80, 180), closeTo(24.69, 0.01));
      expect(_calculateBMI(50, 150), closeTo(22.22, 0.01));
    });

    test('6.2 BMI edge cases', () {
      expect(_calculateBMI(70, 0), equals(0.0)); // Division by zero protection
      expect(_calculateBMI(0, 170), equals(0.0)); // Zero weight
      expect(_calculateBMI(70, -170), equals(0.0)); // Negative height
    });

    test('6.3 BMI label classification', () {
      expect(_getBMILabel(15), equals('Thiếu cân'));
      expect(_getBMILabel(18.4), equals('Thiếu cân'));
      expect(_getBMILabel(18.5), equals('Bình thường'));
      expect(_getBMILabel(22), equals('Bình thường'));
      expect(_getBMILabel(24.9), equals('Bình thường'));
      expect(_getBMILabel(25), equals('Thừa cân'));
      expect(_getBMILabel(28), equals('Thừa cân'));
      expect(_getBMILabel(29.9), equals('Thừa cân'));
      expect(_getBMILabel(30), equals('Béo phì'));
      expect(_getBMILabel(35), equals('Béo phì'));
    });
  });

  group('7. HealthDiary Model Tests', () {
    test('7.1 Create valid HealthDiary', () {
      final diary = HealthDiary(
        userId: 1,
        entryDate: '2024-12-01',
        weight: 70.5,
        height: 170.0,
        content: 'Feeling good today',
      );

      expect(diary.userId, equals(1));
      expect(diary.weight, equals(70.5));
      expect(diary.height, equals(170.0));
      expect(diary.entryDate, equals('2024-12-01'));
      expect(diary.content, equals('Feeling good today'));
    });

    test('7.2 HealthDiary toMap conversion', () {
      final diary = HealthDiary(
        userId: 1,
        entryDate: '2024-12-01',
        weight: 70.5,
        height: 170.0,
        content: 'Test content',
        bmi: 24.22,
        bmiLabel: 'Bình thường',
      );

      final map = diary.toMap();
      expect(map['user_id'], equals(1));
      expect(map['weight'], equals('70.5'));
      expect(map['height'], equals('170.0'));
      expect(map['entry_date'], equals('2024-12-01'));
      expect(map['content'], equals('Test content'));
      expect(map['bmi'], equals(24.22));
      expect(map['bmi_label'], equals('Bình thường'));
    });

    test('7.3 HealthDiary fromMap conversion', () {
      final map = {
        '_id': ObjectId(),
        'user_id': 1,
        'entry_date': '2024-12-01',
        'weight': '70.5',
        'height': '170.0',
        'content': 'Test content',
        'bmi': 24.22,
        'bmi_label': 'Bình thường',
      };

      final diary = HealthDiary.fromMap(map);
      expect(diary.userId, equals(1));
      expect(diary.weight, equals(70.5));
      expect(diary.height, equals(170.0));
      expect(diary.entryDate, equals('2024-12-01'));
      expect(diary.content, equals('Test content'));
      expect(diary.bmi, equals(24.22));
      expect(diary.bmiLabel, equals('Bình thường'));
    });

    test('7.4 HealthDiary BMI calculation method', () {
      final diary = HealthDiary(
        userId: 1,
        entryDate: '2024-12-01',
        weight: 70.0,
        height: 170.0,
      );

      double calculatedBMI = diary.calculateBMI();
      expect(calculatedBMI, closeTo(24.22, 0.01));
    });

    test('7.5 HealthDiary with zero height', () {
      final diary = HealthDiary(
        userId: 1,
        entryDate: '2024-12-01',
        weight: 70.0,
        height: 0.0,
      );

      double calculatedBMI = diary.calculateBMI();
      expect(calculatedBMI, equals(0.0));
    });
  });

  group('8. Complete Diary Validation Tests', () {
    test('8.1 Valid complete diary', () {
      final diary = HealthDiary(
        userId: 1,
        entryDate: '2024-12-01',
        weight: 70.0,
        height: 170.0,
        content: 'Feeling healthy today',
      );

      expect(_isValidHealthDiary(diary), isTrue);
    });

    test('8.2 Invalid diary - Bad weight', () {
      final diary = HealthDiary(
        userId: 1,
        entryDate: '2024-12-01',
        weight: 0.0, // Invalid weight
        height: 170.0,
        content: 'Test',
      );

      expect(_isValidHealthDiary(diary), isFalse);
    });

    test('8.3 Invalid diary - Bad height', () {
      final diary = HealthDiary(
        userId: 1,
        entryDate: '2024-12-01',
        weight: 70.0,
        height: 50.0, // Invalid height (too low)
        content: 'Test',
      );

      expect(_isValidHealthDiary(diary), isFalse);
    });

    test('8.4 Invalid diary - Bad user ID', () {
      final diary = HealthDiary(
        userId: 0, // Invalid user ID
        entryDate: '2024-12-01',
        weight: 70.0,
        height: 170.0,
        content: 'Test',
      );

      expect(_isValidHealthDiary(diary), isFalse);
    });

    test('8.5 Invalid diary - Long content', () {
      final diary = HealthDiary(
        userId: 1,
        entryDate: '2024-12-01',
        weight: 70.0,
        height: 170.0,
        content: 'a' * 501, // Content too long
      );

      expect(_isValidHealthDiary(diary), isFalse);
    });
  });

  group('9. Real-world Scenarios', () {
    test('9.1 Common user input mistakes', () {
      // Weight with unit
      expect(_validateWeight('70kg'), isNotNull);
      expect(_validateWeight('70 kg'), isNotNull);
      
      // Height with unit
      expect(_validateHeight('170cm'), isNotNull);
      expect(_validateHeight('1.7m'), isNotNull);
      
      // Wrong date format
      expect(_validateDate('01/12/2024'), isNotNull);
      expect(_validateDate('2024/12/01'), isNotNull);
    });

    test('9.2 Edge case measurements', () {
      // Very small person
      expect(_validateWeight('20'), isNull); // Minimum valid weight
      expect(_validateHeight('100'), isNull); // Minimum valid height
      
      // Very large person
      expect(_validateWeight('300'), isNull); // Maximum valid weight
      expect(_validateHeight('250'), isNull); // Maximum valid height
      
      // Just outside valid ranges
      expect(_validateWeight('19.9'), isNotNull);
      expect(_validateWeight('300.1'), isNotNull);
      expect(_validateHeight('99.9'), isNotNull);
      expect(_validateHeight('250.1'), isNotNull);
    });    test('9.3 Vietnamese specific scenarios', () {
      // Vietnamese content
      final vietnameseContent = 'Hôm nay tôi cảm thấy rất khỏe mạnh. Đã tập thể dục và ăn uống điều độ.';
      expect(_validateContent(vietnameseContent), isNull);
      
      // Long Vietnamese content (should be over 500 characters)
      final longVietnameseContent = 'Hôm nay là một ngày tuyệt vời cho sức khỏe của tôi. Tôi đã thức dậy lúc 6 giờ sáng và bắt đầu ngày mới với tinh thần thoải mái. Sau khi rửa mặt và đánh răng, tôi đã tập thể dục nhẹ nhàng trong 30 phút bao gồm các bài tập cardio và yoga. Bữa sáng của tôi rất bổ dưỡng với bánh mì nguyên cám, trứng luộc, sữa tươi và một quả chuối. Buổi trưa tôi ăn cơm với nhiều rau xanh như rau muống, cải thảo, cùng với thịt nạc và cá. Buổi chiều tôi đi bộ trong công viên gần nhà khoảng 45 phút để hít thở không khí trong lành và thư giãn tinh thần. Tối về tôi chỉ ăn nhẹ với salad và một ít hoa quả rồi đi ngủ sớm vào lúc 10 giờ. Cảm thấy cơ thể rất khỏe mạnh.';
      expect(longVietnameseContent.length > 500, isTrue); // Verify it's actually over 500 chars
      expect(_validateContent(longVietnameseContent), isNotNull); // Should be too long
    });
  });

  group('10. Security and Attack Tests', () {
    test('10.1 SQL injection attempts', () {
      expect(_validateContent("'; DROP TABLE health_diary; --"), isNull); // Content allows anything
      expect(_validateWeight("50'; DROP TABLE users; --"), isNotNull); // Weight must be number
      expect(_validateHeight("170'; DELETE FROM diary; --"), isNotNull); // Height must be number
    });

    test('10.2 XSS attempts', () {
      expect(_validateContent('<script>alert("xss")</script>'), isNull); // Content allows HTML
      expect(_validateWeight('<script>70</script>'), isNotNull); // Weight must be pure number
      expect(_validateHeight('javascript:170'), isNotNull); // Height must be pure number
    });

    test('10.3 Extreme value attacks', () {
      expect(_validateWeight('999999999'), isNotNull); // Extremely high weight
      expect(_validateHeight('999999999'), isNotNull); // Extremely high height
      expect(_validateContent('a' * 10000), isNotNull); // Extremely long content
    });
  });

  group('11. Multiple Validation Errors', () {
    test('11.1 Diary with multiple errors', () {
      final badDiary = HealthDiary(
        userId: -1, // Error 1: Invalid user ID
        entryDate: '2025-12-31', // Error 2: Future date
        weight: 0, // Error 3: Invalid weight
        height: 50, // Error 4: Invalid height (too low)
        content: 'a' * 600, // Error 5: Content too long
      );

      expect(_validateUserId(badDiary.userId), isNotNull);
      expect(_validateDate(badDiary.entryDate), isNotNull);
      expect(_validateWeight(badDiary.weight.toString()), isNotNull);
      expect(_validateHeight(badDiary.height.toString()), isNotNull);
      expect(_validateContent(badDiary.content!), isNotNull);
      expect(_isValidHealthDiary(badDiary), isFalse);
    });

    test('11.2 All possible weight errors', () {
      // Error 1: Empty weight
      expect(_validateWeight(''), equals('Vui lòng nhập cân nặng'));
      
      // Error 2: Non-numeric weight  
      expect(_validateWeight('abc'), equals('Cân nặng phải là số'));
      
      // Error 3: Zero weight
      expect(_validateWeight('0'), equals('Cân nặng phải lớn hơn 0'));
      
      // Error 4: Negative weight
      expect(_validateWeight('-10'), equals('Cân nặng phải lớn hơn 0'));
      
      // Error 5: Too low weight
      expect(_validateWeight('15'), equals('Cân nặng quá thấp (tối thiểu 20kg)'));
      
      // Error 6: Too high weight
      expect(_validateWeight('350'), equals('Cân nặng quá cao (tối đa 300kg)'));
    });

    test('11.3 All possible height errors', () {
      // Error 1: Empty height
      expect(_validateHeight(''), equals('Vui lòng nhập chiều cao'));
      
      // Error 2: Non-numeric height
      expect(_validateHeight('abc'), equals('Chiều cao phải là số'));
      
      // Error 3: Zero height
      expect(_validateHeight('0'), equals('Chiều cao phải lớn hơn 0'));
      
      // Error 4: Negative height
      expect(_validateHeight('-170'), equals('Chiều cao phải lớn hơn 0'));
      
      // Error 5: Too low height
      expect(_validateHeight('80'), equals('Chiều cao quá thấp (tối thiểu 100cm)'));
      
      // Error 6: Too high height
      expect(_validateHeight('300'), equals('Chiều cao quá cao (tối đa 250cm)'));
    });

    test('11.4 All possible date errors', () {
      // Error 1: Empty date
      expect(_validateDate(''), equals('Vui lòng chọn ngày'));
      
      // Error 2: Invalid format
      expect(_validateDate('invalid'), equals('Định dạng ngày không hợp lệ'));
      
      // Error 3: Future date
      DateTime tomorrow = DateTime.now().add(Duration(days: 1));
      String tomorrowStr = DateTime(tomorrow.year, tomorrow.month, tomorrow.day).toString().split(' ')[0];
      expect(_validateDate(tomorrowStr), equals('Không thể chọn ngày trong tương lai'));
      
      // Error 4: Too old date
      DateTime twoYearsAgo = DateTime.now().subtract(Duration(days: 800));
      String oldDateStr = DateTime(twoYearsAgo.year, twoYearsAgo.month, twoYearsAgo.day).toString().split(' ')[0];
      expect(_validateDate(oldDateStr), equals('Ngày quá xa (chỉ được trong vòng 1 năm)'));
    });

    test('11.5 Content and user ID errors', () {
      // Error 1: Content too long
      expect(_validateContent('a' * 501), equals('Nội dung không được quá 500 ký tự'));
      
      // Error 2: Null user ID
      expect(_validateUserId(null), equals('ID người dùng không hợp lệ'));
      
      // Error 3: Zero user ID
      expect(_validateUserId(0), equals('ID người dùng không hợp lệ'));
      
      // Error 4: Negative user ID
      expect(_validateUserId(-5), equals('ID người dùng không hợp lệ'));
    });
  });
  group('12. Required Failing Tests', () {
    test('FAIL - Weight validation rejects valid weight', () {
      // This test will FAIL because we expect an error but get null (valid)
      expect(_validateWeight('70'), equals('Cân nặng không hợp lệ'));
    });

    test('FAIL - Height validation rejects valid height', () {
      // This test will FAIL because we expect an error but get null (valid)
      expect(_validateHeight('170'), equals('Chiều cao không hợp lệ'));
    });

    test('FAIL - BMI calculation wrong result', () {
      // This test will FAIL because the expected BMI is intentionally wrong
      expect(_calculateBMI(70, 170), equals(25.0)); // Actual is ~24.22
    });

    test('FAIL - User ID validation wrong error', () {
      // This test will FAIL because we expect wrong admin credentials to be true
      expect(_validateUserId(1), equals('ID không hợp lệ')); // This should return null
    });

    test('FAIL - Date validation accepts future date', () {
      // This test will FAIL because future dates should be rejected
      DateTime tomorrow = DateTime.now().add(Duration(days: 1));
      String tomorrowStr = DateTime(tomorrow.year, tomorrow.month, tomorrow.day).toString().split(' ')[0];
      expect(_validateDate(tomorrowStr), isNull); // Should return error message
    });

    test('FAIL - Content validation rejects short content', () {
      // This test will FAIL because short content is actually valid
      expect(_validateContent('OK'), equals('Nội dung quá ngắn'));
    });

    test('FAIL - BMI label wrong classification', () {
      // This test will FAIL because BMI 22 is normal, not overweight
      expect(_getBMILabel(22), equals('Thừa cân')); // Should be 'Bình thường'
    });

    test('FAIL - Valid diary marked as invalid', () {
      // This test will FAIL because the diary is actually valid
      final validDiary = HealthDiary(
        userId: 1,
        entryDate: '2024-12-01',
        weight: 70.0,
        height: 170.0,
        content: 'Feeling good',
      );
      expect(_isValidHealthDiary(validDiary), isFalse); // Should be true
    });
  });
}
