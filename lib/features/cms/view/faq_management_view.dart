import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/faq.dart';
import '../data/cms_providers.dart';
import '../../../core/widgets/admin_ui_components.dart';

class FaqManagementView extends ConsumerStatefulWidget {
  const FaqManagementView({super.key});

  @override
  ConsumerState<FaqManagementView> createState() => _FaqManagementViewState();
}

class _FaqManagementViewState extends ConsumerState<FaqManagementView> {
  String _activeCategory = 'All';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faqState = ref.watch(faqListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildFilters(),
          const SizedBox(height: 24),
          faqState.when(
            data: (faqs) {
              final filteredFaqs = _applyFilters(faqs);
              if (filteredFaqs.isEmpty) {
                return _buildEmptyState();
              }
              return Column(
                children: filteredFaqs.asMap().entries.map((e) => _buildFaqCard(e.key, e.value)).toList(),
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
              'FAQ Management',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage help center content and frequently asked questions',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _showEditorDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add FAQ'),
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
    final categories = ['All', 'general', 'payment', 'rental', 'technical', 'account'];
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
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            onChanged: (v) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search questions...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
              prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.2), size: 18),
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
          color: active ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : Colors.transparent),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: active ? Colors.blue.shade300 : Colors.white38,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  List<FAQ> _applyFilters(List<FAQ> faqs) {
    return faqs.where((f) {
      if (_activeCategory != 'All' && f.category.toLowerCase() != _activeCategory.toLowerCase()) return false;
      if (_searchController.text.isNotEmpty && !f.question.toLowerCase().contains(_searchController.text.toLowerCase())) return false;
      return true;
    }).toList();
  }

  Widget _buildFaqCard(int index, FAQ faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141E2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        expandedAlignment: Alignment.topLeft,
        childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        shape: const RoundedRectangleBorder(),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text('${index + 1}', style: GoogleFonts.outfit(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14))),
        ),
        title: Text(faq.question, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _categoryBadge(faq.category),
              StatusBadge(status: faq.isActive ? 'active' : 'inactive'),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.thumb_up_outlined, size: 12, color: Colors.white24),
                  const SizedBox(width: 4),
                  Text('${faq.helpfulCount}', style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        iconColor: Colors.white38,
        collapsedIconColor: Colors.white38,
        children: [
          const Divider(color: Colors.white10, height: 32),
          Text(faq.answer, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.6)),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Was this helpful?', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic)),
              const Spacer(),
              _actionButton(Icons.edit_outlined, 'Edit', Colors.blue, () => _showEditorDialog(faq)),
              const SizedBox(width: 12),
              _actionButton(Icons.delete_outline, 'Delete', Colors.red, () => _confirmDelete(faq)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
      child: Text(category.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: color.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(64.0),
        child: Column(
          children: [
            Icon(Icons.help_outline, size: 64, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text('No FAQs found', style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Add your first FAQ entry to populate the help center', style: TextStyle(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  void _showEditorDialog([FAQ? faq]) {
    final qCtrl = TextEditingController(text: faq?.question);
    final aCtrl = TextEditingController(text: faq?.answer);
    String category = faq?.category ?? 'general';
    bool isActive = faq?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Text(faq == null ? 'Add FAQ Entry' : 'Edit FAQ Entry', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
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
                        _fieldLabel('Question'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: qCtrl,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: _fieldDecoration('Enter the question...'),
                        ),
                        const SizedBox(height: 24),
                        _fieldLabel('Answer'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: aCtrl,
                          maxLines: 6,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: _fieldDecoration('Enter the answer (HTML supported)...'),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel('Category'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: category,
                                    dropdownColor: const Color(0xFF1E293B),
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    decoration: _fieldDecoration(''),
                                    items: ['general', 'payment', 'rental', 'technical', 'account'].map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                                    onChanged: (v) => setModalState(() => category = v!),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel('Status'),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                                    child: SwitchListTile(
                                      title: Text(isActive ? 'Visible' : 'Hidden', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                      value: isActive,
                                      activeThumbColor: Colors.blue,
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
                          final data = FAQ(
                            id: faq?.id ?? 0,
                            question: qCtrl.text,
                            answer: aCtrl.text,
                            category: category,
                            isActive: isActive,
                            helpfulCount: faq?.helpfulCount ?? 0,
                            notHelpfulCount: faq?.notHelpfulCount ?? 0,
                            createdAt: faq?.createdAt ?? DateTime.now(),
                            updatedAt: DateTime.now(),
                          );
                          if (faq == null) {
                            await ref.read(faqRepositoryProvider).createFaq(data);
                          } else {
                            await ref.read(faqRepositoryProvider).updateFaq(faq.id, data);
                          }
                          ref.invalidate(faqListProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                        child: const Text('Save FAQ'),
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

  Widget _fieldLabel(String label) => Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold));

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  void _confirmDelete(FAQ faq) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete FAQ?', style: TextStyle(color: Colors.white)),
        content: const Text('This entry will be permanently removed from the help center.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(faqListProvider.notifier).deleteFaq(faq.id);
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
