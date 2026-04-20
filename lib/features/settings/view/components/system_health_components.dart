import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/system_health_models.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class OverallStatusBanner extends StatelessWidget {
  final SystemState state;
  final String statusText;

  const OverallStatusBanner({
    super.key,
    required this.state,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    IconData icon;
    
    switch (state) {
      case SystemState.normal:
        bgColor = const Color(0xFF1B5E20); // Dark green
        icon = Icons.check_circle;
        break;
      case SystemState.degraded:
        bgColor = const Color(0xFFE65100); // Dark orange
        icon = Icons.warning_rounded;
        break;
      case SystemState.critical:
        bgColor = const Color(0xFFB71C1C); // Dark red
        icon = Icons.error;
        break;
      case SystemState.maintenance:
        bgColor = const Color(0xFF1A237E); // Dark blue
        icon = Icons.build_circle;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              statusText,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum MetricType { gauge, progress, number }

class MetricCard extends StatefulWidget {
  final String title;
  final MetricData metric;
  final MetricType type;

  const MetricCard({
    super.key,
    required this.title,
    required this.metric,
    required this.type,
  });

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends SafeState<MetricCard> {
  bool _isExpanded = false;

  Color _getColor(double percentage) {
    if (widget.title.contains('Uptime')) {
      if (percentage >= 99.9) return Colors.green;
      if (percentage >= 99.0) return Colors.orange;
      return Colors.red;
    }
    if (percentage < 60) return Colors.green;
    if (percentage < 80) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.metric.value / widget.metric.max) * 100;
    final color = _getColor(percentage);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.metric.sparkline.isNotEmpty ? () {
          setState(() => _isExpanded = !_isExpanded);
        } : null,
        borderRadius: BorderRadius.circular(16),
        hoverColor: Colors.white.withValues(alpha: 0.02),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(
            minHeight: 340,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isExpanded ? color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.05),
              width: _isExpanded ? 1.5 : 1,
            ),
            boxShadow: _isExpanded ? [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCenterVisual(color, percentage),
                    const SizedBox(height: 12),
                    if (widget.metric.subLabel.isNotEmpty && widget.type != MetricType.progress)
                      Text(
                        widget.metric.subLabel,
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    if (widget.metric.trend != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.metric.trend! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 14,
                            color: widget.metric.trend! >= 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.metric.trend!.abs()}%',
                            style: GoogleFonts.robotoMono(
                              color: widget.metric.trend! >= 0 ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Column(
                        key: const ValueKey('expanded_metric'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 16),
                          Text(
                            '24h History',
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 60,
                            child: _buildSparkline(color),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSparkline(Color color) {
    if (widget.metric.sparkline.isEmpty) return const SizedBox();
    
    final spots = widget.metric.sparkline.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterVisual(Color color, double percentage) {
    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      alignment: Alignment.center,
      child: _buildTypeVisual(color, percentage),
    );
  }

  Widget _buildTypeVisual(Color color, double percentage) {
    switch (widget.type) {
      case MetricType.gauge:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 100,
              width: 100,
              child: PieChart(
                PieChartData(
                  startDegreeOffset: 270,
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: color,
                      value: percentage,
                      title: '',
                      radius: 8,
                    ),
                    PieChartSectionData(
                      color: Colors.white.withValues(alpha: 0.05),
                      value: 100 - percentage,
                      title: '',
                      radius: 8,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.metric.label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case MetricType.progress:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.metric.label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(0)}% used',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 10,
              ),
            ),
          ],
        );
      case MetricType.number:
        final isUptime = widget.title.contains('Uptime');
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isUptime) ...[
                  Icon(
                    percentage >= 99.9
                        ? Icons.check_circle
                        : percentage >= 99.0
                            ? Icons.warning_rounded
                            : Icons.error,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.metric.label,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}
