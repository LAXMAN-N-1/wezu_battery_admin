import '../../../../core/api/api_client.dart';
import '../models/dealer.dart';
import '../models/dealer_application.dart';
import '../models/commission.dart';

class DealerRepository {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getDealers({int skip = 0, int limit = 100, String? search, String? city}) async {
    final Map<String, dynamic> params = {
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (search != null) params['search'] = search;
    if (city != null) params['city'] = city;
    
    try {
      final response = await _api.get('/api/v1/admin/dealers/', queryParameters: params);
      return {
        'dealers': (response.data['dealers'] as List).map((d) => DealerProfile.fromJson(d)).toList(),
        'total_count': response.data['total_count']
      };
    } catch (e) {
      return {'dealers': <DealerProfile>[], 'total_count': 0};
    }
  }

  Future<DealerStats> getDealerStats() async {
    try {
      final response = await _api.get('/api/v1/admin/dealers/stats');
      return DealerStats.fromJson(response.data);
    } catch (e) {
      return const DealerStats(totalActiveDealers: 0, pendingOnboardings: 0, totalCommissionsPaid: 0.0);
    }
  }

  Future<List<DealerApplication>> getApplications({String? stage}) async {
    final params = stage != null ? {'stage': stage} : null;
    try {
      final response = await _api.get('/api/v1/admin/dealers/applications', queryParameters: params);
      return (response.data as List).map((a) => DealerApplication.fromJson(a)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateApplicationStage(int appId, String stage, {String? notes}) async {
    try {
      await _api.put('/api/v1/admin/dealers/applications/$appId/stage', data: {'stage': stage, 'notes': notes});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<DealerKycDocument>> getKycDocuments() async {
    try {
      final response = await _api.get('/api/v1/admin/dealers/kyc');
      return (response.data as List).map((d) => DealerKycDocument.fromJson(d)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> verifyDocument(int docId, bool isVerified) async {
    try {
      await _api.put('/api/v1/admin/dealers/documents/$docId/verify', queryParameters: {'is_verified': isVerified});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<CommissionConfig>> getCommissionConfigs() async {
    try {
      final response = await _api.get('/api/v1/admin/dealers/commissions/configs');
      return (response.data as List).map((c) => CommissionConfig.fromJson(c)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateCommissionConfig(int configId, Map<String, dynamic> data) async {
    try {
      await _api.put('/api/v1/admin/dealers/commissions/configs/$configId', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<CommissionLog>> getCommissionLogs({int skip = 0, int limit = 50}) async {
    final Map<String, dynamic> params = {
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    try {
      final response = await _api.get('/api/v1/admin/dealers/commissions/logs', queryParameters: params);
      return (response.data as List).map((l) => CommissionLog.fromJson(l)).toList();
    } catch (e) {
      return [];
    }
  }
}
