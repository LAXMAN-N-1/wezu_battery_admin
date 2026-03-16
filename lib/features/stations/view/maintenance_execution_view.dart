import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/maintenance_checklist.dart';
import '../data/models/maintenance_event.dart';
import '../data/providers/maintenance_provider.dart';
import '../data/providers/checklist_provider.dart';

class MaintenanceExecutionView extends ConsumerStatefulWidget {
  final MaintenanceEvent event;
  final ChecklistTemplate template;

  const MaintenanceExecutionView({
    super.key,
    required this.event,
    required this.template,
  });

  @override
  ConsumerState<MaintenanceExecutionView> createState() => _MaintenanceExecutionViewState();
}

class _MaintenanceExecutionViewState extends ConsumerState<MaintenanceExecutionView> {
  late List<ChecklistTask> _tasks;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tasks = List.from(widget.template.tasks);
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index] = _tasks[index].copyWith(isCompleted: !_tasks[index].isCompleted);
    });
  }

  void _updateNote(int index, String note) {
    setState(() {
      _tasks[index] = _tasks[index].copyWith(note: note);
    });
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    
    final submission = ChecklistSubmission(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      eventId: widget.event.id,
      templateId: widget.template.id,
      templateVersion: widget.template.version,
      completedTasks: _tasks,
      submittedBy: widget.event.assignedCrew ?? 'Admin',
      submittedAt: DateTime.now(),
      isFinal: true,
    );

    await ref.read(checklistSubmissionNotifierProvider.notifier).submitChecklist(submission);
    
    // Also update the maintenance event status to completed
    final updatedEvent = widget.event.copyWith(status: MaintenanceStatus.completed);
    await ref.read(maintenanceNotifierProvider.notifier).updateEvent(updatedEvent);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maintenance Checklist Submitted Successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCompleted = _tasks.every((t) => !t.isRequired || t.isCompleted);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Perform Maintenance', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            Text(widget.event.title, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _buildTaskItem(index),
            ),
          ),
          _buildFooter(allCompleted),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.template.name,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Station: ${widget.event.stationName}',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'v${widget.template.version}',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(int index) {
    final task = _tasks[index];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: task.isCompleted ? Colors.green.withValues(alpha: 0.3) : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: (_) => _toggleTask(index),
                activeColor: Colors.green,
                side: const BorderSide(color: Colors.white24),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      task.description,
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
                    ),
                  ],
                ),
              ),
              if (task.isRequired)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text('*', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          if (task.isCompleted) ...[
            const Divider(color: Colors.white10, height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => _updateNote(index, v),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Add notes...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_a_photo, color: Colors.blueAccent, size: 20),
                  onPressed: () {
                    // Photo attachment logic would go here
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(bool ready) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.black38,
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: ready && !_isSubmitting ? _submit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSubmitting 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Complete Maintenance', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
