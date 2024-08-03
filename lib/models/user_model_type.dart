import 'package:gazelle_serialization/gazelle_serialization.dart';

import '../entities/user.dart';

class UserModelType extends GazelleModelType<User> {
  @override
  User fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"] as String,
      name: json["name"] as String,
      email: json["email"] as String,
      age: json["age"] as int,
      dateOfBirth: DateTime.parse(json["dateOfBirth"] as String),
      height: json["height"] as double,
      isDeleted: json["isDeleted"] == 0 ? false : true,
    );
  }

  @override
  Map<String, dynamic> toJson(User value) {
    return {
      "id": value.id,
      "name": value.name,
      "email": value.email,
      "age": value.age,
      "dateOfBirth": value.dateOfBirth.toIso8601String(),
      "height": value.height,
      "isDeleted": value.isDeleted,
    };
  }

  @override
  Map<String, String> get modelAttributes => {
        "id": "String",
        "name": "String",
        "email": "String",
        "age": "int",
        "dateOfBirth": "DateTime",
        "height": "double",
        "isDeleted": "bool",
      };
}
