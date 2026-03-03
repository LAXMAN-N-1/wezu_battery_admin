import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_widgets.dart';
import '../../../core/models/kyc_model.dart';
import '../../../core/providers/kyc_provider.dart';
import '../../../core/models/user_model.dart';
import 'kyc_verification_view.dart';
import '../../../core/widgets/responsive.dart';

class KycQueueView extends ConsumerWidget {
  const KycQueueView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kycProvider);
    final notifier = ref.read(kycProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(32),
          child: SectionHeader(
            title: 'KYC Verification Queue',
            action: ElevatedButton.icon(
              onPressed: () => notifier.loadQueue(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
        ),


        // Analytics Cards
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Responsive.isMobile(context) ? 16 : 32),
          child: GridView.count(
            crossAxisCount: Responsive.isMobile(context) ? 2 : Responsive.isTablet(context) ? 2 : 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: Responsive.isMobile(context) ? 0.9 : 1.5,
            children: [
              InkWell(
                onTap: () => notifier.setStatusFilter(KycStatus.pending),
                child: StatCard(
                  title: 'Pending Review',
                  value: '${state.analytics['pending'] ?? 0}',
                  icon: Icons.hourglass_empty,
                  color: AppColors.warning,
                ),
              ),
              InkWell(
                onTap: () => notifier.setStatusFilter(KycStatus.approved),
                child: StatCard(
                  title: 'Approved Today',
                  value: '${state.analytics['approved_today'] ?? 0}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
              ),
              InkWell(
                onTap: () => notifier.setStatusFilter(KycStatus.rejected),
                child: StatCard(
                  title: 'Rejected Today',
                  value: '${state.analytics['rejected_today'] ?? 0}',
                  icon: Icons.cancel_outlined,
                  color: AppColors.error,
                  trend: '+2%',
                  trendUp: false,
                ),
              ),
              StatCard(
                title: 'Avg. Verification Time',
                value: '${state.analytics['avg_time'] ?? '0m'}',
                icon: Icons.timer_outlined,
                color: AppColors.info,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Queue Table
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.requests.isEmpty
                  ? const EmptyState(
                      message: 'All caught up!',
                      subMessage: 'No pending KYC requests at the moment.',
                      icon: Icons.verified_user_outlined,
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 800),
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
                            showCheckboxColumn: false,
                            columns: const [
                              DataColumn(label: Text('User')),
                              DataColumn(label: Text('Document Type')),
                              DataColumn(label: Text('Submitted')),
                              DataColumn(label: Text('Wait Time')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: state.requests.map((req) {
                              final waitTime = DateTime.now().difference(req.submittedAt);
                              String waitLabel = '';
                              if (waitTime.inHours > 24) {
                                waitLabel = '${waitTime.inDays}d ago';
                              } else if (waitTime.inHours > 0) {
                                waitLabel = '${waitTime.inHours}h ago';
                              } else {
                                waitLabel = '${waitTime.inMinutes}m ago';
                              }

                              return DataRow(
                                onSelectChanged: (_) {
                                  _openVerification(context, req, ref);
                                },
                                cells: [
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(req.userName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                        Text(req.userId, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(req.documentType.label)),
                                  DataCell(Text(DateFormat.yMMMd().add_jm().format(req.submittedAt))),
                                  DataCell(Text(
                                    waitLabel,
                                    style: TextStyle(
                                      color: waitTime.inHours > 24 ? AppColors.error : AppColors.textSecondary,
                                      fontWeight: waitTime.inHours > 24 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  )),
                                  DataCell(_buildStatusBadge(req.status)),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
                                          onPressed: () => notifier.approveRequest(req.id),
                                          tooltip: 'Quick Approve',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                                          onPressed: () => _openVerification(context, req, ref),
                                          tooltip: 'Review & Reject',
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
        ),
      ],
    );
  }

  void _openVerification(BuildContext context, KycRequest request, WidgetRef ref) {
    ref.read(kycProvider.notifier).selectRequest(request);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => KycVerificationView(request: request),
    );
  }

  Widget _buildStatusBadge(KycStatus status) {
    switch (status) {
      case KycStatus.approved:
        return StatusBadge.success('Approved');
      case KycStatus.rejected:
        return StatusBadge.error('Rejected');
      case KycStatus.pending:
        return StatusBadge.warning('Pending Review');
      case KycStatus.none:
        return StatusBadge.warning('None');
    }
  }
}
