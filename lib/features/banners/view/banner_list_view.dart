import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_widgets.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/models/banner_model.dart';
import '../../../core/providers/banner_provider.dart';
import 'banner_form_dialog.dart';

class BannerListView extends ConsumerWidget {
  const BannerListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bannerProvider);
    final notifier = ref.read(bannerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherits dashboard background
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newBanner = await showDialog<BannerModel>(
            context: context,
            builder: (context) => const BannerFormDialog(),
          );
          if (newBanner != null) {
            notifier.addBanner(newBanner);
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Banner'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(32),
            child: SectionHeader(
              title: 'Banner Management',
              action: ElevatedButton.icon(
                onPressed: () => notifier.loadBanners(),
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

          // Banner Grid
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.banners.isEmpty
                    ? const EmptyState(
                        message: 'No active banners',
                        subMessage: 'Create a new banner to get started',
                        icon: Icons.campaign_outlined,
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(32, 0, 32, 80),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: Responsive.isMobile(context) ? 1 : Responsive.isTablet(context) ? 2 : 3,
                          childAspectRatio: 0.9, 
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                        ),
                        itemCount: state.banners.length,
                        itemBuilder: (context, index) {
                          final banner = state.banners[index];
                          return _BannerCard(
                            banner: banner,
                            onEdit: () async {
                              final updatedBanner = await showDialog<BannerModel>(
                                context: context,
                                builder: (context) => BannerFormDialog(banner: banner),
                              );
                              if (updatedBanner != null) {
                                notifier.updateBanner(updatedBanner);
                              }
                            },
                            onDelete: () => _confirmDelete(context, banner, notifier),
                            onToggleStatus: () => notifier.toggleStatus(banner.id),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, BannerModel banner, BannerNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Banner?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Are you sure you want to delete "${banner.title}"? This action cannot be undone.', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              notifier.deleteBanner(banner.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _BannerCard({
    required this.banner,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Preview (Reduced flex to give more space to text)
          Expanded(
            flex: 1, 
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  banner.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.background,
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: Colors.white24, size: 32),
                          SizedBox(height: 8),
                          Text('Image Error', style: TextStyle(color: Colors.white24, fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: banner.isActive ? AppColors.success.withValues(alpha: 0.9) : AppColors.background.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      banner.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: banner.isActive ? Colors.white : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Details & Actions
          Expanded(
            flex: 1, // Increased relative space for details
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          banner.title,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Switch(
                        value: banner.isActive,
                        onChanged: (_) => onToggleStatus(),
                        activeThumbColor: AppColors.success,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${banner.startDate != null ? DateFormat.yMMMd().format(banner.startDate!) : 'N/A'} - ${banner.endDate != null ? DateFormat.yMMMd().format(banner.endDate!) : 'N/A'}',
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                        onPressed: onEdit,
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                        onPressed: onDelete,
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
