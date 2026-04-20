import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/rental_model.dart';
import '../data/repositories/rental_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class RentalHistoryView extends StatefulWidget {
  const RentalHistoryView({super.key});

  @override
  State<RentalHistoryView> createState() => _RentalHistoryViewState();
}

class _RentalHistoryViewState extends SafeState<RentalHistoryView> {
  final RentalRepository _repository = RentalRepository();
  List<Rental> _history = [];
  List<Rental> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all';
  Rental? _selectedRental;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final history = await _repository.getRentalHistory(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
    setState(() {
      _history = history;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    _filtered = _history.where((r) {
      if (_statusFilter != 'all' &&
          r.status.toLowerCase() != _statusFilter.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final completed = _history
        .where((r) => r.status.toUpperCase() == 'COMPLETED')
        .length;
    final overdue = _history
        .where((r) => r.status.toUpperCase() == 'OVERDUE')
        .length;
    final totalRev = _history.fold<double>(0, (s, r) => s + r.totalAmount);

    return Row(
      children: [
        Expanded(
          flex: _selectedRental != null ? 3 : 1,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: 'Rental History',
                  subtitle: 'Complete log of all rental transactions.',
                  actionButton: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                        onPressed: _loadData,
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('Export CSV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 20),

                // Stats
                Row(
                  children: [
                    _buildStat(
                      'Total Records',
                      '${_history.length}',
                      Icons.history_outlined,
                      const Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 12),
                    _buildStat(
                      'Completed',
                      '$completed',
                      Icons.check_circle_outline,
                      const Color(0xFF22C55E),
                    ),
                    const SizedBox(width: 12),
                    _buildStat(
                      'Overdue',
                      '$overdue',
                      Icons.warning_amber_outlined,
                      const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 12),
                    _buildStat(
                      'Revenue',
                      '₹${NumberFormat('#,##0').format(totalRev)}',
                      Icons.currency_rupee_outlined,
                      const Color(0xFF8B5CF6),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                const SizedBox(height: 20),

                // Filters
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        onChanged: (v) {
                          _searchQuery = v;
                          _loadData();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by rental ID, user...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white38,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ...['all', 'COMPLETED', 'OVERDUE', 'CANCELLED'].map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: FilterChip(
                          selected: _statusFilter == s,
                          label: Text(
                            s == 'all'
                                ? 'All'
                                : s[0] + s.substring(1).toLowerCase(),
                            style: TextStyle(
                              color: _statusFilter == s
                                  ? Colors.white
                                  : Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          selectedColor: const Color(0xFF3B82F6),
                          backgroundColor: const Color(0xFF1E293B),
                          checkmarkColor: Colors.white,
                          onSelected: (_) => setState(() {
                            _statusFilter = s;
                            _applyFilters();
                          }),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Colors.transparent),
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
                const SizedBox(height: 20),

                Expanded(
                  child: AdvancedCard(
                    padding: EdgeInsets.zero,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No history found.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : AdvancedTable(
                            columns: const [
                              'ID',
                              'User',
                              'Battery',
                              'Start',
                              'End',
                              'Amount',
                              'Status',
                            ],
                            rows: _filtered
                                .map(
                                  (r) => [
                                    Text(
                                      '#${r.id}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      r.userName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'BAT_${r.batteryId}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      DateFormat(
                                        'MMM dd HH:mm',
                                      ).format(r.startTime),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      r.endTime != null
                                          ? DateFormat(
                                              'MMM dd HH:mm',
                                            ).format(r.endTime!)
                                          : '—',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '₹${r.totalAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Color(0xFF22C55E),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    StatusBadge(status: r.status),
                                  ],
                                )
                                .toList(),
                            onRowTap: (i) =>
                                setState(() => _selectedRental = _filtered[i]),
                          ),
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
              ],
            ),
          ),
        ),
        if (_selectedRental != null)
          Container(
            width: 360,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(left: BorderSide(color: Colors.white12)),
            ),
            child: _buildDetailPanel(_selectedRental!),
          ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2),
      ],
    );
  }

  Widget _buildDetailPanel(Rental r) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rental #${r.id}',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => setState(() => _selectedRental = null),
              ),
            ],
          ),
          const SizedBox(height: 4),
          StatusBadge(status: r.status),
          const Divider(color: Colors.white12, height: 32),
          _infoRow('User', r.userName),
          _infoRow('Battery', 'BAT_${r.batteryId}'),
          _infoRow('Station', 'Station #${r.startStationId}'),
          _infoRow(
            'Start',
            DateFormat('MMM dd, yyyy HH:mm').format(r.startTime),
          ),
          _infoRow(
            'Expected End',
            DateFormat('MMM dd, yyyy HH:mm').format(r.expectedEndTime),
          ),
          if (r.endTime != null)
            _infoRow(
              'Actual End',
              DateFormat('MMM dd, yyyy HH:mm').format(r.endTime!),
            ),
          const Divider(color: Colors.white12, height: 24),
          _infoRow('Amount', '₹${r.totalAmount.toStringAsFixed(2)}'),
          _infoRow('Deposit', '₹${r.securityDeposit.toStringAsFixed(2)}'),
          _infoRow('Battery Level', '${(r.batteryLevel ?? 0).toInt()}%'),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BATTERY LEVEL',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white38,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (r.batteryLevel ?? 0) / 100,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(
                      (r.batteryLevel ?? 0) > 60
                          ? const Color(0xFF22C55E)
                          : (r.batteryLevel ?? 0) > 30
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFEF4444),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: AdvancedCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
