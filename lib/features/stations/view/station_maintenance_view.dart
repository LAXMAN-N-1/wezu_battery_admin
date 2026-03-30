import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class StationMaintenanceView extends StatelessWidget {
  const StationMaintenanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Maintenance Scheduling',
      icon: Icons.build_outlined,
      description:
          'Maintenance workflows are temporarily gated while the station-management merge is normalized.',
      accentColor: Color(0xFFF59E0B),
    );
  }
}
