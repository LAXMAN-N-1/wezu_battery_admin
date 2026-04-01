import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../view/stock_levels_view.dart';
import '../view/station_stock_detail_view.dart';

class StockMapView extends ConsumerStatefulWidget {
  const StockMapView({super.key});

  @override
  ConsumerState<StockMapView> createState() => _StockMapViewState();
}

class _StockMapViewState extends ConsumerState<StockMapView> {
  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(stockStationsProvider);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: stationsAsync.when(
        data: (stations) {
          if (stations.isEmpty) {
            return const Center(
              child: Text(
                'No stations to display on map',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          final markers = stations.map((s) {
            final isCritical = s.isLowStock;
            final isWarning = s.utilizationPercentage > 85 && !isCritical;
            final hue = isCritical
                ? BitmapDescriptor.hueRed
                : (isWarning
                      ? BitmapDescriptor.hueOrange
                      : BitmapDescriptor.hueGreen);

            return Marker(
              markerId: MarkerId(s.stationId.toString()),
              position: LatLng(s.latitude, s.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(hue),
              infoWindow: InfoWindow(
                title: s.stationName,
                snippet:
                    'Available: ${s.availableCount} | Rented: ${s.rentedCount}',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          StationStockDetailView(stationId: s.stationId),
                    ),
                  );
                },
              ),
            );
          }).toSet();

          // Determine bounds to fit all stations if possible, or just use first station as center
          final center = LatLng(
            stations.first.latitude,
            stations.first.longitude,
          );

          return GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 11),
            markers: markers,
            myLocationEnabled: false,
            mapType: MapType.normal,
            // Custom map style can be added here
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Error rendering map: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
