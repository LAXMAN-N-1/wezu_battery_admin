class RoleModel {
  final String id;
  final String name;
  final String description;
  final List<String> permissions;
  final int userCount;

  RoleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    required this.userCount,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      permissions: List<String>.from(json['permissions'] ?? []),
      userCount: json['user_count'] ?? 0,
    );
  }
}
