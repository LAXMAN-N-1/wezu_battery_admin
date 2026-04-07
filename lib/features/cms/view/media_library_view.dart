import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../data/models/media_asset.dart';
import '../data/cms_providers.dart';
import '../../../core/widgets/admin_ui_components.dart';

class MediaLibraryView extends ConsumerStatefulWidget {
  const MediaLibraryView({super.key});

  @override
  ConsumerState<MediaLibraryView> createState() => _MediaLibraryViewState();
}

class _MediaLibraryViewState extends ConsumerState<MediaLibraryView> {
  String _activeCategory = 'All';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildFilters(),
            const SizedBox(height: 24),
            mediaState.when(
              data: (assets) {
                final filteredAssets = _applyFilters(assets);
                if (filteredAssets.isEmpty) return _buildEmptyState();
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filteredAssets.length,
                  itemBuilder: (context, index) => _buildMediaCard(filteredAssets[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
            ),
          ],
        ),
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
              'Media Library',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage and organize your platform assets, images, and branding files',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _showUploadDialog(),
          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
          label: const Text('Upload Media'),
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

  Widget _buildFilters() {
    final categories = ['All', 'general', 'banners', 'blogs', 'products', 'branding'];
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) => _filterTab(cat)).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            onChanged: (v) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search assets by name...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.2), size: 18),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterTab(String label) {
    final active = _activeCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _activeCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF3B82F6).withOpacity(0.15) : Colors.white.withOpacity(0.05) ,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? const Color(0xFF3B82F6).withOpacity(0.3) : Colors.transparent),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: active ? Colors.blue.shade300 : Colors.white38,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  List<MediaAsset> _applyFilters(List<MediaAsset> assets) {
    return assets.where((a) {
      if (_activeCategory != 'All' && a.category?.toLowerCase() != _activeCategory.toLowerCase()) return false;
      if (_searchController.text.isNotEmpty && !a.fileName.toLowerCase().contains(_searchController.text.toLowerCase())) return false;
      return true;
    }).toList();
  }

  Widget _buildMediaCard(MediaAsset asset) {
    return GestureDetector(
      onTap: () => _showAssetDetails(asset),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141E2B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      asset.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.white10, child: const Icon(Icons.broken_image_outlined, color: Colors.white24)),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                        child: Text(asset.fileType.split('/').last.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
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
                  Text(asset.fileName, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(NumberFormat.compact().format(asset.fileSizeBytes / 1024) + ' KB', style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
                      Icon(Icons.more_horiz, size: 14, color: Colors.white24),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssetDetails(MediaAsset asset) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.horizontal(left: Radius.circular(23))),
                  child: Center(
                    child: Hero(
                      tag: asset.id,
                      child: Image.network(
                        asset.url, 
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image, color: Colors.white24, size: 48),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Asset Info', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          const Spacer(),
                          IconButton(icon: const Icon(Icons.close, color: Colors.white38), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _infoRow('Name', asset.fileName),
                      _infoRow('Type', asset.fileType.toUpperCase()),
                      _infoRow('Size', '${(asset.fileSizeBytes / 1024).toStringAsFixed(2)} KB'),
                      _infoRow('Category', asset.category?.toUpperCase() ?? 'GENERAL'),
                      _infoRow('Alt Text', asset.altText ?? 'None provided'),
                      const Spacer(),
                      _sectionLabel('Public URL'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Expanded(child: Text(asset.url, style: GoogleFonts.robotoMono(color: Colors.blue.shade300, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16, color: Colors.blue),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: asset.url));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL copied!')));
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmDelete(asset),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove Asset'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(label),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(label, style: GoogleFonts.inter(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5));

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.image_search_outlined, size: 80, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 24),
          Text('No assets found', style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Upload your platform images or documents to populate the library', style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    final urlCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final altCtrl = TextEditingController();
    String category = 'general';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 500,
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Text('Upload Asset', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white38), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      _buildTextField('Asset URL', urlCtrl, 'Direct link to the media file'),
                      const SizedBox(height: 20),
                      _buildTextField('Internal Name', nameCtrl, 'e.g. app_hero_banner'),
                      const SizedBox(height: 20),
                      _buildTextField('Alt Text', altCtrl, 'Accessibility description'),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('Category'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: category,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                            items: ['general', 'banners', 'blogs', 'products', 'branding'].map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                            onChanged: (v) => setModalState(() => category = v!),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await ref.read(mediaRepositoryProvider).createMediaAsset(
                            fileName: nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Asset_${DateTime.now().millisecondsSinceEpoch}',
                            fileType: 'image/jpeg',
                            fileSizeBytes: 0,
                            url: urlCtrl.text,
                            altText: altCtrl.text,
                            category: category,
                          );
                          ref.invalidate(mediaListProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                        child: const Text('Add to Library'),
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

  Widget _buildTextField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
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

  void _confirmDelete(MediaAsset asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Asset?', style: TextStyle(color: Colors.white)),
        content: const Text('This will remove the link to this asset. The file itself may remain on the storage provider.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(mediaListProvider.notifier).deleteAsset(asset.id);
              Navigator.pop(ctx);
              Navigator.pop(context); // Close the details view too
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
