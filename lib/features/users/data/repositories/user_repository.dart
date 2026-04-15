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

  String? _normalizeStatus(String? status) {
    if (status == null || status.trim().isEmpty) return null;
    switch (status.trim().toLowerCase()) {
      case 'active':
        return 'active';
      case 'suspended':
        return 'suspended';
      case 'pending':
      case 'pending_verification':
        return 'pending_verification';
      default:
        // Backend does not support direct filtering for this status.
        return null;
    }
  }

  String? _normalizeUserType(String? role) {
    if (role == null || role.trim().isEmpty) return null;
    switch (role.trim().toLowerCase()) {
      case 'dealer':
        return 'dealer';
      case 'customer':
        return 'customer';
      case 'driver':
        return 'driver';
      case 'super admin':
      case 'admin':
      case 'manager':
      case 'support agent':
      case 'read-only':
        return 'admin';
      default:
        return null;
    }
  }

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
      final normalizedStatus = _normalizeStatus(status);
      if (normalizedStatus != null) queryParams['status'] = normalizedStatus;
      final normalizedRole = _normalizeUserType(userType);
      if (normalizedRole != null) queryParams['user_type'] = normalizedRole;
      if (kycStatus != null && kycStatus.isNotEmpty) queryParams['kyc_status'] = kycStatus;

      final response = await _api.get(
        '/api/v1/admin/users/',
        queryParameters: queryParams,
      );
      
      final raw = response.data;
      final data = raw is Map<String, dynamic>
          ? (raw['items'] ?? raw['users'] ?? const <dynamic>[]) as List
          : raw is Map
          ? ((raw['items'] ?? raw['users'] ?? const <dynamic>[]) as List)
          : raw is List 
          ? raw
          : const <dynamic>[];

      final users = data.map((json) => User.fromJson(json)).toList();

      int totalCount;
      if (raw is Map && raw['total_count'] != null) {
        totalCount = raw['total_count'] as int;
      } else {
        totalCount = users.length;
      }

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
    final payload = {
      'full_name': fullName.trim(),
      'email': email.trim(),
      if (phoneNumber.trim().isNotEmpty) 'phone_number': phoneNumber.trim(),
      'password': password,
      if (roleName.trim().isNotEmpty) 'role_name': roleName.trim(),
      'user_type': userType,
      'status': status,
    };

    try {
      final response = await _api.post('/api/v1/admin/users/', data: payload);
      return response.data as Map<String, dynamic>;
    } on Exception {
      final response = await _api.post(
        '/api/v1/admin/users/create',
        data: payload,
      );
      return response.data as Map<String, dynamic>;
    }
  }

  Future<Map<String, dynamic>> inviteUser({
    required String email,
    required String roleName,
    String? fullName,
  }) async {
    final payload = {
      'email': email.trim(),
      'role_name': roleName.trim(),
      if (fullName != null && fullName.trim().isNotEmpty)
        'full_name': fullName.trim(),
    };

    try {
      final response = await _api.post(
        '/api/v1/admin/users/invite',
        data: payload,
      );
      return response.data as Map<String, dynamic>;
    } on Exception {
      return createUser(
        fullName: fullName?.trim().isNotEmpty == true
            ? fullName!.trim()
            : email.trim(),
        email: email.trim(),
        phoneNumber: '',
        password: 'Welcome@123',
        roleName: roleName.trim(),
      );
    }
  }

  Future<Map<String, dynamic>> adminBulkInvite(
    List<Map<String, dynamic>> invites,
  ) async {
    try {
      final response = await _api.post(
        '/api/v1/admin/users/bulk-invite',
        data: {'invites': invites},
      );
      return response.data as Map<String, dynamic>;
    } on Exception {
      var success = 0;
      var failed = 0;
      for (final invite in invites) {
        try {
          await inviteUser(
            email: invite['email']?.toString() ?? '',
            roleName: invite['role_name']?.toString() ?? 'customer',
            fullName: invite['full_name']?.toString(),
          );
          success += 1;
        } catch (_) {
          failed += 1;
        }
      }
      return {
        'status': 'partial',
        'message': 'Processed invites via fallback flow',
        'success_count': success,
        'failed_count': failed,
      };
    }
  }

  Future<User> updateUser(User user) async {
    try {
      final response = await _api.put(
        '/api/v1/admin/users/${user.id}',
        data: {
          'full_name': user.fullName,
          'email': user.email,
          'phone_number': user.phoneNumber,
        },
      );
      return User.fromJson(response.data);
    } catch (_) {
      final refreshed = await getUserById(user.id);
      if (refreshed != null) return refreshed;
      rethrow;
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      await _api.delete('/api/v1/admin/users/$userId');
    } on Exception {
      await _api.delete('/api/v1/users/$userId');
    }
  }

  Future<User> toggleUserActive(int userId) async {
    await _api.put('/api/v1/admin/users/$userId/toggle-active');
    final result = await getUserById(userId);
    return result ??
        User(
          id: userId,
          fullName: 'Unknown',
          email: '',
          phoneNumber: '',
          role: 'customer',
          kycStatus: 'pending',
          isActive: true,
          joinedAt: DateTime.now(),
          lastActive: DateTime.now(),
        );
  }

  Future<User> suspendUser(
    int userId, {
    required String reason,
    int? durationDays,
  }) async {
    await _api.put(
      '/api/v1/admin/users/$userId/suspend',
      data: {
        'reason': reason,
        if (durationDays != null) 'duration_days': durationDays,
      },
    );

    final result = await getUserById(userId);
    return result ??
        User(
          id: userId,
          fullName: 'Unknown',
          email: '',
          phoneNumber: '',
          role: 'customer',
          kycStatus: 'pending',
          isActive: false,
          joinedAt: DateTime.now(),
          lastActive: DateTime.now(),
          suspensionReason: reason,
          suspendedAt: DateTime.now(),
        );
  }

  Future<void> updateKycStatus(int userId, String status) async {
    await _api.put(
      '/api/v1/admin/users/$userId/kyc-status',
      queryParameters: {'status': status},
    );
  }

  Future<User> reactivateUser(int userId, {String? notes}) async {
    await _api.put('/api/v1/admin/users/$userId/reactivate', data: {
      'notes': notes ?? '',
    });
    final result = await getUserById(userId);
    return result ??
        User(
          id: userId,
          fullName: 'Unknown',
          email: '',
          phoneNumber: '',
          role: 'customer',
          kycStatus: 'pending',
          isActive: true,
          joinedAt: DateTime.now(),
          lastActive: DateTime.now(),
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

  Future<void> changePassword(
    int userId,
    String newPassword,
    bool forceReset,
  ) async {
    try {
      await _api.post(
        '/api/v1/admin/users/$userId/reset-password',
        data: {'new_password': newPassword},
      );
    } on Exception {
      await _api.put(
        '/api/v1/admin/users/$userId/password',
        data: {'password': newPassword, 'force_reset': forceReset},
      );
    }
  }

  // Admin: User Management
  Future<User> changeUserRole(
    int userId, {
    required int roleId,
    required String reason,
  }) async {
    try {
      await _api.post(
        '/api/v1/admin/rbac/users/$userId/roles',
        data: {'role_id': roleId, 'notes': reason},
      );
    } on Exception {
      await _api.put(
        '/api/v1/admin/users/$userId/role',
        data: {'role_id': roleId, 'reason': reason},
      );
    }

    final refreshed = await getUserById(userId);
    if (refreshed != null) return refreshed;
    throw Exception('Role updated but user refresh failed for user $userId');
  }

  Future<dynamic> bulkUserAction(
    List<int> userIds,
    String action, {
    Map<String, dynamic>? additionalData,
  }) async {
    final data = {
      'user_ids': userIds,
      'action': action,
      if (additionalData != null) ...additionalData,
    };
    final response = await _api.post(
      '/api/v1/admin/users/bulk-action',
      data: data,
    );
    return response.data;
  }

  Future<dynamic> exportUsers({Map<String, dynamic>? filters}) async {
    final response = await _api.post(
      '/api/v1/admin/users/export',
      data: filters ?? {},
    );
    return response.data;
  }

  Future<void> terminateUserSessions(int userId) async {
    try {
      await _api.delete('/api/v1/admin/users/$userId/sessions');
    } on Exception {
      await _api.post('/api/v1/admin/users/$userId/force-logout');
    }
  }

  Future<dynamic> getSuspensionHistory(int userId) async {
    try {
      final response = await _api.get(
        '/api/v1/admin/users/$userId/suspension-history',
      );
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
      final response = await _api.get(
        '/api/v1/admin/fraud/users/$userId/risk-score',
      );
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
