import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/fraud_risk.dart';
import '../models/duplicate_account.dart';
import '../models/blacklist_entry.dart';

final fraudRepositoryProvider = Provider<FraudRepository>((ref) {
  return FraudRepository(ref.watch(apiClientProvider));
});

class FraudRepository {
  final ApiClient _api;

  FraudRepository(this._api);

  /// List users with high fraud risk scores
  Future<List<FraudRisk>> getHighRiskUsers({double threshold = 50, int limit = 100}) async {
    final response = await _api.get(
      '/api/v1/admin/fraud/high-risk-users',
      queryParameters: {'threshold': threshold, 'limit': limit},
    );
    if (response.data is List) {
      return (response.data as List).map((json) => FraudRisk.fromJson(json)).toList();
    }
    return [];
  }

  /// Get fraud risk score for a specific user
  Future<FraudRisk> getUserRiskScore(int userId) async {
    final response = await _api.get('/api/v1/admin/fraud/users/$userId/risk-score');
    return FraudRisk.fromJson(response.data);
  }

  /// Get potential duplicate accounts
  Future<List<DuplicateAccount>> getDuplicateAccounts({String? status, double minConfidence = 50}) async {
    final params = <String, dynamic>{'min_confidence': minConfidence};
    if (status != null) params['status'] = status;
    final response = await _api.get(
      '/api/v1/admin/fraud/duplicate-accounts',
      queryParameters: params,
    );
    if (response.data is List) {
      return (response.data as List).map((json) => DuplicateAccount.fromJson(json)).toList();
    }
    return [];
  }

  /// Take action on duplicate account detection
  Future<void> handleDuplicateAccount(int id, {required String action, String? notes}) async {
    await _api.post(
      '/api/v1/admin/fraud/duplicate-accounts/$id/action',
      data: {'action': action, if (notes != null) 'notes': notes},
    );
  }

  /// Get blacklist entries
  Future<List<BlacklistEntry>> getBlacklist({String? type}) async {
    final params = <String, dynamic>{};
    if (type != null) params['type'] = type;
    final response = await _api.get(
      '/api/v1/admin/fraud/blacklist',
      queryParameters: params.isNotEmpty ? params : null,
    );
    if (response.data is List) {
      return (response.data as List).map((json) => BlacklistEntry.fromJson(json)).toList();
    }
    return [];
  }

  /// Add entry to blacklist
  Future<BlacklistEntry> addToBlacklist({
    required String type,
    required String value,
    required String reason,
  }) async {
    final response = await _api.post(
      '/api/v1/admin/fraud/blacklist',
      data: {'type': type, 'value': value, 'reason': reason},
    );
    return BlacklistEntry.fromJson(response.data);
  }

  /// Remove from blacklist
  Future<void> removeFromBlacklist(int id) async {
    await _api.delete('/api/v1/admin/fraud/blacklist/$id');
  }

  /// Get device fingerprints for analysis
  Future<List<Map<String, dynamic>>> getDeviceFingerprints({
    int? userId,
    bool suspiciousOnly = false,
    int limit = 100,
  }) async {
    final params = <String, dynamic>{
      'suspicious_only': suspiciousOnly,
      'limit': limit,
    };
    if (userId != null) params['user_id'] = userId;
    final response = await _api.get(
      '/api/v1/admin/fraud/device-fingerprints',
      queryParameters: params,
    );
    return response.data is List ? List<Map<String, dynamic>>.from(response.data) : [];
  }

  /// Submit device fingerprint for tracking
  Future<Map<String, dynamic>> submitDeviceFingerprint(Map<String, dynamic> data) async {
    final response = await _api.post(
      '/api/v1/admin/fraud/device/fingerprint',
      data: data,
    );
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : {};
  }

  /// Verify PAN number
  Future<dynamic> verifyPan({required String panNumber, required String name}) async {
    final response = await _api.post(
      '/api/v1/admin/fraud/verify/pan',
      data: {'pan_number': panNumber, 'name': name},
    );
    return response.data;
  }

  /// Verify GST number
  Future<dynamic> verifyGst({required String gstNumber, required String businessName}) async {
    final response = await _api.post(
      '/api/v1/admin/fraud/verify/gst',
      data: {'gst_number': gstNumber, 'business_name': businessName},
    );
    return response.data;
  }

  /// Check phone number for fraud indicators
  Future<dynamic> verifyPhone({required String phoneNumber}) async {
    final response = await _api.post(
      '/api/v1/admin/fraud/verify/phone',
      data: {'phone_number': phoneNumber},
    );
    return response.data;
  }
}
