import 'package:mongo_dart/mongo_dart.dart';

class User {
  ObjectId? id;
  int idUser;
  String fullName;
  String birthDate;
  String gender;
  String email;
  String username;
  String password;

  User({
    this.id,
    required this.idUser,
    required this.fullName,
    required this.birthDate,
    required this.gender,
    required this.email,
    required this.username,
    required this.password,
  });

  // Chuyển từ Map sang User object
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['_id'],
      idUser: map['id_user'],
      fullName: map['full_name'],
      birthDate: map['birth_date'],
      gender: map['gender'],
      email: map['email'],
      username: map['username'],
      password: map['password'],
    );
  }

  // Chuyển từ User object sang Map
  Map<String, dynamic> toMap() {
    return {
      'id_user': idUser,
      'full_name': fullName,
      'birth_date': birthDate,
      'gender': gender,
      'email': email,
      'username': username,
      'password': password,
    };
  }
}
