class InviteLink {
  final int id;
  final String token;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String createdBy;
  final DateTime? usedAt;
  final bool isUsed;

  const InviteLink({
    required this.id,
    required this.token,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.expiresAt,
    required this.createdBy,
    this.usedAt,
    this.isUsed = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  String get status {
    if (isUsed) return 'Used';
    if (isExpired) return 'Expired';
    return 'Pending';
  }

  String get inviteUrl => 'https://admin.wezu.in/invite/$token';

  InviteLink copyWith({
    int? id,
    String? token,
    String? email,
    String? role,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? createdBy,
    DateTime? usedAt,
    bool? isUsed,
  }) {
    return InviteLink(
      id: id ?? this.id,
      token: token ?? this.token,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdBy: createdBy ?? this.createdBy,
      usedAt: usedAt ?? this.usedAt,
      isUsed: isUsed ?? this.isUsed,
    );
  }
}
