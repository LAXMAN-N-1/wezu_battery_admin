class PushCampaign {
  final int id; final String title; final String message; final String targetSegment;
  final int targetCount; final String channel; final String status;
  final String? scheduledAt; final String? sentAt;
  final int sentCount; final int deliveredCount; final int openCount; final int clickCount; final int failedCount;
  final String createdAt;

  PushCampaign({required this.id, required this.title, required this.message, required this.targetSegment,
    required this.targetCount, required this.channel, required this.status,
    this.scheduledAt, this.sentAt, required this.sentCount, required this.deliveredCount,
    required this.openCount, required this.clickCount, required this.failedCount, required this.createdAt});

  factory PushCampaign.fromJson(Map<String, dynamic> json) => PushCampaign(
    id: (json['id'] is int) ? json['id'] : 0, title: json['title']?.toString() ?? '',
    message: json['message']?.toString() ?? '', targetSegment: json['target_segment']?.toString() ?? 'all',
    targetCount: (json['target_count'] as num?)?.toInt() ?? 0, channel: json['channel']?.toString() ?? 'push',
    status: json['status']?.toString() ?? 'draft', scheduledAt: json['scheduled_at']?.toString(),
    sentAt: json['sent_at']?.toString(), sentCount: (json['sent_count'] as num?)?.toInt() ?? 0,
    deliveredCount: (json['delivered_count'] as num?)?.toInt() ?? 0, openCount: (json['open_count'] as num?)?.toInt() ?? 0,
    clickCount: (json['click_count'] as num?)?.toInt() ?? 0, failedCount: (json['failed_count'] as num?)?.toInt() ?? 0,
    createdAt: json['created_at']?.toString() ?? '');
}

class AutomatedTrigger {
  final int id; final String name; final String? description; final String eventType;
  final String channel; final String templateMessage; final int delayMinutes;
  final bool isActive; final int triggerCount; final String? lastTriggeredAt;

  AutomatedTrigger({required this.id, required this.name, this.description, required this.eventType,
    required this.channel, required this.templateMessage, required this.delayMinutes,
    required this.isActive, required this.triggerCount, this.lastTriggeredAt});

  factory AutomatedTrigger.fromJson(Map<String, dynamic> json) => AutomatedTrigger(
    id: (json['id'] is int) ? json['id'] : 0, name: json['name']?.toString() ?? '',
    description: json['description']?.toString(), eventType: json['event_type']?.toString() ?? '',
    channel: json['channel']?.toString() ?? 'push', templateMessage: json['template_message']?.toString() ?? '',
    delayMinutes: (json['delay_minutes'] as num?)?.toInt() ?? 0, isActive: json['is_active'] == true,
    triggerCount: (json['trigger_count'] as num?)?.toInt() ?? 0, lastTriggeredAt: json['last_triggered_at']?.toString());
}

class NotificationLog {
  final int id; final int? campaignId; final int? userId; final String channel;
  final String title; final String message; final String status;
  final String? errorMessage; final String sentAt; final String? deliveredAt; final String? openedAt;

  NotificationLog({required this.id, this.campaignId, this.userId, required this.channel,
    required this.title, required this.message, required this.status,
    this.errorMessage, required this.sentAt, this.deliveredAt, this.openedAt});

  factory NotificationLog.fromJson(Map<String, dynamic> json) => NotificationLog(
    id: (json['id'] is int) ? json['id'] : 0, campaignId: json['campaign_id'] as int?,
    userId: json['user_id'] as int?, channel: json['channel']?.toString() ?? 'push',
    title: json['title']?.toString() ?? '', message: json['message']?.toString() ?? '',
    status: json['status']?.toString() ?? '', errorMessage: json['error_message']?.toString(),
    sentAt: json['sent_at']?.toString() ?? '', deliveredAt: json['delivered_at']?.toString(),
    openedAt: json['opened_at']?.toString());
}

class NotificationConfig {
  final int id; final String provider; final String channel; final String displayName;
  final String? apiKey; final String? senderId; final bool isActive;
  final String? lastTestedAt; final String? testStatus;

  NotificationConfig({required this.id, required this.provider, required this.channel,
    required this.displayName, this.apiKey, this.senderId, required this.isActive,
    this.lastTestedAt, this.testStatus});

  factory NotificationConfig.fromJson(Map<String, dynamic> json) => NotificationConfig(
    id: (json['id'] is int) ? json['id'] : 0, provider: json['provider']?.toString() ?? '',
    channel: json['channel']?.toString() ?? '', displayName: json['display_name']?.toString() ?? '',
    apiKey: json['api_key']?.toString(), senderId: json['sender_id']?.toString(),
    isActive: json['is_active'] == true, lastTestedAt: json['last_tested_at']?.toString(),
    testStatus: json['test_status']?.toString());
}
