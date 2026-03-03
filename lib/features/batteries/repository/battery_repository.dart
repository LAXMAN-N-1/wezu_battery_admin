import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/battery_model.dart';
import 'dart:math';

final batteryRepositoryProvider = Provider<BatteryRepository>((ref) {
  return BatteryRepository();
});

class BatteryRepository {
  final List<BatteryModel> _mockBatteries = [];

  BatteryRepository() {
    _generateMockData();
  }

  void _generateMockData() {
    final random = Random();
    for (int i = 0; i < 100; i++) {
      final statusRoll = random.nextDouble();
      BatteryStatus status;
      String? stationId;
      String? userId;

      if (statusRoll < 0.6) {
        status = BatteryStatus.inStation;
        stationId = 'STN-${100 + random.nextInt(25)}';
      } else if (statusRoll < 0.9) {
        status = BatteryStatus.inUse;
        userId = 'USR-${1000 + random.nextInt(50)}';
      } else {
        status = BatteryStatus.maintenance;
      }

      _mockBatteries.add(BatteryModel(
        id: 'BAT-${10000 + i}',
        serialNumber: 'SN${20240000 + i}',
        type: random.nextBool() ? 'Li-ion 2kWh' : 'Li-ion 1.5kWh',
        health: 80 + random.nextDouble() * 20,
        cycles: random.nextInt(1000),
        status: status,
        assignedStationId: stationId,
        assignedUserId: userId,
        chargeLevel: 50.0 + random.nextInt(50),
      ));
    }
  }

  Future<List<BatteryModel>> fetchBatteries({String? query, BatteryStatus? statusFilter}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    var filtered = _mockBatteries;
    
    if (query != null && query.isNotEmpty) {
      filtered = filtered.where((b) => b.serialNumber.toLowerCase().contains(query.toLowerCase())).toList();
    }
    
    if (statusFilter != null) {
      filtered = filtered.where((b) => b.status == statusFilter).toList();
    }

    return filtered;
  }

  Future<void> createBattery(BatteryModel battery) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newBattery = BatteryModel(
      id: battery.id.isEmpty ? 'BAT-${20000 + _mockBatteries.length}' : battery.id,
      serialNumber: battery.serialNumber,
      type: battery.type,
      health: battery.health,
      cycles: battery.cycles,
      status: battery.status,
      assignedStationId: battery.assignedStationId,
      assignedUserId: battery.assignedUserId,
      chargeLevel: battery.chargeLevel,
    );
    _mockBatteries.insert(0, newBattery);
  }
}
