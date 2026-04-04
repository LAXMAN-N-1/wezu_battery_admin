import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';
import '../data/models/maintenance_event.dart';

class MaintenanceFormDialog extends StatelessWidget {
  final MaintenanceEvent? initialEvent;

  const MaintenanceFormDialog({super.key, this.initialEvent});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111827),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 480,
        child: PlaceholderScreen(
          title: initialEvent == null
              ? 'Schedule Maintenance'
              : 'Edit Maintenance',
          icon: Icons.event_note_outlined,
          description:
              'Maintenance authoring is temporarily disabled while recurring scheduling dependencies are removed from the merged admin build.',
          accentColor: const Color(0xFFF59E0B),
        ),
      ),
    );
  }
}
