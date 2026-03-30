import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/repositories/cms_repository.dart';

class LegalDocsView extends StatefulWidget {
  const LegalDocsView({super.key});
  @override State<LegalDocsView> createState() => _LegalDocsViewState();
}

class _LegalDocsViewState extends State<LegalDocsView> {
  final CmsRepository _repo = CmsRepository();
  List<Map<String, dynamic>> _docs = [];
  bool _isLoading = true;

  @override void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try { _docs = await _repo.getLegalDocs(); if (mounted) setState(() => _isLoading = false); }
    catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Legal Documents', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Terms, privacy policies, and legal agreements', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
        ])),
        ElevatedButton.icon(onPressed: _showCreateDialog, icon: const Icon(Icons.add, size: 18), label: const Text('New Document'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      ]),
      const SizedBox(height: 24),
      _isLoading ? const Center(child: CircularProgressIndicator())
          : Column(children: _docs.map(_buildDocCard).toList()),
    ]));
  }

  Widget _buildDocCard(Map<String, dynamic> doc) {
    final isActive = doc['is_active'] == true;
    final forceUpdate = doc['force_update'] == true;
    return Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? Colors.blue.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.description, color: Colors.blue, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doc['title']?.toString() ?? '', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
                child: Text('v${doc['version'] ?? '1.0'}', style: GoogleFonts.robotoMono(color: Colors.white54, fontSize: 11))),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
                child: Text(doc['slug']?.toString() ?? '', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10))),
            ]),
          ])),
          Column(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(isActive ? 'PUBLISHED' : 'DRAFT', style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold))),
            if (forceUpdate) ...[
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.warning_amber, size: 12, color: Colors.orange), const SizedBox(width: 4),
                  Text('FORCE UPDATE', style: GoogleFonts.inter(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)),
                ])),
            ],
          ]),
        ]),
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.all(12), width: double.infinity,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(8)),
          child: Text(
            (doc['content']?.toString() ?? '').replaceAll(RegExp(r'<[^>]*>'), ''),
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis)),
        const SizedBox(height: 12),
        Row(children: [
          if (doc['published_at'] != null) ...[
            Icon(Icons.calendar_today, size: 12, color: Colors.white38), const SizedBox(width: 4),
            Text('Published: ${_formatDate(doc['published_at'])}', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
          ],
          const Spacer(),
          IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18), onPressed: () => _showEditDialog(doc)),
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), onPressed: () async {
            await _repo.deleteLegalDoc(doc['id']); _loadData();
          }),
        ]),
      ]));
  }

  void _showEditDialog(Map<String, dynamic> doc) {
    final titleCtrl = TextEditingController(text: doc['title']?.toString());
    final slugCtrl = TextEditingController(text: doc['slug']?.toString());
    final versionCtrl = TextEditingController(text: doc['version']?.toString());
    final contentCtrl = TextEditingController(text: doc['content']?.toString());
    bool isActive = doc['is_active'] == true;
    bool forceUpdate = doc['force_update'] == true;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Edit Legal Document', style: GoogleFonts.outfit(color: Colors.white)),
        content: SizedBox(width: 650, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(flex: 2, child: _field(titleCtrl, 'Document Title')), const SizedBox(width: 10),
            Expanded(flex: 1, child: _field(slugCtrl, 'Slug')),
          ]),
          const SizedBox(height: 10),
          _field(contentCtrl, 'Content (HTML/Markdown supported)', maxLines: 12),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _field(versionCtrl, 'Version (e.g. 1.2)')),
            const SizedBox(width: 10),
            Expanded(child: Container(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)), child: SwitchListTile(
              title: Text('Published', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
              value: isActive, activeColor: Colors.green, inactiveTrackColor: Colors.white12,
              onChanged: (v) => setModalState(() => isActive = v),
            ))),
            const SizedBox(width: 10),
            Expanded(child: Container(decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)), child: SwitchListTile(
              title: Text('Force App Update', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
              value: forceUpdate, activeColor: Colors.red, inactiveTrackColor: Colors.white12,
              onChanged: (v) => setModalState(() => forceUpdate = v),
            ))),
          ])
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            await _repo.updateLegalDoc(doc['id'], {
              'title': titleCtrl.text, 'slug': slugCtrl.text, 'version': versionCtrl.text,
              'content': contentCtrl.text, 'is_active': isActive, 'force_update': forceUpdate
            });
            if (ctx.mounted) Navigator.pop(ctx); _loadData();
          }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)), child: const Text('Save Document')),
        ])));
  }


  String _formatDate(String ts) {
    try { final dt = DateTime.parse(ts); return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}'; } catch (_) { return ts; }
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final versionCtrl = TextEditingController(text: '1.0.0');
    final contentCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text('New Legal Document', style: GoogleFonts.outfit(color: Colors.white)),
      content: SizedBox(width: 500, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _field(titleCtrl, 'Title'), const SizedBox(height: 10),
        _field(slugCtrl, 'Slug'), const SizedBox(height: 10),
        _field(versionCtrl, 'Version'), const SizedBox(height: 10),
        _field(contentCtrl, 'Content (HTML)', maxLines: 4),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          await _repo.createLegalDoc({'title': titleCtrl.text, 'slug': slugCtrl.text, 'version': versionCtrl.text, 'content': contentCtrl.text, 'is_active': true});
          if (ctx.mounted) Navigator.pop(ctx); _loadData();
        }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)), child: const Text('Create')),
      ]));
  }

  Widget _field(TextEditingController ctrl, String label, {int maxLines = 1}) {
    return TextField(controller: ctrl, style: const TextStyle(color: Colors.white), maxLines: maxLines,
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white38),
        filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)));
  }
}
