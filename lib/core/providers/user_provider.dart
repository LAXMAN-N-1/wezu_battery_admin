import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

class UserListState {
  final List<UserModel> users;
  final bool isLoading;
  final String searchQuery;
  final KycStatus? kycFilter;
  final AccountStatus? accountFilter;
  final Map<String, int> stats;
  final int page;
  final int limit;

  UserListState({
    this.users = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.kycFilter,
    this.accountFilter,
    this.stats = const {},
    this.page = 1,
    this.limit = 10,
  });

  int get total => stats['total'] ?? 0;
  int get totalPages => (total / limit).ceil();

  UserListState copyWith({
    List<UserModel>? users,
    bool? isLoading,
    String? searchQuery,
    KycStatus? kycFilter,
    AccountStatus? accountFilter,
    Map<String, int>? stats,
    int? page,
    int? limit,
  }) {
    return UserListState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      kycFilter: kycFilter ?? this.kycFilter,
      accountFilter: accountFilter ?? this.accountFilter,
      stats: stats ?? this.stats,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

final userListProvider = StateNotifierProvider<UserListNotifier, UserListState>((ref) {
  return UserListNotifier();
});

class UserListNotifier extends StateNotifier<UserListState> {
  UserListNotifier() : super(UserListState(isLoading: true)) {
    loadUsers();
  }

  Future<void> loadUsers({int page = 1}) async {
    state = state.copyWith(page: page);
    _fetchUsers();
  }

  List<UserModel> _allUsers = [];

  Future<void> _fetchUsers() async {
    try {
      state = state.copyWith(isLoading: true);
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Initialize Mock Data only once
      if (_allUsers.isEmpty) {
        _allUsers = List.generate(20, (index) {
          return UserModel(
            id: 'USER-${1000 + index}',
            name: 'User ${index + 1}',
            email: 'user${index + 1}@example.com',
            phone: '+1 555 01${index.toString().padLeft(2, '0')}',
            registrationDate: DateTime.now().subtract(Duration(days: index * 5)),
            kycStatus: KycStatus.values[index % KycStatus.values.length],
            accountStatus: AccountStatus.values[index % AccountStatus.values.length],
            lastActive: DateTime.now().subtract(Duration(minutes: index * 20)),
            walletBalance: (index * 15.5),
            totalSwaps: index * 3,
          );
        });
      }

      var users = List<UserModel>.from(_allUsers);

      // Apply Search Filter
      if (state.searchQuery.isNotEmpty) {
        final query = state.searchQuery.toLowerCase();
        users = users.where((u) {
          return u.name.toLowerCase().contains(query) ||
                 u.email.toLowerCase().contains(query) ||
                 u.phone.contains(query);
        }).toList();
      }

      // Apply KYC Filter
      if (state.kycFilter != null) {
        users = users.where((u) => u.kycStatus == state.kycFilter).toList();
      }

      // Apply Account Filter
      if (state.accountFilter != null) {
        users = users.where((u) => u.accountStatus == state.accountFilter).toList();
      }

      final stats = {
        'total': _allUsers.length,
        'active': _allUsers.where((u) => u.accountStatus == AccountStatus.active).length,
        'kyc_pending': _allUsers.where((u) => u.kycStatus == KycStatus.pending).length,
        'new_this_week': 5,
      };

      state = UserListState(
        users: users,
        isLoading: false,
        searchQuery: state.searchQuery,
        kycFilter: state.kycFilter,
        accountFilter: state.accountFilter,
        stats: stats,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addUser(UserModel user) async {
    _allUsers.insert(0, user);
    _fetchUsers();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _fetchUsers();
  }

  void setKycFilter(KycStatus? status) {
     // Explicitly create new state to handle null
     state = UserListState(
       users: state.users,
       isLoading: state.isLoading,
       searchQuery: state.searchQuery,
       kycFilter: status,
       accountFilter: state.accountFilter,
       stats: state.stats,
     );
     _fetchUsers();
  }

  void setAccountFilter(AccountStatus? status) {
     state = UserListState(
       users: state.users,
       isLoading: state.isLoading,
       searchQuery: state.searchQuery,
       kycFilter: state.kycFilter,
       accountFilter: status,
       stats: state.stats,
     );
     _fetchUsers();
  }
   void clearFilters() {
     state = UserListState(
      users: state.users,
      isLoading: state.isLoading,
      searchQuery: '',
      kycFilter: null,
      accountFilter: null,
      limit: state.limit,
    );
     _fetchUsers();
   }

  void setSort(String field, {bool ascending = true}) {
    // Implement sort logic
    _fetchUsers(); // Mock reload
  }

  Future<void> suspendUser(String userId) async {
    // Implement suspend logic
    _fetchUsers(); // Mock reload
  }

  Future<void> activateUser(String userId) async {
    // Implement activate logic
    _fetchUsers(); // Mock reload
  }
}
