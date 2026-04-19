import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/models/station_status.dart';
import '../data/providers/station_status_provider.dart';
import '../data/providers/stations_provider.dart';
import '../data/providers/station_details_provider.dart';
import 'station_performance_view.dart';

// -------------------------------------------------------
// Filter type
// -------------------------------------------------------
enum _StatusFilter { all, operational, error, maintenance, offline }

extension _StatusFilterX on _StatusFilter {
  String get label {
    switch (this) {
      case _StatusFilter.all:
        return 'All';
      case _StatusFilter.operational:
        return 'Operational';
      case _StatusFilter.error:
        return 'Error';
      case _StatusFilter.maintenance:
        return 'Maintenance';
      case _StatusFilter.offline:
        return 'Offline';
    }
  }

  Color get color {
    switch (this) {
      case _StatusFilter.all:
        return Colors.blue;
      case _StatusFilter.operational:
        return const Color(0xFF22C55E);
      case _StatusFilter.error:
        return const Color(0xFFEF4444);
      case _StatusFilter.maintenance:
        return const Color(0xFFF59E0B);
      case _StatusFilter.offline:
        return const Color(0xFF6B7280);
    }
  }
}

// -------------------------------------------------------
// Main view
// -------------------------------------------------------
class StationMonitorView extends ConsumerStatefulWidget {
  const StationMonitorView({super.key});

  @override
  ConsumerState<StationMonitorView> createState() => _StationMonitorViewState();
}

class _StationMonitorViewState extends ConsumerState<StationMonitorView>
    with SingleTickerProviderStateMixin {
  _StatusFilter _filter = _StatusFilter.all;
  StationStatusEvent? _selected;
  List<StationStatusEvent> _previous = [];

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(stationStatusStreamProvider);
    final alerts = ref.watch(alertsProvider);
    final maintenance = ref.watch(maintenanceProvider);

    // Detect new alerts on each rebuild
    statusAsync.whenData((current) {
      if (_previous.isNotEmpty) {
        ref.read(alertsProvider.notifier).processSnapshot(current, _previous);
      }
      _previous = current;
    });

    final isMobile = MediaQuery.of(context).size.width < 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Active alert banners ---
        if (alerts.isNotEmpty) _AlertBanner(alerts: alerts),

        // --- Header row ---
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Expanded(child: _buildFilterBar(statusAsync.valueOrNull ?? [])),
              const SizedBox(width: 12),
              // Live indicator
              statusAsync.when(
                data: (_) => _LivePulse(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // --- Content ---
        Expanded(
          child: statusAsync.when(
            data: (events) {
              final filtered = _applyFilter(events);
              if (isMobile) {
                return _buildGrid(filtered, maintenance);
              }
              return Row(
                children: [
                  Expanded(flex: 3, child: _buildGrid(filtered, maintenance)),
                  if (_selected != null)
                    SizedBox(
                      width: 340,
                      child: _DetailPanel(
                        event: _selected!,
                        maintenance: maintenance[_selected!.stationId],
                        onClose: () => setState(() => _selected = null),
                        onSchedule: (ms) async {
                          // 1. Save schedule to maintenanceProvider
                          await ref
                              .read(maintenanceProvider.notifier)
                              .schedule(ms);
                          // 2. If it's active now, sync the base station status to "maintenance"
                          if (ms.isActive) {
                            await ref
                                .read(stationsProvider.notifier)
                                .updateStationStatus(
                                  ms.stationId,
                                  'maintenance',
                                );
                          }
                        },
                        onCancelMaintenance: () async {
                          final stationId = _selected!.stationId;
                          final ms = maintenance[stationId];
                          if (ms != null) {
                            // 1. Remove schedule from maintenanceProvider
                            await ref
                                .read(maintenanceProvider.notifier)
                                .cancel(stationId, ms.id);
                          }
                          // 2. Revert base station status to "active"
                          await ref
                              .read(stationsProvider.notifier)
                              .updateStationStatus(stationId, 'active');
                        },
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            ),
            error: (e, _) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(List<StationStatusEvent> events) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _StatusFilter.values.map((f) {
          final count = f == _StatusFilter.all
              ? events.length
              : events.where((e) => e.status.name == f.name).length;
          final isActive = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                _filter = f;
                _selected = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? f.color.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? f.color.withValues(alpha: 0.5)
                        : Colors.white12,
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      f.label,
                      style: TextStyle(
                        color: isActive ? f.color : Colors.white54,
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? f.color.withValues(alpha: 0.2)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isActive ? f.color : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGrid(
    List<StationStatusEvent> events,
    Map<int, MaintenanceSchedule> maintenance,
  ) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              'No stations match the current filter',
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        childAspectRatio: 1.25,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: events.length,
      itemBuilder: (ctx, i) {
        final ev = events[i];
        final isSelected = _selected?.stationId == ev.stationId;
        final ms = maintenance[ev.stationId];
        return _StatusCard(
          event: ev,
          maintenance: ms,
          isSelected: isSelected,
          onTap: () {
            setState(() => _selected = isSelected ? null : ev);
            if (!isSelected && MediaQuery.of(context).size.width < 900) {
              _showMobileDetail(context, ev, maintenance);
            }
          },
        );
      },
    );
  }

  void _showMobileDetail(
    BuildContext context,
    StationStatusEvent ev,
    Map<int, MaintenanceSchedule> maintenance,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: _DetailPanel(
                  event: ev,
                  maintenance: maintenance[ev.stationId],
                  onClose: () => Navigator.pop(ctx),
                  onSchedule: (ms) async {
                    await ref.read(maintenanceProvider.notifier).schedule(ms);
                    if (ms.isActive) {
                      await ref
                          .read(stationsProvider.notifier)
                          .updateStationStatus(ms.stationId, 'maintenance');
                    }
                  },
                  onCancelMaintenance: () async {
                    final ms = maintenance[ev.stationId];
                    if (ms != null) {
                      await ref
                          .read(maintenanceProvider.notifier)
                          .cancel(ev.stationId, ms.id);
                    }
                    await ref
                        .read(stationsProvider.notifier)
                        .updateStationStatus(ev.stationId, 'active');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<StationStatusEvent> _applyFilter(List<StationStatusEvent> events) {
    if (_filter == _StatusFilter.all) return events;
    return events.where((e) => e.status.name == _filter.name).toList();
  }
}

// -------------------------------------------------------
// Alert Banner
// -------------------------------------------------------
class _AlertBanner extends ConsumerWidget {
  final List<StatusAlert> alerts;
  const _AlertBanner({required this.alerts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final critical = alerts.where((a) => !a.dismissed).take(3).toList();
    if (critical.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFEF4444),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              critical.length == 1
                  ? '⚠️ ${critical.first.stationName} changed to ${critical.first.newStatus.label}'
                  : '⚠️ ${critical.length} stations have critical alerts',
              style: TextStyle(
                color: const Color(0xFFEF4444),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(alertsProvider.notifier).dismissAll(),
            child: Text(
              'Dismiss All',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------
// Live pulse indicator
// -------------------------------------------------------
class _LivePulse extends StatefulWidget {
  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _anim,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'LIVE',
          style: GoogleFonts.outfit(
            color: const Color(0xFF22C55E),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------
// Status Card
// -------------------------------------------------------
class _StatusCard extends StatefulWidget {
  final StationStatusEvent event;
  final MaintenanceSchedule? maintenance;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusCard({
    required this.event,
    required this.maintenance,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<_StatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    if (widget.event.status == StationOperationalStatus.error) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_StatusCard old) {
    super.didUpdateWidget(old);
    if (widget.event.status == StationOperationalStatus.error) {
      _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.event.status.colorValue);
    final ms = widget.maintenance;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? color.withValues(alpha: 0.12)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isSelected
                ? color.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.07),
            width: widget.isSelected ? 1.5 : 1,
          ),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Pulsing status ring
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) {
                    return Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(
                          alpha: 0.1 + 0.1 * _pulse.value,
                        ),
                        border: Border.all(
                          color: color.withValues(
                            alpha: 0.5 + 0.5 * _pulse.value,
                          ),
                          width: 2,
                        ),
                        boxShadow:
                            widget.event.status ==
                                StationOperationalStatus.error
                            ? [
                                BoxShadow(
                                  color: color.withValues(
                                    alpha: 0.3 * _pulse.value,
                                  ),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        _statusIcon(widget.event.status),
                        color: color,
                        size: 16,
                      ),
                    );
                  },
                ),
                const Spacer(),
                // Maintenance badge
                if (ms != null && ms.isActive)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🔧 Maint',
                        style: TextStyle(
                          color: const Color(0xFFF59E0B),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.event.stationName,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              widget.event.stationAddress,
              style: TextStyle(color: Colors.white38, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.event.status.label,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _relativeTime(widget.event.timestamp),
                  style: TextStyle(color: Colors.white24, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(StationOperationalStatus s) {
    switch (s) {
      case StationOperationalStatus.operational:
        return Icons.check_circle_outline;
      case StationOperationalStatus.error:
        return Icons.error_outline;
      case StationOperationalStatus.maintenance:
        return Icons.construction_outlined;
      case StationOperationalStatus.offline:
        return Icons.cloud_off_outlined;
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 10) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return DateFormat('HH:mm').format(dt);
  }
}

// -------------------------------------------------------
// Detail Panel
// -------------------------------------------------------
class _DetailPanel extends ConsumerStatefulWidget {
  final StationStatusEvent event;
  final MaintenanceSchedule? maintenance;
  final VoidCallback onClose;
  final ValueChanged<MaintenanceSchedule> onSchedule;
  final VoidCallback onCancelMaintenance;

  const _DetailPanel({
    required this.event,
    required this.maintenance,
    required this.onClose,
    required this.onSchedule,
    required this.onCancelMaintenance,
  });

  @override
  ConsumerState<_DetailPanel> createState() => _DetailPanelState();
}

class _DetailPanelState extends ConsumerState<_DetailPanel> {
  @override
  Widget build(BuildContext context) {
    final color = Color(widget.event.status.colorValue);
    final historyAsync = ref.watch(statusHistoryProvider);
    final history =
        historyAsync.valueOrNull
            ?.where((h) => h.stationId == widget.event.stationId)
            .take(8)
            .toList() ??
        [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Close + title
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.event.stationName,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white38,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            Text(
              widget.event.stationAddress,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Current status chip
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: color, size: 10),
                    const SizedBox(width: 8),
                    Text(
                      widget.event.status.label,
                      style: GoogleFonts.outfit(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${DateFormat('HH:mm:ss').format(widget.event.timestamp)}',
                      style: TextStyle(
                        color: color.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // View Performance Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StationPerformanceView(),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: const Text('View Performance Analytics'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                ),
              ),
            ),

            // Error section
            if (widget.event.status == StationOperationalStatus.error &&
                widget.event.errorMessage != null) ...[
              const SizedBox(height: 20),
              _SectionLabel(
                'Error Details',
                Icons.error_outline,
                Colors.redAccent,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  widget.event.errorMessage!,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              const SizedBox(height: 14),
              _SectionLabel(
                'Troubleshooting Steps',
                Icons.build_circle_outlined,
                Colors.orange,
              ),
              const SizedBox(height: 8),
              ...widget.event.troubleshootingSteps.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Maintenance scheduling
            _SectionLabel(
              'Maintenance',
              Icons.calendar_month_outlined,
              Colors.amber,
            ),
            const SizedBox(height: 8),

            if (widget.maintenance != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.maintenance!.isActive
                          ? '🔧 In Progress'
                          : '📅 Scheduled',
                      style: TextStyle(
                        color: const Color(0xFFF59E0B),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${DateFormat('MMM d, HH:mm').format(widget.maintenance!.startTime)} → '
                      '${DateFormat('HH:mm').format(widget.maintenance!.endTime)}',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    if (widget.maintenance!.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.maintenance!.notes,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: widget.onCancelMaintenance,
                      icon: const Icon(Icons.cancel_outlined, size: 14),
                      label: const Text('Cancel Maintenance'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: BorderSide(
                          color: Colors.redAccent.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (widget.event.status ==
                StationOperationalStatus.maintenance) ...[
              // Station is already in maintenance — no scheduling needed
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.construction_outlined,
                      color: Color(0xFFF59E0B),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Station is currently under maintenance.\nUpdate its status to schedule future maintenance.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => _showMaintenanceDialog(context),
                icon: const Icon(Icons.schedule, size: 14),
                label: const Text('Schedule Maintenance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Official Backend Alerts
            ref.watch(stationAlertsProvider(widget.event.stationId)).when(
              data: (backendAlerts) {
                if (backendAlerts.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Hardware Alerts', Icons.notification_important_outlined, Colors.redAccent),
                    const SizedBox(height: 8),
                    ...backendAlerts.map((a) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  a.severity.toUpperCase(),
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                DateFormat('HH:mm').format(a.createdAt),
                                style: const TextStyle(color: Colors.white24, fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            a.message,
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 12),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Official Charging Queue
            ref.watch(chargingQueueProvider(widget.event.stationId)).when(
              data: (queueResponse) {
                if (queueResponse.currentQueue.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Charging Queue', Icons.bolt, Colors.blue),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                '${queueResponse.currentQueue.length} Batteries',
                                style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(
                                'Capacity: ${queueResponse.capacity}',
                                style: TextStyle(color: Colors.white24, fontSize: 11),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white10, height: 16),
                          ...queueResponse.currentQueue.map((q) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '#${q.priority}',
                                      style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Battery ${q.batteryId.substring(0, 8)}...',
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: q.currentSoc / 100,
                                          minHeight: 3,
                                          backgroundColor: Colors.white10,
                                          valueColor: AlwaysStoppedAnimation(
                                            q.currentSoc > 80 ? Colors.green : Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${q.currentSoc.toInt()}%',
                                  style: GoogleFonts.jetBrainsMono(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // History timeline
            if (history.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionLabel('Status History', Icons.timeline, Colors.blue),
              const SizedBox(height: 8),
              ...history.asMap().entries.map(
                (e) => _TimelineRow(
                  event: e.value,
                  isFirst: e.key == 0,
                  isLast: e.key == history.length - 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMaintenanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _MaintenanceDialog(
        stationId: widget.event.stationId,
        onSchedule: widget.onSchedule,
      ),
    );
  }
}

// -------------------------------------------------------
// Timeline row
// -------------------------------------------------------
class _TimelineRow extends StatelessWidget {
  final StationStatusEvent event;
  final bool isFirst;
  final bool isLast;

  const _TimelineRow({
    required this.event,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(event.status.colorValue);
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Container(width: 1.5, color: Colors.white12),
                    ),
                  ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Container(width: 1.5, color: Colors.white12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event.status.label,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('HH:mm').format(event.timestamp),
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------
// Maintenance Schedule Dialog
// -------------------------------------------------------
class _MaintenanceDialog extends StatefulWidget {
  final int stationId;
  final ValueChanged<MaintenanceSchedule> onSchedule;

  const _MaintenanceDialog({required this.stationId, required this.onSchedule});

  @override
  State<_MaintenanceDialog> createState() => _MaintenanceDialogState();
}

class _MaintenanceDialogState extends State<_MaintenanceDialog> {
  DateTime _start = DateTime.now().add(const Duration(hours: 1));
  DateTime _end = DateTime.now().add(const Duration(hours: 3));
  String _type = 'Routine';
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.calendar_month, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Schedule Maintenance',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateTimeRow(
              label: 'Start Time',
              value: _start,
              onPick: (dt) => setState(() => _start = dt),
            ),
            const SizedBox(height: 12),
            _DateTimeRow(
              label: 'End Time',
              value: _end,
              onPick: (dt) => setState(() => _end = dt),
            ),
            const SizedBox(height: 12),
            Text(
              'Maintenance Type',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _type,
                  dropdownColor: const Color(0xFF1E293B),
                  isExpanded: true,
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  items: ['Routine', 'Repair', 'Upgrade', 'Inspection']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v!),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Notes (optional)',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesCtrl,
              style: TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Battery module replacement, cable inspection…',
                hintStyle: TextStyle(
                  color: Colors.white24,
                  fontSize: 12,
                ),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.white38),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSchedule(
              MaintenanceSchedule(
                stationId: widget.stationId,
                startTime: _start,
                endTime: _end,
                notes: _notesCtrl.text.trim(),
                maintenanceType: _type,
              ),
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Schedule',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPick;
  const _DateTimeRow({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
              builder: (ctx, child) =>
                  Theme(data: ThemeData.dark(), child: child!),
            );
            if (!context.mounted || date == null) return;
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(value),
              builder: (ctx, child) =>
                  Theme(data: ThemeData.dark(), child: child!),
            );
            if (time == null) return;
            onPick(
              DateTime(date.year, date.month, date.day, time.hour, time.minute),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white38, size: 16),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, yyyy  HH:mm').format(value),
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------
// Small label widget
// -------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _SectionLabel(this.text, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
