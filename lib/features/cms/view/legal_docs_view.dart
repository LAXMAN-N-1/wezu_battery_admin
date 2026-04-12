import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../../../core/widgets/glass_components.dart';
import '../data/models/legal_document.dart';
import '../provider/cms_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class LegalDocsView extends ConsumerStatefulWidget {
  const LegalDocsView({super.key});

  @override
  ConsumerState<LegalDocsView> createState() => _LegalDocsViewState();
}

class _LegalDocsViewState extends ConsumerState<LegalDocsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  LegalDocument? _historyDoc;

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(legalProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      endDrawer: _historyDoc != null ? _VersionHistoryDrawer(doc: _historyDoc!) : null,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Legal Documents',
              subtitle: 'Manage versioned legal content and push re-acceptance to users',
              actionButton: ElevatedButton.icon(
                onPressed: () => context.push('/cms/legal/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('NEW DOCUMENT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            Expanded(
              child: GlassContainer(
                padding: EdgeInsets.zero,
                child: docsAsync.when(
                  data: (docs) => _buildDocsTable(docs),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocsTable(List<LegalDocument> docs) {
    return AdvancedTable(
      columns: const ['Document Name', 'Version', 'Status', 'Last Updated', 'Updated By', 'Actions'],
      rows: docs.map((doc) => [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(doc.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text('/legal/${doc.slug}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
        Text('v${doc.version}', style: GoogleFonts.robotoMono(color: Colors.blue.shade200, fontSize: 12)),
        _statusBadge(doc.status),
        Text(DateFormat('dd MMM yyyy').format(doc.updatedAt), style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(doc.lastUpdatedBy ?? 'System', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueAccent),
              onPressed: () => context.push('/cms/legal/edit', extra: doc),
              tooltip: 'Edit Document',
            ),
            IconButton(
              icon: const Icon(Icons.history, size: 18, color: Colors.amberAccent),
              onPressed: () {
                setState(() => _historyDoc = doc);
                _scaffoldKey.currentState?.openEndDrawer();
              },
              tooltip: 'Version History',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
              onPressed: doc.status == 'DRAFT' ? () => _confirmDelete(doc) : null,
              tooltip: doc.status == 'DRAFT' ? 'Delete' : 'Archived only',
            ),
          ],
        ),
      ]).toList(),
      onRowTap: (idx) => context.push('/cms/legal/edit', extra: docs[idx]),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'PUBLISHED') color = Colors.green;
    if (status == 'DRAFT') color = Colors.amber;
    if (status == 'ARCHIVED') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), border: Border.all(color: color.withOpacity(0.2)), borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmDelete(LegalDocument doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Document', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${doc.title}"? This action cannot be undone.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              await ref.read(legalProvider.notifier).deleteDoc(doc.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _VersionHistoryDrawer extends StatelessWidget {
  final LegalDocument doc;

  const _VersionHistoryDrawer({required this.doc});

  @override
  Widget build(BuildContext context) {
    final versions = doc.history ?? [];

    return Drawer(
      width: 400,
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text('Version History', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: versions.isEmpty 
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: versions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _buildVersionCard(context, versions[index]),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionCard(BuildContext context, LegalVersion v) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('v${v.version}', style: GoogleFonts.robotoMono(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              const Spacer(),
              _chip('RESTORE', Colors.white10),
            ],
          ),
          const SizedBox(height: 8),
          Text(v.publishedBy, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(v.publishedAt),
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () {}, // Preview logic
                child: const Text('PREVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {}, // Restore logic
                style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
                child: const Text('RESTORE AS DRAFT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 48, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          const Text('No previous versions', style: TextStyle(color: Colors.white24, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

