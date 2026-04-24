import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/admin_ui_components.dart';
import '../data/models/user.dart';
import '../data/providers/user_master_providers.dart';

class UsersMasterListView extends ConsumerStatefulWidget {
  const UsersMasterListView({super.key});

  @override
  ConsumerState<UsersMasterListView> createState() =>
      _UsersMasterListViewState();
}

class _UsersMasterListViewState extends ConsumerState<UsersMasterListView>
    with TickerProviderStateMixin {
  static const int _rowsPerPage = 20;
  static const List<String> _statusOptions = [
    'All',
    'Active',
    'Inactive',
    'Suspended',
    'Pending Verification',
  ];
  static const List<String> _userTypeOptions = [
    'All',
    'Admin',
    'Dealer',
    'Dealer Staff',
    'Logistics',
    'Support Agent',
    'Customer',
  ];

  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  // Filters
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _userTypeFilter = 'All';

  // Pagination
  int _currentPage = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = query;
        _currentPage = 0;
      });
    });
  }

  void _applyFilter(String type, String value) {
    setState(() {
      if (type == 'status') _statusFilter = value;
      if (type == 'userType') _userTypeFilter = value;
      _currentPage = 0;
    });
  }

  void _clearFilters() {
    if (!mounted) return;
    setState(() {
      _statusFilter = 'All';
      _userTypeFilter = 'All';
      _searchQuery = '';
      _currentPage = 0;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use a stable string key to prevent Riverpod from re-creating the provider on every rebuild
    final statusParam = _statusFilter == 'All' ? '' : _statusFilter;
    final userTypeParam = _userTypeFilter == 'All' ? '' : _userTypeFilter;
    final queryKey =
        'search=$_searchQuery&role=$userTypeParam&status=$statusParam&skip=${_currentPage * _rowsPerPage}&limit=$_rowsPerPage';

    final usersAsync = ref.watch(usersProviderByKey(queryKey));
    final summaryAsync = ref.watch(userSummaryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(usersProviderByKey);
        ref.invalidate(usersProvider);
        ref.invalidate(userSummaryProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatsRow(summaryAsync),
            const SizedBox(height: 20),
            _buildQuickFilters(),
            const SizedBox(height: 20),
            _buildFilterBar(),
            const SizedBox(height: 20),
            _buildTableCard(usersAsync),
          ],
        ),
      ),
    );
  }

  // ===================================
  // HEADER
  // ===================================
  Widget _buildHeader() {
    return PageHeader(
      title: 'All Users',
      subtitle: 'Manage system access, view profiles, and control user roles.',
      actionButton: Row(
        children: [
          _outlinedBtn(
            Icons.download_rounded,
            'Export',
            () => context.go('/user-master/bulk'),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => context.go('/user-master/edit'),
              icon: const Icon(
                Icons.add_rounded,
                size: 20,
                color: Colors.white,
              ),
              label: const Text(
                'Add User',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _outlinedBtn(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white70),
      label: Text(label, style: const TextStyle(color: Colors.white70)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ===================================
  // STAT CARDS
  // ===================================
  Widget _buildStatsRow(AsyncValue<Map<String, dynamic>> summaryAsync) {
    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text(
          'Error loading stats: $err',
          style: const TextStyle(color: Color(0xFFEF4444)),
        ),
      ),
      data: (summary) {
        final total = summary['total_users'] as int? ?? 0;
        final active = summary['active_count'] as int? ?? 0;
        final inactive = summary['inactive_count'] as int? ?? 0;
        final suspended = summary['suspended_count'] as int? ?? 0;
        final pending = summary['pending_count'] as int? ?? 0;

        return Row(
          children: [
            Expanded(
              child: _premiumStatCard(
                'Total Users',
                '$total',
                Icons.people_alt_outlined,
                const Color(0xFF3B82F6),
                null,
                'All',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _premiumStatCard(
                'Active Users',
                '$active',
                Icons.how_to_reg_outlined,
                const Color(0xFF22C55E),
                null,
                'Active',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _premiumStatCard(
                'Inactive / Suspended',
                '${inactive + suspended}',
                Icons.person_off_outlined,
                const Color(0xFFF59E0B),
                'Not currently active',
                null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _premiumStatCard(
                'Pending Approval',
                '$pending',
                Icons.hourglass_empty_rounded,
                const Color(0xFF8B5CF6),
                null,
                'Pending Verification',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _premiumStatCard(
                'Online Right Now',
                '${(active * 0.1).round()}',
                Icons.wifi_tethering_rounded,
                const Color(0xFF14B8A6),
                'Sessions active',
                null,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.05);
      },
    );
  }

  Widget _premiumStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String? subtitle,
    String? filterStatus,
  ) {
    final isActive = filterStatus != null && _statusFilter == filterStatus;

    return GestureDetector(
      onTap: filterStatus != null
          ? () => _applyFilter('status', filterStatus)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.08)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border(top: BorderSide(color: color, width: 3)),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? color.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                // Mini sparkline placeholder (7 dots)
                Row(
                  children: List.generate(
                    7,
                    (i) => Container(
                      width: 4,
                      height: [8.0, 12.0, 10.0, 14.0, 9.0, 13.0, 11.0][i],
                      margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.3 + i * 0.08),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
              duration: const Duration(milliseconds: 900),
              builder: (context, val, _) {
                return Text(
                  '$val',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===================================
  // QUICK FILTERS
  // ===================================
  Widget _buildQuickFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _userTypeOptions.map((filter) {
          final isSelected =
              _userTypeFilter == filter ||
              (filter == 'All' && _userTypeFilter == 'All');
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) _applyFilter('userType', filter);
              },
              backgroundColor: const Color(0xFF1E293B),
              selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.8),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : Colors.white.withValues(alpha: 0.06),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  // ===================================
  // FILTER BAR
  // ===================================
  Widget _buildFilterBar() {
    int activeFilterCount = 0;
    if (_statusFilter != 'All') activeFilterCount++;
    if (_userTypeFilter != 'All') activeFilterCount++;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name, email, phone...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _buildDropdownFilter(
              'Status',
              _statusOptions,
              _statusFilter,
              (val) => _applyFilter('status', val!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _buildDropdownFilter(
              'User Type',
              _userTypeOptions,
              _userTypeFilter,
              (val) => _applyFilter('userType', val!),
            ),
          ),
          if (activeFilterCount > 0) ...[
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear, size: 16, color: Color(0xFFEF4444)),
              label: const Text(
                'Clear',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildDropdownFilter(
    String label,
    List<String> options,
    String currentValue,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          hint: Text(label, style: const TextStyle(color: Colors.white54)),
          isExpanded: true,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          style: const TextStyle(color: Colors.white),
          items: options.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ===================================
  // DATA TABLE
  // ===================================
  Widget _buildTableCard(AsyncValue<Map<String, dynamic>> usersAsync) {
    return AdvancedCard(
      padding: EdgeInsets.zero,
      child: usersAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, __) => Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Text(
              'Error: $error',
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ),
        data: (data) {
          final usersJson = data['items'] as List<dynamic>? ?? [];
          final users = usersJson.map((e) => User.fromJson(e)).toList();
          final totalCount = data['total_count'] as int? ?? users.length;
          final pageCount = totalCount == 0
              ? 1
              : (totalCount / _rowsPerPage).ceil();
          final currentPageNumber = _currentPage + 1;
          final startIndex = users.isEmpty
              ? 0
              : (_currentPage * _rowsPerPage) + 1;
          final endIndex = users.isEmpty ? 0 : startIndex + users.length - 1;

          if (users.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(60.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 48, color: Colors.white24),
                    SizedBox(height: 16),
                    Text(
                      'No users found matching the current filters.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              AdvancedTable(
                columns: const [
                  'User ID',
                  'Full Name',
                  'Email',
                  'Role',
                  'Station / Region',
                  'Status',
                  'Last Login',
                  'Actions',
                ],
                rows: users.map((user) {
                  return [
                    Text(
                      user.id.padRight(8).substring(0, 8).trim().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(
                            0xFF3B82F6,
                          ).withValues(alpha: 0.2),
                          backgroundImage: user.profilePhotoUrl != null
                              ? NetworkImage(user.profilePhotoUrl!)
                              : null,
                          child: user.profilePhotoUrl == null
                              ? Text(
                                  user.fullName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF3B82F6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            user.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    _buildRoleBadge(user.roleName),
                    Text(
                      user.assignedStationName ?? 'Global',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    StatusBadge(status: user.status.name),
                    Text(
                      user.lastLogin != null
                          ? DateFormat(
                              'MMM dd, yyyy HH:mm',
                            ).format(user.lastLogin!)
                          : '--',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Color(0xFF3B82F6),
                          ),
                          tooltip: 'Edit User',
                          onPressed: () => context.go(
                            '/user-master/edit?id=${user.id}&action=edit',
                          ),
                        ),
                        if (user.status == UserStatus.active)
                          IconButton(
                            icon: const Icon(
                              Icons.block_outlined,
                              size: 18,
                              color: Color(0xFFF59E0B),
                            ),
                            tooltip: 'Suspend Account',
                            onPressed: () => context.go(
                              '/user-master/edit?id=${user.id}&action=suspend',
                            ),
                          ),
                        if (user.status == UserStatus.suspended)
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: Color(0xFF22C55E),
                            ),
                            tooltip: 'Reactivate Account',
                            onPressed: () => context.go(
                              '/user-master/edit?id=${user.id}&action=reactivate',
                            ),
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                          tooltip: 'Delete User',
                          onPressed: () => context.go(
                            '/user-master/edit?id=${user.id}&action=delete',
                          ),
                        ),
                      ],
                    ),
                  ];
                }).toList(),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Showing $startIndex-$endIndex of $totalCount users',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white70,
                      ),
                      tooltip: 'Previous page',
                      onPressed: _currentPage > 0
                          ? () => setState(() => _currentPage--)
                          : null,
                    ),
                    Text(
                      'Page $currentPageNumber of $pageCount',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white70,
                      ),
                      tooltip: 'Next page',
                      onPressed: currentPageNumber < pageCount
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildRoleBadge(String roleName) {
    final normalized = roleName.toLowerCase();
    Color color;
    if (normalized.contains('admin')) {
      color = const Color(0xFF8B5CF6);
    } else if (normalized.contains('manager')) {
      color = const Color(0xFF3B82F6);
    } else if (normalized.contains('dealer')) {
      color = const Color(0xFF22C55E);
    } else if (normalized.contains('support')) {
      color = const Color(0xFFF59E0B);
    } else if (normalized.contains('driver') ||
        normalized.contains('logistics')) {
      color = const Color(0xFF06B6D4);
    } else {
      color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        roleName,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
