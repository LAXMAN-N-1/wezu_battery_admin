import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/dealer.dart';
import '../data/repositories/dealer_repository.dart';

class DealerInventoryView extends StatefulWidget {
  const DealerInventoryView({super.key});

  @override
  State<DealerInventoryView> createState() => _DealerInventoryViewState();
}

class _DealerInventoryViewState extends State<DealerInventoryView> {
  final DealerRepository _repository = DealerRepository();

  List<DealerProfile> _dealers = [];
  DealerProfile? _selectedDealer;

  List<Map<String, dynamic>> _batteries = [];
  Map<String, dynamic>? _metrics;
  Map<String, dynamic>? _pagination;

  bool _loadingDealers = true;
  bool _loadingInventory = false;

  String _searchQuery = '';
  String _statusFilter = 'all';
  int _currentPage = 1;

  static const _statusOptions = [
    'all',
    'available',
    'rented',
    'maintenance',
    'charging',
    'reserved',
    'retired',
  ];

  @override
  void initState() {
    super.initState();
    _loadDealers();
  }

  Future<void> _loadDealers() async {
    setState(() => _loadingDealers = true);
    try {
      final result = await _repository.getDealers(limit: 200);
      setState(() {
        _dealers = result['dealers'] as List<DealerProfile>;
        _loadingDealers = false;
      });
    } catch (_) {
      setState(() => _loadingDealers = false);
    }
  }

  Future<void> _loadInventory() async {
    if (_selectedDealer == null) return;
    setState(() => _loadingInventory = true);
    try {
      final invResponse = await _repository.getDealerInventory(
        _selectedDealer!.id,
        page: _currentPage,
        limit: 50,
        status: _statusFilter != 'all' ? _statusFilter : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      final metricsResponse = await _repository.getDealerInventoryMetrics(_selectedDealer!.id);

      final invData = invResponse['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _batteries = List<Map<String, dynamic>>.from(invData['batteries'] ?? []);
        _pagination = invData['pagination'] as Map<String, dynamic>?;
        _metrics = metricsResponse['data'] as Map<String, dynamic>? ?? {};
        _loadingInventory = false;
      });
    } catch (_) {
      setState(() => _loadingInventory = false);
    }
  }

  void _onDealerChanged(DealerProfile? dealer) {
    setState(() {
      _selectedDealer = dealer;
      _batteries = [];
      _metrics = null;
      _pagination = null;
      _currentPage = 1;
      _searchQuery = '';
      _statusFilter = 'all';
    });
    if (dealer != null) _loadInventory();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xFF22C55E);
      case 'rented':
        return const Color(0xFF3B82F6);
      case 'maintenance':
        return const Color(0xFFF59E0B);
      case 'charging':
        return const Color(0xFF8B5CF6);
      case 'reserved':
        return const Color(0xFF06B6D4);
      case 'retired':
        return const Color(0xFFEF4444);
      default:
        return Colors.white38;
    }
  }

  Color _healthColor(double pct) {
    if (pct >= 80) return const Color(0xFF22C55E);
    if (pct >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Dealer Inventory',
            subtitle: 'Select a dealer to view their battery inventory.',
            actionButton: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: _loadInventory,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

          const SizedBox(height: 24),

          // Dealer selector
          AdvancedCard(
            child: Row(
              children: [
                const Icon(Icons.handshake_outlined, color: Color(0xFF3B82F6), size: 20),
                const SizedBox(width: 12),
                Text(
                  'Select Dealer:',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _loadingDealers
                      ? const LinearProgressIndicator()
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<DealerProfile>(
                              value: _selectedDealer,
                              hint: const Text(
                                'Choose a dealer...',
                                style: TextStyle(color: Colors.white38),
                              ),
                              dropdownColor: const Color(0xFF1E293B),
                              isExpanded: true,
                              items: _dealers.map((d) {
                                return DropdownMenuItem<DealerProfile>(
                                  value: d,
                                  child: Text(
                                    '${d.businessName} — ${d.city}',
                                    style: const TextStyle(color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: _onDealerChanged,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

          if (_selectedDealer != null) ...[
            const SizedBox(height: 24),

            // Metrics row
            if (_metrics != null)
              _buildMetricsRow().animate().fadeIn(duration: 400.ms, delay: 150.ms),

            const SizedBox(height: 24),

            // Filters
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) {
                      _searchQuery = v;
                      _currentPage = 1;
                      _loadInventory();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search serial number, model...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      dropdownColor: const Color(0xFF1E293B),
                      items: _statusOptions.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(
                            s == 'all' ? 'All Statuses' : _capitalize(s),
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        _statusFilter = v ?? 'all';
                        _currentPage = 1;
                        _loadInventory();
                      },
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

            const SizedBox(height: 24),

            // Battery table
            AdvancedCard(
              padding: EdgeInsets.zero,
              child: _loadingInventory
                  ? const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _batteries.isEmpty
                  ? const SizedBox(
                      height: 300,
                      child: Center(
                        child: Text(
                          'No batteries found for this dealer.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        AdvancedTable(
                          columns: const [
                            'Serial Number',
                            'Model',
                            'Status',
                            'Health',
                            'Charge',
                            'Station',
                          ],
                          rows: _batteries.map((b) {
                            final health = (b['health'] as Map<String, dynamic>?) ?? {};
                            final healthPct = (health['percentage'] as num?)?.toDouble() ?? 0;
                            final chargePct =
                                ((b['charge'] as Map<String, dynamic>?)?['percentage'] as num?)
                                    ?.toDouble() ??
                                0;
                            final statusStr = b['current_status']?.toString() ?? '';
                            final stationName =
                                (b['location'] as Map<String, dynamic>?)?['station_name']
                                    ?.toString() ??
                                '—';

                            return [
                              Text(
                                b['serial_number']?.toString() ?? '—',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                b['model_name']?.toString() ?? '—',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(statusStr).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _statusColor(statusStr).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  _capitalize(statusStr),
                                  style: TextStyle(
                                    color: _statusColor(statusStr),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              _buildBar(healthPct, _healthColor(healthPct)),
                              _buildBar(chargePct, const Color(0xFF3B82F6)),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.ev_station_outlined,
                                    size: 14,
                                    color: Colors.white38,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      stationName,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ];
                          }).toList(),
                        ),
                        if (_pagination != null) _buildPagination(),
                      ],
                    ),
            ).animate().fadeIn(duration: 500.ms, delay: 250.ms).slideY(begin: 0.05),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    final summary = (_metrics?['summary'] as Map<String, dynamic>?) ?? {};
    final total = summary['total_stock'] ?? 0;
    final available = summary['available'] ?? 0;
    final rented = summary['rented'] ?? 0;
    final maintenance = summary['maintenance'] ?? 0;

    return Row(
      children: [
        _metricCard('Total Batteries', total.toString(), Icons.battery_full, const Color(0xFF3B82F6)),
        const SizedBox(width: 16),
        _metricCard('Available', available.toString(), Icons.check_circle_outline, const Color(0xFF22C55E)),
        const SizedBox(width: 16),
        _metricCard('Rented', rented.toString(), Icons.directions_bike_outlined, const Color(0xFF8B5CF6)),
        const SizedBox(width: 16),
        _metricCard('Maintenance', maintenance.toString(), Icons.build_outlined, const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
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
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(double pct, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${pct.toStringAsFixed(0)}%',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    final total = (_pagination?['total'] as num?)?.toInt() ?? 0;
    final totalPages = (_pagination?['total_pages'] as num?)?.toInt() ?? 1;
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page $_currentPage of $totalPages  ($total batteries)',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white54),
                onPressed: _currentPage > 1
                    ? () {
                        _currentPage--;
                        _loadInventory();
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white54),
                onPressed: _currentPage < totalPages
                    ? () {
                        _currentPage++;
                        _loadInventory();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
