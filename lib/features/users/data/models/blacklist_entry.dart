class BlacklistEntry {
  final int id;
  final String type;
  final String value;
  final String reason;
  final DateTime createdAt;

  BlacklistEntry({
    required this.id,
    required this.type,
    required this.value,
    required this.reason,
    required this.createdAt,
  });

  factory BlacklistEntry.fromJson(Map<String, dynamic> json) {
    return BlacklistEntry(
      id: json['id'] as int,
      type: json['type'] ?? 'unknown',
      value: json['value'] ?? '',
      reason: json['reason'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
