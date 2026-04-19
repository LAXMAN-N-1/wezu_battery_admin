import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../data/models/user.dart';
import '../provider/user_provider.dart';
import 'dialogs/create_user_dialog.dart';
import 'dialogs/edit_user_dialog.dart';
import 'dialogs/invite_users_dialog.dart';
import 'dialogs/suspend_user_dialog.dart';
import '../../../core/widgets/wezu_skeleton.dart';
import '../../../core/widgets/admin_ui_components.dart';

class UsersView extends ConsumerStatefulWidget {
  const UsersView({super.key});
  @override
  ConsumerState<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends ConsumerState<UsersView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() { super.initState(); _tabController = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  bool _isMobile(BuildContext ctx) => MediaQuery.of(ctx).size.width < 800;

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userListProvider);
    final inviteState = ref.watch(inviteListProvider);
    final mobile = _isMobile(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(mobile ? 12 : 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header - using PageHeader for consistency
        PageHeader(
          title: 'User Management',
          subtitle: 'View and manage all users across the platform.',
          actionButton: Row(
            children: [
              _buildActionButton('Invite Users', Icons.mail_outline, const Color(0xFF22C55E), _showInviteDialog),
              const SizedBox(width: 12),
              _buildActionButton('Create User', Icons.person_add, const Color(0xFF3B82F6), _showCreateDialog),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

        // Stats Cards - using AdvancedCard for consistency
        if (mobile)
          Column(children: [
            Row(children: [
              Expanded(child: _buildStatCard('Total Users', userState.totalCount.toString(), Icons.people_outline, const Color(0xFF3B82F6))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Active', userState.activeUsers.toString(), Icons.check_circle_outline, const Color(0xFF22C55E))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildStatCard('Suspended', userState.suspendedUsers.toString(), Icons.block, const Color(0xFFEF4444))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Pending KYC', userState.pendingKyc.toString(), Icons.verified_user_outlined, const Color(0xFFF59E0B))),
            ]),
          ])
        else
          Row(children: [
            Expanded(child: _buildStatCard('Total Users', userState.totalCount.toString(), Icons.people_outline, const Color(0xFF3B82F6))),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Active', userState.activeUsers.toString(), Icons.check_circle_outline, const Color(0xFF22C55E))),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Suspended', userState.suspendedUsers.toString(), Icons.block, const Color(0xFFEF4444))),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Pending KYC', userState.pendingKyc.toString(), Icons.verified_user_outlined, const Color(0xFFF59E0B))),
          ]).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05),
        const SizedBox(height: 24),

        // Tabs
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: const Color(0xFF3B82F6),
            unselectedLabelColor: Colors.white54,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: mobile ? 11 : 13),
            isScrollable: mobile,
            tabs: [
              Tab(text: 'All Users (${userState.totalCount})'),
              Tab(text: 'Invites (${inviteState.invites.length})'),
              const Tab(text: 'History'),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
        const SizedBox(height: 16),

        SizedBox(
          height: mobile ? 500 : 600,
          child: TabBarView(controller: _tabController, children: [
            _buildUsersTab(userState, mobile),
            _buildInvitesTab(inviteState, mobile),
            _buildHistoryTab(),
          ]),
        ),
      ]),
    );
  }

  // === Users Tab ===
  Widget _buildUsersTab(UserListState state, bool mobile) {
    return Column(children: [
      // Search & Filters
      if (mobile)
        TextField(
          style: const TextStyle(color: Colors.white),
          onChanged: (v) => ref.read(userListProvider.notifier).setSearchQuery(v),
          decoration: InputDecoration(
            hintText: 'Search users...', hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search, color: Colors.white38),
            filled: true, fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        )
      else
        Row(children: [
          Expanded(
            flex: 3,
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => ref.read(userListProvider.notifier).setSearchQuery(v),
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone...', hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true, fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildFilterDropdown(value: state.filterRole, hint: 'Role',
            items: [null, 'admin', 'supervisor', 'support', 'dealer', 'driver', 'customer'],
            labels: ['All Roles', 'Admin', 'Supervisor', 'Support', 'Dealer', 'Driver', 'Customer'],
            onChanged: (v) => ref.read(userListProvider.notifier).setRoleFilter(v)),
          const SizedBox(width: 12),
          _buildFilterDropdown(value: state.filterStatus, hint: 'Status',
            items: [null, 'active', 'inactive', 'suspended'],
            labels: ['All Status', 'Active', 'Inactive', 'Suspended'],
            onChanged: (v) => ref.read(userListProvider.notifier).setStatusFilter(v)),
        ]).animate().fadeIn(duration: 400.ms, delay: 150.ms),
      const SizedBox(height: 16),

      Expanded(child: state.isLoading
        ? const Padding(padding: EdgeInsets.all(12), child: WezuSkeletonTable(rows: 8, columns: 6))
        : mobile
          ? _buildUserCards(state)
          : _buildUserTable(state),
      ),
      
      // Pagination Controls
      if (!state.isLoading && state.totalCount > 0)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white70),
                onPressed: state.page > 1 ? () => ref.read(userListProvider.notifier).goToPage(state.page - 1) : null,
              ),
              Text(
                'Page ${state.page} of ${(state.totalCount / state.limit).ceil()}',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white70),
                onPressed: state.page < (state.totalCount / state.limit).ceil()
                    ? () => ref.read(userListProvider.notifier).goToPage(state.page + 1)
                    : null,
              ),
            ],
          ),
        ),
    ]);
  }

  // Mobile: card list
  Widget _buildUserCards(UserListState state) {
    return ListView.builder(
      itemCount: state.filteredUsers.length,
      itemBuilder: (_, i) {
        final user = state.filteredUsers[i];
        return AdvancedCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getRoleColor(user.role).withValues(alpha: 0.3),
                      _getRoleColor(user.role).withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    user.fullName[0].toUpperCase(),
                    style: TextStyle(color: _getRoleColor(user.role), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(user.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
                      _buildRoleBadge(user.role),
                    ]),
                    const SizedBox(height: 4),
                    Text(user.email, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 6),
                    Row(children: [
                      StatusBadge(status: _getUserStatusString(user)),
                      const SizedBox(width: 8),
                      _buildKycBadge(user.kycStatus),
                      const Spacer(),
                      _buildRiskBadge(user.riskScore, user.riskLevel),
                    ]),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.white54),
                color: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (_) => _buildUserPopupItems(user),
                onSelected: (action) => _handleUserAction(action, user),
              ),
            ],
          ),
        ).animate(delay: (i * 50).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05);
      },
    );
  }

  // Desktop: AdvancedTable-based table
  Widget _buildUserTable(UserListState state) {
    return AdvancedCard(
      padding: EdgeInsets.zero,
      child: state.filteredUsers.isEmpty
          ? const SizedBox(
              height: 300,
              child: Center(
                child: Text('No users found.', style: TextStyle(color: Colors.white54)),
              ),
            )
          : AdvancedTable(
              columns: const ['User', 'Role', 'Status', 'KYC', 'Risk', 'Joined', 'Actions'],
              rows: state.filteredUsers.map((user) {
                return [
                  // User cell
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getRoleColor(user.role).withValues(alpha: 0.3),
                              _getRoleColor(user.role).withValues(alpha: 0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            user.fullName[0].toUpperCase(),
                            style: TextStyle(
                              color: _getRoleColor(user.role),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(user.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(user.email, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Role cell
                  _buildRoleBadge(user.role),
                  // Status cell
                  StatusBadge(status: _getUserStatusString(user)),
                  // KYC cell
                  _buildKycBadge(user.kycStatus),
                  // Risk cell
                  _buildRiskBadge(user.riskScore, user.riskLevel),
                  // Joined cell
                  Text(
                    DateFormat('MMM d, y').format(user.joinedAt),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  // Actions cell
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: Colors.white54),
                    color: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (_) => _buildUserPopupItems(user),
                    onSelected: (action) => _handleUserAction(action, user),
                  ),
                ];
              }).toList(),
            ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05);
  }

  // === Invites Tab ===
  Widget _buildInvitesTab(InviteListState state, bool mobile) {
    if (state.isLoading) return const Padding(padding: EdgeInsets.all(12), child: WezuSkeletonTable(rows: 8, columns: 3));
    return Column(
      children: [
        Row(children: [
          _buildMiniStat('Pending', state.pending.toString(), const Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          _buildMiniStat('Accepted', state.accepted.toString(), const Color(0xFF22C55E)),
          const SizedBox(width: 8),
          _buildMiniStat('Expired', state.expired.toString(), const Color(0xFFEF4444)),
        ]).animate().fadeIn(duration: 400.ms, delay: 100.ms),
        const SizedBox(height: 12),
        Expanded(
          child: AdvancedCard(
            padding: EdgeInsets.zero,
            child: state.invites.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No invite records have been generated yet.',
                        style: TextStyle(color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.invites.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.04)),
                    itemBuilder: (_, i) {
                      final invite = state.invites[i];
                      final inviteId = int.tryParse(invite['id']?.toString() ?? '') ?? 0;
                      final inviteStatus = (invite['status']?.toString() ?? 'pending').toLowerCase();
                      final sentAt = DateTime.tryParse(invite['sent_at']?.toString() ?? '');
                      final expiresAt = DateTime.tryParse(invite['expires_at']?.toString() ?? '');
                      final role = invite['role']?.toString() ?? 'customer';

                      Color statusColor;
                      switch (inviteStatus) {
                        case 'accepted':
                          statusColor = const Color(0xFF22C55E);
                          break;
                        case 'expired':
                          statusColor = const Color(0xFFEF4444);
                          break;
                        case 'revoked':
                          statusColor = Colors.grey;
                          break;
                        default:
                          statusColor = const Color(0xFFF59E0B);
                      }

                      return ListTile(
                        dense: mobile,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.mail_outline, color: statusColor, size: 18),
                        ),
                        title: Text(
                          invite['email']?.toString() ?? 'Unknown email',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '$role • Sent ${sentAt != null ? DateFormat('MMM d, y • HH:mm').format(sentAt) : 'Unknown'}',
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                            if (expiresAt != null)
                              Text(
                                'Expires ${DateFormat('MMM d, y • HH:mm').format(expiresAt)}',
                                style: const TextStyle(color: Colors.white24, fontSize: 11),
                              ),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusBadge(status: inviteStatus),
                            if (inviteId > 0 && inviteStatus != 'accepted')
                              IconButton(
                                tooltip: 'Resend invite',
                                onPressed: () async {
                                  await ref.read(inviteListProvider.notifier).resendInvite(inviteId);
                                  _showSnackbar('Invite resent to ${invite['email']}');
                                },
                                icon: const Icon(Icons.refresh, color: Color(0xFF3B82F6), size: 18),
                              ),
                            if (inviteId > 0 && inviteStatus == 'pending')
                              IconButton(
                                tooltip: 'Revoke invite',
                                onPressed: () async {
                                  await ref.read(inviteListProvider.notifier).revokeInvite(inviteId);
                                  _showSnackbar('Invite revoked for ${invite['email']}');
                                },
                                icon: const Icon(Icons.block, color: Color(0xFFEF4444), size: 18),
                              ),
                          ],
                        ),
                      ).animate(delay: (i * 50).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // === History Tab ===
  Widget _buildHistoryTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(userRepositoryProvider).getCreationHistory(),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(padding: EdgeInsets.all(12), child: WezuSkeletonTable(rows: 5, columns: 4));
        }
        if (snap.hasError) {
          return AdvancedCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Creation history is unavailable: ${snap.error}',
                  style: const TextStyle(color: Color(0xFFEF4444)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        final data = snap.data ?? const <Map<String, dynamic>>[];
        return AdvancedCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.04)),
            itemBuilder: (_, i) {
              final e = data[i];
              return ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.history, color: Color(0xFF3B82F6), size: 18),
                ),
                title: Text(e['action'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
                subtitle: Text('${e['user']} • by ${e['by']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                trailing: Text(DateFormat('MMM d').format(e['date'] as DateTime), style: const TextStyle(color: Colors.white24, fontSize: 11)),
              ).animate(delay: (i * 50).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05);
            },
          ),
        );
      },
    );
  }

  // === Helpers ===

  String _getUserStatusString(User user) {
    if (user.suspensionStatus == 'suspended') return 'Suspended';
    return user.isActive ? 'Active' : 'Inactive';
  }

  List<PopupMenuEntry<String>> _buildUserPopupItems(User user) {
    return [
      _buildPopupItem('edit', Icons.edit_outlined, 'Edit Profile', const Color(0xFF3B82F6)),
      _buildPopupItem('toggle', user.isActive ? Icons.toggle_off : Icons.toggle_on,
        user.isActive ? 'Deactivate' : 'Activate', const Color(0xFFF59E0B)),
      _buildPopupItem(user.suspensionStatus == 'suspended' ? 'reactivate' : 'suspend',
        user.suspensionStatus == 'suspended' ? Icons.check_circle : Icons.block,
        user.suspensionStatus == 'suspended' ? 'Reactivate' : 'Suspend',
        user.suspensionStatus == 'suspended' ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
      _buildPopupItem('reset', Icons.lock_reset, 'Reset Password', const Color(0xFF8B5CF6)),
      const PopupMenuDivider(),
      _buildPopupItem('delete', Icons.delete_outline, 'Delete', const Color(0xFFEF4444)),
    ];
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return AdvancedCard(
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(width: 6),
      Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
    ]));

  Widget _buildFilterDropdown({String? value, required String hint, required List<String?> items, required List<String> labels, required Function(String?) onChanged}) =>
    Container(padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: value, hint: Text(hint, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        dropdownColor: const Color(0xFF1E293B), icon: const Icon(Icons.filter_list, color: Colors.white54, size: 18),
        style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        items: List.generate(items.length, (i) => DropdownMenuItem(value: items[i], child: Text(labels[i]))),
        onChanged: onChanged)));

  Color _getRoleColor(String role) => {
    'admin': const Color(0xFF8B5CF6),
    'supervisor': const Color(0xFF6366F1),
    'support': const Color(0xFF14B8A6),
    'dealer': const Color(0xFFF59E0B),
    'driver': const Color(0xFF3B82F6),
  }[role] ?? const Color(0xFF22C55E);

  Widget _buildRoleBadge(String role) {
    final c = _getRoleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Text(
        role.toUpperCase(),
        style: GoogleFonts.inter(color: c, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildKycBadge(String status) {
    final m = {
      'verified': (const Color(0xFF22C55E), Icons.check_circle),
      'pending': (const Color(0xFFF59E0B), Icons.pending),
      'rejected': (const Color(0xFFEF4444), Icons.cancel),
    };
    final d = m[status] ?? (Colors.grey, Icons.help);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(d.$2, size: 14, color: d.$1),
      const SizedBox(width: 4),
      Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(color: d.$1, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    ]);
  }

  Widget _buildRiskBadge(int score, String level) {
    final c = {
      'critical': const Color(0xFFEF4444),
      'high': const Color(0xFFF59E0B),
      'medium': const Color(0xFFFBBF24),
    }[level] ?? const Color(0xFF22C55E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Text('$score', style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String v, IconData i, String l, Color c) => PopupMenuItem(value: v,
    child: Row(children: [Icon(i, size: 18, color: c), const SizedBox(width: 12),
      Text(l, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13))]));

  void _showCreateDialog() => showDialog(context: context, builder: (_) => CreateUserDialog(
    onSubmit: (name, email, phone, password, role) {
      ref.read(userListProvider.notifier).createUser(fullName: name, email: email, phoneNumber: phone, password: password, role: role);
      _showSnackbar('User "$name" created');
    }));

  void _showInviteDialog() => showDialog(context: context, builder: (_) => InviteUsersDialog(
    onSingleInvite: (email, role) async {
      await ref.read(inviteListProvider.notifier).sendInvite(email: email, role: role);
      _showSnackbar('Invite sent to $email');
    },
    onBulkInvite: (rows) async {
      await ref.read(inviteListProvider.notifier).sendBulkInvites(rows);
      _showSnackbar('${rows.length} invites sent');
    }));

  void _handleUserAction(String action, User user) {
    switch (action) {
      case 'edit':
        showDialog(
          context: context,
          builder: (_) => EditUserDialog(
            user: user,
            onSubmit: (u) async {
              try {
                await ref.read(userListProvider.notifier).updateUser(u);
                _showSnackbar('User updated successfully');
              } catch (e) {
                _showErrorSnackbar('Failed to update user: $e');
              }
            },
          ),
        );
        break;

      case 'toggle':
        () async {
          try {
            await ref.read(userListProvider.notifier).toggleUserActive(user.id);
            _showSnackbar(user.isActive ? 'User deactivated' : 'User activated');
          } catch (e) {
            _showErrorSnackbar('Failed to toggle user status: $e');
          }
        }();
        break;

      case 'suspend':
        showDialog(
          context: context,
          builder: (_) => SuspendUserDialog(
            userName: user.fullName,
            onSubmit: (r, n, d) async {
              try {
                await ref.read(userListProvider.notifier).suspendUser(user.id, reason: r, durationDays: d);
                _showSnackbar('User suspended');
              } catch (e) {
                _showErrorSnackbar('Failed to suspend user: $e');
              }
            },
          ),
        );
        break;

      case 'reactivate':
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            title: const Text('Reactivate User', style: TextStyle(color: Colors.white)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Text('Are you sure you want to reactivate ${user.fullName}?', style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ref.read(userListProvider.notifier).reactivateUser(user.id);
                    _showSnackbar('User reactivated');
                  } catch (e) {
                    _showErrorSnackbar('Failed to reactivate user: $e');
                  }
                },
                child: const Text('Reactivate', style: TextStyle(color: Color(0xFF22C55E))),
              ),
            ],
          ),
        );
        break;

      case 'reset':
        () async {
          try {
            await ref.read(userListProvider.notifier).resetPassword(user.id);
            _showSnackbar('Password reset initiated for ${user.fullName}');
          } catch (e) {
            _showErrorSnackbar('Failed to reset password: $e');
          }
        }();
        break;

      case 'delete':
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            title: const Text('Delete User', style: TextStyle(color: Colors.white)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Text('Permanently delete ${user.fullName}? This cannot be undone.', style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ref.read(userListProvider.notifier).deleteUser(user.id);
                    _showSnackbar('User deleted');
                  } catch (e) {
                    _showErrorSnackbar('Failed to delete user: $e');
                  }
                },
                child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
              ),
            ],
          ),
        );
        break;
    }
  }

  void _showSnackbar(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    backgroundColor: const Color(0xFF1E293B),
  ));

  void _showErrorSnackbar(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.error_outline, color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
    ]),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    backgroundColor: const Color(0xFFEF4444),
    duration: const Duration(seconds: 4),
  ));
}
