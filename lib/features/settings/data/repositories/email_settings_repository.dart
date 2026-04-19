import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../models/email_config_model.dart';

final emailSettingsRepositoryProvider = Provider<EmailSettingsRepository>((ref) {
  return EmailSettingsRepository(ref.read(apiClientProvider));
});

class EmailSettingsRepository {
  final ApiClient _apiClient;
  static const String _base = '/api/v1/admin/settings';
  
  // Cache the IDs of general settings items to update them properly
  final Map<String, int> _configIds = {};

  EmailSettingsRepository(this._apiClient);

  /// Fetch email configuration from the generic settings API.
  Future<EmailConfigModel> getEmailConfig() async {
    try {
      final keys = [
        'smtp_from_name',
        'smtp_from_email',
        'smtp_reply_to_email',
        'smtp_host',
        'smtp_port',
        'smtp_encryption',
        'smtp_username',
        'smtp_password',
      ];

      final Map<String, String> configMap = {};

      await Future.wait(keys.map((key) async {
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
          // Key doesn't exist yet, it's fine.
          debugPrint('[EmailSettingsRepo] key "$key" not found: ${e.response?.statusCode}');
        }
      }));

      return EmailConfigModel(
        fromName: configMap['smtp_from_name'] ?? '',
        fromEmail: configMap['smtp_from_email'] ?? '',
        replyToEmail: configMap['smtp_reply_to_email'] ?? '',
        smtpHost: configMap['smtp_host'] ?? '',
        smtpPort: int.tryParse(configMap['smtp_port'] ?? '587') ?? 587,
        encryption: configMap['smtp_encryption']?.isNotEmpty == true ? configMap['smtp_encryption']! : 'STARTTLS',
        smtpUsername: configMap['smtp_username'] ?? '',
        smtpPassword: configMap['smtp_password'] ?? '',
      );
    } on DioException catch (e) {
      debugPrint('[EmailSettingsRepo] getEmailConfig failed: $e');
      rethrow;
    }
  }

  /// Update email configuration by patching individual generic settings.
  Future<EmailConfigModel> updateEmailConfig(EmailConfigModel info) async {
    try {
      final updates = {
        'smtp_from_name': info.fromName,
        'smtp_from_email': info.fromEmail,
        'smtp_reply_to_email': info.replyToEmail,
        'smtp_host': info.smtpHost,
        'smtp_port': info.smtpPort.toString(),
        'smtp_encryption': info.encryption,
        'smtp_username': info.smtpUsername,
        'smtp_password': info.smtpPassword,
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
              'description': 'Email configuration for $key'
            },
          );
        }
      }
      
      return await getEmailConfig();
    } on DioException catch (e) {
      debugPrint('[EmailSettingsRepo] updateEmailConfig failed: $e');
      rethrow;
    }
  }

  /// Send a test email to verify SMTP configuration
  Future<void> sendTestEmail() async {
    try {
      await _apiClient.post('$_base/general/test-email');
    } on DioException catch (e) {
      debugPrint('[EmailSettingsRepo] sendTestEmail failed: $e');
      
      // Determine what to throw so the UI can show the error toast
      final status = e.response?.statusCode;
      final msg = e.response?.data is Map ? e.response?.data['message'] : e.message;
      throw Exception('SMTP Error ($status): $msg');
    }
  }
}
