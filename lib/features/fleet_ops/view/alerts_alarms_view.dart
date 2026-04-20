import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/alert_model.dart';
import '../data/repositories/fleet_ops_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class AlertsAlarmsView extends StatefulWidget {
  const AlertsAlarmsView({super.key});

  @override
  State<AlertsAlarmsView> createState() => _AlertsAlarmsViewState();
}

class _AlertsAlarmsViewState extends SafeState<AlertsAlarmsView> {
  final FleetOpsRepository _repository = FleetOpsRepository();
  List<FleetAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repository.getAlerts();
      setState(() {
        _alerts = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load alerts: $e')));
    }
  }

  Future<void> _acknowledge(int id) async {
    final ok = await _repository.acknowledgeAlert(id);
    if (ok) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 1280;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alerts & Alarms',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Urgent field alerts, hardware failures, and safety violations requiring immediate attention.',
                    style: TextStyle(fontSize: 16, color: Colors.white54),
                  ),
                ],
              ),
              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, color: Colors.white70),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 32),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (isNarrow) {
                  final feedHeight = constraints.maxHeight * 0.62;
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: feedHeight.clamp(320.0, 720.0),
                            child: _buildAlertFeedCard(),
                          ),
                          const SizedBox(height: 16),
                          _buildInsightsPanel(),
                        ],
                      ),
                    ),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildAlertFeedCard()),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        child: _buildInsightsPanel(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }

  Widget _buildAlertFeedCard() {
    return AdvancedCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Text(
                  'Active Alerts',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _alerts.length.toString(),
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _alerts.isEmpty
                ? const Center(
                    child: Text(
                      'All systems normal. No active alerts.',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.separated(
                    itemCount: _alerts.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final a = _alerts[index];
                      return _buildAlertTile(a);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsPanel() {
    return Column(
      children: [
        AdvancedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Priority Distribution',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              _buildSeverityRatio(
                'Critical',
                _countSeverity('CRITICAL'),
                Colors.red,
              ),
              _buildSeverityRatio(
                'High',
                _countSeverity('HIGH'),
                Colors.orange,
              ),
              _buildSeverityRatio(
                'Medium',
                _countSeverity('MEDIUM'),
                Colors.yellow,
              ),
              _buildSeverityRatio('Low', _countSeverity('LOW'), Colors.blue),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            children: [
              Icon(Icons.flash_on, color: Colors.blue, size: 32),
              SizedBox(height: 16),
              Text(
                'Automated Resolution',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'AI is currently monitoring 42 nodes for predictive maintenance.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertTile(FleetAlert a) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _getSeverityColor(a.severity).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getAlertIcon(a.alertType),
          color: _getSeverityColor(a.severity),
          size: 20,
        ),
      ),
      title: Text(
        a.message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        '${a.alertType} | ${_formatTime(a.createdAt)}',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: ElevatedButton(
        onPressed: () => _acknowledge(a.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white10,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 12),
        ),
        child: const Text('Acknowledge'),
      ),
    );
  }

  Widget _buildSeverityRatio(String label, int count, Color color) {
    double ratio = _alerts.isEmpty ? 0 : count / _alerts.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            color: color,
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  int _countSeverity(String s) => _alerts.where((a) => a.severity == s).length;

  Color _getSeverityColor(String s) {
    switch (s) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'LOW':
        return Colors.blue;
      default:
        return Colors.yellow;
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'OVERHEAT':
        return Icons.thermostat;
      case 'TAMPERING':
        return Icons.gpp_bad;
      case 'OFFLINE':
        return Icons.cloud_off;
      case 'POWER_FAIL':
        return Icons.power_off;
      default:
        return Icons.warning_amber;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${dt.hour}:${dt.minute.toString().padLeft(2, "0")}';
  }
}
