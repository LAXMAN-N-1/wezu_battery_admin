import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/api/api_client.dart';
import '../models/station.dart';
import '../repositories/station_repository.dart';
import 'station_status_provider.dart';

part 'stations_provider.g.dart';

@riverpod
StationRepository stationRepository(Ref ref) {
  final apiClient = ref.read(apiClientProvider);
  return StationRepository(apiClient);
}

@riverpod
class Stations extends _$Stations {
  @override
  FutureOr<List<Station>> build() async {
    // Watch maintenance schedules so this provider rebuilds when one starts/ends
    final maintenanceSchedules = ref.watch(maintenanceProvider);

    // Core polling logic: refresh every 30 seconds
    final timer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(() => timer.cancel());

    final baseStations = await _fetchStations();

    // Map stations to reflect active maintenance schedules in real-time
    return baseStations.map((s) {
      final ms = maintenanceSchedules[s.id];
      if (ms != null && ms.isActive && s.status != 'maintenance') {
        return s.copyWith(status: 'maintenance');
      }
      return s;
    }).toList();
  }

  Future<List<Station>> _fetchStations() async {
    final repo = ref.read(stationRepositoryProvider);
    return await repo.getStations();
  }

  Future<void> addStation(Station station) async {
    final currentList = state.valueOrNull ?? [];

    // Optimistically update the UI immediately
    // If the station doesn't have an ID yet, it's effectively "pending"
    // but showing it in the list removes the perceived lag.
    state = AsyncValue.data([...currentList, station]);

    try {
      final repo = ref.read(stationRepositoryProvider);
      final newStation = await repo.addStation(station);

      // Once server confirms, replace the optimistic one with the real one (with correct ID)
      final confirmedList = (state.valueOrNull ?? []).map((s) {
        // If we identify the optimistic one by name/address match if ID is 0
        if (s.id == 0 && s.name == station.name) return newStation;
        return s;
      }).toList();

      state = AsyncValue.data(confirmedList);
    } catch (e, stack) {
      // Revert to the original list on failure
      state = AsyncValue.data(currentList);
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateStation(Station station) async {
    // Optimistic update
    final currentList = state.valueOrNull ?? [];
    final index = currentList.indexWhere((s) => s.id == station.id);

    if (index != -1) {
      final newList = List<Station>.from(currentList);
      newList[index] = station;
      state = AsyncValue.data(newList);
    }

    try {
      final repo = ref.read(stationRepositoryProvider);
      await repo.updateStation(station);
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  /// Atomically sets only the status of a station.
  /// Used by the Monitor to keep station.status in sync with
  /// maintenance scheduling without needing the full Station object.
  Future<void> updateStationStatus(int stationId, String newStatus) async {
    final currentList = state.valueOrNull ?? [];
    final index = currentList.indexWhere((s) => s.id == stationId);
    if (index == -1) return;

    final updated = currentList[index].copyWith(status: newStatus);

    // Optimistic update → both Stations list and Monitor see change instantly
    final newList = List<Station>.from(currentList);
    newList[index] = updated;
    state = AsyncValue.data(newList);

    try {
      final repo = ref.read(stationRepositoryProvider);
      await repo.updateStation(updated);
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  Future<void> deleteStation(int id) async {
    // Optimistic update
    final currentList = state.valueOrNull ?? [];
    final newList = currentList.where((s) => s.id != id).toList();
    state = AsyncValue.data(newList);

    try {
      final repo = ref.read(stationRepositoryProvider);
      await repo.deleteStation(id);
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }
}
