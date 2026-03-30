class SystemConfigItem {
  final int id;
  final String key;
  final String value;
  final String? description;

  SystemConfigItem({required this.id, required this.key, required this.value, this.description});

  factory SystemConfigItem.fromJson(Map<String, dynamic> json) => SystemConfigItem(
    id: (json['id'] is int) ? json['id'] : 0,
    key: json['key']?.toString() ?? '',
    value: json['value']?.toString() ?? '',
    description: json['description']?.toString(),
  );
}

class FeatureFlagItem {
  final int id;
  final String name;
  final String key;
  final String? description;
  final bool isEnabled;

  FeatureFlagItem({
    required this.id, required this.name, required this.key, this.description, required this.isEnabled,
  });

  factory FeatureFlagItem.fromJson(Map<String, dynamic> json) => FeatureFlagItem(
    id: (json['id'] is int) ? json['id'] : 0,
    name: json['name']?.toString() ?? '',
    key: json['key']?.toString() ?? '',
    description: json['description']?.toString(),
    isEnabled: json['is_enabled'] == true,
  );
}

class ApiKeyItem {
  final int id;
  final String serviceName;
  final String keyName;
  final String keyValueMasked;
  final String environment;
  final bool isActive;
  final String? lastUsedAt;

  ApiKeyItem({
    required this.id, required this.serviceName, required this.keyName,
    required this.keyValueMasked, required this.environment, required this.isActive,
    this.lastUsedAt,
  });

  factory ApiKeyItem.fromJson(Map<String, dynamic> json) => ApiKeyItem(
    id: (json['id'] is int) ? json['id'] : 0,
    serviceName: json['service_name']?.toString() ?? '',
    keyName: json['key_name']?.toString() ?? '',
    keyValueMasked: json['key_value_masked']?.toString() ?? '****',
    environment: json['environment']?.toString() ?? 'development',
    isActive: json['is_active'] == true,
    lastUsedAt: json['last_used_at']?.toString(),
  );
}
