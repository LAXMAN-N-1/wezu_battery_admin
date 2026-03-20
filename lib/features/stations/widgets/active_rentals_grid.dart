import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/admin_providers.dart';

class ActiveRentalsGrid extends ConsumerWidget {
  final int stationId;

  const ActiveRentalsGrid({super.key, required this.stationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rentalsAsync = ref.watch(adminRentalsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Rentals',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Live',
                  style: GoogleFonts.inter(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          rentalsAsync.when(
            data: (rentals) {
              // Filter rentals for this station
              final stationRentals = rentals.where((r) {
                return r.pickupStationId == stationId;
              }).toList();
              
              return _buildRentalTable(stationRentals);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, stack) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalTable(List<dynamic> rentals) {
    const columnWidths = {
      0: FlexColumnWidth(2),
      1: FlexColumnWidth(1.5),
      2: FlexColumnWidth(1),
      3: FlexColumnWidth(1),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sticky Header
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: Table(
            columnWidths: columnWidths,
            children: [
              TableRow(
                children: [
                  _headerCell('User ID'),
                  _headerCell('Battery'),
                  _headerCell('Start'),
                  _headerCell('Status'),
                ],
              ),
            ],
          ),
        ),
        
        // Scrollable Body
        const SizedBox(height: 8),
        if (rentals.isEmpty)
          Container(
            height: 120,
            alignment: Alignment.center,
            child: Text(
              'No active rentals at this station.',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
            ),
          )
        else
          SizedBox(
            height: 160,
            child: RawScrollbar(
              thumbColor: Colors.white24,
              radius: const Radius.circular(4),
              thickness: 4,
              child: SingleChildScrollView(
                child: Table(
                  columnWidths: columnWidths,
                  children: rentals.map((r) {
                    final timeStr = '${r.startTime.hour.toString().padLeft(2, '0')}:${r.startTime.minute.toString().padLeft(2, '0')}';

                    return TableRow(
                      children: [
                        _dataCell(r.id.toString()),
                        _dataCell(r.battery ?? '---'),
                        _dataCell(timeStr),
                        _dataCell(r.status),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _dataCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white70,
          fontSize: 12,
        ),
      ),
    );
  }
}
