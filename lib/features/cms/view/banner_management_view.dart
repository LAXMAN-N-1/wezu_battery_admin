import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/repositories/cms_repository.dart';

class BannerManagementView extends StatefulWidget {
  const BannerManagementView({super.key});
  @override State<BannerManagementView> createState() => _BannerManagementViewState();
}

class _BannerManagementViewState extends State<BannerManagementView> {
  final CmsRepository _repo = CmsRepository();
  List<Map<String, dynamic>> _banners = [];
  bool _isLoading = true;

  @override void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try { _banners = await _repo.getBanners(); if (mounted) setState(() => _isLoading = false); }
    catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Banner Management', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Manage promotional banners for the customer app', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
        ])),
        ElevatedButton.icon(onPressed: _showCreateDialog, icon: const Icon(Icons.add, size: 18), label: const Text('New Banner'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      ]),
      const SizedBox(height: 24),
      _isLoading ? const Center(child: CircularProgressIndicator())
          : Column(children: _banners.map(_buildBannerCard).toList()),
    ]));
  }

  Widget _buildBannerCard(Map<String, dynamic> banner) {
    final isActive = banner['is_active'] == true;
    final clicks = (banner['click_count'] as num?)?.toInt() ?? 0;
    final priority = (banner['priority'] as num?)?.toInt() ?? 0;
    return Container(margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(
      color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: isActive ? Colors.green.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Banner image
        ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Container(width: double.infinity, height: 120, color: Colors.white.withValues(alpha: 0.03),
            child: banner['image_url'] != null
              ? Image.network(banner['image_url'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Icon(Icons.photo, color: Colors.white.withValues(alpha: 0.1), size: 40)))
              : Center(child: Icon(Icons.photo, color: Colors.white.withValues(alpha: 0.1), size: 40)))),
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(banner['title']?.toString() ?? '', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(isActive ? 'ACTIVE' : 'INACTIVE', style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _infoPill(Icons.star, 'Priority: $priority'),
            const SizedBox(width: 12),
            _infoPill(Icons.touch_app, '$clicks clicks'),
            if (banner['deep_link'] != null) ...[
              const SizedBox(width: 12),
              _infoPill(Icons.link, banner['deep_link']),
            ],
            const Spacer(),
            Switch(value: isActive, activeThumbColor: Colors.green, onChanged: (val) async {
              await _repo.updateBanner(banner['id'], {'is_active': val}); _loadData();
            }),
            IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18), onPressed: () => _showEditDialog(banner)),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), onPressed: () async {
              await _repo.deleteBanner(banner['id']); _loadData();
            }),
          ]),
        ])),
      ]));
  }

  void _showEditDialog(Map<String, dynamic> banner) {
    final titleCtrl = TextEditingController(text: banner['title']?.toString());
    final imageCtrl = TextEditingController(text: banner['image_url']?.toString());
    final linkCtrl = TextEditingController(text: banner['deep_link']?.toString());
    final priorityCtrl = TextEditingController(text: banner['priority']?.toString() ?? '1');
    bool isActive = banner['is_active'] == true;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Edit Banner', style: GoogleFonts.outfit(color: Colors.white)),
        content: SizedBox(width: 450, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDeco('Title CTA')),
          const SizedBox(height: 10),
          TextField(controller: imageCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDeco('Preview Image URL'),
            onChanged: (v) => setModalState(() {})),
          if (imageCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(height: 100, width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
              child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageCtrl.text, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.white38)))),
          ],
          const SizedBox(height: 10),
          TextField(controller: linkCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDeco('Internal Deep Link (e.g. /profile)')),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextField(controller: priorityCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDeco('Priority (higher = first)'))),
            const SizedBox(width: 16),
            Expanded(child: Container(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)), child: SwitchListTile(
              title: Text(isActive ? 'Active' : 'Hidden', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
              value: isActive, activeThumbColor: Colors.green, inactiveTrackColor: Colors.white12,
              onChanged: (v) => setModalState(() => isActive = v),
            ))),
          ])
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            await _repo.updateBanner(banner['id'], {
              'title': titleCtrl.text, 'image_url': imageCtrl.text, 'deep_link': linkCtrl.text,
              'priority': int.tryParse(priorityCtrl.text) ?? 1, 'is_active': isActive
            });
            if (ctx.mounted) Navigator.pop(ctx); _loadData();
          }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)), child: const Text('Save Changes')),
        ])));
  }

  Widget _infoPill(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: Colors.white38), const SizedBox(width: 4),
      Text(text, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis),
    ]);
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text('New Banner', style: GoogleFonts.outfit(color: Colors.white)),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDeco('Title')),
        const SizedBox(height: 10),
        TextField(controller: imageCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDeco('Image URL')),
        const SizedBox(height: 10),
        TextField(controller: linkCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDeco('Deep Link')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          await _repo.createBanner({'title': titleCtrl.text, 'image_url': imageCtrl.text, 'deep_link': linkCtrl.text, 'priority': 1, 'is_active': true});
          if (ctx.mounted) Navigator.pop(ctx); _loadData();
        }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)), child: const Text('Create')),
      ]));
  }

  InputDecoration _inputDeco(String label) => InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white38),
    filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none));
}
