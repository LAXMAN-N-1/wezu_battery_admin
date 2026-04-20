import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/repositories/support_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class TeamPerformanceView extends StatefulWidget {
  const TeamPerformanceView({super.key});

  @override
  State<TeamPerformanceView> createState() => _TeamPerformanceViewState();
}

class _TeamPerformanceViewState extends SafeState<TeamPerformanceView> {
  final SupportRepository _repository = SupportRepository();
  bool _isLoading = true;

  Map<String, dynamic> _perfData = {};
  List<DailyTrend> _trends = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final perfData = await _repository.getTeamPerformance();
      final trends = await _repository.getTeamOverviewTrends();

      setState(() {
        _perfData = perfData;
        _trends = trends;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final slaMetrics = _perfData['sla_metrics'] ?? {};
    final agents =
        (_perfData['agents'] as List?)?.cast<AgentPerformance>() ?? [];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSLAMetrics(slaMetrics),
                const SizedBox(height: 24),
                Expanded(child: _buildTrendChart()),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right Column: Agent Leaderboard
          Expanded(flex: 1, child: _buildAgentLeaderboard(agents)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return PageHeader(
      title: 'Team Performance',
      subtitle:
          'Monitor agent SLAs, CSAT scores, and support desk volume trends.',
      actionButton: ElevatedButton.icon(
        onPressed: () => _loadData(),
        icon: const Icon(Icons.refresh, size: 20, color: Colors.white),
        label: const Text(
          'Refresh Data',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildSLAMetrics(Map<String, dynamic> sla) {
    final criticalBreach = sla['critical_breach_4h'] ?? 0;
    final generalBreach = sla['general_breach_24h'] ?? 0;
    final avgFrt = sla['avg_first_response_minutes'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildSlaCard(
            title: 'Critical Breaches (>4h)',
            value: '$criticalBreach',
            icon: Icons.warning_amber,
            color: criticalBreach > 0 ? Colors.red : Colors.green,
            subtitle: 'Unanswered High priority',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSlaCard(
            title: 'General Overdue (>24h)',
            value: '$generalBreach',
            icon: Icons.timer_off_outlined,
            color: generalBreach > 5 ? Colors.orange : Colors.green,
            subtitle: 'Standard tickets aging',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSlaCard(
            title: 'Avg First Response',
            value: '${avgFrt}m',
            icon: Icons.reply_all,
            color: Colors.blueAccent,
            subtitle: 'Target: < 30m',
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildSlaCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return AdvancedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    return AdvancedCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Ticket Volume Trend (14 Days)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Created',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Resolved',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: _trends.isEmpty
                ? const Center(
                    child: Text(
                      'No trend data available.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY:
                          (_trends
                                      .map(
                                        (t) => t.created > t.resolved
                                            ? t.created
                                            : t.resolved,
                                      )
                                      .reduce((a, b) => a > b ? a : b)
                                      .toDouble() *
                                  1.5)
                              .clamp(10, 1000)
                              .toDouble(),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => Colors.blueGrey,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value < 0 || value >= _trends.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Text(
                                  _trends[value.toInt()].date,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) =>
                            const FlLine(color: Colors.white12, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _trends.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.created.toDouble(),
                              color: const Color(0xFF3B82F6),
                              width: 12,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: e.value.resolved.toDouble(),
                              color: Colors.green,
                              width: 12,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildAgentLeaderboard(List<AgentPerformance> agents) {
    return AdvancedCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Agent Leaderboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (agents.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No active agents.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: agents.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final agent = agents[index];
                  return _buildAgentCard(agent, index + 1);
                },
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideX(begin: 0.05);
  }

  Widget _buildAgentCard(AgentPerformance agent, int rank) {
    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.amber;
    } else if (rank == 2) {
      rankColor = Colors.grey[400]!;
    } else if (rank == 3) {
      rankColor = Colors.orange[800]!;
    } else {
      rankColor = Colors.white24;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank <= 3 ? rankColor.withValues(alpha: 0.3) : Colors.white12,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    color: rankColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF1E293B),
                child: Text(
                  agent.agentName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  agent.agentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.purpleAccent,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      agent.csatScore.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resolved',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    '${agent.resolved} / ${agent.totalAssigned}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Avg Resol. Time',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    '${agent.avgResolutionHours}h',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resolution Rate',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    '${agent.resolutionRate}%',
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
