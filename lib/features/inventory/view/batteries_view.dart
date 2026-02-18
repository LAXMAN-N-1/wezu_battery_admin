import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/battery.dart';
import '../data/repositories/inventory_repository.dart';

class BatteriesView extends StatefulWidget {
  const BatteriesView({super.key});

  @override
  State<BatteriesView> createState() => _BatteriesViewState();
}

class _BatteriesViewState extends State<BatteriesView> {
  final InventoryRepository _repository = InventoryRepository();
  List<Battery> _batteries = [];
  bool _isLoading = true;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final batteries = await _repository.getBatteries();
      setState(() {
        _batteries = batteries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  void _sort<T>(Comparable<T> Function(Battery b) getField, int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _batteries.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return ascending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
      });
    });
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
              Text(
                'Battery Inventory',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Battery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Theme(
                      data: Theme.of(context).copyWith(
                        cardColor: const Color(0xFF1E293B),
                        dividerColor: Colors.white.withValues(alpha: 0.05),
                        textTheme: TextTheme(
                          bodySmall: GoogleFonts.inter(color: Colors.white70),
                          bodyMedium: GoogleFonts.inter(color: Colors.white70),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: DataTable(
                          sortColumnIndex: _sortColumnIndex,
                          sortAscending: _sortAscending,
                          headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.02)),
                          columns: [
                            DataColumn(
                              label: const Text('Serial Number', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              onSort: (index, ascending) => _sort((b) => b.serialNumber, index, ascending),
                            ),
                            DataColumn(
                              label: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              onSort: (index, ascending) => _sort((b) => b.status, index, ascending),
                            ),
                            DataColumn(
                              label: const Text('Location', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              onSort: (index, ascending) => _sort((b) => b.locationName, index, ascending),
                            ),
                            DataColumn(
                              label: const Text('Health', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              numeric: true,
                              onSort: (index, ascending) => _sort((b) => b.healthPercentage, index, ascending),
                            ),
                            const DataColumn(
                              label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                          rows: _batteries.map((battery) {
                            return DataRow(
                              cells: [
                                DataCell(Text(battery.serialNumber, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white))),
                                DataCell(_buildStatusBadge(battery.status)),
                                DataCell(Text(battery.locationName)),
                                DataCell(_buildHealthBar(battery.healthPercentage)),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                        onPressed: () {},
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                        onPressed: () {},
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'available':
        color = Colors.green;
        break;
      case 'rented':
        color = Colors.blue;
        break;
      case 'maintenance':
        color = Colors.orange;
        break;
      case 'retired':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHealthBar(double health) {
    Color color = health > 80 ? Colors.green : (health > 60 ? Colors.orange : Colors.red);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 50,
          child: LinearProgressIndicator(
            value: health / 100,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text('${health.toInt()}%', style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
