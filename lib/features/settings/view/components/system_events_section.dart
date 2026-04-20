import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/system_health_models.dart';
import '../../providers/system_health_provider.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class SystemEventsSection extends ConsumerStatefulWidget {
  final List<SystemEvent> events;
  final String cacheSize;
  final int activeJobs;

  const SystemEventsSection({
    super.key,
    required this.events,
    required this.cacheSize,
    required this.activeJobs,
  });

  @override
  ConsumerState<SystemEventsSection> createState() => _SystemEventsSectionState();
}

class _SystemEventsSectionState extends ConsumerState<SystemEventsSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(SystemEventsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.events.length != oldWidget.events.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent System Events',
                  style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 12),
                _buildQuickActions(context, isMobile),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          height: 350,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.events.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                  itemBuilder: (context, index) {
                    return _SystemEventRow(event: widget.events[index]);
                  },
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              Padding(
                padding: const EdgeInsets.all(12),
                child: InkWell(
                  onTap: () => context.go('/audit/logs?filter=system'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('View all system logs',
                          style: GoogleFonts.inter(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 14, color: Colors.blue),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isMobile) {
    final actions = [
      OutlinedButton.icon(
        onPressed: () => _handleClearCache(context),
        icon: const Icon(Icons.cleaning_services, size: 16),
        label: const Text('Clear Application Cache'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: const BorderSide(color: Colors.orange),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      if (isMobile) const SizedBox(height: 12) else const SizedBox(width: 12),
      OutlinedButton.icon(
        key: const ValueKey('btn-restart-workers'),
        onPressed: () => _handleRestartWorkers(context),
        icon: const Icon(Icons.running_with_errors, size: 16),
        label: const Text('Restart Queue Workers'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: actions,
      );
    }

    return Row(children: actions);
  }

  Future<void> _handleClearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ClearCacheDialog(currentSize: widget.cacheSize),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(systemHealthProvider.notifier).clearCache();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application cache cleared successfully'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _handleRestartWorkers(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _RestartWorkersDialog(activeJobs: widget.activeJobs),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(systemHealthProvider.notifier).restartWorkers();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Queue workers restarted successfully'), backgroundColor: Colors.green),
        );
      }
    }
  }
}

class _SystemEventRow extends StatelessWidget {
  final SystemEvent event;
  const _SystemEventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    Color severityColor;
    IconData severityIcon;

    switch (event.severity) {
      case SystemEventSeverity.critical:
        severityColor = Colors.red;
        severityIcon = Icons.error;
        break;
      case SystemEventSeverity.warning:
        severityColor = Colors.orange;
        severityIcon = Icons.warning;
        break;
      case SystemEventSeverity.success:
        severityColor = Colors.green;
        severityIcon = Icons.check_circle;
        break;
      case SystemEventSeverity.info:
        severityColor = Colors.blue;
        severityIcon = Icons.info;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(
              DateFormat('HH:mm').format(event.timestamp),
              style: GoogleFonts.robotoMono(color: Colors.white24, fontSize: 11),
            ),
          ),
          Icon(severityIcon, size: 14, color: severityColor.withValues(alpha: 0.8)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: severityColor.withValues(alpha: 0.1)),
            ),
            child: Text(
              event.serviceName.toUpperCase(),
              style: GoogleFonts.inter(color: severityColor.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              event.description,
              style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClearCacheDialog extends StatelessWidget {
  final String currentSize;
  const _ClearCacheDialog({required this.currentSize});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text('Clear Application Cache',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This will clear all temporary application data. This might cause a slight performance dip while the cache rebuilds.',
              style: GoogleFonts.inter(color: Colors.white70)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Before', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                    Text(currentSize, style: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Icon(Icons.arrow_forward, color: Colors.orange),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('After', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                    Text('0.0 MB', style: GoogleFonts.robotoMono(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
          child: const Text('Clear Now'),
        ),
      ],
    );
  }
}

class _RestartWorkersDialog extends StatefulWidget {
  final int activeJobs;
  const _RestartWorkersDialog({required this.activeJobs});

  @override
  State<_RestartWorkersDialog> createState() => _RestartWorkersDialogState();
}

class _RestartWorkersDialogState extends SafeState<_RestartWorkersDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _canConfirm = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.red, width: 2),
      ),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 12),
          Text('Restart Queue Workers', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Restarting workers will stop all active processing. There are currently ${widget.activeJobs} active jobs in the queue.',
              style: GoogleFonts.inter(color: Colors.white70)),
          const SizedBox(height: 20),
          Text('Type RESTART WORKERS to confirm:', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            onChanged: (val) => setState(() => _canConfirm = val == 'RESTART WORKERS'),
            style: GoogleFonts.robotoMono(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              hintText: 'RESTART WORKERS',
              hintStyle: const TextStyle(color: Colors.white12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _canConfirm ? () => Navigator.pop(context, true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.red.withValues(alpha: 0.1),
          ),
          child: const Text('Restart All Workers'),
        ),
      ],
    );
  }
}
