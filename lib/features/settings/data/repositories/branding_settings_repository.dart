import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../models/branding_info_model.dart';

final brandingSettingsRepositoryProvider = Provider<BrandingSettingsRepository>((ref) {
  return BrandingSettingsRepository(ref.read(apiClientProvider));
});

class BrandingSettingsRepository {
  final ApiClient _apiClient;
  static const String _base = '/api/v1/admin/settings';
  
  // Cache the IDs of general settings items to update them properly
  final Map<String, int> _configIds = {};

  BrandingSettingsRepository(this._apiClient);

  /// Fetch branding information from the generic settings API.
  Future<BrandingInfoModel> getBrandingInfo() async {
    try {
      final response = await _apiClient.get('$_base/general');
      final data = response.data;
      
      final Map<String, String> configMap = {};
      
      if (data is Map<String, dynamic>) {
        data.forEach((key, val) {
          if (val is Map<String, dynamic>) {
            _configIds[key] = val['id'] as int? ?? 0;
            configMap[key] = val['value']?.toString() ?? '';
          }
        });
      }

      return BrandingInfoModel(
        primaryColor: configMap['branding_primary_color']?.isNotEmpty == true ? configMap['branding_primary_color']! : '#2563EB',
        secondaryColor: configMap['branding_secondary_color']?.isNotEmpty == true ? configMap['branding_secondary_color']! : '#1E40AF',
        themeMode: configMap['branding_theme_mode']?.isNotEmpty == true ? configMap['branding_theme_mode']! : 'system',
        emailHeaderLogoUrl: configMap['branding_email_header_logo'],
      );
    } on DioException catch (e) {
      debugPrint('[BrandingSettingsRepo] getBrandingInfo failed: $e');
      rethrow;
    }
  }

  /// Update branding configuration by patching individual generic settings.
  Future<BrandingInfoModel> updateBrandingInfo(BrandingInfoModel info) async {
    try {
      final updates = {
        'branding_primary_color': info.primaryColor,
        'branding_secondary_color': info.secondaryColor,
        'branding_theme_mode': info.themeMode,
        if (info.emailHeaderLogoUrl != null) 'branding_email_header_logo': info.emailHeaderLogoUrl!,
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
              'description': 'Branding configuration for $key'
            },
          );
        }
      }
      
      return await getBrandingInfo();
    } on DioException catch (e) {
      debugPrint('[BrandingSettingsRepo] updateBrandingInfo failed: $e');
      rethrow;
    }
  }

  /// Upload email header logo via CMS.
  Future<String?> uploadEmailHeaderLogo(List<int> bytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
        'category': 'brand_email',
      });
      final response = await _apiClient.post(
        '/api/v1/admin/media/upload',
        data: formData,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['url']?.toString();
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[BrandingSettingsRepo] uploadEmailHeaderLogo failed: $e');
      rethrow;
    }
  }
}
