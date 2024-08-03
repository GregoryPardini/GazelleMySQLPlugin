class User {
  final String? id;
  final String name;
  final String email;
  final int age;
  final DateTime dateOfBirth;
  final double height;
  final bool isDeleted;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.dateOfBirth,
    required this.height,
    required this.isDeleted,
  });
}
