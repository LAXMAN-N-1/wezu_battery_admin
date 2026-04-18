import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../models/maintenance_mode_model.dart';

final maintenanceSettingsRepositoryProvider =
    Provider<MaintenanceSettingsRepository>((ref) {
  return MaintenanceSettingsRepository(ref.read(apiClientProvider));
});

class MaintenanceSettingsRepository {
  final ApiClient _apiClient;
  static const String _base = '/api/v1/admin/settings';

  // Cache the IDs of general settings items to update them properly
  final Map<String, int> _configIds = {};

  MaintenanceSettingsRepository(this._apiClient);

  /// All backend keys for this section.
  static const _keys = [
    'maintenance_mode_enabled',
    'maintenance_message',
    'maintenance_expected_end_time',
  ];

  /// Fetch maintenance mode settings from the generic settings API.
  Future<MaintenanceModeModel> getMaintenanceSettings() async {
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
            '[MaintenanceSettingsRepo] key "$key" not found: '
            '${e.response?.statusCode}',
          );
        }
      }));

      return MaintenanceModeModel(
        isEnabled:
            configMap['maintenance_mode_enabled']?.toLowerCase() == 'true',
        maintenanceMessage: configMap['maintenance_message'] ?? '',
        expectedEndTime: configMap['maintenance_expected_end_time'] ?? '',
      );
    } on DioException catch (e) {
      debugPrint(
        '[MaintenanceSettingsRepo] getMaintenanceSettings failed: $e',
      );
      rethrow;
    }
  }

  /// Update maintenance mode settings by patching individual generic settings.
  Future<MaintenanceModeModel> updateMaintenanceSettings(
    MaintenanceModeModel settings,
  ) async {
    try {
      final updates = {
        'maintenance_mode_enabled': settings.isEnabled.toString(),
        'maintenance_message': settings.maintenanceMessage,
        'maintenance_expected_end_time': settings.expectedEndTime,
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
              'description': 'Maintenance mode setting for $key',
            },
          );
        }
      }

      // Reload to ensure we have updated IDs
      return await getMaintenanceSettings();
    } on DioException catch (e) {
      debugPrint(
        '[MaintenanceSettingsRepo] updateMaintenanceSettings failed: $e',
      );
      rethrow;
    }
  }
}
