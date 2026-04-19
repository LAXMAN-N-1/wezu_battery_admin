import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/models/station.dart';
import '../data/models/station_specs.dart';
import '../data/providers/stations_provider.dart';
import '../../../core/widgets/placeholder_screen.dart';

final stationSpecsProvider = FutureProvider.autoDispose.family<StationSpecs, int>((
  ref,
  stationId,
) async {
  final repo = ref.watch(stationRepositoryProvider);
  return repo.getSpecs(stationId);
});

Future<void> showStationSpecsDialog(
  BuildContext context,
  Station station,
) async {
  await showDialog<void>(
    context: context,
    builder: (_) => StationSpecsView(station: station),
  );
}

class StationSpecsView extends ConsumerWidget {
  final Station station;

  const StationSpecsView({super.key, required this.station});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specsAsync = ref.watch(stationSpecsProvider(station.id));

    return Dialog(
      backgroundColor: const Color(0xFF111827),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 520,
        child: specsAsync.when(
          data: (specs) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${station.name} Specs',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _SpecsRow(
                  label: 'Capacity',
                  value: '${specs.maxBatteryCapacity} batteries',
                ),
                _SpecsRow(
                  label: 'Charger types',
                  value: '${specs.chargers.length} configured',
                ),
                _SpecsRow(
                  label: 'Safety features',
                  value: '${specs.safetyFeatures.length} active',
                ),
                _SpecsRow(
                  label: 'Temperature range',
                  value:
                      '${specs.minTempC.toStringAsFixed(0)}°C to ${specs.maxTempC.toStringAsFixed(0)}°C',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 280,
                  child: PlaceholderScreen(
                    title: 'Detailed specification editor',
                    icon: Icons.settings_outlined,
                    description:
                        'Detailed station-spec editing remains disabled until the merged station CRUD flows are fully restored.',
                    accentColor: const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.all(32),
            child: SizedBox(
              height: 240,
              child: PlaceholderScreen(
                title: 'Station specs unavailable',
                icon: Icons.error_outline,
                description: 'Specs data could not be loaded for this station.',
                accentColor: const Color(0xFFEF4444),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecsRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecsRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
