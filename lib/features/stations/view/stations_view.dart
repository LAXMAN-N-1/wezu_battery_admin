import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/station.dart';
import '../data/repositories/station_repository.dart';

class StationsView extends ConsumerStatefulWidget {
  const StationsView({super.key});

  @override
  ConsumerState<StationsView> createState() => _StationsViewState();
}

class _StationsViewState extends ConsumerState<StationsView> {
  final TextEditingController _searchController = TextEditingController();

  List<Station> _stations = const [];
  Map<String, dynamic> _stats = const {};
  bool _isLoading = true;
  String _searchQuery = '';
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final repository = ref.read(stationRepositoryProvider);

    try {
      final results = await Future.wait([
        repository.getStations(),
        repository.getStationStats(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _stations = results[0] as List<Station>;
        _stats = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  List<Station> get _visibleStations {
    return _stations.where((station) {
      final matchesSearch = _searchQuery.isEmpty
          ? true
          : [
              station.name,
              station.address,
              station.city ?? '',
              station.stationType,
            ].join(' ').toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _filterStatus == null
          ? true
          : station.status.toLowerCase() == _filterStatus!.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 1100;
    final stations = _visibleStations;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isCompact),
            _buildControlBar(isCompact),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildStationsPanel(stations, isCompact),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Stations',
            subtitle:
                'Monitor live station health, battery availability, and uptime.',
          ),
          Align(alignment: Alignment.centerLeft, child: _buildRefreshButton()),
        ],
      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.04);
    }

    return PageHeader(
      title: 'Stations',
      subtitle:
          'Monitor live station health, battery availability, and uptime.',
      actionButton: _buildRefreshButton(),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.04);
  }

  Widget _buildControlBar(bool isCompact) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: isCompact ? double.infinity : 320,
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by station, city, or address',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _filterStatus,
              dropdownColor: const Color(0xFF111827),
              style: GoogleFonts.inter(color: Colors.white),
              hint: const Text(
                'All statuses',
                style: TextStyle(color: Colors.white70),
              ),
              items: const [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All statuses'),
                ),
                DropdownMenuItem<String?>(
                  value: 'operational',
                  child: Text('Operational'),
                ),
                DropdownMenuItem<String?>(
                  value: 'maintenance',
                  child: Text('Maintenance'),
                ),
                DropdownMenuItem<String?>(
                  value: 'offline',
                  child: Text('Offline'),
                ),
                DropdownMenuItem<String?>(
                  value: 'active',
                  child: Text('Active'),
                ),
              ],
              onChanged: (value) => setState(() => _filterStatus = value),
            ),
          ),
        ),
        if (_searchQuery.isNotEmpty || _filterStatus != null)
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _filterStatus = null;
              });
            },
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Clear filters'),
          ),
      ],
    ).animate().fadeIn(duration: 350.ms, delay: 60.ms);
  }

  Widget _buildStatsGrid() {
    final avgRating = ((_stats['avg_rating'] as num?) ?? 0).toDouble();

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _StationStatCard(
          label: 'Total stations',
          value: '${_stats['total_stations'] ?? _stations.length}',
          icon: Icons.ev_station_outlined,
          accent: const Color(0xFF3B82F6),
        ),
        _StationStatCard(
          label: 'Operational',
          value: '${_stats['operational'] ?? 0}',
          icon: Icons.check_circle_outline,
          accent: const Color(0xFF22C55E),
        ),
        _StationStatCard(
          label: 'Maintenance',
          value: '${_stats['maintenance'] ?? 0}',
          icon: Icons.build_outlined,
          accent: const Color(0xFFF59E0B),
        ),
        _StationStatCard(
          label: 'Offline',
          value: '${_stats['offline'] ?? 0}',
          icon: Icons.cloud_off_outlined,
          accent: const Color(0xFFEF4444),
        ),
        _StationStatCard(
          label: 'Average rating',
          value: avgRating.toStringAsFixed(1),
          icon: Icons.star_outline,
          accent: const Color(0xFF8B5CF6),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 120.ms);
  }

  Widget _buildStationsPanel(List<Station> stations, bool isCompact) {
    return AdvancedCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Text(
                  '${stations.length} stations visible',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (stations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 56),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 42,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No stations match the current filters.',
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else if (isCompact)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: stations
                    .map(
                      (station) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCompactStationCard(station),
                      ),
                    )
                    .toList(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: AdvancedTable(
                columns: const [
                  'Station',
                  'Status',
                  'Inventory',
                  'Heartbeat',
                  'Type',
                  'Details',
                ],
                rows: stations.map(_buildTableRow).toList(),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms, delay: 180.ms).slideY(begin: 0.03);
  }

  List<Widget> _buildTableRow(Station station) {
    final lastSeen = DateFormat(
      'dd MMM, HH:mm',
    ).format(station.lastHeartbeat ?? station.lastPing);

    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            station.name,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            station.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: StatusBadge(status: station.statusDisplay),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${station.availableBatteries} batteries',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${station.availableSlots}/${station.totalSlots} slots open',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
      Text(
        lastSeen,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      Text(
        _titleCase(station.stationType),
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => _showDetails(station),
          icon: const Icon(Icons.visibility_outlined, size: 16),
          label: const Text('View'),
        ),
      ),
    ];
  }

  Widget _buildCompactStationCard(Station station) {
    final lastSeen = DateFormat(
      'dd MMM, HH:mm',
    ).format(station.lastHeartbeat ?? station.lastPing);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      station.address,
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(status: station.statusDisplay),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoPill(
                icon: Icons.inventory_2_outlined,
                label: '${station.availableBatteries} batteries',
              ),
              _InfoPill(
                icon: Icons.space_dashboard_outlined,
                label:
                    '${station.availableSlots}/${station.totalSlots} slots open',
              ),
              _InfoPill(
                icon: Icons.place_outlined,
                label: station.city ?? 'City unavailable',
              ),
              _InfoPill(
                icon: Icons.star_outline,
                label: station.rating > 0
                    ? station.rating.toStringAsFixed(1)
                    : 'Unrated',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Last heartbeat: $lastSeen',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showDetails(station),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return FilledButton.tonalIcon(
      onPressed: _loadData,
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('Refresh'),
    );
  }

  void _showDetails(Station station) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          station.name,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Address', station.address),
              _detailRow('City', station.city ?? 'Not provided'),
              _detailRow('Status', station.statusDisplay),
              _detailRow('Type', _titleCase(station.stationType)),
              _detailRow(
                'Batteries available',
                '${station.availableBatteries}',
              ),
              _detailRow(
                'Open slots',
                '${station.availableSlots}/${station.totalSlots}',
              ),
              _detailRow(
                'Last heartbeat',
                DateFormat(
                  'dd MMM yyyy, HH:mm',
                ).format(station.lastHeartbeat ?? station.lastPing),
              ),
              if (station.contactPhone != null)
                _detailRow('Contact', station.contactPhone!),
              if (station.powerRatingKw != null)
                _detailRow('Power', '${station.powerRatingKw} kW'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _StationStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _StationStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: AdvancedCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}
