import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/models/faq.dart';
import '../provider/cms_providers.dart';

class FAQEditDrawer extends ConsumerStatefulWidget {
  final FAQ? faq;
  final VoidCallback onSave;

  const FAQEditDrawer({super.key, this.faq, required this.onSave});

  @override
  ConsumerState<FAQEditDrawer> createState() => _FAQEditDrawerState();
}

class _FAQEditDrawerState extends ConsumerState<FAQEditDrawer> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late HtmlEditorController _htmlController;
  late String _category;
  late List<String> _targetAudience;
  late bool _isActive;
  late int _displayOrder;
  bool _isSaving = false;
  bool _isDirty = false;

  final List<String> _audiences = ['Customer App', 'Dealer App', 'Fleet Managers'];
  final List<String> _categories = ['Getting Started', 'Billing', 'Technical Support', 'Solar Panels', 'Payments', 'Others'];

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.faq?.question ?? '');
    _htmlController = HtmlEditorController();
    _category = widget.faq?.category ?? 'Getting Started';
    _targetAudience = List.from(widget.faq?.targetAudience ?? ['Customer App']);
    _isActive = widget.faq?.isActive ?? true;
    _displayOrder = widget.faq?.displayOrder ?? 0;

    _questionController.addListener(() => _isDirty = true);
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final content = await _htmlController.getText();
    if (content.isEmpty || content == '<p><br></p>') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Answer is required')));
      return;
    }

    if (_targetAudience.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one target audience')));
      return;
    }

    setState(() => _isSaving = true);
    
    final data = {
      'question': _questionController.text,
      'answer': content,
      'category': _category,
      'target_audience': _targetAudience,
      'is_active': _isActive,
      'display_order': _displayOrder,
    };

    try {
      if (widget.faq == null) {
        await ref.read(faqProvider.notifier).createFaq(data);
      } else {
        await ref.read(faqProvider.notifier).updateFaq(widget.faq!.id, data);
      }
      widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 480,
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Question'),
                      TextFormField(
                        controller: _questionController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        maxLength: 300,
                        decoration: _inputDeco('Enter the question...'),
                        validator: (v) => v!.isEmpty ? 'Question is required' : null,
                      ),
                      const SizedBox(height: 24),
                      _buildFieldLabel('Answer'),
                      _buildEditor(),
                      const SizedBox(height: 24),
                      _buildFieldLabel('Category'),
                      _buildCategoryDropdown(),
                      const SizedBox(height: 24),
                      _buildFieldLabel('Target Audience'),
                      _buildAudienceCheckboxes(),
                      const SizedBox(height: 24),
                      _buildStatusToggle(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.faq == null ? 'Add New FAQ' : 'Edit FAQ',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _buildEditor() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: HtmlEditor(
        controller: _htmlController,
        htmlEditorOptions: HtmlEditorOptions(
          hint: 'Enter formatted answer...',
          initialText: widget.faq?.answer,
          darkMode: true,
        ),
        htmlToolbarOptions: const HtmlToolbarOptions(
          toolbarPosition: ToolbarPosition.belowEditor,
          toolbarType: ToolbarType.nativeExpandable,
          defaultToolbarButtons: [
            FontButtons(bold: true, italic: true, underline: false, clearAll: false, strikethrough: false, superscript: false, subscript: false),
            ListButtons(ul: true, ol: true),
            InsertButtons(link: true, picture: false, audio: false, video: false, otherFile: false, table: false, hr: false),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _categories.contains(_category) ? _category : _categories.first,
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white),
      decoration: _inputDeco(''),
      items: [
        ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
        const DropdownMenuItem(value: 'new', child: Text('+ Create New Category', style: TextStyle(color: Color(0xFF3B82F6)))),
      ],
      onChanged: (v) {
        if (v == 'new') {
          // Logic for new category
        } else {
          setState(() => _category = v!);
        }
      },
    );
  }

  Widget _buildAudienceCheckboxes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: _audiences.map((a) {
          final isSelected = _targetAudience.contains(a);
          return CheckboxListTile(
            title: Text(a, style: const TextStyle(color: Colors.white, fontSize: 14)),
            value: isSelected,
            activeColor: const Color(0xFF3B82F6),
            checkColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() {
                if (val!) {
                  _targetAudience.add(a);
                } else {
                  _targetAudience.remove(a);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isActive ? const Color(0xFF3B82F6).withOpacity(0.05) : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isActive ? const Color(0xFF3B82F6).withOpacity(0.2) : Colors.white10),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isActive ? 'PUBLISHED' : 'DRAFT', style: TextStyle(color: _isActive ? const Color(0xFF3B82F6) : Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(_isActive ? 'Visible to all users' : 'Hidden from apps', style: const TextStyle(color: Colors.white24, fontSize: 12)),
            ],
          ),
          const Spacer(),
          Switch(
            value: _isActive,
            activeColor: const Color(0xFF3B82F6),
            onChanged: (v) => setState(() => _isActive = v),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              : Text(widget.faq == null ? 'CREATE FAQ' : 'SAVE CHANGES', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white10),
      filled: true,
      fillColor: Colors.white.withOpacity(0.03),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}
