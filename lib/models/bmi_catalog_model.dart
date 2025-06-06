import 'package:mongo_dart/mongo_dart.dart';

class BMICatalog {
  ObjectId? id;
  int bmiId;
  String label;
  double minValue;
  double maxValue;

  BMICatalog({
    this.id,
    required this.bmiId,
    required this.label,
    required this.minValue,
    required this.maxValue,
  });

  factory BMICatalog.fromMap(Map<String, dynamic> map) {
    return BMICatalog(
      id: map['_id'],
      bmiId: map['bmi_id'],
      label: map['label'],
      minValue: map['min_value'].toDouble(),
      maxValue: map['max_value'].toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bmi_id': bmiId,
      'label': label,
      'min_value': minValue,
      'max_value': maxValue,
    };
  }

  // Kiểm tra BMI có nằm trong range này không
  bool isInRange(double bmi) {
    return bmi >= minValue && bmi <= maxValue;
  }
}
