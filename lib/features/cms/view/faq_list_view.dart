import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/faq.dart';
import '../data/repositories/faq_repository.dart';

class FaqListView extends StatefulWidget {
  const FaqListView({super.key});

  @override
  State<FaqListView> createState() => _FaqListViewState();
}

class _FaqListViewState extends State<FaqListView> {
  final FaqRepository _repository = FaqRepository();
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
        q: _searchQuery.isEmpty ? null : _searchQuery,
      );
      setState(() {
        _faqs = faqs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading FAQs: $e')),
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
          PageHeader(
            title: 'FAQ Management',
            subtitle: 'Add and categorize frequently asked questions.',
            actionButton: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_comment_outlined, size: 20, color: Colors.white),
              label: const Text('Add New FAQ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
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
                    fillColor: Colors.black.withValues(alpha: 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
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
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05),
          const SizedBox(height: 24),

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _faqs.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _faqs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildFaqTile(_faqs[index]).animate().fadeIn(duration: 400.ms, delay: (200 + index * 50).ms).slideY(begin: 0.05);
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
            ...items.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFaqTile(FAQ faq) {
    return ExpansionTile(
      backgroundColor: Colors.white.withValues(alpha: 0.03),
      collapsedBackgroundColor: Colors.white.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          _buildCategoryBadge(faq.category),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              faq.question,
              style: GoogleFonts.inter(
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
            activeColor: Colors.green,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white38),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
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
              Row(
                children: [
                  _buildStat(Icons.thumb_up_alt_outlined, Colors.green, faq.helpfulCount.toString()),
                  const SizedBox(width: 16),
                  _buildStat(Icons.thumb_down_alt_outlined, Colors.red, faq.notHelpfulCount.toString()),
                  const Spacer(),
                  Text(
                    'Last updated: ${DateFormat('MMM d, y').format(faq.updatedAt)}',
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold),
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
          Icon(Icons.quiz_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1)),
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
