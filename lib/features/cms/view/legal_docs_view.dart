import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/models/legal_document.dart';
import '../data/cms_providers.dart';
import '../../../core/widgets/admin_ui_components.dart';

class LegalDocsView extends ConsumerStatefulWidget {
  const LegalDocsView({super.key});

  @override
  ConsumerState<LegalDocsView> createState() => _LegalDocsViewState();
}

class _LegalDocsViewState extends ConsumerState<LegalDocsView> {
  @override
  Widget build(BuildContext context) {
    final legalState = ref.watch(legalListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          legalState.when(
            data: (docs) {
              if (docs.isEmpty) return _buildEmptyState();
              return _buildLegalTable(docs);
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
              'Legal & Compliance',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage terms of service, privacy policies, and user agreements',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _showEditorDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Document'),
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

  Widget _buildLegalTable(List<LegalDocument> docs) {
    return AdvancedTable(
      columns: ['Document Name', 'Slug', 'Version', 'Status', 'Last Updated', 'Actions'],
      rows: docs.map((doc) {
        return [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.description_outlined, size: 16, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Text(doc.title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          Text(doc.slug, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
            child: Text('v${doc.version}', style: GoogleFonts.robotoMono(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          doc.isActive 
            ? const StatusBadge(status: 'active')
            : const StatusBadge(status: 'draft'),
          Text(
            doc.updatedAt != null ? DateFormat('MMM d, yyyy').format(doc.updatedAt!) : 'N/A',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue), onPressed: () => _showEditorDialog(doc)),
              IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _confirmDelete(doc)),
            ],
          ),
        ];
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(64.0),
        child: Column(
          children: [
            Icon(Icons.gavel_outlined, size: 64, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text('No documents found', style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Upload legal documents to comply with regulations', style: TextStyle(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  void _showEditorDialog([LegalDocument? doc]) {
    final titleCtrl = TextEditingController(text: doc?.title);
    final slugCtrl = TextEditingController(text: doc?.slug);
    final versionCtrl = TextEditingController(text: doc?.version ?? '1.0.0');
    final contentCtrl = TextEditingController(text: doc?.content);
    bool isActive = doc?.isActive ?? true;
    bool forceUpdate = doc?.forceUpdate ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 800,
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Text(doc == null ? 'Create Document' : 'Edit Document', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
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
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Document Title', titleCtrl, 'e.g. Privacy Policy')),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('URL Slug', slugCtrl, 'e.g. privacy-policy')),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildTextField('Content (HTML Supported)', contentCtrl, 'Write your legal text here...', maxLines: 15),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Version Number', versionCtrl, 'e.g. 1.0.4')),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Status & Requirements', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                                    child: Row(
                                      children: [
                                        const Text('Active', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                        Switch(
                                          value: isActive,
                                          activeColor: Colors.blue,
                                          onChanged: (v) => setModalState(() => isActive = v),
                                        ),
                                        const Spacer(),
                                        const Text('Force Update', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                        Switch(
                                          value: forceUpdate,
                                          activeColor: Colors.redAccent,
                                          onChanged: (v) => setModalState(() => forceUpdate = v),
                                        ),
                                      ],
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
                          final data = LegalDocument(
                            id: doc?.id ?? 0,
                            title: titleCtrl.text,
                            slug: slugCtrl.text,
                            content: contentCtrl.text,
                            version: versionCtrl.text,
                            isActive: isActive,
                            forceUpdate: forceUpdate,
                            createdAt: doc?.createdAt ?? DateTime.now(),
                            updatedAt: DateTime.now(),
                          );
                          if (doc == null) {
                            await ref.read(legalRepositoryProvider).createLegalDocument(data);
                          } else {
                            await ref.read(legalRepositoryProvider).updateLegalDocument(doc.id, data);
                          }
                          ref.invalidate(legalListProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                        child: const Text('Save Document'),
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

  Widget _buildTextField(String label, TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(LegalDocument doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Document?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to permanently remove "${doc.title}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(legalListProvider.notifier).deleteLegalDoc(doc.id);
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
