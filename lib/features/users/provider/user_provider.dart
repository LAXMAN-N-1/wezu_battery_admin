import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user.dart';
import '../data/repositories/user_repository.dart';
// Re-export so existing importers still see userRepositoryProvider.
export '../../../core/providers/repository_providers.dart'
    show userRepositoryProvider;
import '../../../core/providers/repository_providers.dart';

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
        fields: 'id,full_name,email,phone_number,user_type,status,kyc_status,role_id,created_at,suspension_status',
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
    final prevUsers = state.users;
    state = state.copyWith(users: state.users.map((u) {
      if (u.id == userId) return u.copyWith(isActive: !u.isActive);
      return u;
    }).toList());

    try {
      await _repository.toggleUserActive(userId);
    } catch (e) {
      state = state.copyWith(users: prevUsers);
      rethrow;
    }
  }

  Future<void> suspendUser(int userId, {required String reason, int? durationDays}) async {
    final prevUsers = state.users;
    state = state.copyWith(users: state.users.map((u) {
      if (u.id == userId) return u.copyWith(suspensionStatus: 'suspended');
      return u;
    }).toList());

    try {
      await _repository.suspendUser(userId, reason: reason, durationDays: durationDays);
    } catch (e) {
      state = state.copyWith(users: prevUsers);
      rethrow;
    }
  }

  Future<void> reactivateUser(int userId) async {
    final prevUsers = state.users;
    state = state.copyWith(users: state.users.map((u) {
      if (u.id == userId) {
        // Optimistically set active
        return u.copyWith(suspensionStatus: 'active');
      }
      return u;
    }).toList());

    try {
      await _repository.reactivateUser(userId);
    } catch (e) {
      state = state.copyWith(users: prevUsers);
      rethrow;
    }
  }

  Future<void> updateKycStatus(int userId, String status) async {
    final prevUsers = state.users;
    state = state.copyWith(users: state.users.map((u) {
      if (u.id == userId) return u.copyWith(kycStatus: status);
      return u;
    }).toList());

    try {
      await _repository.updateKycStatus(userId, status);
    } catch (e) {
      state = state.copyWith(users: prevUsers);
      rethrow;
    }
  }

  Future<void> resetPassword(int userId) async {
    // Generate random pass or trigger flow
    await _repository.changePassword(userId, 'Temporary123!', true);
  }

  Future<void> deleteUser(int userId) async {
    final prevUsers = state.users;
    state = state.copyWith(users: state.users.where((u) => u.id != userId).toList());

    try {
      await _repository.deleteUser(userId);
    } catch (e) {
      state = state.copyWith(users: prevUsers);
      rethrow;
    }
  }
}

final userListProvider = StateNotifierProvider<UserListNotifier, UserListState>((ref) {
  return UserListNotifier(ref.watch(userRepositoryProvider));
});


class InviteListState {
  final List<Map<String, dynamic>> invites;
  final bool isLoading;

  InviteListState({this.invites = const <Map<String, dynamic>>[], this.isLoading = false});

  InviteListState copyWith({List<Map<String, dynamic>>? invites, bool? isLoading}) {
    return InviteListState(invites: invites ?? this.invites, isLoading: isLoading ?? this.isLoading);
  }

  int get pending => invites.where((invite) => (invite['status']?.toString() ?? '').toLowerCase() == 'pending').length;
  int get accepted => invites.where((invite) => (invite['status']?.toString() ?? '').toLowerCase() == 'accepted').length;
  int get expired => invites.where((invite) => (invite['status']?.toString() ?? '').toLowerCase() == 'expired').length;
}

class InviteListNotifier extends StateNotifier<InviteListState> {
  final UserRepository _repository;

  InviteListNotifier(this._repository) : super(InviteListState()) {
    loadInvites();
  }

  Future<void> loadInvites() async {
    state = state.copyWith(isLoading: true);
    try {
      final invites = await _repository.listInvites();
      state = state.copyWith(invites: invites, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> sendInvite({required String email, required String role, String? fullName}) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.inviteUser(email: email, roleName: role, fullName: fullName);
      final invites = await _repository.listInvites();
      state = state.copyWith(invites: invites, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> resendInvite(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.resendInvite(id);
      final invites = await _repository.listInvites();
      state = state.copyWith(invites: invites, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> sendBulkInvites(List<Map<String, String>> invites) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.adminBulkInvite(invites.cast<Map<String, dynamic>>());
      final refreshed = await _repository.listInvites();
      state = state.copyWith(invites: refreshed, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> revokeInvite(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.revokeInvite(id);
      final invites = await _repository.listInvites();
      state = state.copyWith(invites: invites, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final inviteListProvider = StateNotifierProvider<InviteListNotifier, InviteListState>((ref) {
  return InviteListNotifier(ref.watch(userRepositoryProvider));
});
