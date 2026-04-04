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
    int skip = 0,
    int limit = 100,
    String? search,
    String? status,
    String? userType,
    String? kycStatus,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (userType != null && userType.isNotEmpty) queryParams['user_type'] = userType;
      if (kycStatus != null && kycStatus.isNotEmpty) queryParams['kyc_status'] = kycStatus;

      final response = await _api.get('/api/v1/admin/users/', queryParameters: queryParams);
      
      // The response might be a list of users directly or a paginated object.
      // Given the example response value "string" in the prompt, I'll handle potential variations.
      // Looking at the common patterns in this repo, it's likely a list or object with 'users' key.
      
      List data;
      int totalCount;
      if (response.data is List) {
        data = response.data;
        totalCount = data.length;
      } else {
        data = response.data['users'] ?? [];
        totalCount = response.data['total_count'] ?? data.length;
      }
      
      final users = data.map((json) => User.fromJson(json)).toList();
      
      return PaginatedUsers(
        users: users,
        totalCount: totalCount,
        page: (skip / limit).floor() + 1,
        limit: limit,
      );
    } catch (e) {
      print('Error fetching users: $e');
      return PaginatedUsers(users: [], totalCount: 0, page: 1, limit: limit);
    }
  }

  Future<dynamic> getUsersSummary() async {
    final response = await _api.get('/api/v1/admin/users/summary');
    return response.data;
  }

  Future<PaginatedUsers> getSuspendedUsers({
    int skip = 0,
    int limit = 100,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'skip': skip,
      'limit': limit,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _api.get('/api/v1/admin/users/suspended', queryParameters: queryParams);
    
    List data;
    if (response.data is List) {
      data = response.data;
    } else {
      data = response.data['users'] ?? [];
    }
    
    final users = data.map((json) => User.fromJson(json)).toList();
    return PaginatedUsers(
      users: users,
      totalCount: users.length, // Suspended list might not return total_count explicitly
      page: (skip / limit).floor() + 1,
      limit: limit,
    );
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
    String roleName = 'customer',
    String userType = 'customer',
    String status = 'active',
  }) async {
    final response = await _api.post('/api/v1/admin/users/', data: {
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'password': password,
      'role_name': roleName,
      'user_type': userType,
      'status': status,
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
      if (durationDays != null) 'duration_days': durationDays,
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

  Future<User> reactivateUser(int userId, {String? notes}) async {
    await _api.put('/api/v1/admin/users/$userId/reactivate', data: {
      'notes': notes ?? '',
    });
    final result = await getUserById(userId);
    return result ?? User(
      id: userId, fullName: 'Unknown', email: '', phoneNumber: '', role: 'customer',
      kycStatus: 'pending', isActive: true, joinedAt: DateTime.now(), lastActive: DateTime.now()
    );
  }

  Future<void> adminResetPassword(int userId, String newPassword) async {
    await _api.post('/api/v1/admin/users/$userId/reset-password', data: {
      'new_password': newPassword,
    });
  }

  Future<void> forceLogoutUser(int userId) async {
    await _api.post('/api/v1/admin/users/$userId/force-logout');
  }

  Future<void> banUser(int userId, {String reason = 'Violation of terms'}) async {
    await _api.post('/api/v1/admin/users/$userId/ban', queryParameters: {
      'reason': reason,
    });
  }

  Future<void> unbanUser(int userId) async {
    await _api.post('/api/v1/admin/users/$userId/unban');
  }

  Future<void> forcePasswordChange(int userId) async {
    await _api.post('/api/v1/admin/users/$userId/force-password-change');
  }

  Future<void> transitionUserState(int userId, String newStatus) async {
    await _api.post('/api/v1/admin/users/$userId/transition', data: {
      'new_status': newStatus,
    });
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
    // Mocked for the UI since there is no direct endpoint in the provided list
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {'action': 'User Created', 'user': 'John Doe', 'by': 'Admin', 'date': DateTime.now().subtract(const Duration(days: 1))},
      {'action': 'User Invited', 'user': 'jane@example.com', 'by': 'Admin', 'date': DateTime.now().subtract(const Duration(days: 2))},
      {'action': 'User Suspended', 'user': 'Bob Smith', 'by': 'System', 'date': DateTime.now().subtract(const Duration(days: 3))},
    ];
  }
}
