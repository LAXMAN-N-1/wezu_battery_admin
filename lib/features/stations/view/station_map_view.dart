import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class StationMapView extends StatelessWidget {
  const StationMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Station Map',
      icon: Icons.map_outlined,
      description:
          'The map experience is being stabilized after the branch merge. The main station directory remains available.',
      accentColor: Color(0xFF14B8A6),
    );
  }
}
