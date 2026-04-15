import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/user_analytics_repository.dart';
import '../data/repositories/audit_log_repository.dart';
import '../../../../core/api/api_client.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());

final userAnalyticsRepositoryProvider = Provider<UserAnalyticsRepository>((ref) {
  return UserAnalyticsRepository(ref.watch(apiClientProvider));
});

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return AuditLogRepository(ref.watch(apiClientProvider));
});

class UserListState {
  final List<User> users;
  final bool isLoading;
  final String searchQuery;
  final String? filterRole;
  final String? filterStatus;
  final int totalCount;
  final int page;
  final int limit;

  UserListState({
    this.users = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.filterRole,
    this.filterStatus,
    this.totalCount = 0,
    this.page = 1,
    this.limit = 20,
  });

  UserListState copyWith({
    List<User>? users,
    bool? isLoading,
    String? searchQuery,
    String? filterRole,
    String? filterStatus,
    int? totalCount,
    int? page,
    int? limit,
  }) {
    return UserListState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      filterRole: filterRole ?? this.filterRole,
      filterStatus: filterStatus ?? this.filterStatus,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  List<User> get filteredUsers {
    return users.where((user) {
      final matchesSearch = user.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
          user.phoneNumber.contains(searchQuery);
      
      final matchesRole = filterRole == null || user.role == filterRole;
      
      final matchesStatus = filterStatus == null ||
          (filterStatus == 'active' && user.isActive && user.suspensionStatus != 'suspended') ||
          (filterStatus == 'inactive' && !user.isActive && user.suspensionStatus != 'suspended') ||
          (filterStatus == 'suspended' && user.suspensionStatus == 'suspended');

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  int get activeUsers => users.where((u) => u.isActive && u.suspensionStatus != 'suspended').length;
  int get suspendedUsers => users.where((u) => u.suspensionStatus == 'suspended').length;
  int get pendingKyc => users.where((u) => u.kycStatus == 'pending').length;
}

class UserListNotifier extends StateNotifier<UserListState> {
  final UserRepository _repository;

  UserListNotifier(this._repository) : super(UserListState()) {
    loadUsers();
  }

  Future<void> loadUsers({int? page, int? limit}) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _repository.getUsers(
        page: page ?? state.page,
        limit: limit ?? state.limit,
        role: state.filterRole,
        status: state.filterStatus,
      );
      state = state.copyWith(
        users: response.users,
        totalCount: response.totalCount,
        page: response.page,
        limit: response.limit,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
  
  void setRoleFilter(String? role) {
    state = state.copyWith(filterRole: role, page: 1);
    loadUsers();
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(filterStatus: status, page: 1);
    loadUsers();
  }

  void goToPage(int page) {
    state = state.copyWith(page: page);
    loadUsers();
  }

  Future<void> createUser({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    String? role,
  }) async {
    await _repository.createUser(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      roleName: role,
    );
    await loadUsers();
  }

  Future<void> inviteUser({required String email, required String roleName, String? fullName}) async {
    await _repository.inviteUser(email: email, roleName: roleName, fullName: fullName);
    await loadUsers();
  }

  Future<void> updateUser(User user) async {
    await _repository.updateUser(user);
    await loadUsers();
  }

  Future<void> changeUserRole(int userId, {required int roleId, required String reason}) async {
    await _repository.changeUserRole(userId, roleId: roleId, reason: reason);
    await loadUsers();
  }

  Future<void> toggleUserActive(int userId) async {
    await _repository.toggleUserActive(userId);
    await loadUsers();
  }

  Future<void> suspendUser(int userId, {required String reason, int? durationDays}) async {
    await _repository.suspendUser(userId, reason: reason, durationDays: durationDays);
    await loadUsers();
  }

  Future<void> reactivateUser(int userId) async {
    await _repository.reactivateUser(userId);
    await loadUsers();
  }

  Future<void> updateKycStatus(int userId, String status) async {
    await _repository.updateKycStatus(userId, status);
    await loadUsers();
  }

  Future<void> resetPassword(int userId) async {
    // Generate random pass or trigger flow
    await _repository.changePassword(userId, 'Temporary123!', true);
  }

  Future<void> deleteUser(int userId) async {
    await _repository.deleteUser(userId);
    await loadUsers();
  }
}

final userListProvider = StateNotifierProvider<UserListNotifier, UserListState>((ref) {
  return UserListNotifier(ref.watch(userRepositoryProvider));
});


class UserInvite {
  final int id;
  final String email;
  final String role;
  final DateTime expiresAt;
  final String createdBy;
  final DateTime? acceptedAt;
  final bool revoked;

  UserInvite({
    required this.id,
    required this.email,
    required this.role,
    required this.expiresAt,
    required this.createdBy,
    this.acceptedAt,
    this.revoked = false,
  });

  String get displayStatus {
    if (revoked) return 'revoked';
    if (acceptedAt != null) return 'accepted';
    if (expiresAt.isBefore(DateTime.now())) return 'expired';
    return 'pending';
  }
}

class InviteListState {
  final List<UserInvite> invites;
  final bool isLoading;

  InviteListState({this.invites = const [], this.isLoading = false});

  InviteListState copyWith({List<UserInvite>? invites, bool? isLoading}) {
    return InviteListState(invites: invites ?? this.invites, isLoading: isLoading ?? this.isLoading);
  }

  int get pending => invites.where((i) => i.displayStatus == 'pending').length;
  int get accepted => invites.where((i) => i.displayStatus == 'accepted').length;
  int get expired => invites.where((i) => i.displayStatus == 'expired').length;
}

class InviteListNotifier extends StateNotifier<InviteListState> {
  final UserRepository _repository;

  InviteListNotifier(this._repository) : super(InviteListState());

  Future<void> sendInvite({required String email, required String role, String? fullName}) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.inviteUser(email: email, roleName: role, fullName: fullName);
      // Add to local list for immediate UI feedback
      final newInvite = UserInvite(
        id: DateTime.now().millisecondsSinceEpoch,
        email: email, role: role,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        createdBy: 'Admin',
      );
      state = state.copyWith(isLoading: false, invites: [newInvite, ...state.invites]);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void resendInvite(int id) {
    final updated = state.invites.map((i) {
      if (i.id == id) {
        return UserInvite(id: i.id, email: i.email, role: i.role, expiresAt: DateTime.now().add(const Duration(days: 7)), createdBy: i.createdBy);
      }
      return i;
    }).toList();
    state = state.copyWith(invites: updated);
  }

  Future<void> sendBulkInvites(List<Map<String, String>> invites) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.adminBulkInvite(invites.cast<Map<String, dynamic>>());
      // Refresh or add to list if needed. For simplicity, we'll just reload if possible,
      // but the repository doesn't have a clear "getInvites" yet that matches perfectly.
      // We'll just add them locally for now.
      final newInvites = invites.map((inv) => UserInvite(
        id: DateTime.now().millisecondsSinceEpoch + invites.indexOf(inv),
        email: inv['email']!,
        role: inv['role_name']!,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        createdBy: 'Admin',
      )).toList();
      state = state.copyWith(isLoading: false, invites: [...newInvites, ...state.invites]);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void revokeInvite(int id) {
    final updated = state.invites.map((i) {
      if (i.id == id) {
        return UserInvite(id: i.id, email: i.email, role: i.role, expiresAt: i.expiresAt, createdBy: i.createdBy, revoked: true);
      }
      return i;
    }).toList();
    state = state.copyWith(invites: updated);
  }
}

final inviteListProvider = StateNotifierProvider<InviteListNotifier, InviteListState>((ref) {
  return InviteListNotifier(ref.watch(userRepositoryProvider));
});
