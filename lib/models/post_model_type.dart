import 'package:gazelle_serialization/gazelle_serialization.dart';

import '../entities/post.dart';

class PostModelType extends GazelleModelType<Post> {
  @override
  Post fromJson(Map<String, dynamic> json) {
    return Post(
      id: json["id"] as String,
      title: json["title"] as String,
      body: json["body"] as String,
      likes: json["likes"] as int,
      createdAt: DateTime.parse(json["createdAt"] as String),
      isDeleted: json["isDeleted"] == 0 ? false : true,
      viralScore: json["viralScore"] as double,
    );
  }

  @override
  Map<String, dynamic> toJson(Post value) {
    return {
      "id": value.id,
      "title": value.title,
      "body": value.body,
      "likes": value.likes,
      "createdAt": value.createdAt.toIso8601String(),
      "isDeleted": value.isDeleted,
      "viralScore": value.viralScore,
    };
  }

  @override
  Map<String, String> get modelAttributes => {
        "id": "String?",
        "title": "String",
        "body": "String",
        "likes": "int",
        "createdAt": "DateTime",
        "isDeleted": "bool",
        "viralScore": "double",
      };
}
