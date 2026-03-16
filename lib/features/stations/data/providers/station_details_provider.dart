import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/station_alert.dart';
import '../models/charging_queue.dart';
import 'stations_provider.dart';

part 'station_details_provider.g.dart';

@riverpod
Future<List<BackendStationAlert>> stationAlerts(
  StationAlertsRef ref,
  int stationId,
) async {
  final repo = ref.watch(stationRepositoryProvider);
  return repo.getStationAlerts(stationId);
}

@riverpod
Future<ChargingQueueResponse> chargingQueue(
  ChargingQueueRef ref,
  int stationId,
) async {
  final repo = ref.watch(stationRepositoryProvider);
  return repo.getChargingQueue(stationId);
}
