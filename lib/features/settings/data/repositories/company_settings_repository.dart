import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../models/company_info_model.dart';

final companySettingsRepositoryProvider = Provider<CompanySettingsRepository>((ref) {
  return CompanySettingsRepository(ref.read(apiClientProvider));
});

class CompanySettingsRepository {
  final ApiClient _apiClient;
  static const String _base = '/api/v1/admin/settings';
  
  // Cache the IDs of general settings items to update them properly
  final Map<String, int> _configIds = {};

  CompanySettingsRepository(this._apiClient);

  /// Fetch company information from the generic settings API.
  Future<CompanyInfoModel> getCompanyInfo() async {
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
      
      return CompanyInfoModel(
        companyName: configMap['company_name'] ?? '',
        companyEmail: configMap['company_email'] ?? '',
        supportPhone: configMap['support_phone'] ?? '',
        companyAddress: configMap['company_address'] ?? '',
        companyWebsite: configMap['company_website'] ?? '',
        companyLogoUrl: configMap['company_logo_url'],
        faviconUrl: configMap['favicon_url'],
      );
    } on DioException catch (e) {
      debugPrint('[CompanySettingsRepo] getCompanyInfo failed: $e');
      // Keep settings UI usable even if backend config table is missing.
      return const CompanyInfoModel(
        companyName: '',
        companyEmail: '',
        supportPhone: '',
        companyAddress: '',
        companyWebsite: '',
      );
    }
  }

  /// Update company information by patching individual generic settings.
  Future<CompanyInfoModel> updateCompanyInfo(CompanyInfoModel info) async {
    try {
      final updates = {
        'company_name': info.companyName,
        'company_email': info.companyEmail,
        'support_phone': info.supportPhone,
        'company_address': info.companyAddress,
        'company_website': info.companyWebsite,
        if (info.companyLogoUrl != null) 'company_logo_url': info.companyLogoUrl!,
        if (info.faviconUrl != null) 'favicon_url': info.faviconUrl!,
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
              'description': 'System configuration for $key'
            },
          );
        }
      }
      
      // Reload to ensure we have updated IDs
      return await getCompanyInfo();
    } on DioException catch (e) {
      debugPrint('[CompanySettingsRepo] updateCompanyInfo failed: $e');
      rethrow;
    }
  }

  /// Upload company logo via the CMS media endpoint. Returns the new logo URL.
  Future<String?> uploadCompanyLogo(List<int> bytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
        'category': 'brand',
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
      debugPrint('[CompanySettingsRepo] uploadCompanyLogo failed: $e');
      rethrow;
    }
  }

  /// Upload favicon via the CMS media endpoint. Returns the new favicon URL.
  Future<String?> uploadFavicon(List<int> bytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
        'category': 'brand',
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
      debugPrint('[CompanySettingsRepo] uploadFavicon failed: $e');
      rethrow;
    }
  }
}
