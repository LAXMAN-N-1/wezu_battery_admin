import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../../../core/widgets/glass_components.dart';
import '../data/models/faq.dart';
import '../provider/cms_providers.dart';
import 'faq_edit_drawer.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FaqManagementView extends ConsumerStatefulWidget {
  const FaqManagementView({super.key});

  @override
  ConsumerState<FaqManagementView> createState() => _FaqManagementViewState();
}

class _FaqManagementViewState extends ConsumerState<FaqManagementView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _filterCategory;
  String _filterAudience = 'All Users';
  final TextEditingController _searchController = TextEditingController();
  List<FAQ> _currentOrder = [];
  bool _showSaveOrder = false;
  int? _expandedFaqId;
  FAQ? _previewFaq;

  @override
  Widget build(BuildContext context) {
    final faqsAsync = ref.watch(faqProvider);

    return GlassScaffold(
      scaffoldKey: _scaffoldKey,
      endDrawer: FAQEditDrawer(
        faq: _previewFaq,
        onSave: () {
          _previewFaq = null;
          ref.read(faqProvider.notifier).refresh();
        },
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'FAQ Management',
              subtitle: 'Create, organize, and publish FAQs across app platforms.',
              actionButton: ElevatedButton.icon(
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('ADD FAQ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildCategoryTabs(faqsAsync.value ?? [])),
                const SizedBox(width: 16),
                _buildAudienceFilter(),
              ],
            ),
            const SizedBox(height: 24),

            AdminTextField(
              controller: _searchController,
              label: '',
              hint: 'Search FAQs by question or keyword...',
              icon: Icons.search,
              onChanged: (v) => ref.read(faqProvider.notifier).setSearch(v),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: faqsAsync.when(
                data: (faqs) => _buildFaqList(faqs),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(List<FAQ> allFaqs) {
    final categories = ['All', 'Getting Started', 'Billing', 'Technical Support', 'Solar Panels', 'Payments', 'Others'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isAll = cat == 'All';
          final filterVal = isAll ? null : cat.toLowerCase();
          final isSelected = _filterCategory == filterVal;
          final count = isAll ? allFaqs.length : allFaqs.where((f) => f.category.toLowerCase() == filterVal).length;

          return GestureDetector(
            onTap: () => setState(() => _filterCategory = filterVal),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.3) : Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF3B82F6) : Colors.white60,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF3B82F6) : Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAudienceFilter() {
    final options = ['All Users', 'Customer App', 'Dealer App', 'Fleet Managers'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterAudience,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(color: Colors.white, fontSize: 13)))).toList(),
          onChanged: (v) => setState(() => _filterAudience = v!),
        ),
      ),
    );
  }

  Widget _buildFaqList(List<FAQ> faqs) {
    if (faqs.isEmpty) return _buildEmptyState();
    
    final filtered = faqs.where((f) {
      final matchesCat = _filterCategory == null || f.category.toLowerCase() == _filterCategory;
      final matchesAudience = _filterAudience == 'All Users' || f.targetAudience.contains(_filterAudience);
      return matchesCat && matchesAudience;
    }).toList();

    return Stack(
      children: [
        ReorderableListView.builder(
          itemCount: filtered.length,
          padding: const EdgeInsets.only(bottom: 100),
          onReorder: (oldIdx, newIdx) {
            setState(() {
              if (newIdx > oldIdx) newIdx -= 1;
              final item = filtered.removeAt(oldIdx);
              filtered.insert(newIdx, item);
              _showSaveOrder = true;
              _currentOrder = filtered;
            });
          },
          proxyDecorator: (child, index, animation) => Material(
            color: Colors.transparent,
            child: child,
          ),
          itemBuilder: (context, index) {
            final faq = filtered[index];
            return FAQCard(
              key: ValueKey(faq.id),
              faq: faq,
              isExpanded: _expandedFaqId == faq.id,
              onExpand: (expanded) => setState(() => _expandedFaqId = expanded ? faq.id : null),
              onEdit: () => _openEditDrawer(faq),
              onDelete: () => _confirmDelete(faq),
              onToggleStatus: (val) => _toggleStatus(faq, val),
            );
          },
        ),
        if (_showSaveOrder)
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _buildSaveOrderBar(),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help_outline, size: 64, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          const Text('No FAQs matching your filters', style: TextStyle(color: Colors.white38, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() { _filterCategory = null; _filterAudience = 'All Users'; }),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Filters', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveOrderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white),
          const SizedBox(width: 16),
          const Text('FAQ order changed. Would you like to save this order?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => _showSaveOrder = false),
            child: const Text('DISCARD', style: TextStyle(color: Colors.white70)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () async {
              final ids = _currentOrder.map((f) => f.id).toList();
              await ref.read(faqProvider.notifier).updateOrder(ids);
              setState(() => _showSaveOrder = false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF3B82F6)),
            child: const Text('SAVE ORDER'),
          ),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutCubic);
  }

  void _confirmDelete(FAQ faq) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete FAQ', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete this FAQ?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              await ref.read(faqProvider.notifier).deleteFaq(faq.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _openEditDrawer(FAQ faq) {
    setState(() => _previewFaq = faq);
    Scaffold.of(context).openEndDrawer();
  }

  Future<void> _toggleStatus(FAQ faq, bool val) async {
    await ref.read(faqProvider.notifier).toggleStatus(faq.id, val);
  }
}

class FAQCard extends StatelessWidget {
  final FAQ faq;
  final bool isExpanded;
  final Function(bool) onExpand;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onToggleStatus;

  const FAQCard({
    super.key,
    required this.faq,
    required this.isExpanded,
    required this.onExpand,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isExpanded ? const Color(0xFF1E293B) : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isExpanded ? const Color(0xFF3B82F6).withOpacity(0.3) : Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: ReorderableDragStartListener(
              index: 0,
              child: const Icon(Icons.drag_indicator, color: Colors.white10),
            ),
            title: Text(
              faq.question,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 15,
                fontWeight: isExpanded ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _CardChip(text: faq.category.toUpperCase(), bg: Colors.white10),
                  const SizedBox(width: 8),
                  ...faq.targetAudience.map((a) => _CardChip(
                    text: a, 
                    bg: const Color(0xFF3B82F6).withOpacity(0.1), 
                    textColor: const Color(0xFF3B82F6),
                  )),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusToggle(value: faq.isActive, onChanged: onToggleStatus),
                const SizedBox(width: 12),
                IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white38), onPressed: onEdit),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: onDelete),
                const SizedBox(width: 4),
                Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white38),
              ],
            ),
            onTap: () => onExpand(!isExpanded),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(64, 0, 24, 24),
              child: Text(
                faq.answer,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.6),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusToggle extends StatefulWidget {
  final bool value;
  final Function(bool) onChanged;

  const _StatusToggle({required this.value, required this.onChanged});

  @override
  State<_StatusToggle> createState() => _StatusToggleState();
}

class _StatusToggleState extends State<_StatusToggle> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value: widget.value,
        activeColor: const Color(0xFF3B82F6),
        inactiveThumbColor: Colors.white10,
        activeTrackColor: const Color(0xFF3B82F6).withOpacity(0.3),
        inactiveTrackColor: Colors.white10,
        thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
          if (_isLoading) return const Icon(Icons.refresh, size: 12);
          return null;
        }),
        onChanged: (val) async {
          setState(() => _isLoading = true);
          await widget.onChanged(val);
          if (mounted) setState(() => _isLoading = false);
        },
      ),
    );
  }
}

class _CardChip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color? textColor;

  const _CardChip({required this.text, required this.bg, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: TextStyle(color: textColor ?? Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
