import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/repositories/cms_repository.dart';

class FaqManagementView extends StatefulWidget {
  const FaqManagementView({super.key});
  @override State<FaqManagementView> createState() => _FaqManagementViewState();
}

class _FaqManagementViewState extends State<FaqManagementView> {
  final CmsRepository _repo = CmsRepository();
  List<Map<String, dynamic>> _faqs = [];
  bool _isLoading = true;
  String? _filterCategory;

  @override void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try { _faqs = await _repo.getFaqs(category: _filterCategory); setState(() => _isLoading = false); }
    catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('FAQ Management', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Manage frequently asked questions', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
        ])),
        ElevatedButton.icon(onPressed: _showCreateDialog, icon: const Icon(Icons.add, size: 18), label: const Text('Add FAQ'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      ]),
      const SizedBox(height: 16),
      Row(children: ['All', 'general', 'payment', 'rental'].map((cat) {
        final selected = cat == 'All' ? _filterCategory == null : _filterCategory == cat;
        return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
          onTap: () { setState(() => _filterCategory = cat == 'All' ? null : cat); _loadData(); },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: selected ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? const Color(0xFF3B82F6).withValues(alpha: 0.4) : Colors.transparent)),
            child: Text(cat == 'All' ? 'All' : cat.toUpperCase(), style: GoogleFonts.inter(color: selected ? const Color(0xFF3B82F6) : Colors.white54, fontSize: 12)))));
      }).toList()),
      const SizedBox(height: 16),
      _isLoading ? const Center(child: CircularProgressIndicator())
          : Column(children: _faqs.asMap().entries.map((e) => _buildFaqCard(e.key, e.value)).toList()),
    ]));
  }

  Widget _buildFaqCard(int index, Map<String, dynamic> faq) {
    final helpful = (faq['helpful_count'] as num?)?.toInt() ?? 0;
    final notHelpful = (faq['not_helpful_count'] as num?)?.toInt() ?? 0;
    final isActive = faq['is_active'] == true;
    return Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(
      color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        shape: const RoundedRectangleBorder(),
        leading: CircleAvatar(radius: 14, backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: Text('${index + 1}', style: GoogleFonts.inter(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold))),
        title: Text(faq['question']?.toString() ?? '', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
            child: Text(faq['category']?.toString().toUpperCase() ?? '', style: GoogleFonts.inter(color: Colors.white38, fontSize: 9))),
          const SizedBox(width: 8),
          Icon(isActive ? Icons.check_circle : Icons.cancel, size: 12, color: isActive ? Colors.green : Colors.red),
          const SizedBox(width: 4),
          Text(isActive ? 'Active' : 'Inactive', style: GoogleFonts.inter(color: isActive ? Colors.green : Colors.red, fontSize: 10)),
        ]),
        iconColor: Colors.white38, collapsedIconColor: Colors.white38,
        children: [
          Text(faq['answer']?.toString() ?? '', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.6)),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.thumb_up, size: 14, color: Colors.green.withValues(alpha: 0.6)), const SizedBox(width: 4),
            Text('$helpful', style: GoogleFonts.inter(color: Colors.green.withValues(alpha: 0.6), fontSize: 12)),
            const SizedBox(width: 12),
            Icon(Icons.thumb_down, size: 14, color: Colors.red.withValues(alpha: 0.6)), const SizedBox(width: 4),
            Text('$notHelpful', style: GoogleFonts.inter(color: Colors.red.withValues(alpha: 0.6), fontSize: 12)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue), onPressed: () => _showEditDialog(faq)),
            IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () async {
              await _repo.deleteFaq(faq['id']); _loadData();
            }),
          ]),
        ],
      ));
  }

  void _showEditDialog(Map<String, dynamic> faq) {
    final qCtrl = TextEditingController(text: faq['question']?.toString());
    final aCtrl = TextEditingController(text: faq['answer']?.toString());
    String category = faq['category']?.toString() ?? 'general';
    bool isActive = faq['is_active'] == true;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Edit FAQ Entry', style: GoogleFonts.outfit(color: Colors.white)),
        content: SizedBox(width: 500, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: qCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Question', labelStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
          const SizedBox(height: 10),
          TextField(controller: aCtrl, style: const TextStyle(color: Colors.white), maxLines: 4, decoration: InputDecoration(labelText: 'Answer (HTML supported)', labelStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: category, dropdownColor: const Color(0xFF1E293B), style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: 'Category', labelStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
              items: ['general', 'payment', 'rental', 'technical'].map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
              onChanged: (v) { if (v != null) setModalState(() => category = v); }
            )),
            const SizedBox(width: 16),
            Expanded(child: Container(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)), child: SwitchListTile(
              title: Text(isActive ? 'Active' : 'Hidden', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
              value: isActive, activeColor: Colors.green, inactiveTrackColor: Colors.white12,
              onChanged: (v) => setModalState(() => isActive = v),
            ))),
          ]),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            await _repo.updateFaq(faq['id'], {'question': qCtrl.text, 'answer': aCtrl.text, 'category': category, 'is_active': isActive});
            if (ctx.mounted) Navigator.pop(ctx); _loadData();
          }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)), child: const Text('Save Changes')),
        ])));
  }

  void _showCreateDialog() {
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    String category = 'general';
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text('New FAQ', style: GoogleFonts.outfit(color: Colors.white)),
      content: SizedBox(width: 450, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: qCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Question', labelStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
        const SizedBox(height: 10),
        TextField(controller: aCtrl, style: const TextStyle(color: Colors.white), maxLines: 3, decoration: InputDecoration(labelText: 'Answer', labelStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          await _repo.createFaq({'question': qCtrl.text, 'answer': aCtrl.text, 'category': category, 'is_active': true});
          if (ctx.mounted) Navigator.pop(ctx); _loadData();
        }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)), child: const Text('Create')),
      ]));
  }
}
