import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/station_model.dart';

class StationState {
  final List<StationModel> stations;
  final bool isLoading;
  final String searchQuery;
  final StationStatus? statusFilter;
  final Map<String, int> stats;

  StationState({
    this.stations = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.statusFilter,
    this.stats = const {},
  });

  StationState copyWith({
    List<StationModel>? stations,
    bool? isLoading,
    String? searchQuery,
    StationStatus? statusFilter,
    Map<String, int>? stats,
  }) {
    return StationState(
      stations: stations ?? this.stations,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      stats: stats ?? this.stats,
    );
  }
}

final stationProvider = StateNotifierProvider<StationNotifier, StationState>((ref) {
  return StationNotifier();
});

class StationNotifier extends StateNotifier<StationState> {
  StationNotifier() : super(StationState(isLoading: true)) {
    loadStations();
  }

  Future<void> loadStats() async {
    loadStations();
  }

  Future<void> loadStations() async {
    try {
      state = state.copyWith(isLoading: true);
      
      await Future.delayed(const Duration(milliseconds: 600));
      // Mock Data
      var stations = List.generate(10, (index) {
        return StationModel(
          id: 'ST-${100 + index}',
          name: 'Station ${index + 1}',
          locationAddress: '${index * 100} Main St, City',
          latitude: 37.7749 + (index * 0.01),
          longitude: -122.4194 + (index * 0.01),
          status: StationStatus.values[index % StationStatus.values.length],
          totalSlots: 10,
          availableBatteries: 4 + (index % 3),
          chargingBatteries: 4 - (index % 3),
          temperature: 30.0 + (index % 20),
          powerUsage: 12.5 + (index % 5),
          lastHeartbeat: DateTime.now().subtract(Duration(minutes: index)),
        );
      });

      // Apply Search Filter
      if (state.searchQuery.isNotEmpty) {
        final query = state.searchQuery.toLowerCase();
        stations = stations.where((s) {
          return s.name.toLowerCase().contains(query) ||
                 s.locationAddress.toLowerCase().contains(query);
        }).toList();
      }

      // Apply Status Filter
      if (state.statusFilter != null) {
        stations = stations.where((s) => s.status == state.statusFilter).toList();
      }

      final stats = {
        'total': stations.length,
        'active': stations.where((s) => s.status == StationStatus.online).length,
        'faulty': stations.where((s) => s.status == StationStatus.fault || s.status == StationStatus.maintenance).length,
        'offline': stations.where((s) => s.status == StationStatus.offline).length,
        'total_swaps_today': 145,
      };

      state = StationState(
        stations: stations,
        isLoading: false,
        searchQuery: state.searchQuery,
        statusFilter: state.statusFilter,
        stats: stats,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadStations();
  }

  void setStatusFilter(StationStatus? status) {
    state = StationState(
      stations: state.stations,
      isLoading: state.isLoading,
      searchQuery: state.searchQuery,
      statusFilter: status,
      stats: state.stats,
    );
    loadStations();
  }
}
