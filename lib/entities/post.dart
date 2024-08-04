class Post {
  final String? id;
  final String title;
  final String body;
  final int likes;
  final DateTime createdAt;
  final bool isDeleted;
  final double viralScore;

  Post({
    required this.id,
    required this.title,
    required this.body,
    required this.likes,
    required this.createdAt,
    required this.isDeleted,
    required this.viralScore,
  });
}
