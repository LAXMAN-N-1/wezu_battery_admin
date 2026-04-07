import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import '../data/models/blog.dart';
import '../data/cms_providers.dart';
import '../data/repositories/blog_repository.dart';
import '../../../core/widgets/admin_ui_components.dart';

class BlogEditorView extends ConsumerStatefulWidget {
  final int? blogId;

  const BlogEditorView({super.key, this.blogId});

  @override
  ConsumerState<BlogEditorView> createState() => _BlogEditorViewState();
}

class _BlogEditorViewState extends ConsumerState<BlogEditorView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _slugController = TextEditingController();
  final _summaryController = TextEditingController();
  final _metaTitleController = TextEditingController();
  final _metaDescController = TextEditingController();
  final _focusKeywordController = TextEditingController();
  
  late QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  
  String _status = 'draft';
  String _category = 'general';
  String? _featuredImageUrl;
  DateTime? _scheduledAt;
  bool _isLoading = false;
  Blog? _originalBlog;

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
    if (widget.blogId != null) {
      _loadBlog();
    }
    
    _titleController.addListener(_updateSlug);
  }

  void _updateSlug() {
    if (widget.blogId == null) {
      final text = _titleController.text.toLowerCase();
      _slugController.text = text.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
    }
  }

  Future<void> _loadBlog() async {
    setState(() => _isLoading = true);
    try {
      final blog = await ref.read(blogRepositoryProvider).getBlog(widget.blogId!);
      _originalBlog = blog;
      _titleController.text = blog.title;
      _slugController.text = blog.slug;
      _summaryController.text = blog.summary ?? '';
      _status = blog.status;
      _category = blog.category;
      _featuredImageUrl = blog.featuredImageUrl;
      _scheduledAt = blog.publishedAt;
      
      if (blog.content.startsWith('[') || blog.content.startsWith('{')) {
         try {
           final doc = Document.fromJson(jsonDecode(blog.content));
           _quillController = QuillController(
             document: doc,
             selection: const TextSelection.collapsed(offset: 0),
           );
         } catch (e) {
           _quillController.document.insert(0, blog.content);
         }
      } else {
        _quillController.document.insert(0, blog.content);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading blog: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _summaryController.dispose();
    _metaTitleController.dispose();
    _metaDescController.dispose();
    _focusKeywordController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _save(String targetStatus) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final content = jsonEncode(_quillController.document.toDelta().toJson());
    
    final blogData = Blog(
      id: widget.blogId ?? 0,
      title: _titleController.text,
      slug: _slugController.text,
      content: content,
      summary: _summaryController.text,
      featuredImageUrl: _featuredImageUrl,
      category: _category,
      status: targetStatus,
      authorId: 1, // Defaulting to 1 for now
      viewsCount: _originalBlog?.viewsCount ?? 0,
      publishedAt: targetStatus == 'scheduled' ? _scheduledAt : (targetStatus == 'published' ? DateTime.now() : null),
      createdAt: _originalBlog?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.blogId == null) {
        await ref.read(blogRepositoryProvider).createBlog(blogData);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Blog post created successfully!'), backgroundColor: Colors.green));
      } else {
        await ref.read(blogRepositoryProvider).updateBlog(widget.blogId!, blogData);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Blog post updated successfully!'), backgroundColor: Colors.green));
      }
      ref.invalidate(blogListProvider);
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving blog: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141E2B),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
        title: Text(widget.blogId == null ? 'New Blog Post' : 'Edit Blog Post', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          OutlinedButton(
            onPressed: _isLoading ? null : () => _save('draft'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white24)),
            child: const Text('Save as Draft'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _showSchedulePicker(),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.blue, side: const BorderSide(color: Colors.blue)),
            child: const Text('Schedule'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _save('published'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
            child: const Text('Publish'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading && widget.blogId != null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Row(
                children: [
                  // Left Panel - Content
                  Expanded(
                    flex: 7,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _titleController,
                            style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter post title...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                              border: InputBorder.none,
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('URL: wezuenergy.com/blog/', style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextFormField(
                                  controller: _slugController,
                                  style: GoogleFonts.inter(color: Colors.blue.shade300, fontSize: 13),
                                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          // Quill Editor
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Column(
                              children: [
                                QuillSimpleToolbar(
                                  controller: _quillController,
                                  configurations: const QuillSimpleToolbarConfigurations(
                                    showFontSize: false,
                                    showFontFamily: false,
                                    showSearchButton: false,
                                    showSubscript: false,
                                    showSuperscript: false,
                                    showSmallButton: false,
                                    multiRowsDisplay: false,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  constraints: const BoxConstraints(minHeight: 400),
                                  child: QuillEditor.basic(
                                    controller: _quillController,
                                    focusNode: _editorFocusNode,
                                    configurations: const QuillEditorConfigurations(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 48),
                          
                          // SEO Section
                          _buildSeoSection(),
                        ],
                      ),
                    ),
                  ),
                  
                  // Right Panel - Settings
                  Container(
                    width: 350,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141E2B),
                      border: Border(left: BorderSide(color: Colors.white.withOpacity(0.05))),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('Featured Image'),
                          const SizedBox(height: 12),
                          _buildImageUploadZone(),
                          const SizedBox(height: 32),
                          
                          _sectionHeader('Organization'),
                          const SizedBox(height: 16),
                          _buildDropdownField('Category', _category, ['general', 'news', 'tips', 'updates', 'technology', 'company'], (val) => setState(() => _category = val!)),
                          const SizedBox(height: 20),
                          _buildTextField('Summary', _summaryController, maxLines: 4),
                          const SizedBox(height: 32),
                          
                          _sectionHeader('Metadata'),
                          const SizedBox(height: 16),
                          _buildInfoRow('Author', 'Super Admin'),
                          _buildInfoRow('Reading Time', '${(_quillController.document.toPlainText().split(' ').length / 200).ceil()} min'),
                          _buildInfoRow('Status', _status.toUpperCase(), color: _status == 'published' ? Colors.green : Colors.amber),
                          
                          if (_scheduledAt != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow('Scheduled for', '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year}'),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.2));
  }

  Widget _buildSeoSection() {
    return ExpansionTile(
      title: Text('SEO Settings', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text('Manage how this post appears in search engines', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
      childrenPadding: const EdgeInsets.all(20),
      collapsedIconColor: Colors.white54,
      iconColor: Colors.blue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white.withOpacity(0.02),
      children: [
        _buildTextField('Meta Title', _metaTitleController, hint: 'Search engine title'),
        const SizedBox(height: 16),
        _buildTextField('Meta Description', _metaDescController, hint: 'Search engine description', maxLines: 3),
        const SizedBox(height: 16),
        _buildTextField('Focus Keyword', _focusKeywordController, hint: 'Main keyword for this post'),
        const SizedBox(height: 24),
        Text('Preview', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_metaTitleController.text.isEmpty ? (_titleController.text.isEmpty ? 'Your Post Title' : _titleController.text) : _metaTitleController.text, style: const TextStyle(color: Color(0xFF1A0DAB), fontSize: 18, fontWeight: FontWeight.w400)),
              Text('wezuenergy.com/blog/${_slugController.text}', style: const TextStyle(color: Color(0xFF006621), fontSize: 14)),
              const SizedBox(height: 4),
              Text(_metaDescController.text.isEmpty ? (_summaryController.text.isEmpty ? 'Your post description will appear here...' : _summaryController.text) : _metaDescController.text, style: const TextStyle(color: Color(0xFF545454), fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadZone() {
    return GestureDetector(
      onTap: () {
        // Mock image select
        setState(() => _featuredImageUrl = 'https://picsum.photos/seed/blog/800/450');
      },
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1), style: BorderStyle.solid),
        ),
        child: _featuredImageUrl != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11), 
                    child: Image.network(
                      _featuredImageUrl!, 
                      width: double.infinity, 
                      height: double.infinity, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.white.withOpacity(0.05),
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
                      ),
                    ),
                  ),
                  Positioned(right: 8, top: 8, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), backgroundColor: Colors.black26, onPressed: () => setState(() => _featuredImageUrl = null))),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 32, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 12),
                  Text('Click to upload featured image', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                  Text('Recommended: 1200x675px', style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
          Text(value, style: GoogleFonts.inter(color: color ?? Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _showSchedulePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _scheduledAt = date);
      _save('scheduled');
    }
  }
}
