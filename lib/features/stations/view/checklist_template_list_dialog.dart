import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/maintenance_checklist.dart';
import '../data/providers/checklist_provider.dart';
import 'checklist_template_dialog.dart';

class ChecklistTemplateListDialog extends ConsumerStatefulWidget {
  const ChecklistTemplateListDialog({super.key});

  @override
  ConsumerState<ChecklistTemplateListDialog> createState() => _ChecklistTemplateListDialogState();
}

class _ChecklistTemplateListDialogState extends ConsumerState<ChecklistTemplateListDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.checklist_rtl, color: Colors.orangeAccent, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Maintenance Checklists',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.white38,
                    indicatorColor: Colors.blue,
                    dividerColor: Colors.white10,
                    tabs: const [
                      Tab(text: 'Templates'),
                      Tab(text: 'History'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blueAccent, size: 20),
                  onPressed: () {
                    if (_tabController.index == 0) {
                      ref.invalidate(checklistTemplateNotifierProvider);
                    } else {
                      ref.invalidate(checklistSubmissionNotifierProvider);
                    }
                  },
                  tooltip: 'Refresh list',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TemplatesTab(),
                  _HistoryTab(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white38)),
                ),
                const SizedBox(width: 16),
                ValueListenableBuilder<int>(
                  valueListenable: _tabController.indexIsChanging ? ValueNotifier(0) : ValueNotifier(_tabController.index),
                  builder: (context, index, _) {
                    if (_tabController.index == 0) {
                      return ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const ChecklistTemplateDialog(),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create New Template'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplatesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(checklistTemplateNotifierProvider);

    return templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_outlined, color: Colors.white10, size: 64),
                const SizedBox(height: 16),
                Text('No templates found', style: GoogleFonts.inter(color: Colors.white38, fontSize: 16)),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => ref.invalidate(checklistTemplateNotifierProvider),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          itemCount: templates.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _TemplateCard(template: templates[index]),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading templates...', style: TextStyle(color: Colors.white38)),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load templates', style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 8),
            Text(e.toString(), style: const TextStyle(color: Colors.white24, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(checklistTemplateNotifierProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(checklistSubmissionNotifierProvider);

    return submissionsAsync.when(
      data: (submissions) {
        if (submissions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history, color: Colors.white10, size: 64),
                const SizedBox(height: 16),
                Text('No history recorded yet', style: GoogleFonts.inter(color: Colors.white38, fontSize: 16)),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => ref.invalidate(checklistSubmissionNotifierProvider),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          itemCount: submissions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _SubmissionCard(submission: submissions[index]),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading history...', style: TextStyle(color: Colors.white38)),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load history', style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 8),
            Text(e.toString(), style: const TextStyle(color: Colors.white24, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(checklistSubmissionNotifierProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatefulWidget {
  final ChecklistTemplate template;
  const _TemplateCard({required this.template});

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<_TemplateCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.assignment_outlined, color: Colors.blue, size: 24),
            ),
            title: Text(
              widget.template.name,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              '${widget.template.stationType} • ${widget.template.maintenanceType} • ${widget.template.tasks.length} tasks',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ChecklistTemplateDialog(initialTemplate: widget.template),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white38,
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.01),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.template.description.isNotEmpty) ...[
                    Text(
                      'Description',
                      style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.template.description,
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Tasks',
                    style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  ...widget.template.tasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.blueAccent, size: 16),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              if (task.description.isNotEmpty)
                                Text(
                                  task.description,
                                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubmissionCard extends StatefulWidget {
  final ChecklistSubmission submission;
  const _SubmissionCard({required this.submission});

  @override
  State<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends State<_SubmissionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            leading: const Icon(Icons.history_edu, color: Colors.greenAccent),
            title: Text(
              'Completed by ${widget.submission.submittedBy}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: Text(
              '${widget.submission.submittedAt.toString().split('.')[0]} • ${widget.submission.completedTasks.length} tasks',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white38,
              size: 20,
            ),
          ),
          if (_isExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.submission.completedTasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check, color: Colors.green, size: 14),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                      if (task.note != null)
                        Text(
                          'Note: ${task.note}',
                          style: const TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
