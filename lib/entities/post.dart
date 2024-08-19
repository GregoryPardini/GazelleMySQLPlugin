import 'package:gazelle_mysql_plugin/entities/user.dart';

class Post {
  final String? id;
  final String title;
  final String body;
  final int likes;
  final DateTime createdAt;
  final bool isDeleted;
  final double viralScore;
  final User? user;

  Post({
    required this.id,
    required this.title,
    required this.body,
    required this.likes,
    required this.createdAt,
    required this.isDeleted,
    required this.viralScore,
    required this.user,
  });
}
