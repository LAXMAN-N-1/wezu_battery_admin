import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user.dart';
import '../data/repositories/user_repository.dart';

class UsersView extends ConsumerStatefulWidget {
  const UsersView({super.key});

  @override
  ConsumerState<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends ConsumerState<UsersView> {
  late final UserRepository _repository;
  List<User> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _filterRole;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(userRepositoryProvider);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final users = await _repository.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<User> get _filteredUsers {
    return _users.where((user) {
      final matchesSearch = user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.phoneNumber.contains(_searchQuery);
      final matchesRole = _filterRole == null || user.role == _filterRole;
      return matchesSearch && matchesRole;
    }).toList();
  }

  int get _pendingKycCount => _users.where((u) => u.kycStatus == 'pending').length;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Stats
          Row(
            children: [
              Text(
                'User Management',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              _buildStatCard(
                'Total Users',
                _users.length.toString(),
                Icons.people_outline,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Pending KYC',
                _pendingKycCount.toString(),
                Icons.verified_user_outlined,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or phone...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _filterRole,
                    hint: const Text('All Roles', style: TextStyle(color: Colors.white70)),
                    dropdownColor: const Color(0xFF1E293B),
                    icon: const Icon(Icons.filter_list, color: Colors.white70),
                    style: GoogleFonts.inter(color: Colors.white),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Roles')),
                      const DropdownMenuItem(value: 'customer', child: Text('Customer')),
                      const DropdownMenuItem(value: 'driver', child: Text('Driver')),
                      const DropdownMenuItem(value: 'dealer', child: Text('Dealer')),
                      const DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) => setState(() => _filterRole = value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Data Table
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: _isLoading
                ? const SizedBox(
                    height: 200, 
                    child: Center(child: CircularProgressIndicator())
                  )
                : SizedBox(
                    width: double.infinity,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.white.withValues(alpha: 0.1),
                        iconTheme: const IconThemeData(color: Colors.white70),
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.05)),
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 60,
                        columns: const [
                          DataColumn(label: Text('User', style: TextStyle(color: Colors.white70))),
                          DataColumn(label: Text('Role', style: TextStyle(color: Colors.white70))),
                          DataColumn(label: Text('Status', style: TextStyle(color: Colors.white70))),
                          DataColumn(label: Text('KYC', style: TextStyle(color: Colors.white70))),
                          DataColumn(label: Text('Joined', style: TextStyle(color: Colors.white70))),
                          DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white70))),
                        ],
                        rows: _filteredUsers.map((user) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.blue.withValues(alpha: 0.2),
                                      child: Text(
                                        user.fullName[0].toUpperCase(),
                                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(user.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                          Text(user.email, style: const TextStyle(color: Colors.white54, fontSize: 12), overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(_buildRoleBadge(user.role)),
                              DataCell(_buildStatusBadge(user.isActive)),
                              DataCell(_buildKycBadge(user.kycStatus)),
                              DataCell(Text(
                                DateFormat('MMM d, y').format(user.joinedAt),
                                style: const TextStyle(color: Colors.white70),
                              )),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    switch (role) {
      case 'admin': color = Colors.purple; break;
      case 'dealer': color = Colors.orange; break;
      case 'driver': color = Colors.blue; break;
      default: color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? Colors.green : Colors.red,
          fontSize: 11, 
          fontWeight: FontWeight.w500
        ),
      ),
    );
  }

  Widget _buildKycBadge(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'verified': 
        color = Colors.green; 
        icon = Icons.check_circle; 
        break;
      case 'pending': 
        color = Colors.orange; 
        icon = Icons.pending; 
        break;
      case 'rejected': 
        color = Colors.red; 
        icon = Icons.cancel; 
        break;
      default: 
        color = Colors.grey; 
        icon = Icons.help;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          status.replaceAll('_', ' ').capitalize(),
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
