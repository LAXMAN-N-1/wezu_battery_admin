import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/iot_device_model.dart';
import '../data/repositories/fleet_ops_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class IoTDashboardView extends StatefulWidget {
  const IoTDashboardView({super.key});

  @override
  State<IoTDashboardView> createState() => _IoTDashboardViewState();
}

class _IoTDashboardViewState extends SafeState<IoTDashboardView> {
  final FleetOpsRepository _repository = FleetOpsRepository();
  IoTStats? _stats;
  List<IoTDevice> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repository.getIoTStats(),
        _repository.getIoTDevices(),
      ]);
      setState(() {
        _stats = results[0] as IoTStats;
        _devices = results[1] as List<IoTDevice>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('IoT Dashboard', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Real-time telemetry, device health monitoring, and remote diagnostics.', style: TextStyle(fontSize: 16, color: Colors.white54)),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Data'),
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 32),

          if (_stats != null)
            Row(
              children: [
                Expanded(child: AdvancedCard(
                  child: _buildStatItem('Total Devices', _stats!.totalDevices.toString(), Icons.sensors, Colors.blue),
                )),
                const SizedBox(width: 16),
                Expanded(child: AdvancedCard(
                  child: _buildStatItem('Online', _stats!.onlineDevices.toString(), Icons.cloud_done, Colors.green),
                )),
                const SizedBox(width: 16),
                Expanded(child: AdvancedCard(
                  child: _buildStatItem('Critical Alerts', _stats!.activeAlerts.toString(), Icons.warning, Colors.red),
                )),
                const SizedBox(width: 16),
                Expanded(child: AdvancedCard(
                  child: _buildStatItem('Health Score', '${_stats!.healthScore}%', Icons.favorite, Colors.orange),
                )),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          
          const SizedBox(height: 32),

          Expanded(
            child: AdvancedCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('Device Fleet Status', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  Expanded(
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : AdvancedTable(
                          columns: const ['Device ID', 'Type', 'Status', 'Protocol', 'Firmware', 'Last Heartbeat', 'Actions'],
                          rows: _devices.map((d) {
                            return [
                              Text(d.deviceId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text(d.deviceType.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              StatusBadge(status: d.status.toUpperCase()),
                              Text(d.communicationProtocol.toUpperCase(), style: const TextStyle(color: Colors.white54)),
                              Text(d.firmwareVersion ?? 'v1.0.0', style: const TextStyle(color: Colors.white54)),
                              Text(d.lastHeartbeat != null ? _formatTime(d.lastHeartbeat!) : 'Never', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.terminal, color: Colors.blue, size: 20), onPressed: () => _showCommandDialog(d)),
                                  IconButton(icon: const Icon(Icons.settings, color: Colors.grey, size: 20), onPressed: () {}),
                                ],
                              ),
                            ];
                          }).toList(),
                        ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 12),
        Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.white54)),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute}';
  }

  void _showCommandDialog(IoTDevice device) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Remote Command: ${device.deviceId}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCommandOption('LOCK', Icons.lock, Colors.red, device),
            _buildCommandOption('UNLOCK', Icons.lock_open, Colors.green, device),
            _buildCommandOption('REBOOT', Icons.restart_alt, Colors.orange, device),
            _buildCommandOption('DIAGNOSTIC', Icons.analytics, Colors.blue, device),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandOption(String cmd, IconData icon, Color color, IoTDevice device) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(cmd, style: const TextStyle(color: Colors.white)),
      onTap: () async {
        final ok = await _repository.sendCommand(device.id, cmd);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ok ? 'Command Sent: $cmd' : 'Failed to send command'), backgroundColor: ok ? Colors.green : Colors.red),
          );
        }
      },
    );
  }
}
