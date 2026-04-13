import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../../../core/widgets/glass_components.dart';
import '../data/models/blog.dart';
import '../provider/cms_providers.dart';

class BlogEditorView extends ConsumerStatefulWidget {
  final String? blogId;
  const BlogEditorView({super.key, this.blogId});

  @override
  ConsumerState<BlogEditorView> createState() => _BlogEditorViewState();
}

class _BlogEditorViewState extends ConsumerState<BlogEditorView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _slugController;
  late TextEditingController _metaTitleController;
  late TextEditingController _metaDescController;
  late TextEditingController _keywordController;
  late HtmlEditorController _htmlController;
  
  String _status = 'draft';
  String _category = 'News';
  String _author = 'Current User';
  List<String> _tags = [];
  String? _featuredImageUrl;
  bool _isSaving = false;
  bool _isDirty = false;
  bool _showSchedule = false;
  int _readingTime = 1;
  DateTime _scheduleDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduleTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _slugController = TextEditingController();
    _metaTitleController = TextEditingController();
    _metaDescController = TextEditingController();
    _keywordController = TextEditingController();
    _htmlController = HtmlEditorController();
    
    // If editing, load data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.blogId != null) {
        final blogs = ref.read(blogProvider).value;
        final blog = blogs?.firstWhere((b) => b.id.toString() == widget.blogId);
        if (blog != null) {
          _titleController.text = blog.title;
          _slugController.text = blog.slug;
          _metaTitleController.text = blog.metaTitle ?? '';
          _metaDescController.text = blog.metaDescription ?? '';
          _keywordController.text = blog.focusKeyword ?? '';
          _status = blog.status;
          _category = blog.category;
          _tags = List.from(blog.tags);
          _featuredImageUrl = blog.featuredImageUrl;
          // Note: HTML content loading handled by controller
          setState(() {});
        }
      }
    });

    _titleController.addListener(() {
      if (!_isDirty) setState(() => _isDirty = true);
      if (widget.blogId == null) {
        _slugController.text = _titleController.text
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '-');
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _metaTitleController.dispose();
    _metaDescController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Unsaved Changes', style: TextStyle(color: Colors.white)),
        content: const Text('You have unsaved changes. Leave anyway?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay', style: TextStyle(color: Color(0xFF3B82F6)))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard Changes', style: TextStyle(color: Colors.white38))),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _save({required String status}) async {
    if (!_formKey.currentState!.validate()) return;
    
    final content = await _htmlController.getText();
    if (content.isEmpty || content == '<p><br></p>') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter some content')));
      return;
    }

    if (status == 'published' && _featuredImageUrl == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Featured image is required for publishing')));
       return;
    }

    setState(() => _isSaving = true);
    
    final data = {
      'title': _titleController.text,
      'slug': _slugController.text,
      'content': content,
      'featured_image_url': _featuredImageUrl,
      'status': status,
      'category': _category,
      'tags': _tags,
      'meta_title': _metaTitleController.text,
      'meta_description': _metaDescController.text,
      'focus_keyword': _keywordController.text,
      'author_id': 1,
      if (status == 'scheduled') 'published_at': DateTime(_scheduleDate.year, _scheduleDate.month, _scheduleDate.day, _scheduleTime.hour, _scheduleTime.minute).toIso8601String(),
    };

    try {
      if (widget.blogId == null) {
        await ref.read(blogProvider.notifier).createBlog(data);
      } else {
        await ref.read(blogProvider.notifier).updateBlog(int.parse(widget.blogId!), data);
      }
      _isDirty = false;
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          context.pop();
        }
      },
      child: GlassScaffold(
        backgroundColor: const Color(0xFF0F172A),
        child: Column(
          children: [
            _buildTopNav(),
            Expanded(
              child: Form(
                key: _formKey,
                child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 1000;
                        
                        if (isCompact) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildContentPanel(),
                                const Divider(height: 48, color: Colors.white10),
                                _buildSidebarPanel(),
                              ],
                            ),
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Panel (70%)
                            Expanded(
                              flex: 7,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(32),
                                child: _buildContentPanel(),
                              ),
                            ),
                            const VerticalDivider(width: 1, color: Colors.white10),
                            // Right Panel (30%)
                            Expanded(
                              flex: 3,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: _buildSidebarPanel(),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () async {
              if (await _onWillPop()) context.pop();
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white60, size: 18),
            label: const Text('Back to Blogs', style: TextStyle(color: Colors.white60, fontSize: 13)),
          ),
          const Spacer(),
          Text(
            widget.blogId == null ? 'New Blog Post' : 'Edit Post',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Spacer(),
          _topNavButton('Save as Draft', Colors.transparent, Colors.white60, () => _save(status: 'draft'), isOutline: true),
          const SizedBox(width: 12),
          _topNavButton('Schedule', Colors.transparent, const Color(0xFF3B82F6), () => setState(() => _showSchedule = !_showSchedule), isOutline: true),
          const SizedBox(width: 12),
          _topNavButton(
            widget.blogId == null ? 'Publish' : 'Update & Publish',
            const Color(0xFF3B82F6),
            Colors.white,
            () => _confirmPublish(),
          ),
        ],
      ),
    );
  }

  Widget _topNavButton(String label, Color bg, Color text, VoidCallback onTap, {bool isOutline = false}) {
    return ElevatedButton(
      onPressed: _isSaving ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: text,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isOutline ? BorderSide(color: text) : BorderSide.none,
        ),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildSlugEditor() {
    bool _isSlugManuallyEdited = false;

    return Row(
      children: [
        const Text('URL: wezuenergy.com/blog/ ', style: TextStyle(color: Colors.white38, fontSize: 13)),
        const SizedBox(width: 4),
        Expanded(
          child: TextFormField(
            controller: _slugController,
            onChanged: (v) => _isSlugManuallyEdited = true,
            style: GoogleFonts.robotoMono(color: const Color(0xFF3B82F6), fontSize: 13),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 14, color: Colors.white38),
          onPressed: () {}, // Focus slug field
        ),
      ],
    );
  }

  Widget _buildEditor() {
    return Container(
      height: 600,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: HtmlEditor(
        controller: _htmlController,
        callbacks: Callbacks(
          onChangeContent: (content) {
            if (!_isDirty) setState(() => _isDirty = true);
            setState(() {
              _readingTime = _calculateReadingTime(content ?? '');
            });
          },
        ),
        htmlEditorOptions: HtmlEditorOptions(
          hint: 'Begin writing your masterpiece...',
          initialText: widget.blogId != null ? ref.read(blogProvider).value?.firstWhere((b) => b.id.toString() == widget.blogId).content : null,
          darkMode: true,
        ),
      ),
    );
  }

  int _calculateReadingTime(String htmlContent) {
    if (htmlContent.isEmpty) return 1;
    final text = htmlContent.replaceAll(RegExp(r'<[^>]*>'), ''); // strip html
    final words = text.trim().split(RegExp(r'\s+')).length;
    return (words / 200).ceil();
  }

  Widget _buildSEOSection() {
    return GlassContainer(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        title: const Text('Search Engine Optimization (SEO)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        childrenPadding: const EdgeInsets.all(24),
        collapsedIconColor: Colors.white60,
        iconColor: const Color(0xFF3B82F6),
        backgroundColor: Colors.transparent,
        children: [
          Row(
            children: [
              Expanded(child: AdminTextField(controller: _metaTitleController, label: 'Meta Title', hint: 'Max 60 chars', icon: Icons.title)),
              const SizedBox(width: 16),
              Expanded(child: AdminTextField(controller: _keywordController, label: 'Focus Keyword', hint: 'main-topic', icon: Icons.key)),
            ],
          ),
          const SizedBox(height: 16),
          AdminTextField(
            controller: _metaDescController, 
            label: 'Meta Description', 
            hint: 'Summarize the post for search results (Max 160 chars)...', 
            icon: Icons.description,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          _buildGooglePreview(),
        ],
      ),
    );
  }

  Widget _buildGooglePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Google Search Preview', style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 8),
          Text(_metaTitleController.text.isEmpty ? 'Your Post Title' : _metaTitleController.text, style: const TextStyle(color: Color(0xFF8AB4F8), fontSize: 18)),
          Text('wezuenergy.com/blog/${_slugController.text}', style: const TextStyle(color: Color(0xFF34A853), fontSize: 13)),
          Text(_metaDescController.text.isEmpty ? 'Add a description to see how it looks in search results...' : _metaDescController.text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFeaturedImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Featured Image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _featuredImageUrl = 'https://picsum.photos/seed/blog/800/400'), // Mock selection
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.3), 
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: _featuredImageUrl != null
                  ? Stack(
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_featuredImageUrl!, fit: BoxFit.cover, width: double.infinity)),
                        Positioned(
                          top: 8, 
                          right: 8, 
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => setState(() => _featuredImageUrl = null)),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_upload_outlined, size: 40, color: Color(0xFF3B82F6)),
                        const SizedBox(height: 12),
                        const Text('Drag image here or click to browse', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {}, 
                          child: const Text('Choose from Media Library', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12)),
                        ),
                      ],
                    ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds, delay: 1.seconds, color: Colors.white10),
        ),
      ],
    );
  }

  Widget _buildSettingsSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sidebarDropdown('Category', _category, ['Energy Tips', 'News', 'Updates', 'Technology', 'Company', 'Announcements'], (v) => setState(() => _category = v!)),
        const SizedBox(height: 24),
        const Text('Tags', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        _buildTagChips(),
        const SizedBox(height: 24),
        _sidebarDropdown('Author', _author, ['Current User', 'Admin One', 'Rama Koti'], (v) => setState(() => _author = v!)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white38, size: 18),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimated read', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  Text('$_readingTime min', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_showSchedule) _buildSchedulePanel(),
      ],
    );
  }

  Widget _buildTagChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._tags.map((tag) => Chip(
          label: Text(tag, style: const TextStyle(fontSize: 11)),
          onDeleted: () => setState(() => _tags.remove(tag)),
          backgroundColor: Colors.white10,
          labelStyle: const TextStyle(color: Colors.white70),
          deleteIconColor: Colors.white38,
        )),
        ActionChip(
          label: const Icon(Icons.add, size: 14),
          onPressed: _showAddTagDialog,
          backgroundColor: Colors.white.withOpacity(0.05),
        ),
      ],
    );
  }

  void _showAddTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Add Tag', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter tag name (e.g. Solar)',
            hintStyle: TextStyle(color: Colors.white24),
          ),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty && _tags.length < 10) {
              setState(() => _tags.add(v.trim()));
              Navigator.pop(dialogContext);
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty && _tags.length < 10) {
                setState(() => _tags.add(controller.text.trim()));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Add', style: TextStyle(color: Color(0xFF3B82F6))),
          ),
        ],
      ),
    );
  }

  Widget _sidebarDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: const Color(0xFF1E293B),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(color: Colors.white)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSchedulePanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          const Text('Schedule Publication', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _topNavButton('${_scheduleDate.day}/${_scheduleDate.month}/${_scheduleDate.year}', Colors.white10, Colors.white, () async {
            final d = await showDatePicker(context: context, initialDate: _scheduleDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
            if (d != null) setState(() => _scheduleDate = d);
          }),
          const SizedBox(height: 8),
          _topNavButton(_scheduleTime.format(context), Colors.white10, Colors.white, () async {
            final t = await showTimePicker(context: context, initialTime: _scheduleTime);
            if (t != null) setState(() => _scheduleTime = t);
          }),
          const SizedBox(height: 16),
          _topNavButton('Confirm Schedule', const Color(0xFF3B82F6), Colors.white, () => _save(status: 'scheduled')),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildContentPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _titleController,
          style: GoogleFonts.outfit(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
          maxLines: null,
          decoration: InputDecoration(
            hintText: 'Enter post title...',
            hintStyle: const TextStyle(color: Colors.white10),
            border: InputBorder.none,
            counterText: '${_titleController.text.length}/120',
            counterStyle: TextStyle(
              color: _titleController.text.length > 100 ? Colors.amber : Colors.white10,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildSlugEditor(),
        const SizedBox(height: 32),
        _buildEditor(),
        const SizedBox(height: 32),
        _buildSEOSection(),
      ],
    );
  }

  Widget _buildSidebarPanel() {
    return Column(
      children: [
        _buildFeaturedImageSection(),
        const SizedBox(height: 24),
        _buildSettingsSidebar(),
      ],
    );
  }

  void _confirmPublish() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Publish Post?', style: TextStyle(color: Colors.white)),
        content: const Text('This will make your post live for all users immediately.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          ElevatedButton(onPressed: () => _save(status: 'published'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)), child: const Text('Publish Now')),
        ],
      ),
    );
  }
}
