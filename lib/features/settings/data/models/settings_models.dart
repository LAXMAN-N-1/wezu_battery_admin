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
  final String? expiresAt;
  final String category;
  final List<String> permissions;

  ApiKeyItem({
    required this.id,
    required this.serviceName,
    required this.keyName,
    required this.keyValueMasked,
    required this.environment,
    required this.isActive,
    this.lastUsedAt,
    this.expiresAt,
    this.category = 'Custom',
    this.permissions = const ['Read', 'Write'],
  });

  factory ApiKeyItem.fromJson(Map<String, dynamic> json) {
    final service = json['service_name']?.toString() ?? '';
    List<String> perms = ['Read', 'Write'];
    if (json['permissions'] is List) {
      perms = (json['permissions'] as List).map((e) => e.toString()).toList();
    }

    return ApiKeyItem(
      id: (json['id'] is int) ? json['id'] : 0,
      serviceName: service,
      keyName: json['key_name']?.toString() ?? '',
      keyValueMasked: json['key_value_masked']?.toString() ?? '****',
      environment: json['environment']?.toString() ?? 'development',
      isActive: json['is_active'] == true,
      lastUsedAt: json['last_used_at']?.toString(),
      expiresAt: json['expires_at']?.toString(),
      category: json['category']?.toString() ?? _inferCategory(service),
      permissions: perms,
    );
  }

  ApiKeyItem copyWith({
    int? id,
    String? serviceName,
    String? keyName,
    String? keyValueMasked,
    String? environment,
    bool? isActive,
    String? lastUsedAt,
    String? expiresAt,
    String? category,
    List<String>? permissions,
  }) {
    return ApiKeyItem(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      keyName: keyName ?? this.keyName,
      keyValueMasked: keyValueMasked ?? this.keyValueMasked,
      environment: environment ?? this.environment,
      isActive: isActive ?? this.isActive,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      category: category ?? this.category,
      permissions: permissions ?? this.permissions,
    );
  }

  static String _inferCategory(String service) {
    final lower = service.toLowerCase();
    if (lower.contains('stripe') || lower.contains('razorpay') || lower.contains('paypal')) return 'Payments';
    if (lower.contains('twilio') || lower.contains('messagebird')) return 'SMS / Messaging';
    if (lower.contains('sendgrid') || lower.contains('mailgun')) return 'Email Service';
    if (lower.contains('aws') || lower.contains('s3') || lower.contains('gcp')) return 'Storage';
    if (lower.contains('mixpanel') || lower.contains('google_analytics')) return 'Analytics';
    if (lower.contains('webhook')) return 'Webhooks';
    return 'Custom';
  }
}

class WebhookItem {
  final int id;
  final String url;
  final List<String> events;
  final bool isActive;
  final String? lastPingAt;
  final String? secret;
  final int? lastResponseCode;

  WebhookItem({
    required this.id,
    required this.url,
    required this.events,
    required this.isActive,
    this.lastPingAt,
    this.secret,
    this.lastResponseCode,
  });

  factory WebhookItem.fromJson(Map<String, dynamic> json) {
    return WebhookItem(
      id: (json['id'] is int) ? json['id'] : 0,
      url: json['url']?.toString() ?? '',
      events: (json['events'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isActive: json['is_active'] == true,
      lastPingAt: json['last_ping_at']?.toString(),
      secret: json['secret']?.toString(),
      lastResponseCode: json['last_response_code'] as int?,
    );
  }

  WebhookItem copyWith({
    int? id,
    String? url,
    List<String>? events,
    bool? isActive,
    String? lastPingAt,
    String? secret,
    int? lastResponseCode,
  }) {
    return WebhookItem(
      id: id ?? this.id,
      url: url ?? this.url,
      events: events ?? this.events,
      isActive: isActive ?? this.isActive,
      lastPingAt: lastPingAt ?? this.lastPingAt,
      secret: secret ?? this.secret,
      lastResponseCode: lastResponseCode ?? this.lastResponseCode,
    );
  }
}
