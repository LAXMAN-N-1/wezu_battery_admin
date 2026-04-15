import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../../../core/widgets/glass_components.dart';
import '../data/models/banner.dart' as model;
import '../provider/cms_providers.dart';

class BannerManagementView extends ConsumerStatefulWidget {
  const BannerManagementView({super.key});

  @override
  ConsumerState<BannerManagementView> createState() => _BannerManagementViewState();
}

class _BannerManagementViewState extends ConsumerState<BannerManagementView> {
  String _selectedType = 'All';
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannerProvider);

    return GlassScaffold(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'App Banners',
              subtitle: 'Manage in-app promotional and informational banners',
              actionButton: ElevatedButton.icon(
                onPressed: () => context.push('/cms/banners/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('CREATE BANNER'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildFilterRow(),
            const SizedBox(height: 24),

            Expanded(
              child: bannersAsync.when(
                data: (banners) => _buildBannerGrid(banners),
                loading: () => _buildShimmerGrid(),
                error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        _buildDropdown(
          'Banner Type',
          _selectedType,
          ['All', 'Home Carousel', 'Popup', 'Top Notification Bar', 'Floating Card'],
          (v) {
            setState(() => _selectedType = v!);
            ref.read(bannerProvider.notifier).setFilters(type: v);
          },
        ),
        const SizedBox(width: 16),
        _buildDropdown(
          'Status',
          _selectedStatus,
          ['All', 'Active', 'Inactive', 'Scheduled', 'Expired'],
          (v) {
            setState(() => _selectedStatus = v!);
            ref.read(bannerProvider.notifier).setFilters(status: v);
          },
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white38, fontSize: 13)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: const Color(0xFF1E293B),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white38),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerGrid(List<model.Banner> banners) {
    if (banners.isEmpty) return _buildEmptyState();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1600 ? 4 : (constraints.maxWidth > 1000 ? 3 : (constraints.maxWidth > 600 ? 2 : 1));
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.9,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: banners.length,
          itemBuilder: (context, index) => BannerCard(
            banner: banners[index],
             onEdit: () => context.push('/cms/banners/edit', extra: banners[index]),
             onDelete: () => _confirmDelete(banners[index]),
             onToggle: (v) => _confirmToggle(banners[index], v),
           ),
         );
      },
    );
  }

  Widget _buildShimmerGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1600 ? 4 : (constraints.maxWidth > 1000 ? 3 : (constraints.maxWidth > 600 ? 2 : 1));
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.9,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: 6,
          itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(16)),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style_outlined, size: 64, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          const Text('No banners found', style: TextStyle(color: Colors.white38, fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              setState(() { _selectedType = 'All'; _selectedStatus = 'All'; });
              ref.read(bannerProvider.notifier).setFilters(type: 'All', status: 'All');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Filters', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(model.Banner banner) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${banner.title}"? This action cannot be undone.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () {
              ref.read(bannerProvider.notifier).deleteBanner(banner.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _confirmToggle(model.Banner banner, bool newValue) {
    final action = newValue ? 'Activate' : 'Deactivate';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('$action Banner', style: const TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to $action "${banner.title}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () {
              ref.read(bannerProvider.notifier).toggleBanner(banner.id, newValue);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: newValue ? Colors.green : const Color(0xFF3B82F6)),
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );
  }
}

class BannerCard extends StatefulWidget {
  final model.Banner banner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onToggle;

  const BannerCard({
    super.key,
    required this.banner,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  State<BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<BannerCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isDeleting = false;

  void _handleDelete() async {
    setState(() => _isDeleting = true);
    // Wait for the fade out animation to complete before calling onDelete
    await Future.delayed(const Duration(milliseconds: 300));
    widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final status = _calculateStatus(widget.banner);
    
    return AnimatedOpacity(
      duration: 300.ms,
      opacity: _isDeleting ? 0.0 : 1.0,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.01 : 1.0,
          duration: 200.ms,
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _isHovered ? Colors.white24 : Colors.white10),
              boxShadow: _isHovered 
                ? [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]
                : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.banner.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(color: Colors.white.withOpacity(0.05)).animate(onPlay: (c) => c.repeat()).shimmer();
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.white.withOpacity(0.05),
                            child: const Icon(Icons.image_not_supported_outlined, color: Colors.white10, size: 48),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: AnimatedSwitcher(
                            duration: 400.ms,
                            transitionBuilder: (child, animation) => FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(scale: animation, child: child),
                            ),
                            child: _buildStatusBadge(status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.banner.title,
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _chip(widget.banner.type.toUpperCase(), Colors.white10),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 8, color: Colors.white38),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatDateRange(widget.banner),
                              style: const TextStyle(color: Colors.white38, fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.star, size: 8, color: Colors.amberAccent),
                          const SizedBox(width: 4),
                          Text(
                            'P: ${widget.banner.priority}',
                            style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 6),
                      AnimatedOpacity(
                        duration: 200.ms,
                        opacity: _isHovered ? 1.0 : 0.4,
                        child: Row(
                          children: [
                            _ActionButton(
                              icon: Icons.edit_outlined,
                              label: 'EDIT',
                              onPressed: widget.onEdit,
                            ),
                            const Spacer(),
                            _ActionButton(
                              icon: widget.banner.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              label: widget.banner.isActive ? 'OFF' : 'ON',
                              onPressed: () => widget.onToggle(!widget.banner.isActive),
                              isSuccess: !widget.banner.isActive,
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white24),
                              hoverColor: Colors.redAccent.withOpacity(0.1),
                              onPressed: _handleDelete,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _calculateStatus(model.Banner b) {
    if (!b.isActive) return 'Inactive';
    final now = DateTime.now();
    if (b.startDate != null && b.startDate!.isAfter(now)) return 'Scheduled';
    if (b.endDate != null && b.endDate!.isBefore(now)) return 'Expired';
    return 'Active';
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'Active') color = Colors.green;
    if (status == 'Scheduled') color = Colors.blue;
    if (status == 'Expired') color = Colors.red;

    return Container(
      key: ValueKey(status),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  String _formatDateRange(model.Banner b) {
    if (b.startDate == null && b.endDate == null) return 'Always Active';
    final start = b.startDate != null ? '${b.startDate!.day} ${_getMonth(b.startDate!.month)}' : 'Start';
    final end = b.endDate != null ? '${b.endDate!.day} ${_getMonth(b.endDate!.month)}' : 'End';
    return '$start • $end';
  }

  String _getMonth(int m) => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];

  Widget _chip(String text, Color bg, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: TextStyle(color: textColor ?? Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isSuccess;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? Colors.greenAccent : Colors.white54;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
