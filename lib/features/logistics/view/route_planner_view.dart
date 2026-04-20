import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../../../core/widgets/api_error_handler.dart';
import '../data/repositories/logistics_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class RoutePlannerView extends StatefulWidget {
  const RoutePlannerView({super.key});
  @override
  State<RoutePlannerView> createState() => _RoutePlannerViewState();
}

class _RoutePlannerViewState extends SafeState<RoutePlannerView> {
  final LogisticsRepository _repo = LogisticsRepository();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _routes = [];
  String? _statusFilter;

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
      final routes = await _repo.getRoutes(status: _statusFilter);
      if (!mounted) {
        return;
      }
      setState(() {
        _routes = routes;
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
            title: 'Route Planner',
            subtitle: 'View and manage optimized delivery routes.',
            actionButton: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: _loadData,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 16),

          Row(
            children: [
              for (final f in [
                null,
                'PLANNED',
                'IN_PROGRESS',
                'COMPLETED',
                'CANCELLED',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    selected: _statusFilter == f,
                    label: Text(
                      _labelizeStatus(f ?? 'ALL'),
                      style: TextStyle(
                        color: _statusFilter == f
                            ? Colors.white
                            : Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    selectedColor: const Color(0xFF3B82F6),
                    backgroundColor: const Color(0xFF1E293B),
                    onSelected: (_) {
                      _statusFilter = f;
                      _loadData();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide.none,
                    ),
                  ),
                ),
            ],
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorState()
                : _routes.isEmpty
                ? Center(
                    child: Text(
                      'No routes found',
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _routes.length,
                    itemBuilder: (ctx, i) => _routeCard(_routes[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _routeCard(Map<String, dynamic> route, int index) {
    final status = route['status'] ?? 'PLANNED';
    final totalStops = route['total_stops'] ?? 0;
    final completedStops = route['completed_stops'] ?? 0;
    final progress = totalStops > 0 ? completedStops / totalStops : 0.0;
    final stops = List<Map<String, dynamic>>.from(
      (route['stops'] as List?)?.map((s) => s as Map<String, dynamic>) ?? [],
    );

    final statusColor =
        {
          'PLANNED': const Color(0xFF3B82F6),
          'IN_PROGRESS': const Color(0xFFF59E0B),
          'COMPLETED': const Color(0xFF22C55E),
          'CANCELLED': const Color(0xFFEF4444),
        }[status] ??
        Colors.white54;

    return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AdvancedCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.route, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route['route_name'] ?? '',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Driver: ${route['driver_name'] ?? 'Unknown'}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: _labelizeStatus(status)),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$completedStops / $totalStops stops completed',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.05,
                              ),
                              valueColor: AlwaysStoppedAnimation(statusColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    _miniInfo(
                      'Distance',
                      '${route['estimated_distance_km'] ?? 0} km',
                      Icons.straighten,
                    ),
                    const SizedBox(width: 16),
                    _miniInfo(
                      'Duration',
                      '${route['estimated_duration_minutes'] ?? 0} min',
                      Icons.timer,
                    ),
                  ],
                ),

                // Stops timeline
                if (stops.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withValues(alpha: 0.06)),
                  const SizedBox(height: 10),
                  Text(
                    'Route Stops',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: stops.map((s) {
                      final isCompleted = s['status'] == 'COMPLETED';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCompleted
                                ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCompleted
                                  ? Icons.check_circle
                                  : s['type'] == 'PICKUP'
                                  ? Icons.upload
                                  : Icons.download,
                              color: isCompleted
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF3B82F6),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${s['sequence']}. ${s['address'] ?? ''}',
                              style: TextStyle(
                                color: isCompleted
                                    ? Colors.white54
                                    : Colors.white,
                                fontSize: 10,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 + index * 80))
        .slideY(begin: 0.05);
  }

  Widget _miniInfo(String label, String value, IconData icon) => Column(
    children: [
      Icon(icon, color: Colors.white38, size: 16),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
    ],
  );

  String _friendlyError(Object error) {
    if (error is DioException) {
      return ApiErrorHandler.getReadableMessage(error);
    }
    return 'Unable to load route planner data right now.';
  }

  String _labelizeStatus(String raw) {
    return raw
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route_outlined, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unable to load route planner data.',
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
}
