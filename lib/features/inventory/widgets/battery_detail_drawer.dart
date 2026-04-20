import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/battery.dart';
import '../data/repositories/inventory_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class BatteryDetailDrawer extends StatefulWidget {
  final Battery battery;
  const BatteryDetailDrawer({super.key, required this.battery});

  @override
  State<BatteryDetailDrawer> createState() => _BatteryDetailDrawerState();
}

class _BatteryDetailDrawerState extends SafeState<BatteryDetailDrawer> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InventoryRepository _repository = InventoryRepository();
  List<BatteryAuditLog> _auditLogs = [];
  List<BatteryHealthHistory> _healthHistory = [];
  bool _loadingAudit = true;
  bool _loadingHealth = true;

  Battery get b => widget.battery;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    _fetchAuditLogs();
    _fetchHealthHistory();
  }

  Future<void> _fetchAuditLogs() async {
    try {
      final logs = await _repository.getBatteryAuditLogs(b.id);
      if (mounted) setState(() { _auditLogs = logs; _loadingAudit = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingAudit = false);
    }
  }

  Future<void> _fetchHealthHistory() async {
    try {
      final history = await _repository.getBatteryHealthHistory(b.id);
      if (mounted) setState(() { _healthHistory = history; _loadingHealth = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingHealth = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 520,
      color: const Color(0xFF0F172A),
      child: Column(children: [
        _buildHeroHeader(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(controller: _tabController, children: [
            _buildOverviewTab(),
            _buildHealthTrendsTab(),
            _buildAuditTrailTab(),
            _buildRentalHistoryTab(),
          ]),
        ),
      ]),
    );
  }

  // =========================================================================
  // HERO HEADER
  // =========================================================================
  Widget _buildHeroHeader() {
    final healthColor = b.healthPercentage > 80 ? const Color(0xFF22C55E) : (b.healthPercentage > 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [const Color(0xFF1E293B), const Color(0xFF0F172A).withValues(alpha: 0.9)],
        ),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white54),
          ),
          const Spacer(),
          StatusBadge(status: b.status),
        ]),
        const SizedBox(height: 16),
        Text(b.serialNumber, style: GoogleFonts.firaCode(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        if (b.manufacturer != null) ...[
          const SizedBox(height: 4),
          Text(b.manufacturer!, style: const TextStyle(color: Colors.white38, fontSize: 14)),
        ],
        const SizedBox(height: 16),
        Row(children: [
          _heroStat(Icons.favorite, '${b.healthPercentage.toInt()}%', 'Health', healthColor),
          const SizedBox(width: 20),
          _heroStat(Icons.loop, '${b.cycleCount}', 'Cycles', Colors.blueAccent),
          const SizedBox(width: 20),
          _heroStat(Icons.battery_charging_full, b.batteryType ?? '48V', 'Type', Colors.purple),
        ]),
      ]),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _heroStat(IconData icon, String value, String label, Color color) {
    return Column(children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white30, fontSize: 11)),
    ]);
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF3B82F6),
        unselectedLabelColor: Colors.white38,
        indicatorColor: const Color(0xFF3B82F6),
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Health & Trends'),
          Tab(text: 'Audit Trail'),
          Tab(text: 'Usage Log'),
        ],
      ),
    );
  }

  // =========================================================================
  // OVERVIEW TAB
  // =========================================================================
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Warranty status
        _warrantyBanner(),
        const SizedBox(height: 16),

        // Cycles + estimated life
        _cyclesCard(),
        const SizedBox(height: 16),

        // Quick actions
        Row(children: [
          Expanded(child: _quickActionBtn(Icons.build, 'Schedule Maintenance', const Color(0xFFF59E0B))),
          const SizedBox(width: 12),
          Expanded(child: _quickActionBtn(Icons.location_on, 'Change Location', const Color(0xFF3B82F6))),
        ]),
        const SizedBox(height: 24),

        _overviewGrid('Identity', {
          'Serial': b.serialNumber,
          'Battery Type': b.batteryType ?? '48V/30Ah',
          'Manufacturer': b.manufacturer ?? '—',
          'Created': _formatDate(b.createdAt),
        }),
        const SizedBox(height: 16),
        _overviewGrid('Location & Status', {
          'Location': b.locationType.replaceAll('_', ' ').toUpperCase(),
          'Sub-location': b.locationName ?? '—',
          'Last Charged': b.lastChargedAt != null ? _formatDate(b.lastChargedAt) : '—',
          'Last Inspected': b.lastInspectedAt != null ? _formatDate(b.lastInspectedAt) : '—',
        }),
        const SizedBox(height: 16),
        _overviewGrid('Lifecycle', {
          'Manufacture Date': _formatDate(b.manufactureDate),
          'Purchase Date': _formatDate(b.purchaseDate),
          'Warranty Expiry': _formatDate(b.warrantyExpiry),
          'Total Cycles': '${b.totalCycles}',
        }),
        if (b.notes != null && b.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionTitle('Notes'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12)),
            child: Text(b.notes!, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ),
        ],
      ]),
    );
  }

  Widget _warrantyBanner() {
    if (b.warrantyExpiry == null) return const SizedBox.shrink();
    final daysLeft = b.warrantyExpiry!.difference(DateTime.now()).inDays;
    final isValid = daysLeft > 0;
    final color = isValid ? (daysLeft < 30 ? Colors.amber : Colors.greenAccent) : Colors.redAccent;
    final text = isValid ? 'Warranty expires in $daysLeft days' : 'Warranty expired ${-daysLeft} days ago';
    final icon = isValid ? Icons.shield : Icons.shield_outlined;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }

  Widget _cyclesCard() {
    final estimated = b.totalCycles > 0 ? b.totalCycles : 2000;
    final remaining = (estimated - b.cycleCount).clamp(0, estimated);
    final pct = b.cycleCount / estimated;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Charge Cycles', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text('${b.cycleCount} / $estimated', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 2),
          Text('~$remaining remaining', style: TextStyle(color: Colors.greenAccent.withValues(alpha: 0.7), fontSize: 12)),
        ]),
        const Spacer(),
        SizedBox(
          width: 56, height: 56,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(pct > 0.8 ? Colors.redAccent : const Color(0xFF3B82F6)),
              strokeWidth: 5,
            ),
            Text('${(pct * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        ),
      ]),
    );
  }

  Widget _quickActionBtn(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      ]),
    );
  }

  // =========================================================================
  // HEALTH & TRENDS TAB
  // =========================================================================
  Widget _buildHealthTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Health Gauge
        Center(child: _healthGauge()),
        const SizedBox(height: 24),

        // 90-day chart
        _sectionTitle('90-Day Health Degradation'),
        const SizedBox(height: 8),
        _loadingHealth
            ? const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : _healthHistory.isEmpty
                ? _emptyChart()
                : _healthChart(),
        const SizedBox(height: 20),

        // Mini stat cards
        Row(children: [
          Expanded(child: _trendCard('Voltage', '${(b.healthPercentage * 0.48).toStringAsFixed(1)}V', Icons.bolt, Colors.amber)),
          const SizedBox(width: 10),
          Expanded(child: _trendCard('Peak Temp', '35.2°C', Icons.thermostat, Colors.orange)),
          const SizedBox(width: 10),
          Expanded(child: _trendCard('Resistance', '12mΩ', Icons.electrical_services, Colors.cyan)),
        ]),
        const SizedBox(height: 16),

        // Predicted EOL
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Row(children: [
            Icon(Icons.event, color: Colors.white.withValues(alpha: 0.3), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Predicted End-of-Life', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 2),
                Text('Based on degradation rate', style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11)),
              ]),
            ),
            Text(
              _predictEOL(),
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ]),
        ),
      ]),
    );
  }

  String _predictEOL() {
    if (_healthHistory.length < 2) return '—';
    final first = _healthHistory.first;
    final last = _healthHistory.last;
    final daysBetween = last.recordedAt.difference(first.recordedAt).inDays;
    if (daysBetween == 0) return '—';
    final ratePerDay = (first.healthPercentage - last.healthPercentage) / daysBetween;
    if (ratePerDay <= 0) return 'N/A';
    final daysRemaining = (last.healthPercentage - 20) / ratePerDay;
    final eolDate = DateTime.now().add(Duration(days: daysRemaining.toInt()));
    return DateFormat('MMM yyyy').format(eolDate);
  }

  Widget _healthGauge() {
    final health = b.healthPercentage;
    final color = health > 80 ? const Color(0xFF22C55E) : (health > 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return SizedBox(
      width: 140, height: 140,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: 140, height: 140,
          child: CircularProgressIndicator(
            value: health / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: 10,
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${health.toInt()}', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)),
          Text('Health Score', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ]),
    ).animate().scale(begin: const Offset(0.8, 0.8), duration: 600.ms, curve: Curves.elasticOut);
  }

  Widget _emptyChart() {
    return Container(
      height: 160,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text('No health data recorded yet', style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13))),
    );
  }

  Widget _healthChart() {
    // Build a simple bar chart from health history data
    final maxItems = _healthHistory.length > 30 ? 30 : _healthHistory.length;
    final items = _healthHistory.sublist(_healthHistory.length - maxItems);

    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: items.map((h) {
          final color = h.healthPercentage > 80 ? const Color(0xFF22C55E) : (h.healthPercentage > 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
          return Expanded(
            child: Tooltip(
              message: '${h.healthPercentage.toStringAsFixed(1)}% on ${DateFormat('MMM d').format(h.recordedAt)}',
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                height: (h.healthPercentage / 100) * 130,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _trendCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ]),
    );
  }

  // =========================================================================
  // AUDIT TRAIL TAB
  // =========================================================================
  Widget _buildAuditTrailTab() {
    if (_loadingAudit) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (_auditLogs.isEmpty) return _emptyState('No Audit Records', 'No changes have been logged for this battery.');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _auditLogs.length,
      separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.04), height: 1),
      itemBuilder: (context, index) {
        final log = _auditLogs[index];
        final isCreate = log.fieldChanged == 'created';
        final isDelete = log.fieldChanged == 'status' && log.newValue == 'retired';
        final dotColor = isCreate ? const Color(0xFF22C55E) : (isDelete ? const Color(0xFFEF4444) : const Color(0xFF3B82F6));

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 10, height: 10, margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor,
                boxShadow: [BoxShadow(color: dotColor.withValues(alpha: 0.3), blurRadius: 6)]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(log.fieldChanged.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.3)),
                  const Spacer(),
                  Text(_relativeTime(log.timestamp), style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11)),
                ]),
                const SizedBox(height: 4),
                if (!isCreate && log.oldValue != null && log.newValue != null)
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                      child: Text(log.oldValue!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, size: 12, color: Colors.white.withValues(alpha: 0.25))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                      child: Text(log.newValue!, style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                    ),
                  ]),
                if (isCreate)
                  Text('Battery registered: ${log.newValue}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                if (log.reason != null) ...[
                  const SizedBox(height: 4),
                  Text('Reason: ${log.reason}', style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11, fontStyle: FontStyle.italic)),
                ],
                if (log.changedBy != null) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.person, size: 12, color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(width: 4),
                    Text('Admin #${log.changedBy}', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11)),
                  ]),
                ],
              ]),
            ),
          ]),
        );
      },
    );
  }

  // =========================================================================
  // RENTAL HISTORY TAB
  // =========================================================================
  Widget _buildRentalHistoryTab() {
    return _emptyState('No Rentals Recorded', 'This battery has no rental history yet.\nRental data will appear here once the battery is assigned to a customer.');
  }

  // =========================================================================
  // HELPERS
  // =========================================================================
  Widget _overviewGrid(String title, Map<String, String> data) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(title),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: data.entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Text(e.key, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const Spacer(),
              Text(e.value, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
          )).toList(),
        ),
      ),
    ]);
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5));
  }

  String _formatDate(DateTime? d) => d != null ? DateFormat('dd MMM yyyy').format(d) : '—';

  String _relativeTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(d);
  }

  Widget _emptyState(String title, String sub) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inbox_rounded, size: 64, color: Colors.white.withValues(alpha: 0.06)),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(sub, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 13)),
      ]),
    );
  }
}
