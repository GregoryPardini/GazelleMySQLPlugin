import 'package:gazelle_mysql_plugin/entities/post.dart';

class User {
  final String? id;
  final String name;
  final String email;
  final int age;
  final DateTime dateOfBirth;
  final double height;
  final bool isDeleted;
  final String? password;
  final Post? post;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.dateOfBirth,
    required this.height,
    required this.isDeleted,
    required this.password,
    required this.post,
  });
}
