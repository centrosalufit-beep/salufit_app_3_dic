class UserModel {

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'client',
    );
  }
  final String id;
  final String email;
  final String role;
}
