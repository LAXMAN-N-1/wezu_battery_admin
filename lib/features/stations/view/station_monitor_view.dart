import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class StationMonitorView extends StatelessWidget {
  const StationMonitorView({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Station Monitor',
      icon: Icons.monitor_heart_outlined,
      description:
          'Live monitoring is hidden until the real-time station providers are fully reconciled with the merged repository layer.',
      accentColor: Color(0xFF10B981),
    );
  }
}
