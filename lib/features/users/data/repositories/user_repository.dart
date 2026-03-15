import '../../../../core/api/api_client.dart';
import '../models/user.dart';

class UserRepository {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getUsers({
    int skip = 0,
    int limit = 100,
    String? search,
    String? status,
    String? userType,
    String? kycStatus,
  }) async {
    final params = <String, dynamic>{
      'skip': skip,
      'limit': limit,
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null) params['status'] = status;
    if (userType != null) params['user_type'] = userType;
    if (kycStatus != null) params['kyc_status'] = kycStatus;

    try {
      final response = await _api.get('/api/v1/admin/users/', queryParameters: params);
      final data = response.data;
      final users = (data['users'] as List).map((u) => User.fromJson(u)).toList();
      return {
        'users': users,
        'total_count': data['total_count'] ?? users.length,
      };
    } catch (e) {
      // Fallback to empty list on error
      return {'users': <User>[], 'total_count': 0};
    }
  }

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await _api.get('/api/v1/admin/users/stats');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {
        'total_users': 0,
        'active_users': 0,
        'suspended_users': 0,
        'pending_verification': 0,
        'pending_kyc': 0,
      };
    }
  }

  Future<Map<String, dynamic>> getSuspendedUsers({
    int skip = 0,
    int limit = 100,
    String? search,
  }) async {
    final params = <String, dynamic>{
      'skip': skip,
      'limit': limit,
    };
    if (search != null && search.isNotEmpty) params['search'] = search;

    try {
      final response = await _api.get('/api/v1/admin/users/suspended', queryParameters: params);
      final data = response.data;
      final users = (data['users'] as List).map((u) => User.fromJson(u)).toList();
      return {
        'users': users,
        'total_count': data['total_count'] ?? users.length,
      };
    } catch (e) {
      return {'users': <User>[], 'total_count': 0};
    }
  }

  Future<bool> suspendUser(int userId, String reason) async {
    try {
      await _api.put('/api/v1/admin/users/$userId/suspend', data: {'reason': reason});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> reactivateUser(int userId) async {
    try {
      await _api.put('/api/v1/admin/users/$userId/reactivate', data: {});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleUserActive(int userId) async {
    try {
      await _api.put('/api/v1/admin/users/$userId/toggle-active');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> inviteUser({required String email, required String role, String? fullName}) async {
    try {
      await _api.post('/api/v1/admin/users/invite', data: {
        'email': email,
        'role': role,
        if (fullName != null) 'full_name': fullName,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
