import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/audit_trail_model.dart';
import '../data/repositories/audit_trail_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class AuditTrailView extends StatefulWidget {
  const AuditTrailView({super.key});

  @override
  State<AuditTrailView> createState() => _AuditTrailViewState();
}

class _AuditTrailViewState extends SafeState<AuditTrailView> {
  final AuditTrailRepository _repository = AuditTrailRepository();
  List<AuditTrailEntry> _entries = [];
  AuditTrailStats? _stats;
  bool _isLoading = true;
  int _totalCount = 0;
  int _currentPage = 0;
  final int _pageSize = 20;
  String? _selectedActionType;
  String _searchQuery = '';
  AuditTrailEntry? _selectedEntry;

  final List<String> _actionTypes = ['transfer', 'status_change', 'manual_entry', 'disposal', 'restock', 'reassignment'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _repository.getAuditTrails(
        skip: _currentPage * _pageSize,
        limit: _pageSize,
        actionType: _selectedActionType,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      ),
      _repository.getStats(),
    ]);

    setState(() {
      final data = results[0] as Map<String, dynamic>;
      _entries = data['entries'] as List<AuditTrailEntry>;
      _totalCount = data['total_count'] as int;
      _stats = results[1] as AuditTrailStats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: _selectedEntry != null ? 3 : 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                PageHeader(
                  title: 'Inventory Audit Trail',
                  subtitle: 'Track all inventory changes — who moved what, when, and why.',
                  actionButton: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _loadData),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('Export CSV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
                const SizedBox(height: 24),

                // Stats Cards
                if (_stats != null)
                  Row(
                    children: [
                      _buildStatCard('Total Entries', _stats!.totalEntries.toString(), Icons.history, const Color(0xFF3B82F6)),
                      const SizedBox(width: 16),
                      _buildStatCard('Today', _stats!.todayCount.toString(), Icons.today_outlined, const Color(0xFF22C55E)),
                      const SizedBox(width: 16),
                      _buildStatCard('This Week', _stats!.weekCount.toString(), Icons.date_range_outlined, const Color(0xFF8B5CF6)),
                      const SizedBox(width: 16),
                      _buildStatCard('Transfers', _stats!.transfers.toString(), Icons.swap_horiz, const Color(0xFFF59E0B)),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05),
                const SizedBox(height: 24),

                // Filters Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        onChanged: (v) {
                          _searchQuery = v;
                          _currentPage = 0;
                          _loadData();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search notes...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(Icons.search, color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedActionType,
                            hint: const Text('All Actions', style: TextStyle(color: Colors.white54)),
                            dropdownColor: const Color(0xFF1E293B),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text('All Actions', style: TextStyle(color: Colors.white))),
                              ..._actionTypes.map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: Colors.white)),
                              )),
                            ],
                            onChanged: (v) {
                              setState(() => _selectedActionType = v);
                              _currentPage = 0;
                              _loadData();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
                const SizedBox(height: 24),

                // Data Table
                AdvancedCard(
                  padding: EdgeInsets.zero,
                  child: _isLoading
                    ? const SizedBox(height: 400, child: Center(child: CircularProgressIndicator()))
                    : _entries.isEmpty
                        ? const SizedBox(height: 300, child: Center(child: Text('No audit entries found.', style: TextStyle(color: Colors.white54))))
                        : Column(
                            children: [
                              AdvancedTable(
                                columns: const ['ID', 'Battery', 'Action', 'From → To', 'Actor', 'Notes', 'Time'],
                                rows: _entries.map((e) {
                                  return [
                                    Text('#${e.id}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text('BAT_${e.batteryId}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                    _buildActionBadge(e.actionType),
                                    _buildLocationFlow(e),
                                    Text(e.actorName, style: const TextStyle(color: Colors.white70)),
                                    Tooltip(
                                      message: e.notes ?? '',
                                      child: SizedBox(
                                        width: 160,
                                        child: Text(
                                          e.notes ?? '—',
                                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    Text(DateFormat('HH:mm | MMM dd').format(e.timestamp), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  ];
                                }).toList(),
                                onRowTap: (index) {
                                  setState(() => _selectedEntry = _entries[index]);
                                },
                              ),
                              // Pagination
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Showing ${_currentPage * _pageSize + 1}–${(_currentPage * _pageSize + _entries.length)} of $_totalCount',
                                      style: const TextStyle(color: Colors.white54, fontSize: 13)),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left, color: Colors.white54),
                                          onPressed: _currentPage > 0 ? () { setState(() => _currentPage--); _loadData(); } : null,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                          decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                          child: Text('Page ${_currentPage + 1}', style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right, color: Colors.white54),
                                          onPressed: (_currentPage + 1) * _pageSize < _totalCount ? () { setState(() => _currentPage++); _loadData(); } : null,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05),
              ],
            ),
          ),
        ),

        // Detail Drawer
        if (_selectedEntry != null)
          Container(
            width: 380,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(left: BorderSide(color: Colors.white12)),
            ),
            child: _buildDetailPanel(_selectedEntry!),
          ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2),
      ],
    );
  }

  Widget _buildDetailPanel(AuditTrailEntry entry) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Audit Detail', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => setState(() => _selectedEntry = null)),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailRow('Entry ID', '#${entry.id}'),
          _buildDetailRow('Battery', 'BAT_${entry.batteryId}'),
          _buildDetailRow('Action', entry.actionType.replaceAll('_', ' ').toUpperCase()),
          _buildDetailRow('Actor', entry.actorName),
          _buildDetailRow('Timestamp', DateFormat('MMM dd, yyyy HH:mm:ss').format(entry.timestamp)),
          const Divider(color: Colors.white12, height: 32),
          if (entry.fromLocationType != null) ...[
            Text('FROM', style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.fromLocationType!.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('ID: ${entry.fromLocationId}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (entry.toLocationType != null) ...[
            Text('TO', style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF22C55E), size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.toLocationType!.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('ID: ${entry.toLocationId}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (entry.notes != null) ...[
            const SizedBox(height: 24),
            Text('NOTES', style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
              child: Text(entry.notes!, style: const TextStyle(color: Colors.white70, height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: AdvancedCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(title, style: TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBadge(String type) {
    final colors = {
      'transfer': const Color(0xFF3B82F6),
      'status_change': const Color(0xFFF59E0B),
      'manual_entry': const Color(0xFF8B5CF6),
      'disposal': const Color(0xFFEF4444),
      'restock': const Color(0xFF22C55E),
      'reassignment': const Color(0xFF06B6D4),
    };
    final color = colors[type] ?? Colors.white54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(type.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLocationFlow(AuditTrailEntry e) {
    if (e.fromLocationType == null && e.toLocationType == null) {
      return const Text('—', style: TextStyle(color: Colors.white24));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (e.fromLocationType != null)
          Text('${e.fromLocationType}#${e.fromLocationId}', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11)),
        if (e.fromLocationType != null && e.toLocationType != null)
          const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, color: Colors.white24, size: 14)),
        if (e.toLocationType != null)
          Text('${e.toLocationType}#${e.toLocationId}', style: const TextStyle(color: Color(0xFF22C55E), fontSize: 11)),
      ],
    );
  }
}
