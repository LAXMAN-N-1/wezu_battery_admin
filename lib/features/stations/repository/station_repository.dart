import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../core/models/station_model.dart';

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  return StationRepository();
});

class StationRepository {
  final List<StationModel> _mockStations = [];

  StationRepository() {
    _generateMockStations();
  }

  void _generateMockStations() {
    final random = Random();
    final areas = ['Downtown', 'Westside', 'North Hills', 'Harbor Point', 'Tech Park', 'Central Station', 'Mall Area', 'University District', 'Airport Rd', 'Industrial Zone'];
    
    for (int i = 0; i < 25; i++) {
      final statusRoll = random.nextDouble();
      StationStatus status;
      if (statusRoll > 0.9) {
        status = StationStatus.fault;
      } else if (statusRoll > 0.8) {
        status = StationStatus.maintenance;
      } else if (statusRoll > 0.7) {
        status = StationStatus.offline;
      } else {
        status = StationStatus.online;
      }

      _mockStations.add(StationModel(
        id: 'STN-${100 + i}',
        name: '${areas[i % areas.length]} Station ${i + 1}',
        locationAddress: '${100 + random.nextInt(900)} ${areas[i % areas.length]} Ave',
        latitude: 12.9716 + (random.nextDouble() - 0.5) * 0.1,
        longitude: 77.5946 + (random.nextDouble() - 0.5) * 0.1,
        status: status,
        totalSlots: 12,
        availableBatteries: random.nextInt(10),
        chargingBatteries: random.nextInt(5),
        emptySlots: random.nextInt(3),
        temperature: 25.0 + random.nextDouble() * 15,
        powerUsage: 5.0 + random.nextDouble() * 10,
        lastHeartbeat: DateTime.now().subtract(Duration(minutes: random.nextInt(60))),
        dailySwaps: random.nextInt(50),
      ));
    }
  }

  Future<List<StationModel>> fetchStations({String? query, StationStatus? statusFilter, bool? ascending, String? sortBy}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    var filtered = _mockStations;
    
    if (query != null && query.isNotEmpty) {
      filtered = filtered.where((s) => s.name.toLowerCase().contains(query.toLowerCase())).toList();
    }
    if (statusFilter != null) {
      filtered = filtered.where((s) => s.status == statusFilter).toList();
    }
    if (ascending != null && sortBy != null) {
      filtered.sort((a, b) {
        // Simple sort logic
        return ascending ? 1 : -1;
      });
    }

    return filtered;
  }

  Future<StationModel?> fetchStationDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      return _mockStations.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> fetchStationStats() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      'total': _mockStations.length,
      'active': _mockStations.where((s) => s.status == StationStatus.online).length,
      'faulty': _mockStations.where((s) => s.status == StationStatus.fault).length,
      'total_swaps_today': _mockStations.fold(0, (sum, s) => sum + s.dailySwaps),
    };
  }
}
