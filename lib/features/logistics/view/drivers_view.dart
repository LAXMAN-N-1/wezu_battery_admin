import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../../../core/widgets/api_error_handler.dart';
import '../data/repositories/logistics_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class DriversView extends StatefulWidget {
  const DriversView({super.key});
  @override
  State<DriversView> createState() => _DriversViewState();
}

class _DriversViewState extends SafeState<DriversView> {
  final LogisticsRepository _repo = LogisticsRepository();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _stats = {};
  List<dynamic> _drivers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _repo.getDriverStats(),
        _repo.getDrivers(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _drivers = results[1] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Drivers',
            subtitle: 'Manage delivery fleet drivers and performance.',
            actionButton: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: _loadData,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 16),

          if (!_isLoading) ...[
            Row(
              children: [
                _stat(
                  'Total Drivers',
                  '${_stats['total_drivers'] ?? 0}',
                  Icons.people_outline,
                  const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 12),
                _stat(
                  'Online',
                  '${_stats['online_drivers'] ?? 0}',
                  Icons.circle,
                  const Color(0xFF22C55E),
                ),
                const SizedBox(width: 12),
                _stat(
                  'Offline',
                  '${_stats['offline_drivers'] ?? 0}',
                  Icons.circle_outlined,
                  Colors.white38,
                ),
                const SizedBox(width: 12),
                _stat(
                  'Avg Rating',
                  '${_stats['avg_rating'] ?? 0} ★',
                  Icons.star_outline,
                  const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 12),
                _stat(
                  'Total Deliveries',
                  '${_stats['total_deliveries'] ?? 0}',
                  Icons.delivery_dining,
                  const Color(0xFF8B5CF6),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 20),
          ],

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorState()
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.5,
                        ),
                    itemCount: _drivers.length,
                    itemBuilder: (ctx, i) => _driverCard(_drivers[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      return ApiErrorHandler.getReadableMessage(error);
    }
    return 'Unable to load drivers right now.';
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unable to load drivers.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) =>
      Expanded(
        child: AdvancedCard(
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _driverCard(Map<String, dynamic> d, int index) {
    final isOnline = d['is_online'] == true;
    final rating = (d['rating'] as num?)?.toDouble() ?? 0;
    final totalDeliveries = d['total_deliveries'] ?? 0;
    final onTime = d['on_time_deliveries'] ?? 0;
    final onTimePct = totalDeliveries > 0
        ? (onTime / totalDeliveries * 100)
        : 0.0;

    return AdvancedCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(
                          0xFF3B82F6,
                        ).withValues(alpha: 0.1),
                        child: Text(
                          (d['name'] ?? 'D')[0].toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF3B82F6),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFF22C55E)
                                : Colors.white24,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0F172A),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d['name'] ?? 'Unknown',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${(d['vehicle_type'] ?? '').toString().toUpperCase()} • ${d['vehicle_plate'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: Colors.white.withValues(alpha: 0.06)),
              const SizedBox(height: 10),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _miniStat(
                    'Rating',
                    '${rating.toStringAsFixed(1)} ★',
                    const Color(0xFFF59E0B),
                  ),
                  _miniStat(
                    'Deliveries',
                    '$totalDeliveries',
                    const Color(0xFF3B82F6),
                  ),
                  _miniStat(
                    'On-Time',
                    '${onTimePct.toStringAsFixed(0)}%',
                    const Color(0xFF22C55E),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Rating bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: rating / 5,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation(
                    rating >= 4
                        ? const Color(0xFF22C55E)
                        : rating >= 3
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 + index * 60))
        .scale(begin: const Offset(0.95, 0.95));
  }

  Widget _miniStat(String label, String value, Color color) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
    ],
  );
}
