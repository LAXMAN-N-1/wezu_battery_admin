import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_widgets.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/models/user_model.dart';

class UserDetailView extends ConsumerWidget {
  final UserModel user;

  const UserDetailView({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            Divider(height: 1, color: AppColors.divider),
            
            // Content
            Expanded(
              child: Flex(
                direction: Responsive.isMobile(context) ? Axis.vertical : Axis.horizontal,
                children: [
                  // Sidebar
                  Container(
                    width: Responsive.isMobile(context) ? double.infinity : 280,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(
                        right: Responsive.isMobile(context) ? BorderSide.none : BorderSide(color: AppColors.divider),
                        bottom: Responsive.isMobile(context) ? BorderSide(color: AppColors.divider) : BorderSide.none,
                      ),
                    ),
                    child: Responsive.isMobile(context)
                        ? Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: AppColors.surfaceHighlight,
                                    backgroundImage: user.profilePhotoUrl != null
                                        ? NetworkImage(user.profilePhotoUrl!)
                                        : null,
                                    child: user.profilePhotoUrl == null
                                        ? Text(
                                            user.name[0].toUpperCase(),
                                            style: GoogleFonts.outfit(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          style: GoogleFonts.outfit(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          user.id,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatusRow('KYC', _buildKycBadge(user.kycStatus)),
                                  _buildStatusRow('Account', _buildAccountBadge(user.accountStatus)),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: AppColors.surfaceHighlight,
                                backgroundImage: user.profilePhotoUrl != null
                                    ? NetworkImage(user.profilePhotoUrl!)
                                    : null,
                                child: user.profilePhotoUrl == null
                                    ? Text(
                                        user.name[0].toUpperCase(),
                                        style: GoogleFonts.outfit(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                user.name,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.id,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildStatusRow('KYC', _buildKycBadge(user.kycStatus)),
                              const SizedBox(height: 12),
                              _buildStatusRow('Account', _buildAccountBadge(user.accountStatus)),
                              const SizedBox(height: 32),
                              _buildSidebarInfo('Email', user.email),
                              const SizedBox(height: 16),
                              _buildSidebarInfo('Phone', user.phone),
                              const SizedBox(height: 16),
                              _buildSidebarInfo('Joined', DateFormat.yMMMd().format(user.registrationDate)),
                              const SizedBox(height: 16),
                              _buildSidebarInfo('Last Active', DateFormat.yMMMd().add_jm().format(user.lastActive)),
                            ],
                          ),
                  ),

                  // Main Tabs
                  Expanded(
                    child: DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          TabBar(
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.textSecondary,
                            indicatorColor: AppColors.primary,
                            dividerColor: AppColors.divider,
                            tabs: const [
                              Tab(text: 'Overview'),
                              Tab(text: 'Vehicles'),
                              Tab(text: 'Transactions'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildOverviewTab(),
                                _buildVehiclesTab(),
                                const Center(child: Text('Transactions History Coming Soon', style: TextStyle(color: Colors.white38))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'User Details',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, Widget statusBadge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        statusBadge,
      ],
    );
  }

  Widget _buildSidebarInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Wallet Balance',
                value: '₹${user.walletBalance.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: StatCard(
                title: 'Total Swaps',
                value: '${user.totalSwaps}',
                icon: Icons.swap_horiz,
                color: AppColors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SectionHeader(title: 'Recent Activity'),
        const SizedBox(height: 16),
        Container(
          height: 200,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text('No recent activity', style: TextStyle(color: Colors.white24)),
        ),
      ],
    );
  }

  Widget _buildVehiclesTab() {
    if (user.vehicles.isEmpty) {
      return const EmptyState(
        message: 'No vehicles registered',
        icon: Icons.electric_scooter_outlined,
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(32),
      itemCount: user.vehicles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.electric_scooter, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.vehicles[index],
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Primary Vehicle',
                      style: TextStyle(color: AppColors.success, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
