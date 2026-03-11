import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
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
          // Header
          PageHeader(
            title: 'User Management',
            subtitle: 'Manage roles, view KYC status, and monitor activity.',
            searchField: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

          // Stats & Filters Row
          Row(
            children: [
              _buildStatCard(
                'Total Users',
                _users.length.toString(),
                Icons.people_outline,
                const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Pending KYC',
                _pendingKycCount.toString(),
                Icons.verified_user_outlined,
                const Color(0xFFF59E0B),
              ),
              const Spacer(),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05),
          const SizedBox(height: 24),

          // Data Table
          AdvancedCard(
            padding: EdgeInsets.zero,
            child: _isLoading
                ? const SizedBox(
                    height: 200, 
                    child: Center(child: CircularProgressIndicator())
                  )
                : AdvancedTable(
                    columns: const ['User', 'Role', 'Status', 'KYC', 'Joined', 'Actions'],
                    rows: _filteredUsers.map((user) {
                      return [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                              child: Text(
                                user.fullName[0].toUpperCase(),
                                style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold),
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
                        StatusBadge(status: user.role), // Role badge
                        StatusBadge(status: user.isActive ? 'active' : 'inactive'), // Account status
                        StatusBadge(status: user.kycStatus), // KYC status
                        Text(
                          DateFormat('MMM d, y').format(user.joinedAt),
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.more_horiz, size: 20, color: Colors.white54),
                            onPressed: () {},
                          ),
                        ),
                      ];
                    }).toList(),
                  ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return AdvancedCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      width: 200,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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

  // Manual badge methods mapped to Advanced StatusBadges are now removed 
  // as AdvancedTable uses the new StatusBadge object directly.
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
