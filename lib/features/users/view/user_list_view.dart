import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_widgets.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/user_provider.dart';
import 'user_detail_view.dart';
import 'user_form_dialog.dart';

class UserListView extends ConsumerStatefulWidget {
  const UserListView({super.key});

  @override
  ConsumerState<UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends ConsumerState<UserListView> {
  bool _isFilterPanelVisible = false;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAll(UserListNotifier notifier) {
    _searchController.clear();
    notifier.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userListProvider);
    final notifier = ref.read(userListProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(32),
          child: SectionHeader(
            title: 'User Management',
            action: ElevatedButton.icon(
              onPressed: () async {
                final newUser = await showDialog<UserModel>(
                  context: context,
                  builder: (context) => const UserFormDialog(),
                );
                if (newUser != null) {
                  notifier.addUser(newUser);
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),

        // Search & Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              SearchFilterBar(
                controller: _searchController,
                onSearch: (value) => notifier.setSearchQuery(value),
                onFilterTap: () => setState(() => _isFilterPanelVisible = !_isFilterPanelVisible),
                activeFilters: [
                  if (state.kycFilter != null)
                    Chip(
                      label: Text('KYC: ${state.kycFilter!.label}'),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => notifier.setKycFilter(null),
                      backgroundColor: AppColors.surface,
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  if (state.accountFilter != null)
                    Chip(
                      label: Text('Account: ${state.accountFilter!.label}'),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => notifier.setAccountFilter(null),
                      backgroundColor: AppColors.surface,
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                ],
                onClearFilters: () => _clearAll(notifier),
              ),

              if (_isFilterPanelVisible) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Wrap(
                    spacing: 32,
                    runSpacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: [
                      _buildFilterGroup(
                        'KYC Status',
                        Wrap(
                          spacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: state.kycFilter == null,
                              onSelected: (_) => notifier.setKycFilter(null),
                              backgroundColor: AppColors.background,
                              selectedColor: AppColors.primary.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: state.kycFilter == null ? AppColors.primary : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: state.kycFilter == null ? AppColors.primary : AppColors.border,
                                ),
                              ),
                            ),
                            ...KycStatus.values.map((status) {
                              final isSelected = state.kycFilter == status;
                              return FilterChip(
                                label: Text(status.label),
                                selected: isSelected,
                                onSelected: (_) => notifier.setKycFilter(isSelected ? null : status),
                                backgroundColor: AppColors.background,
                                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      // const SizedBox(width: 32), // Handled by Wrap spacing
                      _buildFilterGroup(
                        'Account Status',
                        Wrap(
                          spacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: state.accountFilter == null,
                              onSelected: (_) => notifier.setAccountFilter(null),
                              backgroundColor: AppColors.background,
                              selectedColor: AppColors.primary.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: state.accountFilter == null ? AppColors.primary : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: state.accountFilter == null ? AppColors.primary : AppColors.border,
                                ),
                              ),
                            ),
                            ...AccountStatus.values.map((status) {
                              final isSelected = state.accountFilter == status;
                              return FilterChip(
                                label: Text(status.label),
                                selected: isSelected,
                                onSelected: (_) => notifier.setAccountFilter(isSelected ? null : status),
                                backgroundColor: AppColors.background,
                                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Data Table
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.users.isEmpty
                  ? const EmptyState(
                      message: 'No users found',
                      subMessage: 'Try adjusting your search or filters',
                      icon: Icons.people_outline,
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 800), // Ensure minimum width
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: AppColors.divider,
                            dataTableTheme: DataTableThemeData(
                              headingTextStyle: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              dataTextStyle: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          child: DataTable(
                            horizontalMargin: 24,
                            columnSpacing: 24,
                            columns: [
                              DataColumn(
                                label: const Text('User'),
                                onSort: (idx, _) => notifier.setSort('name'),
                              ),
                              const DataColumn(label: Text('Phone')),
                              DataColumn(
                                label: const Text('Joined'),
                                onSort: (idx, _) => notifier.setSort('date'),
                              ),
                              const DataColumn(label: Text('KYC')),
                              const DataColumn(label: Text('Status')),
                              DataColumn(
                                label: const Text('Balance'),
                                numeric: true,
                                onSort: (idx, _) => notifier.setSort('balance'),
                              ),
                              const DataColumn(label: Text('Actions')),
                            ],
                            rows: state.users.map((user) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: AppColors.surfaceHighlight,
                                          backgroundImage: user.profilePhotoUrl != null
                                              ? NetworkImage(user.profilePhotoUrl!)
                                              : null,
                                          child: user.profilePhotoUrl == null
                                              ? Text(
                                                  user.name[0].toUpperCase(),
                                                  style: const TextStyle(
                                                    color: AppColors.textPrimary,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              user.name,
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              user.email,
                                              style: TextStyle(
                                                color: AppColors.textTertiary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(user.phone)),
                                  DataCell(Text(DateFormat.yMMMd().format(user.registrationDate))),
                                  DataCell(_buildKycBadge(user.kycStatus)),
                                  DataCell(_buildAccountBadge(user.accountStatus)),
                                  DataCell(Text('₹${user.walletBalance.toStringAsFixed(2)}')),
                                  DataCell(
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                                      onSelected: (value) {
                                        if (value == 'view') {
                                          showDialog(
                                            context: context,
                                            builder: (context) => UserDetailView(user: user),
                                          );
                                        } else if (value == 'suspend') {
                                          notifier.suspendUser(user.id);
                                        } else if (value == 'activate') {
                                          notifier.activateUser(user.id);
                                        }
                                      },
                                      color: AppColors.surfaceHighlight,
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'view',
                                          child: Row(children: [Icon(Icons.visibility_outlined, size: 18), SizedBox(width: 8), Text('View Details')]),
                                        ),
                                        if (user.accountStatus == AccountStatus.active)
                                          const PopupMenuItem(
                                            value: 'suspend',
                                            child: Row(children: [Icon(Icons.block_outlined, size: 18, color: AppColors.warning), SizedBox(width: 8), Text('Suspend Account')]),
                                          ),
                                        if (user.accountStatus == AccountStatus.suspended)
                                          const PopupMenuItem(
                                            value: 'activate',
                                            child: Row(children: [Icon(Icons.check_circle_outline, size: 18, color: AppColors.success), SizedBox(width: 8), Text('Activate Account')]),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
          ), // Closes Expanded
          
          // Pagination Footer
          if (state.totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Responsive.isMobile(context)
                ? Column(
                    children: [
                      Text(
                        'Showing ${(state.page - 1) * state.limit + 1}-${((state.page - 1) * state.limit) + state.users.length} of ${state.total} users',
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: state.page > 1 ? () => notifier.loadUsers(page: state.page - 1) : null,
                            icon: const Icon(Icons.chevron_left),
                            color: AppColors.textSecondary,
                          ),
                          Text(
                            'Page ${state.page} of ${state.totalPages}',
                            style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                          ),
                          IconButton(
                            onPressed: state.page < state.totalPages ? () => notifier.loadUsers(page: state.page + 1) : null,
                            icon: const Icon(Icons.chevron_right),
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${(state.page - 1) * state.limit + 1}-${((state.page - 1) * state.limit) + state.users.length} of ${state.total} users',
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: state.page > 1 ? () => notifier.loadUsers(page: state.page - 1) : null,
                            icon: const Icon(Icons.chevron_left),
                            color: AppColors.textSecondary,
                          ),
                          Text(
                            'Page ${state.page} of ${state.totalPages}',
                            style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                          ),
                          IconButton(
                            onPressed: state.page < state.totalPages ? () => notifier.loadUsers(page: state.page + 1) : null,
                            icon: const Icon(Icons.chevron_right),
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
      ],
    );
  }

  Widget _buildFilterGroup(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildKycBadge(KycStatus status) {
    switch (status) {
      case KycStatus.approved: return StatusBadge.success('Approved');
      case KycStatus.pending: return StatusBadge.warning('Pending');
      case KycStatus.rejected: return StatusBadge.error('Rejected');
      case KycStatus.none: return StatusBadge.gray('None');
    }
  }

  Widget _buildAccountBadge(AccountStatus status) {
    switch (status) {
      case AccountStatus.active: return StatusBadge.success('Active');
      case AccountStatus.suspended: return StatusBadge.warning('Suspended');
      case AccountStatus.banned: return StatusBadge.error('Banned');
    }
  }
}
