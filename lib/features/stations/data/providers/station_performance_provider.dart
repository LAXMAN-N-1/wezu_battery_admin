import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/station_performance.dart';
import 'stations_provider.dart';

part 'station_performance_provider.g.dart';

@riverpod
Future<StationPerformance> stationPerformance(
  StationPerformanceRef ref, {
  required int stationId,
  DateTime? start,
  DateTime? end,
}) async {
  final repo = ref.watch(stationRepositoryProvider);
  return await repo.getStationPerformance(stationId, start: start, end: end);
}

@riverpod
Future<List<StationRanking>> stationRankings(
  StationRankingsRef ref, {
  String metric = 'revenue',
  int limit = 10,
}) async {
  final repo = ref.watch(stationRepositoryProvider);
  return await repo.getStationRankings(metric: metric, limit: limit);
}

@riverpod
class PerformanceDateRange extends _$PerformanceDateRange {
  @override
  DateTimeRange build() {
    return DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
  }

  void updateRange(DateTime start, DateTime end) {
    state = DateTimeRange(start: start, end: end);
  }
}
