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
  final ApiClient _api;
  UserRepository([ApiClient? api]) : _api = api ?? ApiClient();

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
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
    String? role,
    String? status,
  }) async {
    try {
      final skip = page > 1 ? (page - 1) * limit : 0;
      final queryParams = <String, dynamic>{'skip': skip, 'limit': limit};
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;
      final normalizedStatus = _normalizeStatus(status);
      if (normalizedStatus != null) queryParams['status'] = normalizedStatus;
      final userType = _normalizeUserType(role);
      if (userType != null) queryParams['user_type'] = userType;

      final response = await _api.get(
        '/api/v1/admin/users',
        queryParameters: queryParams,
      );
      final raw = response.data;
      final data = raw is Map<String, dynamic>
          ? (raw['items'] ?? raw['users'] ?? const <dynamic>[]) as List
          : raw is Map
          ? ((raw['items'] ?? raw['users'] ?? const <dynamic>[]) as List)
          : const <dynamic>[];
      final users = data.map((json) => User.fromJson(json)).toList();

      return PaginatedUsers(
        users: users,
        totalCount: (raw is Map && raw['total_count'] != null)
            ? raw['total_count'] as int
            : users.length,
        page: (raw is Map && raw['page'] != null) ? raw['page'] as int : page,
        limit: (raw is Map && (raw['page_size'] ?? raw['limit']) != null)
            ? (raw['page_size'] ?? raw['limit']) as int
            : limit,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> getUserById(int id) async {
    try {
      final response = await _api.get('/api/v1/admin/users/$id');
      return User.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createUser({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    String? roleName,
  }) async {
    final payload = {
      'full_name': fullName.trim(),
      'email': email.trim(),
      if (phoneNumber.trim().isNotEmpty) 'phone_number': phoneNumber.trim(),
      'password': password,
      if (roleName != null && roleName.trim().isNotEmpty)
        'role_name': roleName.trim(),
    };

    try {
      final response = await _api.post(
        '/api/v1/admin/users/create',
        data: payload,
      );
      return response.data as Map<String, dynamic>;
    } on Exception {
      final response = await _api.post('/api/v1/admin/users', data: payload);
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

    final response = await _api.post(
      '/api/v1/admin/users/invite',
      data: payload,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> adminBulkInvite(
    List<Map<String, dynamic>> invites,
  ) async {
    final response = await _api.post(
      '/api/v1/admin/users/bulk-invite',
      data: {'invites': invites},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listInvites() async {
    final response = await _api.get('/api/v1/admin/users/invites');
    final payload = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
    final items = payload['items'] is List
        ? payload['items'] as List
        : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> resendInvite(int inviteId) async {
    final response = await _api.post(
      '/api/v1/admin/users/$inviteId/invite/resend',
    );
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> revokeInvite(int inviteId) async {
    final response = await _api.post(
      '/api/v1/admin/users/$inviteId/invite/revoke',
    );
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
  }

  Future<User> updateUser(User user) async {
    final response = await _api.put(
      '/api/v1/admin/users/${user.id}',
      data: {
        'full_name': user.fullName,
        'email': user.email,
        'phone_number': user.phoneNumber,
      },
    );
    return User.fromJson(response.data);
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
    if (result == null) {
      throw StateError(
        'Backend updated user $userId but did not return a refreshable record.',
      );
    }
    return result;
  }

  Future<User> suspendUser(
    int userId, {
    required String reason,
    int? durationDays,
  }) async {
    await _api.put(
      '/api/v1/admin/users/$userId/suspend',
      data: {'reason': reason, 'duration_days': durationDays},
    );

    final result = await getUserById(userId);
    if (result == null) {
      throw StateError(
        'Backend suspended user $userId but did not return a refreshable record.',
      );
    }
    return result;
  }

  Future<void> updateKycStatus(int userId, String status) async {
    await _api.put(
      '/api/v1/admin/users/$userId/kyc-status',
      queryParameters: {'status': status},
    );
  }

  Future<User> reactivateUser(int userId) async {
    await _api.put('/api/v1/admin/users/$userId/reactivate');
    final result = await getUserById(userId);
    if (result == null) {
      throw StateError(
        'Backend reactivated user $userId but did not return a refreshable record.',
      );
    }
    return result;
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
    final response = await _api.get(
      '/api/v1/admin/users/$userId/suspension-history',
    );
    return response.data;
  }

  Future<dynamic> getUserAuditLog(int userId) async {
    final response = await _api.get(
      '/api/v1/admin/security/audit-logs',
      queryParameters: {'user_id': userId, 'skip': 0, 'limit': 100},
    );
    return response.data;
  }

  Future<double?> getUserRiskScore(int userId) async {
    final response = await _api.get('/api/v1/fraud/users/$userId/risk-score');
    return response.data['risk_score']?.toDouble();
  }

  Future<List<Map<String, dynamic>>> getCreationHistory() async {
    final response = await _api.get(
      '/api/v1/admin/security/audit-logs',
      queryParameters: {'days': 30, 'skip': 0, 'limit': 200},
    );
    final payload = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
    final items = payload['items'] is List
        ? payload['items'] as List
        : const <dynamic>[];

    final relevant = items.whereType<Map>().where((raw) {
      final action = raw['action']?.toString();
      return action == 'USER_CREATION' ||
          action == 'USER_INVITE' ||
          action == 'ACCOUNT_STATUS_CHANGE';
    }).toList();

    return relevant.map((raw) {
      final item = Map<String, dynamic>.from(raw);
      final action = item['action']?.toString() ?? 'EVENT';
      final label = switch (action) {
        'USER_CREATION' => 'User Created',
        'USER_INVITE' => 'User Invited',
        'ACCOUNT_STATUS_CHANGE' => 'User Status Changed',
        _ => action,
      };
      return {
        'action': label,
        'user':
            item['details']?.toString() ??
            item['resource_id']?.toString() ??
            'User',
        'by': item['user_id'] != null ? 'User #${item['user_id']}' : 'System',
        'date':
            DateTime.tryParse(item['timestamp']?.toString() ?? '') ??
            DateTime.now(),
      };
    }).toList();
  }
}
