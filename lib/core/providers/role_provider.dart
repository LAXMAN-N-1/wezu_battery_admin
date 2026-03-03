import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/role_model.dart';

class RoleState {
  final List<RoleModel> roles;
  final bool isLoading;
  final String searchQuery;

  RoleState({
    this.roles = const [],
    this.isLoading = false,
    this.searchQuery = '',
  });

  RoleState copyWith({
    List<RoleModel>? roles,
    bool? isLoading,
    String? searchQuery,
  }) {
    return RoleState(
      roles: roles ?? this.roles,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final roleProvider = StateNotifierProvider<RoleNotifier, RoleState>((ref) {
  return RoleNotifier();
});

class RoleNotifier extends StateNotifier<RoleState> {
  RoleNotifier() : super(RoleState(isLoading: true)) {
    _fetchRoles();
  }

  List<RoleModel> _allRoles = [];

  Future<void> _fetchRoles() async {
    try {
      state = state.copyWith(isLoading: true);
      await Future.delayed(const Duration(milliseconds: 400));
      
      // Initialize Mock Data only once
      if (_allRoles.isEmpty) {
        _allRoles = [
          RoleModel(id: 'R1', name: 'Super Admin', description: 'Full access to all features', permissions: ['all'], userCount: 2),
          RoleModel(id: 'R2', name: 'Logistics Manager', description: 'Manage fleets and stations', permissions: ['stations.manage', 'batteries.manage'], userCount: 5),
          RoleModel(id: 'R3', name: 'Support Agent', description: 'Handle customer tickets', permissions: ['users.view', 'tickets.manage'], userCount: 12),
        ];
      }

      var roles = List<RoleModel>.from(_allRoles);

      // Apply Search Filter
      if (state.searchQuery.isNotEmpty) {
        final query = state.searchQuery.toLowerCase();
        roles = roles.where((r) {
          return r.name.toLowerCase().contains(query) ||
                 r.description.toLowerCase().contains(query);
        }).toList();
      }

      state = state.copyWith(roles: roles, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addRole(RoleModel role) async {
    _allRoles.add(role);
    _fetchRoles();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _fetchRoles();
  }
}
