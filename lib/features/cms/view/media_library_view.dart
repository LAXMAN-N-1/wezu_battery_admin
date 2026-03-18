import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/models/media_asset.dart';
import '../data/repositories/media_repository.dart';

class MediaLibraryView extends StatefulWidget {
  const MediaLibraryView({super.key});

  @override
  State<MediaLibraryView> createState() => _MediaLibraryViewState();
}

class _MediaLibraryViewState extends State<MediaLibraryView> {
  final MediaRepository _repository = MediaRepository();
  List<MediaAsset> _assets = [];
  bool _isLoading = true;
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final assets = await _repository.getMediaAssets(category: _filterCategory);
      setState(() {
        _assets = assets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading media: $e')),
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
          Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Media Library',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Trigger file picker
                },
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Upload Assets'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Filters
          Row(
            children: [
              _buildCategoryChip(null, 'All Assets'),
              const SizedBox(width: 12),
              _buildCategoryChip('blog', 'Blog Images'),
              const SizedBox(width: 12),
              _buildCategoryChip('banner', 'App Banners'),
              const SizedBox(width: 12),
              _buildCategoryChip('kyc', 'KYC Documents'),
            ],
          ),
          const SizedBox(height: 32),

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _assets.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: _assets.length,
                      itemBuilder: (context, index) {
                        return _buildAssetTile(_assets[index]);
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? category, String label) {
    bool isSelected = _filterCategory == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterCategory = category;
          _loadData();
        });
      },
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      selectedColor: Colors.blue.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildAssetTile(MediaAsset asset) {
    return Tooltip(
      message: asset.fileName,
      child: InkWell(
        onTap: () => _showAssetDetails(asset),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (asset.isImage)
                Image.network(asset.url, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white24))
              else if (asset.isPdf)
                const Center(child: Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 32))
              else
                const Center(child: Icon(Icons.insert_drive_file_outlined, color: Colors.white24, size: 32)),
              
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssetDetails(MediaAsset asset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(asset.fileName, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (asset.isImage)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(image: NetworkImage(asset.url), fit: BoxFit.contain),
                ),
              ),
            const SizedBox(height: 16),
            _buildDetailRow('URL', asset.url),
            _buildDetailRow('Type', asset.fileType),
            _buildDetailRow('Category', asset.category),
            _buildDetailRow('Uploaded', DateFormat('MMM d, y').format(asset.createdAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy URL to clipboard logic
              Navigator.pop(context);
            },
            child: const Text('Copy URL'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.perm_media_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          Text(
            'Library is empty',
            style: GoogleFonts.outfit(fontSize: 20, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload images for your blogs and banners here.',
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
