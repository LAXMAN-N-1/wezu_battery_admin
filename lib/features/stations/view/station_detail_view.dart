import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_widgets.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/models/station_model.dart';
// import '../../../core/providers/station_provider.dart'; // May need for actions later

class StationDetailView extends StatelessWidget {
  final StationModel station;

  const StationDetailView({super.key, required this.station});

  @override
  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(station.name, style: GoogleFonts.outfit(color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getStatusColor(station.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _getStatusColor(station.status).withValues(alpha: 0.3)),
              ),
              child: Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(station.status),
                        color: _getStatusColor(station.status),
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: ${station.status.label}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: _getStatusColor(station.status),
                            ),
                          ),
                          Text(
                            'Last heartbeat: ${DateFormat.yMMMd().add_jm().format(station.lastHeartbeat)}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isMobile) const Spacer(),
                  if (isMobile) const SizedBox(height: 16),
                  if (station.status != StationStatus.online)
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.build, size: 16),
                      label: const Text('Schedule Maintenance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.black,
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            Flex(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Slots & Telemetry
                Container(
                  width: isMobile ? double.infinity : null,
                  constraints: isMobile ? null : const BoxConstraints(maxWidth: 700), // Limit width on large screens if using flexible 
                  child: Column(
                    children: [
                      // Slot Grid
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(title: 'Battery Slots Status'),
                            const SizedBox(height: 24),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isMobile ? 2 : 4,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.2,
                              ),
                              itemCount: station.totalSlots,
                              itemBuilder: (context, index) {
                                // Mock slot status
                                bool isAvailable = index < station.availableBatteries;
                                bool isCharging = index >= station.availableBatteries && index < (station.availableBatteries + station.chargingBatteries);
                                
                                Color slotColor;
                                IconData icon;
                                String label;

                                if (isAvailable) {
                                  slotColor = AppColors.success;
                                  icon = Icons.battery_full;
                                  label = 'Ready';
                                } else if (isCharging) {
                                  slotColor = AppColors.warning;
                                  icon = Icons.battery_charging_full;
                                  label = 'Charging';
                                } else {
                                  slotColor = AppColors.textTertiary;
                                  icon = Icons.check_box_outline_blank;
                                  label = 'Empty';
                                }

                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: slotColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Slot ${index + 1}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                                      const SizedBox(height: 8),
                                      Icon(icon, color: slotColor, size: 28),
                                      const SizedBox(height: 4),
                                      Text(label, style: TextStyle(color: slotColor, fontSize: 12, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Telemetry Charts (Placeholder for now)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(title: 'Live Telemetry'),
                            const SizedBox(height: 24),
                            isMobile
                                ? Column(
                                    children: [
                                      _buildTelemetryCard(
                                        'Temperature',
                                        '${station.temperature.toStringAsFixed(1)}°C',
                                        Icons.thermostat,
                                        station.temperature > 45 ? AppColors.error : AppColors.success,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTelemetryCard(
                                        'Power Usage',
                                        '${station.powerUsage.toStringAsFixed(1)} kW',
                                        Icons.bolt,
                                        AppColors.info,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: _buildTelemetryCard(
                                          'Temperature',
                                          '${station.temperature.toStringAsFixed(1)}°C',
                                          Icons.thermostat,
                                          station.temperature > 45 ? AppColors.error : AppColors.success,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTelemetryCard(
                                          'Power Usage',
                                          '${station.powerUsage.toStringAsFixed(1)} kW',
                                          Icons.bolt,
                                          AppColors.info,
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (!isMobile) const SizedBox(width: 24),
                if (isMobile) const SizedBox(height: 24),

                // Right Column: Info & Logs
                isMobile
                    ? Column(
                        children: [
                          _buildLocationInfo(station),
                          const SizedBox(height: 24),
                          _buildRecentLogs(station),
                        ],
                      )
                    : Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildLocationInfo(station),
                            const SizedBox(height: 24),
                            _buildRecentLogs(station),
                          ],
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(StationModel station) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Location Details'),
          const SizedBox(height: 16),
          Text(station.locationAddress, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
          const SizedBox(height: 8),
          Text('Lat: ${station.latitude.toStringAsFixed(6)}', style: const TextStyle(color: AppColors.textTertiary)),
          Text('Lng: ${station.longitude.toStringAsFixed(6)}', style: const TextStyle(color: AppColors.textTertiary)),
          const SizedBox(height: 16),
          Container(
            height: 150,
            color: AppColors.background,
            alignment: Alignment.center,
            child: const Text('Map View Placeholder', style: TextStyle(color: Colors.white24)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLogs(StationModel station) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Recent Activity'),
          const SizedBox(height: 16),
          _buildLogItem('System', 'Heartbeat received', DateTime.now().subtract(const Duration(minutes: 5))),
          _buildLogItem('User', 'Battery swapped at Slot 3', DateTime.now().subtract(const Duration(minutes: 25))),
          _buildLogItem('System', 'Temperature stabilized', DateTime.now().subtract(const Duration(hours: 2))),
          _buildLogItem('Admin', 'Remote reboot initiated', DateTime.now().subtract(const Duration(hours: 5))),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(String source, String message, DateTime time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(source, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                Text(DateFormat.jm().format(time), style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(StationStatus status) {
    switch (status) {
      case StationStatus.online: return AppColors.success;
      case StationStatus.offline: return AppColors.gray;
      case StationStatus.maintenance: return AppColors.warning;
      case StationStatus.fault: return AppColors.error;
    }
  }

  IconData _getStatusIcon(StationStatus status) {
    switch (status) {
      case StationStatus.online: return Icons.check_circle_outline;
      case StationStatus.offline: return Icons.cloud_off;
      case StationStatus.maintenance: return Icons.build_circle_outlined;
      case StationStatus.fault: return Icons.warning_amber_rounded;
    }
  }
}
