import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/models/blog.dart';
import '../data/cms_providers.dart';
import '../../../core/widgets/admin_ui_components.dart';

class BlogManagementView extends ConsumerStatefulWidget {
  const BlogManagementView({super.key});

  @override
  ConsumerState<BlogManagementView> createState() => _BlogManagementViewState();
}

class _BlogManagementViewState extends ConsumerState<BlogManagementView> {
  String _activeTab = 'All';
  final _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blogState = ref.watch(blogListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildFilters(),
          const SizedBox(height: 24),
          blogState.when(
            data: (blogs) {
              final filteredBlogs = _applyFilters(blogs);
              if (filteredBlogs.isEmpty) {
                return _buildEmptyState();
              }
              return _buildBlogTable(filteredBlogs);
            },
            loading: () => _buildShimmer(),
            error: (e, st) => _buildErrorState(e.toString()),
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
              'Blog Management',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Create, edit and publish blog articles across the WEZU platform',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => context.push('/cms/blogs/new'),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Post'),
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
    final blogState = ref.watch(blogListProvider);
    final countAll = blogState.asData?.value.length ?? 0;
    final countPublished = blogState.asData?.value.where((b) => b.status == 'published').length ?? 0;
    final countDraft = blogState.asData?.value.where((b) => b.status == 'draft').length ?? 0;
    final countScheduled = blogState.asData?.value.where((b) => b.status == 'scheduled').length ?? 0;

    return Column(
      children: [
        Row(
          children: [
            _filterTab('All', countAll),
            _filterTab('Published', countPublished),
            _filterTab('Draft', countDraft),
            _filterTab('Scheduled', countScheduled),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search posts by title or author...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.2)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            _buildDropdownFilter('Category', _selectedCategory, ['All', 'news', 'tips', 'updates', 'technology', 'company'], (val) {
              setState(() => _selectedCategory = val == 'All' ? null : val);
            }),
          ],
        ),
      ],
    );
  }

  Widget _filterTab(String label, int count) {
    final active = _activeTab == label;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF3B82F6).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? const Color(0xFF3B82F6).withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(
          children: [
            Text(label, style: GoogleFonts.inter(color: active ? Colors.blue.shade300 : Colors.white38, fontWeight: active ? FontWeight.w600 : FontWeight.w400, fontSize: 13)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: active ? const Color(0xFF3B82F6).withOpacity(0.2) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
              child: Text(count.toString(), style: GoogleFonts.inter(color: active ? Colors.blue.shade300 : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value ?? 'All',
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white),
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  List<Blog> _applyFilters(List<Blog> blogs) {
    return blogs.where((b) {
      if (_activeTab != 'All' && b.status.toLowerCase() != _activeTab.toLowerCase()) return false;
      if (_selectedCategory != null && b.category != _selectedCategory) return false;
      if (_searchController.text.isNotEmpty && !b.title.toLowerCase().contains(_searchController.text.toLowerCase())) return false;
      return true;
    }).toList();
  }

  Widget _buildBlogTable(List<Blog> blogs) {
    return AdvancedTable(
      columns: ['Thumbnail', 'Title', 'Author', 'Category', 'Status', 'Views', 'Actions'],
      rows: blogs.map((blog) {
        return [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 40,
              child: blog.featuredImageUrl != null
                  ? Image.network(blog.featuredImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imagePlaceholder())
                  : _imagePlaceholder(),
            ),
          ),
          Text(blog.title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
          _authorBadge('Super Admin'),
          _categoryBadge(blog.category),
          StatusBadge(status: blog.status),
          Text(NumberFormat.compact().format(blog.viewsCount), style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue), onPressed: () => context.push('/cms/blogs/${blog.id}/edit')),
              IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _confirmDelete(blog)),
            ],
          ),
        ];
      }).toList(),
      onRowTap: (idx) => context.push('/cms/blogs/${blogs[idx].id}/edit'),
    );
  }

  Widget _imagePlaceholder() => Container(color: Colors.white10, child: const Icon(Icons.image_outlined, size: 16, color: Colors.white24));

  Widget _authorBadge(String name) {
    return Row(
      children: [
        CircleAvatar(radius: 10, backgroundColor: Colors.blue.withOpacity(0.2), child: Text(name[0], style: const TextStyle(fontSize: 8, color: Colors.blue))),
        const SizedBox(width: 8),
        Text(name, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _categoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
      child: Text(category.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(64.0),
        child: Column(
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text('No blog posts found', style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Create your first blog post to get started', style: GoogleFonts.inter(color: Colors.white38)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => context.push('/cms/blogs/new'), child: const Text('New Post')),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(String error) {
    return Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red)));
  }

  void _confirmDelete(Blog blog) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Post?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${blog.title}"? This cannot be undone.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(blogListProvider.notifier).deleteBlog(blog.id);
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
