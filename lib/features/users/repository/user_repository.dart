import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import 'dart:math';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

class UserRepository {
  final List<UserModel> _mockUsers = [];

  UserRepository() {
    _generateMockData();
  }

  void _generateMockData() {
    final random = Random();
    final names = ['Alan Turing', 'Grace Hopper', 'Ada Lovelace', 'Dennis Ritchie', 'Ken Thompson', 'Linus Torvalds', 'Steve Jobs', 'Bill Gates', 'Elon Musk', 'Jeff Bezos', 'Mark Zuckerberg', 'Larry Page', 'Sergey Brin', 'Tim Cook', 'Satya Nadella', 'Sundar Pichai', 'Jensen Huang', 'Lisa Su', 'Pat Gelsinger', 'Arvind Krishna'];
    
    for (int i = 0; i < 200; i++) {
      final name = names[random.nextInt(names.length)];
      final kycStatus = KycStatus.values[random.nextInt(KycStatus.values.length)];
      final accountStatus = random.nextDouble() > 0.9 ? AccountStatus.suspended : AccountStatus.active;
      
      _mockUsers.add(UserModel(
        id: 'USR-${1000 + i}',
        name: '$name ${i + 1}',
        phone: '+91 98765 ${10000 + i}',
        email: 'user${i + 1}@example.com',
        registrationDate: DateTime.now().subtract(Duration(days: random.nextInt(365))),
        kycStatus: kycStatus,
        accountStatus: accountStatus,
        lastActive: DateTime.now().subtract(Duration(minutes: random.nextInt(10000))),
        walletBalance: (random.nextInt(5000) * 10).toDouble(),
        totalSwaps: random.nextInt(50),
        vehicles: ['EV Bike ${random.nextInt(999)}', if (random.nextBool()) 'EV Scooter'],
      ));
    }
  }

  Future<PaginatedUsers> fetchUsers({
    int page = 1,
    int limit = 50,
    String? query,
    KycStatus? kycFilter,
    AccountStatus? accountFilter,
    String? sortBy,
    bool ascending = true,
  }) async {
    // TODO: Replace with real API call
    // final response = await _apiClient.get('/api/v1/users', queryParameters: {...});
    
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate latency

    List<UserModel> filtered = List.from(_mockUsers);

    // Filter
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered.where((u) => 
        u.name.toLowerCase().contains(q) || 
        u.email.toLowerCase().contains(q) || 
        u.phone.contains(q) ||
        u.id.toLowerCase().contains(q)
      ).toList();
    }

    if (kycFilter != null) {
      filtered = filtered.where((u) => u.kycStatus == kycFilter).toList();
    }

    if (accountFilter != null) {
      filtered = filtered.where((u) => u.accountStatus == accountFilter).toList();
    }

    // Sort
    if (sortBy != null) {
      filtered.sort((a, b) {
        int cmp = 0;
        switch (sortBy) {
          case 'name': cmp = a.name.compareTo(b.name); break;
          case 'date': cmp = a.registrationDate.compareTo(b.registrationDate); break;
          case 'balance': cmp = a.walletBalance.compareTo(b.walletBalance); break;
          case 'swaps': cmp = a.totalSwaps.compareTo(b.totalSwaps); break;
          default: cmp = 0;
        }
        return ascending ? cmp : -cmp;
      });
    } else {
      // Default sort by registration date desc
      filtered.sort((a, b) => b.registrationDate.compareTo(a.registrationDate));
    }

    // Pagination
    final startIndex = (page - 1) * limit;
    final endIndex = min(startIndex + limit, filtered.length);
    final pageData = startIndex >= filtered.length ? <UserModel>[] : filtered.sublist(startIndex, endIndex);

    return PaginatedUsers(
      users: pageData,
      total: filtered.length,
      page: page,
      totalPages: (filtered.length / limit).ceil(),
    );
  }

  Future<UserModel?> fetchUserDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      return _mockUsers.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateUserStatus(String id, AccountStatus status) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockUsers.indexWhere((u) => u.id == id);
    if (index != -1) {
      final user = _mockUsers[index];
      // Create new instance with updated status (immutable pattern)
      _mockUsers[index] = UserModel(
        id: user.id,
        name: user.name,
        phone: user.phone,
        email: user.email,
        registrationDate: user.registrationDate,
        kycStatus: user.kycStatus,
        accountStatus: status, // Updated
        lastActive: user.lastActive,
        walletBalance: user.walletBalance,
        totalSwaps: user.totalSwaps,
        vehicles: user.vehicles,
        profilePhotoUrl: user.profilePhotoUrl,
      );
    }
  }
  Future<void> createUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Generate simple ID if empty
    final newUser = UserModel(
      id: user.id.isEmpty ? 'USR-${1200 + _mockUsers.length}' : user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      registrationDate: user.registrationDate,
      kycStatus: user.kycStatus,
      accountStatus: user.accountStatus,
      lastActive: user.lastActive,
      walletBalance: user.walletBalance,
      totalSwaps: user.totalSwaps,
      vehicles: user.vehicles,
      profilePhotoUrl: user.profilePhotoUrl,
    );
    _mockUsers.insert(0, newUser); // Add to top
  }
}

class PaginatedUsers {
  final List<UserModel> users;
  final int total;
  final int page;
  final int totalPages;

  PaginatedUsers({
    required this.users,
    required this.total,
    required this.page,
    required this.totalPages,
  });
}
