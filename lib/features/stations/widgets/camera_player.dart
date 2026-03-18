import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/models/station.dart';

class CameraPlayer extends StatelessWidget {
  final Station station;

  const CameraPlayer({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final cameraCount = station.cameras.length;

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
            Icons.videocam_off_outlined,
            color: Colors.white.withValues(alpha: 0.65),
            size: 30,
          ),
          const SizedBox(height: 12),
          Text(
            cameraCount == 0
                ? 'No camera feeds configured for this station.'
                : '$cameraCount camera feeds are configured but hidden until the merged monitoring stack is stabilized.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
