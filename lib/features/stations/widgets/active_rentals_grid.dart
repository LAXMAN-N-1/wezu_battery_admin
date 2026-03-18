import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActiveRentalsGrid extends StatelessWidget {
  final int stationId;

  const ActiveRentalsGrid({super.key, required this.stationId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.electric_bolt_outlined,
            color: Colors.white.withValues(alpha: 0.7),
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            'Rental telemetry is currently disabled for station $stationId.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
