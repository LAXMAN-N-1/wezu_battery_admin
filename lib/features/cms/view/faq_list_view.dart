import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/models/faq.dart';
import '../data/repositories/faq_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class FaqListView extends StatefulWidget {
  const FaqListView({super.key});

  @override
  State<FaqListView> createState() => _FaqListViewState();
}

class _FaqListViewState extends SafeState<FaqListView> {
  final FAQRepository _repository = FAQRepository();
  List<FAQ> _faqs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final faqs = await _repository.getFaqs(
        category: _filterCategory,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      setState(() {
        _faqs = faqs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading FAQs: $e')));
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
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'FAQ Management',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to create view
                },
                icon: const Icon(Icons.add_comment_outlined),
                label: const Text('Add New FAQ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    _searchQuery = value;
                    _loadData();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search questions and answers...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildFilterDropdown(
                value: _filterCategory,
                hint: 'Category',
                items: ['general', 'rental', 'payment', 'safety'],
                onChanged: (val) => setState(() {
                  _filterCategory = val;
                  _loadData();
                }),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _faqs.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _faqs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildFaqTile(_faqs[index]);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.white38)),
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
          style: const TextStyle(color: Colors.white),
          items: [
            DropdownMenuItem(value: null, child: Text('All $hint')),
            ...items.map(
              (e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFaqTile(FAQ faq) {
    final updatedAtLabel = faq.updatedAt != null
        ? DateFormat('MMM d, y').format(faq.updatedAt!)
        : '—';

    return ExpansionTile(
      backgroundColor: Colors.white.withValues(alpha: 0.03),
      collapsedBackgroundColor: Colors.white.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Row(
        children: [
          _buildCategoryBadge(faq.category),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              faq.question,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch.adaptive(
            value: faq.isActive,
            onChanged: (val) {
              // TODO: Update status
            },
            activeThumbColor: Colors.green,
            activeTrackColor: Colors.green.withValues(alpha: 0.45),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: Colors.white38,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: Colors.redAccent,
            ),
            onPressed: () {},
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              Text(
                faq.answer,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildStat(
                    Icons.thumb_up_alt_outlined,
                    Colors.green,
                    faq.helpfulCount.toString(),
                  ),
                  const SizedBox(width: 16),
                  _buildStat(
                    Icons.thumb_down_alt_outlined,
                    Colors.red,
                    faq.notHelpfulCount.toString(),
                  ),

                  Text(
                    'Last updated: $updatedAtLabel',
                    style: const TextStyle(color: Colors.white24, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, Color color, String count) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(count, style: TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.quiz_outlined,
            size: 80,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 24),
          Text(
            'No FAQs found',
            style: GoogleFonts.outfit(fontSize: 20, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add some common questions and answers for your users.',
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
