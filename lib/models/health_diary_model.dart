import 'package:mongo_dart/mongo_dart.dart';

class HealthDiary {
  ObjectId? id;
  int userId;
  String entryDate;
  double weight;
  double height;
  String? content;
  double? bmi;
  String? bmiLabel;

  HealthDiary({
    this.id,
    required this.userId,
    required this.entryDate,
    required this.weight,
    required this.height,
    this.content,
    this.bmi,
    this.bmiLabel,
  });

  // Chuyển từ Map sang HealthDiary object
  factory HealthDiary.fromMap(Map<String, dynamic> map) {
    return HealthDiary(
      id: map['_id'],
      userId: map['user_id'],
      entryDate: map['entry_date'],
      weight: double.tryParse(map['weight'].toString()) ?? 0.0,
      height: double.tryParse(map['height'].toString()) ?? 0.0,
      content: map['content'],
      bmi: map['bmi']?.toDouble(),
      bmiLabel: map['bmi_label'],
    );
  }

  // Chuyển từ HealthDiary object sang Map
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'entry_date': entryDate,
      'weight': weight.toString(),
      'height': height.toString(),
      'content': content,
      'bmi': bmi,
      'bmi_label': bmiLabel,
    };
  }

  // Tính BMI
  double calculateBMI() {
    if (height > 0) {
      return weight / ((height / 100) * (height / 100));
    }
    return 0.0;
  }
}
