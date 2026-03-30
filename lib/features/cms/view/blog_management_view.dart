import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/repositories/cms_repository.dart';

class BlogManagementView extends StatefulWidget {
  const BlogManagementView({super.key});
  @override State<BlogManagementView> createState() => _BlogManagementViewState();
}

class _BlogManagementViewState extends State<BlogManagementView> {
  final CmsRepository _repo = CmsRepository();
  List<Map<String, dynamic>> _blogs = [];
  bool _isLoading = true;
  String? _filterStatus;

  @override void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try { _blogs = await _repo.getBlogs(status: _filterStatus); setState(() => _isLoading = false); }
    catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Blog Management', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Create, edit and publish blog articles', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
        ])),
        ElevatedButton.icon(onPressed: _showCreateDialog, icon: const Icon(Icons.add, size: 18), label: const Text('New Post'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      ]),
      const SizedBox(height: 16),
      // Status filters
      Row(children: [
        _filterChip('All', _filterStatus == null, () { setState(() => _filterStatus = null); _loadData(); }),
        const SizedBox(width: 8),
        _filterChip('Published', _filterStatus == 'published', () { setState(() => _filterStatus = 'published'); _loadData(); }),
        const SizedBox(width: 8),
        _filterChip('Draft', _filterStatus == 'draft', () { setState(() => _filterStatus = 'draft'); _loadData(); }),
        const SizedBox(width: 8),
        _filterChip('Scheduled', _filterStatus == 'scheduled', () { setState(() => _filterStatus = 'scheduled'); _loadData(); }),
      ]),
      const SizedBox(height: 16),
      _isLoading ? const Center(child: CircularProgressIndicator())
          : Column(children: _blogs.map(_buildBlogCard).toList()),
    ]));
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: selected ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? const Color(0xFF3B82F6).withValues(alpha: 0.4) : Colors.transparent)),
      child: Text(label, style: GoogleFonts.inter(color: selected ? const Color(0xFF3B82F6) : Colors.white54, fontSize: 13))));
  }

  Widget _buildBlogCard(Map<String, dynamic> blog) {
    final status = blog['status']?.toString() ?? 'draft';
    final statusColor = status == 'published' ? Colors.green : status == 'draft' ? Colors.grey : Colors.amber;
    final views = (blog['views_count'] as num?)?.toInt() ?? 0;
    return Container(margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: InkWell(
        onTap: () => _showEditDialog(blog),
        borderRadius: BorderRadius.circular(16),
        child: Container(padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Thumbnail
        ClipRRect(borderRadius: BorderRadius.circular(10),
          child: Container(width: 100, height: 70, color: Colors.white.withValues(alpha: 0.05),
            child: blog['featured_image_url'] != null
              ? Image.network(blog['featured_image_url'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.white24))
              : const Icon(Icons.article, color: Colors.white24, size: 30))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(blog['title']?.toString() ?? '', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 4),
          Text(blog['summary']?.toString() ?? '', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.category, size: 13, color: Colors.white38), const SizedBox(width: 4),
            Text(blog['category']?.toString() ?? 'general', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
            const SizedBox(width: 16),
            Icon(Icons.visibility, size: 13, color: Colors.white38), const SizedBox(width: 4),
            Text('$views views', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), iconSize: 18,
              onPressed: () async { await _repo.deleteBlog(blog['id']); _loadData(); }),
          ]),
        ])),
      ]),
    )));
  }

  void _showEditDialog(Map<String, dynamic> blog) {
    final titleCtrl = TextEditingController(text: blog['title']?.toString());
    final slugCtrl = TextEditingController(text: blog['slug']?.toString());
    final summaryCtrl = TextEditingController(text: blog['summary']?.toString());
    final contentCtrl = TextEditingController(text: blog['content']?.toString());
    String status = blog['status']?.toString() ?? 'draft';
    String category = blog['category']?.toString() ?? 'general';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => Dialog(
        backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.all(40),
        child: Container(width: 800, height: 750, decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(24), child: Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.edit_document, color: Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Edit Blog Post', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Update details, rich text content, and publish status', style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
              ])),
              IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
            ])),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(32), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: _field(titleCtrl, 'Headline Title')), const SizedBox(width: 16),
                Expanded(child: _field(slugCtrl, 'URL Slug (e.g. new-update-2026)')),
              ]),
              const SizedBox(height: 20),
              _field(summaryCtrl, 'Short Excerpt Summary', maxLines: 2),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Publish Status', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)), const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: status, dropdownColor: const Color(0xFF1E293B), style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                    items: ['draft', 'published', 'scheduled'].map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                    onChanged: (v) { if (v != null) setModalState(() => status = v); }
                  ),
                ])),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Content Category', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)), const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: category, dropdownColor: const Color(0xFF1E293B), style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                    items: ['general', 'news', 'educational', 'update'].map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                    onChanged: (v) { if (v != null) setModalState(() => category = v); }
                  ),
                ])),
              ]),
              const SizedBox(height: 24),
              Text('HTML Body Content', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
              _field(contentCtrl, 'Write your comprehensive article here...', maxLines: 12),
            ]))),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            Padding(padding: const EdgeInsets.all(24), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_forever, size: 18), label: const Text('Delete Post'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                onPressed: () async { await _repo.deleteBlog(blog['id']); if (ctx.mounted) Navigator.pop(ctx); _loadData(); },
              ),
              Row(children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Discard')), const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save, size: 18), label: const Text('Save & Publish'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                  onPressed: () async {
                    await _repo.updateBlog(blog['id'], {
                      'title': titleCtrl.text, 'slug': slugCtrl.text, 'summary': summaryCtrl.text,
                      'content': contentCtrl.text, 'status': status, 'category': category,
                    });
                    if (ctx.mounted) Navigator.pop(ctx); _loadData();
                  },
                ),
              ]),
            ])),
          ]),
        ),
      )
    ));
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final summaryCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text('New Blog Post', style: GoogleFonts.outfit(color: Colors.white)),
      content: SizedBox(width: 450, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _field(titleCtrl, 'Title'), const SizedBox(height: 10),
        _field(slugCtrl, 'Slug'), const SizedBox(height: 10),
        _field(summaryCtrl, 'Summary', maxLines: 2),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          await _repo.createBlog({'title': titleCtrl.text, 'slug': slugCtrl.text, 'summary': summaryCtrl.text, 'content': '<p>${summaryCtrl.text}</p>', 'status': 'draft', 'author_id': 1, 'category': 'news'});
          if (ctx.mounted) Navigator.pop(ctx); _loadData();
        }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)), child: const Text('Create')),
      ]));
  }

  Widget _field(TextEditingController ctrl, String label, {int maxLines = 1}) {
    return TextField(controller: ctrl, style: const TextStyle(color: Colors.white), maxLines: maxLines,
      decoration: InputDecoration(labelText: maxLines == 1 ? label : null, hintText: maxLines > 1 ? label : null, labelStyle: const TextStyle(color: Colors.white38), hintStyle: const TextStyle(color: Colors.white38),
        filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)));
  }
}
