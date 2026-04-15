import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../../../core/widgets/glass_components.dart';
import '../data/models/blog.dart';
import '../provider/cms_providers.dart';

class BlogManagementView extends ConsumerStatefulWidget {
  const BlogManagementView({super.key});

  @override
  ConsumerState<BlogManagementView> createState() => _BlogManagementViewState();
}

class _BlogManagementViewState extends ConsumerState<BlogManagementView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _activeTab = 'all';
  String _selectedCategory = 'all';
  String _sortColumn = 'Published';
  bool _sortAscending = false;
  Blog? _previewBlog;
  int? _hoveredRowIdx;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(blogProvider.notifier).setSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final blogsAsync = ref.watch(blogProvider);
    final statsAsync = ref.watch(blogStatsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildFilterBar(statsAsync),
                const SizedBox(height: 12),
                _buildSearchAndControls(),
                const SizedBox(height: 16),
                Expanded(
                  child: GlassContainer(
                    padding: EdgeInsets.zero,
                    child: blogsAsync.when(
                      data: (blogs) => _buildBlogTable(blogs),
                      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
                      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                    ),
                  ),
                ),
                _buildPagination(blogsAsync),
              ],
            ),
          ),
          if (_previewBlog != null) _buildPreviewDrawer(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Blog Management',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate().fadeIn().slideX(begin: -0.2),
            Text(
              'Create, edit and publish blog articles',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
            ).animate(delay: 100.ms).fadeIn(),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => context.push('/cms/blogs/new'),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('New Post'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
          ).copyWith(
            overlayColor: WidgetStateProperty.all(Colors.white10),
          ),
        ).animate().scale(delay: 200.ms),
      ],
    );
  }

  Widget _buildFilterBar(AsyncValue<Map<String, int>> statsAsync) {
    final stats = statsAsync.value ?? {'all': 0, 'published': 0, 'draft': 0, 'scheduled': 0};
    
    return Row(
      children: [
        _tabItem('All', 'all', stats['all'] ?? 0),
        _tabItem('Published', 'published', stats['published'] ?? 0),
        _tabItem('Draft', 'draft', stats['draft'] ?? 0),
        _tabItem('Scheduled', 'scheduled', stats['scheduled'] ?? 0),
      ],
    );
  }

  Widget _tabItem(String label, String value, int count) {
    final isActive = _activeTab == value;
    return GestureDetector(
      onTap: () {
        setState(() => _activeTab = value);
        ref.read(blogProvider.notifier).setFilters(status: value);
      },
      child: AnimatedContainer(
        duration: 300.ms,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: isActive ? Colors.white : Colors.white60,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? Colors.white24 : Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  color: isActive ? Colors.white : Colors.white38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndControls() {
    return Column(
      children: [
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search posts by title or author...',
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(Icons.search, color: Colors.white24),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.white24),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(blogProvider.notifier).setSearch('');
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildDropdownFilter(
              'Category',
              _selectedCategory,
              ['all', 'Energy Tips', 'News', 'Updates', 'Technology', 'Company'],
              (v) {
                setState(() => _selectedCategory = v!);
                ref.read(blogProvider.notifier).setFilters(category: v);
              },
            ),
            const SizedBox(width: 16),
            _buildDateRangePicker(),
            const Spacer(),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _activeTab = 'all';
                  _selectedCategory = 'all';
                  _startDate = null;
                  _endDate = null;
                });
                ref.read(blogProvider.notifier).setSearch('');
                ref.read(blogProvider.notifier).setFilters(status: 'all', category: 'all');
              },
              child: const Text('Clear Filters', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownFilter(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: Container(),
        dropdownColor: const Color(0xFF1E293B),
        style: const TextStyle(color: Colors.white),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  DateTime? _startDate;
  DateTime? _endDate;

  Widget _buildDateRangePicker() {
    final label = _startDate != null && _endDate != null
        ? '${DateFormat('dd MMM').format(_startDate!)} — ${DateFormat('dd MMM').format(_endDate!)}'
        : 'From — To';

    return GestureDetector(
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF3B82F6),
                onPrimary: Colors.white,
                surface: Color(0xFF1E293B),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (range != null) {
          setState(() {
            _startDate = range.start;
            _endDate = range.end;
          });
          // Update provider filters
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _startDate != null ? const Color(0xFF3B82F6).withOpacity(0.5) : Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: _startDate != null ? const Color(0xFF3B82F6) : Colors.white38),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: _startDate != null ? Colors.white : Colors.white38, fontSize: 13)),
            if (_startDate != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() { _startDate = null; _endDate = null; }),
                child: const Icon(Icons.close, size: 14, color: Colors.white38),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBlogTable(List<Blog> blogs) {
    if (blogs.isEmpty) return _buildEmptyState();

    return AdvancedTable(
      columns: const ['Article', 'Author', 'Category', 'Status', 'Published', 'Views', 'Actions'],
      sortColumn: _sortColumn,
      sortAscending: _sortAscending,
      onSort: (col) {
        setState(() {
          if (_sortColumn == col) {
            _sortAscending = !_sortAscending;
          } else {
            _sortColumn = col;
            _sortAscending = false;
          }
        });
        // In a real app, you'd trigger a reload with sort params
      },
      onRowTap: (idx) => context.push('/cms/blogs/edit/${blogs[idx].id}'),
      rows: blogs.asMap().entries.map((entry) {
        final idx = entry.key;
        final blog = entry.value;
        return [
        // Article Column
        MouseRegion(
          onEnter: (_) => setState(() => _hoveredRowIdx = idx),
          onExit: (_) => setState(() => _hoveredRowIdx = null),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  color: Colors.white10,
                  child: blog.featuredImageUrl != null
                      ? Image.network(blog.featuredImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.white24))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined, color: Colors.white24, size: 20),
                            SizedBox(height: 4),
                            Text('NO IMG', style: TextStyle(color: Colors.white10, fontSize: 8)),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  blog.title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    decoration: _hoveredRowIdx == idx ? TextDecoration.underline : TextDecoration.none,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Author Column
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF3B82F6),
              child: Text(
                'A', // Mock initials
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Admin One', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        // Category Column
        _buildCategoryChip(blog.category),
        // Status Column
        GestureDetector(
          onTap: () => _confirmPublishToggle(blog),
          child: StatusBadge(status: blog.status.toUpperCase()),
        ),
        // Date Column
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              blog.publishedAt != null ? DateFormat('dd MMM yyyy').format(blog.publishedAt!) : 'Not Pub.',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
            if (blog.status == 'scheduled')
              const Icon(Icons.access_time, size: 12, color: Color(0xFF3B82F6)),
          ],
        ),
        // Views Column
        Text(
          NumberFormat('#,###').format(blog.viewsCount),
          style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 12),
        ),
        // Actions Column
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionIcon(Icons.edit_outlined, Colors.blueAccent, 'Edit', () => context.push('/cms/blogs/edit/${blog.id}')),
            _actionIcon(Icons.visibility_outlined, Colors.white60, 'Preview', () => setState(() => _previewBlog = blog)),
            _actionIcon(Icons.delete_outline, Colors.redAccent, 'Delete', () => _confirmDelete(blog)),
          ],
        ),
      ];
    }).toList(),
    );
  }

  Widget _buildCategoryChip(String category) {
    Color color;
    switch (category.toLowerCase()) {
      case 'energy tips': color = const Color(0xFF06B6D4); break;
      case 'news': color = const Color(0xFF3B82F6); break;
      case 'updates': color = const Color(0xFF22C55E); break;
      case 'technology': color = const Color(0xFFA855F7); break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        category,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: color, size: 18),
        onPressed: onTap,
        splashRadius: 20,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 24),
          const Text('No blog posts found', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Create your first blog post to get started', style: TextStyle(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/cms/blogs/new'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('New Post'),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(AsyncValue<List<Blog>> blogsAsync) {
    final count = blogsAsync.value?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing 1–$count of $count posts',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          Row(
            children: [
              const Text('Rows per page:', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 8),
              _buildMiniDropdown('10'),
              const SizedBox(width: 24),
              _buildPaginationButton(Icons.chevron_left, false),
              const SizedBox(width: 8),
              _buildPageNumber('1', true),
              _buildPageNumber('2', false),
              _buildPageNumber('3', false),
              const Text('...', style: TextStyle(color: Colors.white38)),
              _buildPageNumber('12', false),
              const SizedBox(width: 8),
              _buildPaginationButton(Icons.chevron_right, true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniDropdown(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11)),
          const Icon(Icons.arrow_drop_down, color: Colors.white38, size: 16),
        ],
      ),
    );
  }

  Widget _buildPaginationButton(IconData icon, bool active) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: active ? Colors.white70 : Colors.white10, size: 18),
    );
  }

  Widget _buildPageNumber(String num, bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: active ? Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)) : null,
      ),
      child: Text(
        num,
        style: TextStyle(
          color: active ? const Color(0xFF3B82F6) : Colors.white38,
          fontSize: 12,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPreviewDrawer() {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, offset: const Offset(-20, 0))],
          ),
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                title: const Text('Post Preview'),
                actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _previewBlog = null))],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      // Mock Mobile Frame
                      Container(
                        width: 280,
                        height: 560,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.grey.shade800, width: 8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_previewBlog?.featuredImageUrl != null)
                                  Image.network(_previewBlog!.featuredImageUrl!, fit: BoxFit.cover),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_previewBlog!.title, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Text(_previewBlog!.content, style: const TextStyle(color: Colors.black87, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate().slideX(begin: 1.0, duration: 400.ms, curve: Curves.easeOut),
      ),
    );
  }

  void _confirmDelete(Blog blog) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Post?', style: TextStyle(color: Colors.white)),
        content: const Text('This will permanently delete this blog post and cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              await ref.read(blogProvider.notifier).deleteBlog(blog.id);
              if (mounted) {
                if (Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted successfully'), backgroundColor: Colors.green));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete Post'),
          ),
        ],
      ),
    );
  }

  void _confirmPublishToggle(Blog blog) {
    final isPublished = blog.status == 'published';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(isPublished ? 'Unpublish Post?' : 'Publish Post?', style: const TextStyle(color: Colors.white)),
        content: Text(isPublished ? 'This will revert the post to a draft.' : 'This will make the post live for all users.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              await ref.read(blogProvider.notifier).toggleStatus(blog.id, blog.status);
              if (mounted) {
                if (Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
            child: Text(isPublished ? 'Unpublish' : 'Publish'),
          ),
        ],
      ),
    );
  }
}
