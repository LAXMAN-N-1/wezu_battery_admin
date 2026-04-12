import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../../../core/widgets/glass_components.dart';
import '../data/models/legal_document.dart';
import '../provider/cms_providers.dart';

class LegalEditorView extends ConsumerStatefulWidget {
  final LegalDocument? doc;
  const LegalEditorView({super.key, this.doc});

  @override
  ConsumerState<LegalEditorView> createState() => _LegalEditorViewState();
}

class _LegalEditorViewState extends ConsumerState<LegalEditorView> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _versionController;
  late DateTime _effectiveDate;
  late bool _forceReAccept;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.doc?.title);
    _contentController = TextEditingController(text: widget.doc?.content ?? '');
    _versionController = TextEditingController(text: widget.doc?.version ?? '1.0');
    _effectiveDate = widget.doc?.effectiveDate ?? DateTime.now();
    _forceReAccept = widget.doc?.forceUpdate ?? false;
    _updateWordCount();
  }

  void _updateWordCount() {
    setState(() {
      _wordCount = _contentController.text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      child: Column(
        children: [
          _buildTopBar(),
          _buildVersionInfoBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_forceReAccept) _buildWarningCard().animate().fadeIn().slideY(begin: 0.1),
                  _buildEditorSection(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), border: Border(bottom: BorderSide(color: Colors.white10))),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white54),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Text(widget.doc == null ? 'New Legal Document' : 'Edit ${widget.doc!.title}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          OutlinedButton(
            onPressed: () => _handleSave(isDraft: true),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white24)),
            child: const Text('SAVE AS DRAFT'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _confirmPublish(),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
            child: Text(widget.doc == null ? 'PUBLISH DOCUMENT' : 'PUBLISH NEW VERSION'),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfoBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 12),
      color: Colors.blueAccent.withOpacity(0.05),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Text(
            widget.doc == null 
              ? 'Currently creating a new policy' 
              : 'Editing draft based on v${widget.doc!.version} | Last published: ${DateFormat('dd MMM yyyy').format(widget.doc!.updatedAt)}',
            style: const TextStyle(color: Colors.blueAccent, fontSize: 13),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {}, // History
            icon: const Icon(Icons.history, size: 14),
            label: const Text('View Version History', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Force Re-Acceptance Enabled', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  'Users will see a mandatory consent modal on their next login and cannot use the app until they accept this specific version.',
                  style: TextStyle(color: Colors.amber.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             Expanded(
               child: AdminTextField(
                 controller: _titleController,
                 label: 'Document Name',
                 hint: 'e.g. Terms and Conditions',
                 icon: Icons.title,
               ),
             ),
             const SizedBox(width: 24),
             SizedBox(
               width: 120,
               child: AdminTextField(
                 controller: _versionController,
                 label: 'Version',
                 hint: '1.0',
                 icon: Icons.vignette,
               ),
             ),
             const SizedBox(width: 24),
             _buildEffectiveDatePicker(),
          ],
        ),
        const SizedBox(height: 32),
        Row(
           children: [
             const Text('Policy Content', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
             const Spacer(),
             Switch(
               value: _forceReAccept,
               activeColor: Colors.amber,
               onChanged: (v) => setState(() => _forceReAccept = v),
             ),
             const Text('Force Re-acceptance', style: TextStyle(color: Colors.white54, fontSize: 12)),
           ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contentController,
          maxLines: 25,
          onChanged: (_) => _updateWordCount(),
          style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.6),
          decoration: InputDecoration(
            hintText: 'Paste or type legal content here...',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withOpacity(0.02),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildEffectiveDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Effective Date', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _effectiveDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) setState(() => _effectiveDate = date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.white54),
                const SizedBox(width: 8),
                Text(DateFormat('dd MMM yyyy').format(_effectiveDate), style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(color: Colors.black26, border: Border(top: BorderSide(color: Colors.white10))),
      child: Row(
        children: [
          Text('Word count: $_wordCount', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const Spacer(),
          const Text('Markdown Supported', style: TextStyle(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }

  Future<void> _handleSave({required bool isDraft}) async {
    if (_titleController.text.isEmpty) return;
    
    final data = {
      'title': _titleController.text,
      'slug': widget.doc?.slug ?? _titleController.text.toLowerCase().replaceAll(' ', '-'),
      'content': _contentController.text,
      'version': _versionController.text,
      'status': isDraft ? 'DRAFT' : 'PUBLISHED',
      'is_active': !isDraft,
      'force_update': _forceReAccept,
      'effective_date': _effectiveDate.toIso8601String(),
    };

    if (widget.doc == null) {
      await ref.read(legalProvider.notifier).createDoc(data);
    } else {
      await ref.read(legalProvider.notifier).updateDoc(widget.doc!.id, data);
    }

    if (mounted) context.pop();
  }

  void _confirmPublish() {
    final newVersion = _versionController.text;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Publish v$newVersion', style: const TextStyle(color: Colors.white)),
        content: Text(
          'Publishing will replace the current live version. ${_forceReAccept ? "Users will be prompted to re-accept." : ""}\n\nContinue?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleSave(isDraft: false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            child: Text('PUBLISH v$newVersion'),
          ),
        ],
      ),
    );
  }
}
