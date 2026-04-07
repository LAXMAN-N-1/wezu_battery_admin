import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/models/banner.dart' as model;
import '../data/cms_providers.dart';
import '../../../core/widgets/admin_ui_components.dart';

class BannerManagementView extends ConsumerStatefulWidget {
  const BannerManagementView({super.key});

  @override
  ConsumerState<BannerManagementView> createState() => _BannerManagementViewState();
}

class _BannerManagementViewState extends ConsumerState<BannerManagementView> {
  @override
  Widget build(BuildContext context) {
    final bannerState = ref.watch(bannerListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          bannerState.when(
            data: (banners) {
              if (banners.isEmpty) return _buildEmptyState();
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  mainAxisExtent: 460,
                ),
                itemCount: banners.length,
                itemBuilder: (context, index) => _buildBannerCard(banners[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promotion Banners',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage mobile app banners, promotions, and deep-link campaigns',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _showEditorDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create Banner'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCard(model.Banner banner) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141E2B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image Preview
          AspectRatio(
            aspectRatio: 16 / 7,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      banner.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white24)),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: StatusBadge(status: banner.isActive ? 'active' : 'inactive'),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                      child: Text('Priority: ${banner.priority}', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(banner.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(banner.deepLink ?? banner.externalUrl ?? 'No link assigned', style: GoogleFonts.inter(color: Colors.blue.shade300, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 20),
                
                // Metrics
                Row(
                  children: [
                    _metricItem(Icons.touch_app_outlined, 'Clicks', NumberFormat.compact().format(banner.clickCount)),
                    const SizedBox(width: 24),
                    _metricItem(Icons.calendar_today_outlined, 'Started', banner.startDate != null ? DateFormat('MMM d').format(banner.startDate!) : 'Immediate'),
                  ],
                ),
                
                const SizedBox(height: 24),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 16),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditorDialog(banner),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _confirmDelete(banner),
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      style: IconButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.05)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.white24),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.view_carousel_outlined, size: 80, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 24),
          Text('No active banners', style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Promote features or offers by creating your first banner', style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  void _showEditorDialog([model.Banner? banner]) {
     final titleCtrl = TextEditingController(text: banner?.title);
     final imageCtrl = TextEditingController(text: banner?.imageUrl);
     final linkCtrl = TextEditingController(text: banner?.deepLink);
     double priority = (banner?.priority ?? 1).toDouble();
     bool isActive = banner?.isActive ?? true;
     DateTimeRange? dateRange;
     if (banner?.startDate != null && banner?.endDate != null) {
       dateRange = DateTimeRange(start: banner!.startDate!, end: banner.endDate!);
     }

     showDialog(
       context: context,
       builder: (ctx) => StatefulBuilder(
         builder: (context, setModalState) => Dialog(
           backgroundColor: Colors.transparent,
           child: Container(
             width: 700,
             decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1))),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Padding(
                   padding: const EdgeInsets.all(24),
                   child: Row(
                     children: [
                       Text(banner == null ? 'Create Banner' : 'Edit Banner', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                       const Spacer(),
                       IconButton(icon: const Icon(Icons.close, color: Colors.white38), onPressed: () => Navigator.pop(ctx)),
                     ],
                   ),
                 ),
                 const Divider(color: Colors.white10, height: 1),
                 Flexible(
                   child: SingleChildScrollView(
                     padding: const EdgeInsets.all(32),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         // Live Preview
                         _sectionLabel('Preview'),
                         const SizedBox(height: 12),
                         Container(
                           width: double.infinity,
                           height: 160,
                           decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                           child: ClipRRect(
                             borderRadius: BorderRadius.circular(11),
                             child: imageCtrl.text.isNotEmpty 
                               ? Image.network(imageCtrl.text, fit: BoxFit.cover, errorBuilder: (_,__,___) => _previewPlaceholder())
                               : _previewPlaceholder(),
                           ),
                         ),
                         const SizedBox(height: 32),
                         
                         Row(
                           children: [
                             Expanded(child: _buildTextField('Campaign Title', titleCtrl, 'e.g. Summer Special Offer')),
                             const SizedBox(width: 24),
                             Expanded(child: _buildTextField('Image URL', imageCtrl, 'Direct link to image asset', onChanged: (v) => setModalState(() {}))),
                           ],
                         ),
                         const SizedBox(height: 24),
                         
                         Row(
                           children: [
                             Expanded(child: _buildTextField('Deep Link / Destination', linkCtrl, 'e.g. /swaps or /wallet')),
                             const SizedBox(width: 24),
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   _sectionLabel('Display Period'),
                                   const SizedBox(height: 8),
                                   InkWell(
                                     onTap: () async {
                                       final range = await showDateRangePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                                       if (range != null) setModalState(() => dateRange = range);
                                     },
                                     child: Container(
                                       padding: const EdgeInsets.all(16),
                                       decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                                       child: Row(
                                         children: [
                                           const Icon(Icons.calendar_month, color: Colors.white38, size: 18),
                                           const SizedBox(width: 12),
                                           Text(
                                             dateRange == null ? 'Set duration (Optional)' : '${DateFormat('MMM d').format(dateRange!.start)} - ${DateFormat('MMM d').format(dateRange!.end)}',
                                             style: TextStyle(color: dateRange == null ? Colors.white24 : Colors.white70, fontSize: 13),
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
                         const SizedBox(height: 32),
                         
                         Row(
                           children: [
                             Expanded(
                               flex: 2,
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   _sectionLabel('Display Priority: ${priority.toInt()}'),
                                   const SizedBox(height: 8),
                                   SliderTheme(
                                     data: SliderTheme.of(context).copyWith(trackHeight: 2, activeTrackColor: Colors.blue, thumbColor: Colors.blue, overlayColor: Colors.blue.withOpacity(0.1)),
                                     child: Slider(value: priority, min: 1, max: 10, divisions: 9, onChanged: (v) => setModalState(() => priority = v)),
                                   ),
                                 ],
                               ),
                             ),
                             const SizedBox(width: 48),
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   _sectionLabel('Status'),
                                   const SizedBox(height: 8),
                                   Container(
                                     decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                                     child: SwitchListTile(
                                       title: const Text('Active', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                       value: isActive,
                                       onChanged: (v) => setModalState(() => isActive = v),
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                           ],
                         ),
                       ],
                     ),
                   ),
                 ),
                 const Divider(color: Colors.white10, height: 1),
                 Padding(
                   padding: const EdgeInsets.all(24),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.end,
                     children: [
                       TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Discard')),
                       const SizedBox(width: 16),
                       ElevatedButton(
                         onPressed: () async {
                           final data = model.Banner(
                             id: banner?.id ?? 0,
                             title: titleCtrl.text,
                             imageUrl: imageCtrl.text,
                             deepLink: linkCtrl.text,
                             priority: priority.toInt(),
                             isActive: isActive,
                             startDate: dateRange?.start,
                             endDate: dateRange?.end,
                             clickCount: banner?.clickCount ?? 0,
                             createdAt: banner?.createdAt ?? DateTime.now(),
                             updatedAt: DateTime.now(),
                           );
                           if (banner == null) {
                             await ref.read(bannerRepositoryProvider).createBanner(data);
                           } else {
                             await ref.read(bannerRepositoryProvider).updateBanner(banner.id, data);
                           }
                           ref.invalidate(bannerListProvider);
                           if (ctx.mounted) Navigator.pop(ctx);
                         },
                         style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                         child: const Text('Save Banner'),
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

  Widget _previewPlaceholder() => Center(child: Icon(Icons.image_outlined, color: Colors.white.withOpacity(0.05), size: 48));

  Widget _sectionLabel(String label) => Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5));

  Widget _buildTextField(String label, TextEditingController ctrl, String hint, {ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(model.Banner banner) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Remove Banner?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to remove the "${banner.title}" banner?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(bannerListProvider.notifier).deleteBanner(banner.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
