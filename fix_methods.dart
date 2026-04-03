import 'dart:io';

void fixFile(String path, String appendContent) {
  var file = File(path);
  var content = file.readAsStringSync();
  int lastBraceIndex = content.lastIndexOf('}');
  if (lastBraceIndex != -1) {
    var newContent =
        '${content.substring(0, lastBraceIndex)}$appendContent\n}\n';
    file.writeAsStringSync(newContent);
    stdout.writeln("Fixed $path");
  } else {
    stderr.writeln("Could not find brace in $path");
  }
}

void main() {
  String mediaMethods = """
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
""";

  String legalMethods = """
  Widget _buildDocCard(LegalDocument doc) {
    return AdvancedCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Version \${doc.version}',
                        style: const TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: doc.isActive ? 'Active' : 'Inactive'),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                if (doc.forceUpdate)
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.redAccent, size: 12),
                        const SizedBox(width: 4),
                        Text('FORCE UPDATE', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('Edit Content'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white38, size: 20),
                  onPressed: () {},
                  tooltip: 'Version History',
                ),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.gavel_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          Text(
            'No legal documents found',
            style: GoogleFonts.outfit(fontSize: 20, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ensure your platform is compliant by adding T&C and Privacy Policy.',
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }
""";

  String bannerMethods = """
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
                        Text('\${banner.clickCount} Clicks', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        const Spacer(),
                        if (banner.startDate != null)
                          Text(
                            'Starts: \${DateFormat('MMM d').format(banner.startDate!)}',
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
              heroTag: 'edit_\${banner.id}',
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
        'P\$priority',
        style: const TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

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
""";

  fixFile('lib/features/cms/view/media_library_view.dart', mediaMethods);
  fixFile('lib/features/cms/view/legal_list_view.dart', legalMethods);
  fixFile('lib/features/cms/view/banner_list_view.dart', bannerMethods);
}
