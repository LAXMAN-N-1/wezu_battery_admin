import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../../core/widgets/admin_ui_components.dart';
import '../../../core/widgets/glass_components.dart';
import '../data/models/media_asset.dart';
import '../provider/cms_providers.dart';

class MediaLibraryView extends ConsumerStatefulWidget {
  const MediaLibraryView({super.key});

  @override
  ConsumerState<MediaLibraryView> createState() => _MediaLibraryViewState();
}

class _MediaLibraryViewState extends ConsumerState<MediaLibraryView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedIds = {};
  MediaAsset? _selectedAsset;
  String _currentFolder = 'All Files';
  final List<String> _folders = ['All Files', 'Blog Images', 'Banner Assets', 'Legal Documents', 'Videos'];
  String _sortOrder = 'Newest First';
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      scaffoldKey: _scaffoldKey,
      endDrawer: _selectedAsset != null ? _MediaDetailsDrawer(asset: _selectedAsset!) : null,
      child: Row(
        children: [
          _buildFolderSidebar(),
          const VerticalDivider(width: 1, color: Colors.white10),
          Expanded(child: _buildExplorerArea()),
        ],
      ),
    );
  }

  Widget _buildFolderSidebar() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Explorer', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          ..._folders.map((folder) => _buildSidebarItem(
            _getFolderIcon(folder),
            folder,
            _currentFolder == folder,
          )),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _showNewFolderDialog,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('New Folder'),
            style: TextButton.styleFrom(foregroundColor: Colors.white38),
          ),
          const Spacer(),
          _buildStorageUsage(),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _currentFolder = label),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isSelected ? const Color(0xFF3B82F6) : Colors.white54),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStorageUsage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Storage Usage', style: TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: 0.23, backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)), minHeight: 6),
        ),
        const SizedBox(height: 8),
        const Text('2.3 GB used of 10 GB', style: TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildExplorerArea() {
    final mediaAsync = ref.watch(mediaProvider);

    return Column(
      children: [
        _buildExplorerHeader(),
        _buildToolbar(),
        Expanded(
          child: Stack(
            children: [
              mediaAsync.when(
                data: (assets) => _isGridView ? _buildGrid(assets) : _buildList(assets),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
              if (_selectedIds.isNotEmpty) _buildBulkActionBar(),
              _buildUploadWidget(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExplorerHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_currentFolder, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('Manage and organize assets in this folder', style: TextStyle(color: Colors.white38, fontSize: 13)),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _pickAndUploadFiles,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.cloud_upload_outlined, size: 18),
            label: const Text('UPLOAD FILES'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Row(
        children: [
          Expanded(child: TextField(controller: _searchController, decoration: InputDecoration(prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white24), hintText: 'Search files...', hintStyle: const TextStyle(color: Colors.white24), border: InputBorder.none))),
          DropdownButton<String>(value: 'All Types', style: const TextStyle(color: Colors.white70), dropdownColor: const Color(0xFF1E293B), items: ['All Types', 'Images', 'Videos', 'PDFs'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {}),
          const SizedBox(width: 16),
          IconButton(icon: Icon(Icons.grid_view, color: _isGridView ? const Color(0xFF3B82F6) : Colors.white24), onPressed: () => setState(() => _isGridView = true)),
          IconButton(icon: Icon(Icons.list, color: !_isGridView ? const Color(0xFF3B82F6) : Colors.white24), onPressed: () => setState(() => _isGridView = false)),
        ],
      ),
    );
  }

  Widget _buildGrid(List<MediaAsset> assets) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.85, crossAxisSpacing: 20, mainAxisSpacing: 20),
      itemCount: assets.length,
      itemBuilder: (context, index) => _AssetCard(
        asset: assets[index],
        isSelected: _selectedIds.contains(assets[index].id),
        onToggle: () => setState(() => _selectedIds.contains(assets[index].id) ? _selectedIds.remove(assets[index].id) : _selectedIds.add(assets[index].id)),
        onTap: () => _showDetailsDrawer(assets[index]),
      ),
    );
  }

  Widget _buildList(List<MediaAsset> assets) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: assets.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
      itemBuilder: (context, index) => ListTile(
        title: Text(assets[index].fileName),
        subtitle: Text(assets[index].fileType),
        leading: const Icon(Icons.insert_drive_file),
      ),
    );
  }

  Widget _buildBulkActionBar() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20, offset: const Offset(0, 8))]),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_selectedIds.length} files selected', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 24),
              _barAction(Icons.folder_shared, 'Move'),
              _barAction(Icons.download, 'Download'),
              _barAction(Icons.delete, 'Delete', isRed: true),
              IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => setState(() => _selectedIds.clear())),
            ],
          ),
        ).animate().slideY(begin: 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  Widget _barAction(IconData icon, String label, {bool isRed = false}) {
    return TextButton.icon(onPressed: () {}, icon: Icon(icon, size: 16, color: Colors.white), label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)));
  }

  Widget _buildUploadWidget() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Container(
        width: 320,
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10), boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 30)]),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
              child: const Row(
                children: [
                  Text('Uploading 3 files...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Spacer(),
                  Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _UploadProgressRow(name: 'hero_banner_solar.jpg', progress: 0.8),
                  SizedBox(height: 12),
                  _UploadProgressRow(name: 'terms_v3.pdf', progress: 0.45),
                ],
              ),
            ),
          ],
        ),
      ).animate().slideX(begin: 1.0),
    );
  }

  void _showDetailsDrawer(MediaAsset asset) {
    setState(() => _selectedAsset = asset);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<void> _pickAndUploadFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.bytes != null) {
            await ref.read(mediaProvider.notifier).uploadFile(
              bytes: file.bytes!,
              fileName: file.name,
              category: _currentFolder == 'All Files' ? 'general' : _currentFolder.toLowerCase().replaceAll(' ', '_'),
            );
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Files uploaded successfully'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  IconData _getFolderIcon(String name) {
    switch (name) {
      case 'All Files': return Icons.folder_open;
      case 'Blog Images': return Icons.image;
      case 'Banner Assets': return Icons.campaign;
      case 'Legal Documents': return Icons.description;
      case 'Videos': return Icons.movie;
      default: return Icons.folder;
    }
  }

  void _showNewFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Create New Folder', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Folder Name',
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3B82F6))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _folders.add(controller.text);
                  _currentFolder = controller.text;
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }
}

class _AssetCard extends StatefulWidget {
  final MediaAsset asset;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _AssetCard({required this.asset, required this.isSelected, required this.onToggle, required this.onTap});

  @override
  State<_AssetCard> createState() => _AssetCardState();
}

class _AssetCardState extends State<_AssetCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: GlassContainer(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.asset.isImage)
                      Image.network(widget.asset.url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 32, color: Colors.white10))
                    else
                      const Center(child: Icon(Icons.insert_drive_file, size: 40, color: Colors.white24)),
                    if (_isHovered) Container(color: Colors.black45),
                    if (_isHovered || widget.isSelected) Positioned(top: 8, left: 8, child: Checkbox(value: widget.isSelected, onChanged: (_) => widget.onToggle(), fillColor: MaterialStateProperty.all(const Color(0xFF3B82F6)))),
                    if (_isHovered) Positioned(bottom: 8, right: 8, child: Row(children: [IconButton(icon: const Icon(Icons.link, size: 16, color: Colors.white), onPressed: () {}), IconButton(icon: const Icon(Icons.folder_shared, size: 16, color: Colors.white), onPressed: () {})])),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.asset.fileName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${(widget.asset.fileSizeBytes / 1024).toStringAsFixed(1)} KB • ${DateFormat('dd MMM').format(widget.asset.createdAt)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate(target: _isHovered ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 200.ms),
    );
  }
}

class _UploadProgressRow extends StatelessWidget {
  final String name;
  final double progress;
  const _UploadProgressRow({required this.name, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1),
        const SizedBox(height: 4),
        ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: Colors.white.withOpacity(0.05), valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)))),
      ],
    );
  }
}

class _MediaDetailsDrawer extends StatelessWidget {
  final MediaAsset asset;
  const _MediaDetailsDrawer({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 400,
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('File Details', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 32),
              Container(height: 200, width: double.infinity, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)), child: asset.isImage ? Image.network(asset.url, fit: BoxFit.contain) : const Icon(Icons.insert_drive_file, size: 64, color: Colors.white10)),
              const SizedBox(height: 32),
              _infoRow('Filename', asset.fileName),
              _infoRow('Size', '${(asset.fileSizeBytes / 1024).toStringAsFixed(2)} KB'),
              _infoRow('Type', asset.fileType),
              _infoRow('Dimensions', asset.dimensions ?? 'N/A'),
              _infoRow('Uploaded', DateFormat('dd MMM yyyy, hh:mm a').format(asset.createdAt)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.link, size: 18),
                label: const Text('COPY PUBLIC URL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download, size: 18), label: const Text('DOWNLOAD'), style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52), foregroundColor: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))]),
    );
  }
}
