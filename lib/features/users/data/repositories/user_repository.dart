import '../../../../core/api/api_client.dart';
import '../models/user.dart';

class PaginatedUsers {
  final List<User> users;
  final int totalCount;
  final int page;
  final int limit;

  PaginatedUsers({
    required this.users,
    required this.totalCount,
    required this.page,
    required this.limit,
  });
}

class UserRepository {
  final ApiClient _api = ApiClient();

  Future<PaginatedUsers> getUsers({
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
    String? role,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;
      if (role != null && role.isNotEmpty) queryParams['role'] = role;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final response = await _api.get('/api/v1/admin/users/', queryParameters: queryParams);
      final data = response.data['users'] as List;
      final users = data.map((json) => User.fromJson(json)).toList();
      
      return PaginatedUsers(
        users: users,
        totalCount: response.data['total_count'] ?? users.length,
        page: response.data['page'] ?? page,
        limit: response.data['limit'] ?? limit,
      );
    } catch (e) {
      print('Error fetching users: $e');
      return PaginatedUsers(users: [], totalCount: 0, page: page, limit: limit);
    }
  }

  Future<User?> getUserById(int id) async {
    try {
      final response = await _api.get('/api/v1/admin/users/$id');
      return User.fromJson(response.data);
    } catch (e) {
      print("Error fetching user $id: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> createUser({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    String? roleName,
  }) async {
    final response = await _api.post('/api/v1/admin/users/create', data: {
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'password': password,
      if (roleName != null) 'role_name': roleName,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> inviteUser({
    required String email,
    required String roleName,
    String? fullName,
  }) async {
    final response = await _api.post('/api/v1/admin/users/invite', data: {
      'email': email,
      'role_name': roleName,
      if (fullName != null) 'full_name': fullName,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> adminBulkInvite(List<Map<String, dynamic>> invites) async {
    final response = await _api.post('/api/v1/admin/users/bulk-invite', data: {
      'invites': invites,
    });
    return response.data;
  }

  Future<User> updateUser(User user) async {
    final response = await _api.put('/api/v1/admin/users/${user.id}', data: {
      'full_name': user.fullName,
      'email': user.email,
      'phone_number': user.phoneNumber,
    });
    return User.fromJson(response.data);
  }

  Future<void> deleteUser(int userId) async {
    // Note: The prompt doesn't list a direct DELETE /api/v1/admin/users/{id} 
    // but typically it exists or is conceptual. Keeping it updated to admin path if it was there.
    await _api.delete('/api/v1/admin/users/$userId');
  }

  Future<User> toggleUserActive(int userId) async {
    await _api.put('/api/v1/admin/users/$userId/toggle-active');
    final result = await getUserById(userId);
    return result ?? User(
      id: userId, fullName: 'Unknown', email: '', phoneNumber: '', role: 'customer',
      kycStatus: 'pending', isActive: true, joinedAt: DateTime.now(), lastActive: DateTime.now(),
    );
  }

  Future<User> suspendUser(int userId, {required String reason, int? durationDays}) async {
    await _api.put('/api/v1/admin/users/$userId/suspend', data: {
      'reason': reason,
      'duration_days': durationDays,
    });
    
    final result = await getUserById(userId);
    return result ?? User(
      id: userId, fullName: 'Unknown', email: '', phoneNumber: '', role: 'customer',
      kycStatus: 'pending', isActive: false, joinedAt: DateTime.now(), lastActive: DateTime.now(),
      suspensionReason: reason, suspendedAt: DateTime.now()
    );
  }

  Future<void> updateKycStatus(int userId, String status) async {
    await _api.put('/api/v1/admin/users/$userId/kyc-status', queryParameters: {'status': status});
  }

  Future<User> reactivateUser(int userId) async {
    await _api.put('/api/v1/admin/users/$userId/reactivate');
    final result = await getUserById(userId);
    return result ?? User(
      id: userId, fullName: 'Unknown', email: '', phoneNumber: '', role: 'customer',
      kycStatus: 'pending', isActive: true, joinedAt: DateTime.now(), lastActive: DateTime.now()
    );
  }

  Future<void> changePassword(int userId, String newPassword, bool forceReset) async {
    // This endpoint wasn't in the provided list, but keeping it as a generic admin action
    await _api.put('/api/v1/admin/users/$userId/password', data: {
      'password': newPassword,
      'force_reset': forceReset,
    });
  }

  // Admin: User Management
  Future<User> changeUserRole(int userId, {required int roleId, required String reason}) async {
    final response = await _api.put('/api/v1/admin/users/$userId/role', data: {
      'role_id': roleId,
      'reason': reason,
    });
    return User.fromJson(response.data);
  }

  Future<dynamic> bulkUserAction(List<int> userIds, String action, {Map<String, dynamic>? additionalData}) async {
    final data = {
      'user_ids': userIds,
      'action': action,
      if (additionalData != null) ...additionalData,
    };
    final response = await _api.post('/api/v1/admin/users/bulk-action', data: data);
    return response.data;
  }

  Future<dynamic> exportUsers({Map<String, dynamic>? filters}) async {
    final response = await _api.post('/api/v1/admin/users/export', data: filters ?? {});
    return response.data;
  }

  Future<void> terminateUserSessions(int userId) async {
    await _api.delete('/api/v1/admin/users/$userId/sessions');
  }

  Future<dynamic> getSuspensionHistory(int userId) async {
    try {
      final response = await _api.get('/api/v1/admin/users/$userId/suspension-history');
      return response.data;
    } catch (e) {
      print("Error fetching suspension history for user $userId: $e");
      return null;
    }
  }

  Future<dynamic> getUserAuditLog(int userId) async {
    try {
      final response = await _api.get('/api/v1/admin/audit/users/$userId');
      return response.data;
    } catch (e) {
      print("Error fetching audit log for user $userId: $e");
      return null;
    }
  }

  Future<double?> getUserRiskScore(int userId) async {
    try {
      final response = await _api.get('/api/v1/admin/fraud/users/$userId/risk-score');
      return response.data['risk_score']?.toDouble();
    } catch (e) {
      print("Error fetching risk score for user $userId: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCreationHistory() async {
    try {
      final res = await _api.get('/api/v1/admin/users/creation-history');
      if (res.data != null && res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
    } catch (e) {
      print("Error fetching creation history: $e");
    }

    return [];
  }
}
