import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class StationPerformanceView extends StatelessWidget {
  final int? stationId;
  final String? stationName;

  const StationPerformanceView({super.key, this.stationId, this.stationName});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: stationName == null
          ? 'Station Performance'
          : '$stationName Performance',
      icon: Icons.trending_up_outlined,
      description:
          'Performance analytics are temporarily reduced while the merged station reporting APIs are normalized.',
      accentColor: const Color(0xFF8B5CF6),
    );
  }
}
