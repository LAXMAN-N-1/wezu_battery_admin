import 'package:frontend_admin/features/stations/data/repositories/station_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/station_alert.dart';
import '../models/charging_queue.dart';
import '../models/station_specs.dart';
import 'stations_provider.dart';

part 'station_details_provider.g.dart';

@riverpod
Future<List<BackendStationAlert>> stationAlerts(
  Ref ref,
  int stationId,
) async {
  final repo = ref.watch(stationRepositoryProvider);
  return repo.getStationAlerts(stationId);
}

class Ref {
  watch(AutoDisposeProvider<StationRepository> stationRepositoryProvider) {}
}

@riverpod
Future<ChargingQueueResponse> chargingQueue(
  Ref ref,
  int stationId,
) async {
  final repo = ref.watch(stationRepositoryProvider);
  return repo.getChargingQueue(stationId);
}

@riverpod
Future<StationSpecs> stationSpecs(
  Ref ref,
  int stationId,
) async {
  final repo = ref.watch(stationRepositoryProvider);
  return repo.getSpecs(stationId);
}
