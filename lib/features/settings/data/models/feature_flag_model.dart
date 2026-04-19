

enum FeatureFlagCategory {
  customerApp('Customer App'),
  dealerPortal('Dealer Portal'),
  adminPortal('Admin Portal'),
  experimental('Experimental');

  final String label;
  const FeatureFlagCategory(this.label);
}

class FeatureFlagHistoryEntry {
  final String changedBy;
  final DateTime timestamp;
  final bool oldValue;
  final bool newValue;
  final String? comment;

  FeatureFlagHistoryEntry({
    required this.changedBy,
    required this.timestamp,
    required this.oldValue,
    required this.newValue,
    this.comment,
  });

  factory FeatureFlagHistoryEntry.fromJson(Map<String, dynamic> json) {
    return FeatureFlagHistoryEntry(
      changedBy: json['changed_by'] ?? 'System',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      oldValue: json['old_value'] ?? false,
      newValue: json['new_value'] ?? false,
      comment: json['comment'],
    );
  }
}

class FeatureFlagModel {
  final String key;
  final String name;
  final String description;
  final bool isEnabled;
  final FeatureFlagCategory category;
  final List<String> affectedApps;
  final String lastChangedBy;
  final DateTime lastChangedAt;
  final List<FeatureFlagHistoryEntry> history;
  final Map<String, bool> overrides;

  FeatureFlagModel({
    required this.key,
    required this.name,
    required this.description,
    required this.isEnabled,
    required this.category,
    required this.affectedApps,
    required this.lastChangedBy,
    required this.lastChangedAt,
    this.history = const [],
    this.overrides = const {},
  });

  FeatureFlagModel copyWith({
    String? name,
    String? description,
    bool? isEnabled,
    FeatureFlagCategory? category,
    List<String>? affectedApps,
    String? lastChangedBy,
    DateTime? lastChangedAt,
    List<FeatureFlagHistoryEntry>? history,
    Map<String, bool>? overrides,
  }) {
    return FeatureFlagModel(
      key: key,
      name: name ?? this.name,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
      category: category ?? this.category,
      affectedApps: affectedApps ?? this.affectedApps,
      lastChangedBy: lastChangedBy ?? this.lastChangedBy,
      lastChangedAt: lastChangedAt ?? this.lastChangedAt,
      history: history ?? this.history,
      overrides: overrides ?? this.overrides,
    );
  }

  factory FeatureFlagModel.fromJson(Map<String, dynamic> json) {
    return FeatureFlagModel(
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isEnabled: json['is_enabled'] ?? false,
      category: _categoryFromString(json['category']),
      affectedApps: List<String>.from(json['affected_apps'] ?? []),
      lastChangedBy: json['last_changed_by'] ?? 'Unknown',
      lastChangedAt: DateTime.parse(json['last_changed_at'] ?? DateTime.now().toIso8601String()),
      history: (json['history'] as List? ?? [])
          .map((e) => FeatureFlagHistoryEntry.fromJson(e))
          .toList(),
      overrides: Map<String, bool>.from(json['overrides'] ?? {}),
    );
  }

  static FeatureFlagCategory _categoryFromString(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'customer':
      case 'customer app':
        return FeatureFlagCategory.customerApp;
      case 'dealer':
      case 'dealer portal':
        return FeatureFlagCategory.dealerPortal;
      case 'admin':
      case 'admin portal':
        return FeatureFlagCategory.adminPortal;
      case 'experimental':
        return FeatureFlagCategory.experimental;
      default:
        return FeatureFlagCategory.experimental;
    }
  }
}
