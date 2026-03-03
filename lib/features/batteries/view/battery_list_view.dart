import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/admin_widgets.dart';
import '../../../core/providers/battery_provider.dart';
import '../../../core/models/battery_model.dart';
import 'battery_form_dialog.dart';

class BatteryListView extends ConsumerStatefulWidget {
  const BatteryListView({super.key});

  @override
  ConsumerState<BatteryListView> createState() => _BatteryListViewState();
}

class _BatteryListViewState extends ConsumerState<BatteryListView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAll(BatteryNotifier notifier) {
    _searchController.clear();
    notifier.setSearchQuery('');
    notifier.setStatusFilter(null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(batteryProvider);
    final notifier = ref.read(batteryProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 16,
            children: [
              Text(
                'Battery Management',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final newBattery = await showDialog<BatteryModel>(
                    context: context,
                    builder: (context) => const BatteryFormDialog(),
                  );
                  if (newBattery != null) {
                    notifier.addBattery(newBattery);
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Battery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Filters
          SearchFilterBar(
            controller: _searchController,
            hintText: 'Search serial number...', // Changed from searchHint
            onSearch: notifier.setSearchQuery,
            onFilterTap: () {}, // Added required argument
            activeFilters: state.statusFilter == null ? const [] : [
              FilterChip(
                label: Text(state.statusFilter!.label),
                selected: true,
                onSelected: (_) => notifier.setStatusFilter(null),
                backgroundColor: _getStatusColor(state.statusFilter!).withOpacity(0.2),
                labelStyle: TextStyle(color: _getStatusColor(state.statusFilter!), fontSize: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: _getStatusColor(state.statusFilter!)),
                ),
              ),
            ],
            onClearFilters: state.statusFilter != null || state.searchQuery.isNotEmpty 
                ? () => _clearAll(notifier) 
                : null,
          ),
          const SizedBox(height: 16),
          
          // Quick Filter Chips (Moved from filterOptions)
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: state.statusFilter == null,
                onSelected: (_) => notifier.setStatusFilter(null),
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                selectedColor: Colors.blue.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: state.statusFilter == null ? Colors.blue : Colors.white70,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: state.statusFilter == null ? Colors.blue : Colors.white10,
                  ),
                ),
              ),
              ...BatteryStatus.values.map((status) {
                final isSelected = state.statusFilter == status;
                return FilterChip(
                  label: Text(status.label),
                  selected: isSelected,
                  onSelected: (selected) => notifier.setStatusFilter(selected ? status : null),
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  selectedColor: _getStatusColor(status).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? _getStatusColor(status) : Colors.white70,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? _getStatusColor(status) : Colors.white10,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 24),

          // Data Table
          Expanded(
            child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 800),
                      child: AdminDataTable(
                        columns: const [
                          DataColumn(label: Text('Serial Number')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Health (SoH)')),
                          DataColumn(label: Text('Cycles')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Current Location')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: state.batteries.map((battery) {
                          return DataRow(cells: [
                            DataCell(Text(battery.serialNumber, style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(battery.type)),
                            DataCell(
                              Row(
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: LinearProgressIndicator(
                                      value: battery.health / 100,
                                      backgroundColor: Colors.white10,
                                      color: _getHealthColor(battery.health),
                                      minHeight: 6,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${battery.health.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            DataCell(Text(battery.cycleCount.toString())),
                            DataCell(_buildStatusBadge(battery.status)),
                            DataCell(Text(
                              battery.currentStationId ?? battery.currentUserId ?? '-',
                              style: const TextStyle(color: Colors.white54, fontFamily: 'monospace'),
                            )),
                            DataCell(Row(
                              children: [
                                IconButton(icon: const Icon(Icons.history, size: 20, color: Colors.blue), onPressed: () {}),
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(double health) {
    if (health > 90) return Colors.green;
    if (health > 70) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStatusBadge(BatteryStatus status) {
    switch (status) {
      case BatteryStatus.inStation:
        return StatusBadge(color: Colors.green, backgroundColor: Colors.green.withOpacity(0.1), label: 'In Station');
      case BatteryStatus.ready:
        return StatusBadge(color: Colors.teal, backgroundColor: Colors.teal.withOpacity(0.1), label: 'Ready');
      case BatteryStatus.inUse:
        return StatusBadge(color: Colors.blue, backgroundColor: Colors.blue.withOpacity(0.1), label: 'In Use');
      case BatteryStatus.charging:
        return StatusBadge(color: Colors.amber, backgroundColor: Colors.amber.withOpacity(0.1), label: 'Charging');
      case BatteryStatus.maintenance:
        return StatusBadge(color: Colors.orange, backgroundColor: Colors.orange.withOpacity(0.1), label: 'Maintenance');
    }
  }

  Color _getStatusColor(BatteryStatus status) {
    switch (status) {
      case BatteryStatus.inStation: return Colors.green;
      case BatteryStatus.ready: return Colors.teal;
      case BatteryStatus.inUse: return Colors.blue;
      case BatteryStatus.charging: return Colors.amber;
      case BatteryStatus.maintenance: return Colors.orange;
    }
  }
}
