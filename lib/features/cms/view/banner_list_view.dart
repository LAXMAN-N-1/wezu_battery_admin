import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/banner.dart';
import '../data/repositories/banner_repository.dart';

class BannerListView extends ConsumerStatefulWidget {
  const BannerListView({super.key});

  @override
  ConsumerState<BannerListView> createState() => _BannerListViewState();
}

class _BannerListViewState extends ConsumerState<BannerListView> {
  late final BannerRepository _repository;
  List<Banner> _banners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(bannerRepositoryProvider);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final banners = await _repository.getBanners();
      setState(() {
        _banners = banners;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading banners: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'App Banners',
            subtitle: 'Manage promotional banners and hero images.',
            actionButton: ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to create view
              },
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 20, color: Colors.white),
              label: const Text('Add Banner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          const SizedBox(height: 32),

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _banners.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 1.8,
                      ),
                      itemCount: _banners.length,
                      itemBuilder: (context, index) {
                        return _buildBannerCard(_banners[index]).animate().fadeIn(duration: 400.ms, delay: (100 + index * 100).ms).slideY(begin: 0.05);
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(Banner banner) {
    return AdvancedCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.white.withValues(alpha: 0.1),
                  child: Image.network(
                    banner.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 48),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            banner.title,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        _buildPriorityBadge(banner.priority),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.ads_click, size: 14, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text('${banner.clickCount} Clicks', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        const Spacer(),
                        if (banner.startDate != null)
                          Text(
                            'Starts: ${DateFormat('MMM d').format(banner.startDate!)}',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                 StatusBadge(status: banner.isActive ? 'Active' : 'Inactive'),
              ],
            ),
          ),
          Positioned(
            bottom: 60, // Above padding
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'edit_${banner.id}',
              onPressed: () {},
              child: const Icon(Icons.edit_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(int priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Text(
        'P$priority',
        style: const TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Custom buildStatusChip removed, relies on StatusBadge which standardizes colors.

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.view_carousel_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          Text(
            'No active banners',
            style: GoogleFonts.outfit(fontSize: 20, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'Promote station launches or rental discounts with banners.',
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
