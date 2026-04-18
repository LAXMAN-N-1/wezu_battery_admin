import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../models/notification_settings_model.dart';

final notificationSettingsRepositoryProvider =
    Provider<NotificationSettingsRepository>((ref) {
  return NotificationSettingsRepository(ref.read(apiClientProvider));
});

class NotificationSettingsRepository {
  final ApiClient _apiClient;
  static const String _base = '/api/v1/admin/settings';

  // Cache the IDs of general settings items to update them properly
  final Map<String, int> _configIds = {};

  NotificationSettingsRepository(this._apiClient);

  /// All backend keys for this section.
  static const _keys = [
    'notif_alert_email_recipients',
    'notif_on_new_user',
    'notif_on_failed_payment',
    'notif_on_security_alert',
    'notif_on_system_error',
    'notif_daily_summary_enabled',
    'notif_daily_summary_time',
    'notif_weekly_analytics_enabled',
    'notif_weekly_analytics_day',
  ];

  /// Fetch notification settings from the generic settings API.
  Future<NotificationSettingsModel> getNotificationSettings() async {
    try {
      final Map<String, String> configMap = {};

      await Future.wait(_keys.map((key) async {
        try {
          final response = await _apiClient.get(
            '$_base/general',
            queryParameters: {'key': key},
          );
          final data = response.data;
          if (data is Map<String, dynamic>) {
            _configIds[key] = data['id'] as int? ?? 0;
            configMap[key] = data['value']?.toString() ?? '';
          }
        } on DioException catch (e) {
          // Key doesn't exist yet — that's fine, default to empty
          debugPrint(
            '[NotificationSettingsRepo] key "$key" not found: '
            '${e.response?.statusCode}',
          );
        }
      }));

      return NotificationSettingsModel(
        alertEmailRecipients: _parseEmailList(
          configMap['notif_alert_email_recipients'] ?? '',
        ),
        notifyOnNewUser:
            configMap['notif_on_new_user']?.toLowerCase() == 'true',
        notifyOnFailedPayment:
            configMap['notif_on_failed_payment']?.toLowerCase() == 'true',
        // Security alert defaults to true if key doesn't exist yet
        notifyOnSecurityAlert:
            (configMap['notif_on_security_alert']?.toLowerCase() ?? 'true') !=
                'false',
        notifyOnSystemError:
            configMap['notif_on_system_error']?.toLowerCase() == 'true',
        dailySummaryEnabled:
            configMap['notif_daily_summary_enabled']?.toLowerCase() == 'true',
        dailySummaryTime: configMap['notif_daily_summary_time']?.isNotEmpty ==
                true
            ? configMap['notif_daily_summary_time']!
            : '09:00',
        weeklyAnalyticsEnabled:
            configMap['notif_weekly_analytics_enabled']?.toLowerCase() ==
                'true',
        weeklyAnalyticsDay:
            configMap['notif_weekly_analytics_day']?.isNotEmpty == true
                ? configMap['notif_weekly_analytics_day']!
                : 'Monday',
      );
    } on DioException catch (e) {
      debugPrint(
        '[NotificationSettingsRepo] getNotificationSettings failed: $e',
      );
      rethrow;
    }
  }

  /// Update notification settings by patching individual generic settings.
  Future<NotificationSettingsModel> updateNotificationSettings(
    NotificationSettingsModel settings,
  ) async {
    try {
      final updates = {
        'notif_alert_email_recipients':
            settings.alertEmailRecipients.join(','),
        'notif_on_new_user': settings.notifyOnNewUser.toString(),
        'notif_on_failed_payment': settings.notifyOnFailedPayment.toString(),
        'notif_on_security_alert': settings.notifyOnSecurityAlert.toString(),
        'notif_on_system_error': settings.notifyOnSystemError.toString(),
        'notif_daily_summary_enabled':
            settings.dailySummaryEnabled.toString(),
        'notif_daily_summary_time': settings.dailySummaryTime,
        'notif_weekly_analytics_enabled':
            settings.weeklyAnalyticsEnabled.toString(),
        'notif_weekly_analytics_day': settings.weeklyAnalyticsDay,
      };

      for (final entry in updates.entries) {
        final key = entry.key;
        final value = entry.value;
        final id = _configIds[key];

        if (id != null && id > 0) {
          // Exists -> Patch
          await _apiClient.patch(
            '$_base/general/$id',
            queryParameters: {'value': value},
          );
        } else {
          // Doesn't exist -> Create
          await _apiClient.post(
            '$_base/general',
            queryParameters: {
              'key': key,
              'value': value,
              'description': 'Notification setting for $key',
            },
          );
        }
      }

      // Reload to ensure we have updated IDs
      return await getNotificationSettings();
    } on DioException catch (e) {
      debugPrint(
        '[NotificationSettingsRepo] updateNotificationSettings failed: $e',
      );
      rethrow;
    }
  }

  /// Parse a comma-separated email string into a list, trimming whitespace.
  List<String> _parseEmailList(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
