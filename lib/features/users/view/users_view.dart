import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/models/user.dart';
import '../provider/user_provider.dart';
import 'dialogs/create_user_dialog.dart';
import 'dialogs/edit_user_dialog.dart';
import 'dialogs/invite_users_dialog.dart';
import 'dialogs/suspend_user_dialog.dart';

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
        // Header
        if (mobile) ...[
          Text('User Management', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildActionButton('Invite', Icons.mail_outline, Colors.green, _showInviteDialog)),
            const SizedBox(width: 8),
            Expanded(child: _buildActionButton('Create', Icons.person_add, Colors.blue, _showCreateDialog)),
          ]),
        ] else
          Row(children: [
            Text('User Management', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const Spacer(),
            _buildActionButton('Invite Users', Icons.mail_outline, Colors.green, _showInviteDialog),
            const SizedBox(width: 12),
            _buildActionButton('Create User', Icons.person_add, Colors.blue, _showCreateDialog),
          ]),
        const SizedBox(height: 20),

        // Stats - 2x2 grid on mobile, 1x4 row on desktop
        if (mobile)
          Column(children: [
            Row(children: [
              Expanded(child: _buildStatCard('Total Users', userState.totalCount.toString(), Icons.people_outline, Colors.blue, true)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Active', userState.activeUsers.toString(), Icons.check_circle_outline, Colors.green, true)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _buildStatCard('Suspended', userState.suspendedUsers.toString(), Icons.block, Colors.red, true)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Pending KYC', userState.pendingKyc.toString(), Icons.verified_user_outlined, Colors.orange, true)),
            ]),
          ])
        else
          Row(children: [
            Expanded(child: _buildStatCard('Total Users', userState.totalCount.toString(), Icons.people_outline, Colors.blue, false)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Active', userState.activeUsers.toString(), Icons.check_circle_outline, Colors.green, false)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Suspended', userState.suspendedUsers.toString(), Icons.block, Colors.red, false)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Pending KYC', userState.pendingKyc.toString(), Icons.verified_user_outlined, Colors.orange, false)),
          ]),
        const SizedBox(height: 20),

        // Tabs
        Container(
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            labelColor: Colors.blue, unselectedLabelColor: Colors.white54,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: mobile ? 11 : 13),
            isScrollable: mobile,
            tabs: [
              Tab(text: 'All Users (${userState.totalCount})'),
              Tab(text: 'Invites (${inviteState.invites.length})'),
              const Tab(text: 'History'),
            ],
          ),
        ),
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
      if (mobile)
        TextField(
          style: const TextStyle(color: Colors.white),
          onChanged: (v) => ref.read(userListProvider.notifier).setSearchQuery(v),
          decoration: InputDecoration(
            hintText: 'Search users...', hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search, color: Colors.white38),
            filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        )
      else
        Row(children: [
          Expanded(child: TextField(
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => ref.read(userListProvider.notifier).setSearchQuery(v),
            decoration: InputDecoration(
              hintText: 'Search by name, email, or phone...', hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          )),
          const SizedBox(width: 12),
          _buildFilterDropdown(value: state.filterRole, hint: 'Role',
            items: [null, 'admin', 'supervisor', 'support', 'dealer', 'driver', 'customer'],
            labels: ['All Roles', 'Admin', 'Supervisor', 'Support', 'Dealer', 'Driver', 'Customer'],
            onChanged: (v) => ref.read(userListProvider.notifier).setRoleFilter(v)),
          const SizedBox(width: 12),
          _buildFilterDropdown(value: state.filterStatus, hint: 'Status',
            items: [null, 'active', 'inactive', 'suspended'],
            labels: ['All Status', 'Active', 'Inactive', 'Suspended'],
            onChanged: (v) => ref.read(userListProvider.notifier).setStatusFilter(v)),
        ]),
      const SizedBox(height: 12),

      Expanded(child: state.isLoading
        ? const Center(child: CircularProgressIndicator())
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
                style: const TextStyle(color: Colors.white70, fontSize: 13),
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
        return Card(
          color: Colors.white.withValues(alpha: 0.05),
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
              child: Text(user.fullName[0].toUpperCase(),
                style: TextStyle(color: _getRoleColor(user.role), fontWeight: FontWeight.bold)),
            ),
            title: Row(children: [
              Expanded(child: Text(user.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14))),
              _buildRoleBadge(user.role),
            ]),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.email, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 4),
              Row(children: [
                _buildStatusBadge(user),
                const SizedBox(width: 8),
                _buildKycBadge(user.kycStatus),
                const Spacer(),
                _buildRiskBadge(user.riskScore, user.riskLevel),
              ]),
            ]),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: Colors.white54),
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [
                _buildPopupItem('edit', Icons.edit_outlined, 'Edit', Colors.blue),
                _buildPopupItem('toggle', user.isActive ? Icons.toggle_off : Icons.toggle_on,
                  user.isActive ? 'Deactivate' : 'Activate', Colors.orange),
                _buildPopupItem(user.suspensionStatus == 'suspended' ? 'reactivate' : 'suspend',
                  user.suspensionStatus == 'suspended' ? Icons.check_circle : Icons.block,
                  user.suspensionStatus == 'suspended' ? 'Reactivate' : 'Suspend',
                  user.suspensionStatus == 'suspended' ? Colors.green : Colors.red),
                _buildPopupItem('reset', Icons.lock_reset, 'Reset Password', Colors.purple),
                const PopupMenuDivider(),
                _buildPopupItem('delete', Icons.delete_outline, 'Delete', Colors.red),
              ],
              onSelected: (action) => _handleUserAction(action, user),
            ),
          ),
        );
      },
    );
  }

  // Desktop: data table
  Widget _buildUserTable(UserListState state) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(width: double.infinity, child: SingleChildScrollView(child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.white.withValues(alpha: 0.1), iconTheme: const IconThemeData(color: Colors.white70)),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.05)),
          dataRowMinHeight: 64, dataRowMaxHeight: 64,
          columns: const [
            DataColumn(label: Text('User', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Role', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Status', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
            DataColumn(label: Text('KYC', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Risk', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Joined', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
          ],
          rows: state.filteredUsers.map((user) => DataRow(cells: [
            DataCell(Row(children: [
              CircleAvatar(radius: 18, backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
                child: Text(user.fullName[0].toUpperCase(), style: TextStyle(color: _getRoleColor(user.role), fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(user.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                Text(user.email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ]),
            ])),
            DataCell(_buildRoleBadge(user.role)),
            DataCell(_buildStatusBadge(user)),
            DataCell(_buildKycBadge(user.kycStatus)),
            DataCell(_buildRiskBadge(user.riskScore, user.riskLevel)),
            DataCell(Text(DateFormat('MMM d, y').format(user.joinedAt), style: const TextStyle(color: Colors.white70))),
            DataCell(PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20, color: Colors.white54),
              color: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [
                _buildPopupItem('edit', Icons.edit_outlined, 'Edit Profile', Colors.blue),
                _buildPopupItem('toggle', user.isActive ? Icons.toggle_off : Icons.toggle_on,
                  user.isActive ? 'Deactivate' : 'Activate', Colors.orange),
                _buildPopupItem(user.suspensionStatus == 'suspended' ? 'reactivate' : 'suspend',
                  user.suspensionStatus == 'suspended' ? Icons.check_circle : Icons.block,
                  user.suspensionStatus == 'suspended' ? 'Reactivate' : 'Suspend',
                  user.suspensionStatus == 'suspended' ? Colors.green : Colors.red),
                _buildPopupItem('reset', Icons.lock_reset, 'Reset Password', Colors.purple),
                const PopupMenuDivider(),
                _buildPopupItem('delete', Icons.delete_outline, 'Delete', Colors.red),
              ],
              onSelected: (action) => _handleUserAction(action, user),
            )),
          ])).toList(),
        ),
      ))),
    );
  }

  // === Invites Tab ===
  Widget _buildInvitesTab(InviteListState state, bool mobile) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Row(children: [
          _buildMiniStat('Pending', state.pending.toString(), Colors.orange),
          const SizedBox(width: 8),
          _buildMiniStat('Accepted', state.accepted.toString(), Colors.green),
          const SizedBox(width: 8),
          _buildMiniStat('Expired', state.expired.toString(), Colors.red),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: state.invites.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No invite records have been generated yet.',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.invites.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.08)),
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
                          statusColor = Colors.green;
                          break;
                        case 'expired':
                          statusColor = Colors.redAccent;
                          break;
                        case 'revoked':
                          statusColor = Colors.grey;
                          break;
                        default:
                          statusColor = Colors.orange;
                      }

                      return ListTile(
                        dense: mobile,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
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
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            if (expiresAt != null)
                              Text(
                                'Expires ${DateFormat('MMM d, y • HH:mm').format(expiresAt)}',
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                inviteStatus[0].toUpperCase() + inviteStatus.substring(1),
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (inviteId > 0 && inviteStatus != 'accepted')
                              IconButton(
                                tooltip: 'Resend invite',
                                onPressed: () async {
                                  await ref.read(inviteListProvider.notifier).resendInvite(inviteId);
                                  _showSnackbar('Invite resent to ${invite['email']}');
                                },
                                icon: const Icon(Icons.refresh, color: Colors.blueAccent, size: 18),
                              ),
                            if (inviteId > 0 && inviteStatus == 'pending')
                              IconButton(
                                tooltip: 'Revoke invite',
                                onPressed: () async {
                                  await ref.read(inviteListProvider.notifier).revokeInvite(inviteId);
                                  _showSnackbar('Invite revoked for ${invite['email']}');
                                },
                                icon: const Icon(Icons.block, color: Colors.redAccent, size: 18),
                              ),
                          ],
                        ),
                      );
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
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Creation history is unavailable: ${snap.error}',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        final data = snap.data ?? const <Map<String, dynamic>>[];
        return Card(
          color: Colors.white.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.1)),
            itemBuilder: (_, i) {
              final e = data[i];
              return ListTile(
                dense: true,
                leading: Container(padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.history, color: Colors.blue, size: 18)),
                title: Text(e['action'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
                subtitle: Text('${e['user']} • by ${e['by']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                trailing: Text(DateFormat('MMM d').format(e['date'] as DateTime), style: const TextStyle(color: Colors.white38, fontSize: 11)),
              );
            },
          ),
        );
      },
    );
  }

  // === Helpers ===
  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap, icon: Icon(icon, size: 16), label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15), foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withValues(alpha: 0.3)))),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool compact) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Row(children: [
        Container(padding: EdgeInsets.all(compact ? 8 : 10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: compact ? 18 : 22)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.outfit(fontSize: compact ? 20 : 26, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: compact ? 10 : 12)),
        ]),
      ]),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(width: 6),
      Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
    ]));

  Widget _buildFilterDropdown({String? value, required String hint, required List<String?> items, required List<String> labels, required Function(String?) onChanged}) =>
    Container(padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: value, hint: Text(hint, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        dropdownColor: const Color(0xFF1E293B), icon: const Icon(Icons.filter_list, color: Colors.white54, size: 18),
        style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        items: List.generate(items.length, (i) => DropdownMenuItem(value: items[i], child: Text(labels[i]))),
        onChanged: onChanged)));

  Color _getRoleColor(String role) => {'admin': Colors.purple, 'supervisor': Colors.indigo, 'support': Colors.teal,
    'dealer': Colors.orange, 'driver': Colors.blue}[role] ?? Colors.green;

  Widget _buildRoleBadge(String role) { final c = _getRoleColor(role); return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withValues(alpha: 0.2))),
    child: Text(role.toUpperCase(), style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold))); }

  Widget _buildStatusBadge(User user) {
    if (user.suspensionStatus == 'suspended') {
      return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.block, size: 10, color: Colors.red), SizedBox(width: 3),
          Text('Suspended', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w500))]));
    }
    final c = user.isActive ? Colors.green : Colors.grey;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(user.isActive ? 'Active' : 'Inactive', style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w500)));
  }

  Widget _buildKycBadge(String status) {
    final m = {'verified': (Colors.green, Icons.check_circle), 'pending': (Colors.orange, Icons.pending),
      'rejected': (Colors.red, Icons.cancel)}; final d = m[status] ?? (Colors.grey, Icons.help);
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(d.$2, size: 12, color: d.$1), const SizedBox(width: 3),
      Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(color: d.$1, fontSize: 10))]);
  }

  Widget _buildRiskBadge(int score, String level) {
    final c = {'critical': Colors.red, 'high': Colors.orange, 'medium': Colors.amber}[level] ?? Colors.green;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text('$score', style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.bold)));
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
      case 'edit': showDialog(context: context, builder: (_) => EditUserDialog(user: user,
        onSubmit: (u) { ref.read(userListProvider.notifier).updateUser(u); _showSnackbar('Updated'); })); break;
      case 'toggle': ref.read(userListProvider.notifier).toggleUserActive(user.id);
        _showSnackbar(user.isActive ? 'Deactivated' : 'Activated'); break;
      case 'suspend': showDialog(context: context, builder: (_) => SuspendUserDialog(userName: user.fullName,
        onSubmit: (r, n, d) { ref.read(userListProvider.notifier).suspendUser(user.id, reason: r, durationDays: d); _showSnackbar('Suspended'); })); break;
      case 'reactivate': showDialog(context: context, builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B), title: const Text('Reactivate User', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to reactivate ${user.fullName}?', style: const TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { ref.read(userListProvider.notifier).reactivateUser(user.id); Navigator.pop(context); _showSnackbar('Reactivated'); },
            child: const Text('Reactivate', style: TextStyle(color: Colors.green)))])); break;
      case 'reset': ref.read(userListProvider.notifier).resetPassword(user.id); _showSnackbar('Password reset initiated'); break;
      case 'delete': showDialog(context: context, builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B), title: const Text('Delete User', style: TextStyle(color: Colors.white)),
        content: Text('Delete ${user.fullName}?', style: const TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { ref.read(userListProvider.notifier).deleteUser(user.id); Navigator.pop(context); _showSnackbar('Deleted'); },
            child: const Text('Delete', style: TextStyle(color: Colors.red)))])); break;
    }
  }

  void _showSnackbar(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg),
    behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    backgroundColor: const Color(0xFF1E293B)));
}
