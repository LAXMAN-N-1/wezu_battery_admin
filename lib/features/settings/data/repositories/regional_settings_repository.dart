import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../models/regional_info_model.dart';

final regionalSettingsRepositoryProvider = Provider<RegionalSettingsRepository>((ref) {
  return RegionalSettingsRepository(ref.read(apiClientProvider));
});

class RegionalSettingsRepository {
  final ApiClient _apiClient;
  static const String _base = '/api/v1/admin/settings';
  
  // Cache the IDs of general settings items to update them properly
  final Map<String, int> _configIds = {};

  RegionalSettingsRepository(this._apiClient);

  /// Fetch regional configuration from the generic settings API.
  Future<RegionalInfoModel> getRegionalInfo() async {
    try {
      final keys = [
        'regional_language',
        'regional_timezone',
        'regional_date_format',
        'regional_time_format',
        'regional_currency',
        'regional_number_format',
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
          debugPrint('[RegionalSettingsRepo] key "$key" not found: ${e.response?.statusCode}');
        }
      }));

      return RegionalInfoModel(
        language: configMap['regional_language']?.isNotEmpty == true ? configMap['regional_language']! : 'English',
        timezone: configMap['regional_timezone']?.isNotEmpty == true ? configMap['regional_timezone']! : 'Asia/Kolkata (IST +05:30)',
        dateFormat: configMap['regional_date_format']?.isNotEmpty == true ? configMap['regional_date_format']! : 'DD/MM/YYYY',
        timeFormat: configMap['regional_time_format']?.isNotEmpty == true ? configMap['regional_time_format']! : '12-hour',
        currency: configMap['regional_currency']?.isNotEmpty == true ? configMap['regional_currency']! : 'INR (₹)',
        numberFormat: configMap['regional_number_format']?.isNotEmpty == true ? configMap['regional_number_format']! : '1,234.56',
      );
    } on DioException catch (e) {
      debugPrint('[RegionalSettingsRepo] getRegionalInfo failed: $e');
      rethrow;
    }
  }

  /// Update regional configuration by patching individual generic settings.
  Future<RegionalInfoModel> updateRegionalInfo(RegionalInfoModel info) async {
    try {
      final updates = {
        'regional_language': info.language,
        'regional_timezone': info.timezone,
        'regional_date_format': info.dateFormat,
        'regional_time_format': info.timeFormat,
        'regional_currency': info.currency,
        'regional_number_format': info.numberFormat,
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
              'description': 'Regional configuration for $key'
            },
          );
        }
      }
      
      return await getRegionalInfo();
    } on DioException catch (e) {
      debugPrint('[RegionalSettingsRepo] updateRegionalInfo failed: $e');
      rethrow;
    }
  }
}
