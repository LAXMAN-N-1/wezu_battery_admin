import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/system_health_models.dart';
import '../providers/system_health_provider.dart';
import 'components/system_health_components.dart';
import 'components/health_charts.dart';
import 'components/service_action_dialogs.dart';
import 'components/system_events_section.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class SystemHealthView extends ConsumerStatefulWidget {
  const SystemHealthView({super.key});

  @override
  ConsumerState<SystemHealthView> createState() => _SystemHealthViewState();
}

class _SystemHealthViewState extends ConsumerState<SystemHealthView> {
  // Track expanded service rows (by name)
  final Set<String> _expandedServices = {};

  // Track per-service action states
  final Map<String, _ServiceActionState> _actionStates = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(systemHealthProvider);
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final horizontalPadding = isAndroid ? 16.0 : 32.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(state),
          const SizedBox(height: 32),
          if (state.isLoading && state.data == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(64.0),
                child: CircularProgressIndicator(color: Colors.blue),
              ),
            )
          else if (state.data != null)
            _buildContent(state.data!, state.isLoading),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  HEADER
  // ──────────────────────────────────────────────
  Widget _buildHeader(SystemHealthState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'System Health',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Real-time platform infrastructure monitoring',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (state.lastUpdated != null)
                Expanded(child: LiveTimestamp(lastUpdated: state.lastUpdated!)),
              const SizedBox(width: 8),
              _buildAutoRefreshToggle(state.isAutoRefreshEnabled),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => ref.read(systemHealthProvider.notifier).fetchData(),
              icon: state.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh Now'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'System Health',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Real-time platform infrastructure monitoring',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                if (state.lastUpdated != null)
                  LiveTimestamp(lastUpdated: state.lastUpdated!),
                const SizedBox(width: 16),
                _buildAutoRefreshToggle(state.isAutoRefreshEnabled),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () => ref.read(systemHealthProvider.notifier).fetchData(),
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh Now'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildAutoRefreshToggle(bool enabled) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (enabled) const PulsingDot(),
        const SizedBox(width: 8),
        Text(
          'Auto-refresh 60s',
          style: GoogleFonts.inter(
            color: enabled ? Colors.white : Colors.white38,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Switch.adaptive(
          value: enabled,
          onChanged: (_) => ref.read(systemHealthProvider.notifier).toggleAutoRefresh(),
          activeThumbColor: Colors.green,
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  CONTENT
  // ──────────────────────────────────────────────
  Widget _buildContent(SystemHealthData data, bool isRefreshing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OverallStatusBanner(
          state: data.overallState,
          statusText: data.statusText,
        ),
        const SizedBox(height: 32),
        Builder(
          builder: (context) {
            final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
            final horizontalPadding = isAndroid ? 16.0 : 32.0;
            final availableWidth = (MediaQuery.of(context).size.width - (horizontalPadding * 2)).clamp(0.0, double.infinity);
            if (MediaQuery.of(context).size.width < 1100) {
              final cardWidth = availableWidth < 600
                  ? (availableWidth - 16) / 2
                  : (availableWidth - 32) / 3;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(width: cardWidth, child: MetricCard(title: 'CPU Usage', metric: data.cpu, type: MetricType.gauge)),
                  SizedBox(width: cardWidth, child: MetricCard(title: 'Memory (RAM)', metric: data.memory, type: MetricType.gauge)),
                  SizedBox(width: cardWidth, child: MetricCard(title: 'Disk Storage', metric: data.disk, type: MetricType.progress)),
                  SizedBox(width: cardWidth, child: MetricCard(title: 'Active Connections', metric: data.connections, type: MetricType.number)),
                  SizedBox(width: cardWidth, child: MetricCard(title: 'Uptime', metric: data.uptime, type: MetricType.number)),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: MetricCard(key: const ValueKey('cpu'), title: 'CPU Usage', metric: data.cpu, type: MetricType.gauge)),
                const SizedBox(width: 16),
                Expanded(child: MetricCard(key: const ValueKey('mem'), title: 'Memory (RAM)', metric: data.memory, type: MetricType.gauge)),
                const SizedBox(width: 16),
                Expanded(child: MetricCard(key: const ValueKey('disk'), title: 'Disk Storage', metric: data.disk, type: MetricType.progress)),
                const SizedBox(width: 16),
                Expanded(child: MetricCard(key: const ValueKey('conn'), title: 'Active Connections', metric: data.connections, type: MetricType.number)),
                const SizedBox(width: 16),
                Expanded(child: MetricCard(key: const ValueKey('uptime'), title: 'Uptime', metric: data.uptime, type: MetricType.number)),
              ],
            );
          },
        ),
        const SizedBox(height: 48),
        Text(
          'Service Status',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 1000,
                  maxWidth: max(1000.0, constraints.maxWidth),
                ),
                child: IntrinsicHeight(
                  child: _buildServiceTable(data.services),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 48),
        Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
            final isNarrow = screenWidth < 900;
            
            if (isAndroid || isNarrow) {
              return Column(
                children: [
                  ApiResponseTimeChart(data: data.apiResponseTimes),
                  const SizedBox(height: 24),
                  ErrorRateChart(data: data.errorRates),
                ],
              );
            }
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 55,
                  child: ApiResponseTimeChart(data: data.apiResponseTimes),
                ),
                const SizedBox(width: 24),
                Expanded(flex: 45, child: ErrorRateChart(data: data.errorRates)),
              ],
            );
          },
        ),
        const SizedBox(height: 48),
        SystemEventsSection(
          events: data.recentEvents,
          cacheSize: data.currentCacheSize,
          activeJobs: data.activeQueueJobs,
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  SERVICE TABLE
  // ──────────────────────────────────────────────
  Widget _buildServiceTable(List<ServiceStatus> services) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: Colors.white.withValues(alpha: 0.02),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('Service Component', style: _headerStyle()),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Status', style: _headerStyle()),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Latency', style: _headerStyle()),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Uptime %', style: _headerStyle()),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Last Incident', style: _headerStyle()),
                  ),
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('Actions', style: _headerStyle()),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white10),
            // Service rows
            ...services.map((s) => _buildServiceRow(s)),
          ],
        ),
      ),
    );
  }

  TextStyle _headerStyle() => GoogleFonts.inter(
    color: Colors.white54,
    fontWeight: FontWeight.w600,
    fontSize: 13,
  );

  Widget _buildServiceRow(ServiceStatus s) {
    final isExpanded = _expandedServices.contains(s.name);
    final actionState = _actionStates[s.name];

    List<_ActionButton> actions = [];

    Color statusColor = Colors.grey;
    String statusText = 'UNKNOWN';
    String statusIcon = '❓';

    switch (s.state) {
      case ServiceState.operational:
        statusColor = Colors.green;
        statusText = 'OPERATIONAL';
        statusIcon = '✅';
        break;
      case ServiceState.degraded:
        statusColor = Colors.orange;
        statusText = 'DEGRADED';
        statusIcon = '⚠️';
        break;
      case ServiceState.down:
        statusColor = Colors.red;
        statusText = 'DOWN';
        statusIcon = '🔴';
        break;
    }

    // Build action buttons
    actions.add(
      _ActionButton(
        'Logs',
        Icons.article_outlined,
        Colors.blue,
        () => _onLogs(s.name),
      ),
    );
    if (s.name.contains('DB') ||
        s.name.contains('PostgreSQL') ||
        s.name.contains('Broker') ||
        s.state == ServiceState.down) {
      actions.add(
        _ActionButton(
          'Restart',
          Icons.restart_alt,
          Colors.red,
          () => _onRestart(s.name),
        ),
      );
    }
    if (s.name.contains('Redis')) {
      actions.add(
        _ActionButton(
          'Flush Cache',
          Icons.delete_sweep,
          Colors.red,
          () => _onFlushCache(s.name),
        ),
      );
    }
    if (s.name.contains('API') || s.name.contains('Email')) {
      actions.add(
        _ActionButton(
          'Test Ping',
          Icons.wifi_tethering,
          Colors.cyan,
          () => _onTestPing(s.name),
        ),
      );
    }
    if (s.state == ServiceState.degraded) {
      actions.add(
        _ActionButton(
          'Verify',
          Icons.verified_outlined,
          Colors.orange,
          () => _onVerify(s.name),
        ),
      );
    }

    return Column(
      children: [
        // Main row
        InkWell(
          onTap: null, // Expansion now handled by Service Name click
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: actionState?.isRestarting == true
                  ? Colors.orange.withValues(alpha: 0.05)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                // Service name (Expansion Trigger)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => setState(() {
                          if (isExpanded) {
                            _expandedServices.remove(s.name);
                          } else {
                            _expandedServices.add(s.name);
                          }
                        }),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_right,
                              color: Colors.blue,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              s.name,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (s.details != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 26, top: 2),
                          child: Text(
                            s.details!,
                            style: GoogleFonts.inter(
                              color: Colors.white24,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                // Status
                Expanded(
                  flex: 2,
                  child: actionState?.isRestarting == true
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'RESTARTING...',
                              style: GoogleFonts.inter(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              statusIcon,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              statusText,
                              style: GoogleFonts.inter(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                ),
                // Latency
                Expanded(
                  flex: 2,
                  child: Text(
                    s.latencyMs != null ? '${s.latencyMs} ms' : 'T/O',
                    style: GoogleFonts.robotoMono(
                      color: s.latencyMs == null ? Colors.red : Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
                // Uptime
                Expanded(
                  flex: 2,
                  child: Text(
                    '${s.uptimePercentage}%',
                    style: GoogleFonts.robotoMono(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
                // Last Incident
                Expanded(
                  flex: 2,
                  child: Text(
                    s.lastIncident ?? 'None',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ),
                // Actions (3-dot menu)
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.white.withValues(alpha: 0.05),
                      ),
                      child: PopupMenuButton<VoidCallback>(
                        icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                        color: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        offset: const Offset(0, 40),
                        onSelected: (action) => action(),
                        itemBuilder: (context) => actions.map((a) {
                          return PopupMenuItem<VoidCallback>(
                            value: a.onTap,
                            height: 40,
                            child: Row(
                              children: [
                                Icon(a.icon, size: 18, color: a.color),
                                const SizedBox(width: 12),
                                Text(
                                  a.label,
                                  style: GoogleFonts.inter(
                                    color: a.color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Inline results (ping, verify) shown below the row
        if (actionState != null) _buildInlineResults(actionState),
        // Expanded detail panel
        if (isExpanded) _buildExpandedDetails(s),

        const Divider(height: 1, color: Colors.white10),
      ],
    );
  }


  // ──────────────────────────────────────────────
  //  INLINE RESULTS
  // ──────────────────────────────────────────────
  Widget _buildInlineResults(_ServiceActionState state) {
    List<Widget> results = [];

    if (state.pingLoading || state.pingResult != null) {
      results.add(
        Padding(
          padding: const EdgeInsets.only(
            left: 52,
            top: 4,
            bottom: 8,
            right: 24,
          ),
          child: PingResultCard(
            isLoading: state.pingLoading,
            latencyMs: state.pingResult,
            isSuccess: state.pingResult != null && state.pingResult! > 0,
          ),
        ),
      );
    }

    if (state.verifyLoading || state.verifyResult != null) {
      results.add(
        Padding(
          padding: const EdgeInsets.only(
            left: 52,
            top: 4,
            bottom: 8,
            right: 24,
          ),
          child: VerifyResultCard(
            serviceName: '',
            isLoading: state.verifyLoading,
            isPassing: state.verifyResult,
          ),
        ),
      );
    }

    return Column(children: results);
  }

  // ──────────────────────────────────────────────
  //  EXPANDED SERVICE DETAILS
  // ──────────────────────────────────────────────
  Widget _buildExpandedDetails(ServiceStatus s) {
    final random = Random(s.name.hashCode);
    final isDb = s.name.contains('DB') || s.name.contains('PostgreSQL') || s.name.contains('SQL');
    final isRedis = s.name.contains('Redis') || s.name.contains('Cache');

    List<_DetailMetric> metrics = [];

    if (isDb) {
      metrics = [
        _DetailMetric('Active Queries', '${10 + random.nextInt(5)}'),
        _DetailMetric('Connections', '${40 + random.nextInt(10)}'),
        _DetailMetric('Query Avg', '${5 + random.nextInt(5)} ms'),
        _DetailMetric('Row Reads/s', '${1000 + random.nextInt(500)}'),
        _DetailMetric('Cache Hit Rate', '${95 + random.nextInt(4)}%'),
        _DetailMetric('Replication Lag', '${20 + random.nextInt(10)} ms'),
      ];
    } else if (isRedis) {
      metrics = [
        _DetailMetric('Hit Rate', '${92 + random.nextInt(8)}%'),
        _DetailMetric('Memory Usage', '${256 + random.nextInt(128)} MB'),
        _DetailMetric('Keys', '${14000 + random.nextInt(3000)}'),
        _DetailMetric('Ops/sec', '${8000 + random.nextInt(4000)}'),
        _DetailMetric('Evictions', '${random.nextInt(5)}'),
      ];
    } else {
      metrics = [
        _DetailMetric('Requests/min', '${100 + random.nextInt(100)}'),
        _DetailMetric('Avg Response', '${30 + random.nextInt(60)} ms'),
        _DetailMetric('Error Rate', '${(random.nextDouble()).toStringAsFixed(2)}%'),
      ];
    }

    return Container(
      margin: const EdgeInsets.only(left: 52, right: 24, top: 4, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Metrics',
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: metrics.map((m) => _buildDetailItem(m.label, m.value)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white38,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: GoogleFonts.robotoMono(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  ACTION HANDLERS
  // ──────────────────────────────────────────────
  void _onLogs(String serviceName) {
    context.go('/audit/logs');
  }

  Future<void> _onRestart(String serviceName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RestartServiceDialog(serviceName: serviceName),
    );

    if (confirmed == true) {
      setState(() {
        _actionStates[serviceName] =
            (_actionStates[serviceName] ?? _ServiceActionState())
              ..isRestarting = true;
      });

      // Simulate restart delay
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() {
          _actionStates[serviceName]!.isRestarting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$serviceName restarted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _onFlushCache(String serviceName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FlushCacheDialog(),
    );

    if (confirmed == true) {
      setState(() {
        _actionStates[serviceName] =
            (_actionStates[serviceName] ?? _ServiceActionState())
              ..isRestarting = true;
      });

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _actionStates[serviceName]!.isRestarting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Redis cache flushed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _onTestPing(String serviceName) async {
    setState(() {
      _actionStates[serviceName] =
          (_actionStates[serviceName] ?? _ServiceActionState())
            ..pingLoading = true
            ..pingResult = null;
    });

    // Simulate network ping
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final random = Random();
      final latency = 50 + random.nextInt(300);
      setState(() {
        _actionStates[serviceName]!.pingLoading = false;
        _actionStates[serviceName]!.pingResult = latency;
      });

      // Auto-dismiss after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _actionStates[serviceName]?.pingResult = null;
          });
        }
      });
    }
  }

  Future<void> _onVerify(String serviceName) async {
    setState(() {
      _actionStates[serviceName] =
          (_actionStates[serviceName] ?? _ServiceActionState())
            ..verifyLoading = true
            ..verifyResult = null;
    });

    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _actionStates[serviceName]!.verifyLoading = false;
        _actionStates[serviceName]!.verifyResult = Random().nextBool();
      });

      // Auto-dismiss after 8 seconds
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) {
          setState(() {
            _actionStates[serviceName]?.verifyResult = null;
          });
        }
      });
    }
  }
}

// ──────────────────────────────────────────────
//  HELPER CLASSES
// ──────────────────────────────────────────────
class _ServiceActionState {
  bool isRestarting = false;
  bool pingLoading = false;
  int? pingResult;
  bool verifyLoading = false;
  bool? verifyResult;
}

class _ActionButton {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _ActionButton(this.label, this.icon, this.color, this.onTap);
}

class _DetailMetric {
  final String label;
  final String value;
  _DetailMetric(this.label, this.value);
}

// ──────────────────────────────────────────────
//  SUPPORTING WIDGETS
// ──────────────────────────────────────────────
class LiveTimestamp extends StatefulWidget {
  final DateTime lastUpdated;
  const LiveTimestamp({super.key, required this.lastUpdated});

  @override
  State<LiveTimestamp> createState() => _LiveTimestampState();
}

class _LiveTimestampState extends SafeState<LiveTimestamp> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diff = DateTime.now().difference(widget.lastUpdated);
    final seconds = diff.inSeconds;

    String timeText;
    if (seconds < 60) {
      timeText = '$seconds seconds ago';
    } else {
      final mins = diff.inMinutes;
      timeText = '$mins minute${mins > 1 ? 's' : ''} ago';
    }

    return Text(
      'Last updated: $timeText',
      style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
    );
  }
}

class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends SafeState<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.greenAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent,
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
