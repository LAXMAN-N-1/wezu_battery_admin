import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/battery_model.dart';
import 'package:flutter/material.dart'; // For Color if needed or just use logic in view

class BatteryState {
  final List<BatteryModel> batteries;
  final bool isLoading;
  final String searchQuery;
  final BatteryStatus? statusFilter;
  final Map<String, int> stats;

  BatteryState({
    this.batteries = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.statusFilter,
    this.stats = const {},
  });

  BatteryState copyWith({
    List<BatteryModel>? batteries,
    bool? isLoading,
    String? searchQuery,
    BatteryStatus? statusFilter,
    Map<String, int>? stats,
  }) {
    return BatteryState(
      batteries: batteries ?? this.batteries,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      stats: stats ?? this.stats,
    );
  }
}

final batteryProvider = StateNotifierProvider<BatteryNotifier, BatteryState>((ref) {
  return BatteryNotifier();
});

class BatteryNotifier extends StateNotifier<BatteryState> {
  BatteryNotifier() : super(BatteryState(isLoading: true)) {
    _fetchBatteries();
  }

  List<BatteryModel> _allBatteries = [];

  Future<void> _fetchBatteries() async {
    try {
      state = state.copyWith(isLoading: true);
      await Future.delayed(const Duration(milliseconds: 700));
      
      // Initialize Mock Data only once
      if (_allBatteries.isEmpty) {
        _allBatteries = List.generate(30, (index) {
          return BatteryModel(
            id: 'BAT-${2000 + index}',
            serialNumber: 'SN-${2000 + index}',
            type: index % 2 == 0 ? 'Li-ion 2kWh' : 'LiFePO4 2.5kWh',
            health: 100.0 - (index % 20),
            cycles: index * 5,
            status: BatteryStatus.values[index % BatteryStatus.values.length],
            assignedStationId: index % 3 == 0 ? 'ST-10${index % 5}' : null,
            chargeLevel: 80.0 + (index % 20),
          );
        });
      }

      var batteries = List<BatteryModel>.from(_allBatteries);

      // Apply Search Filter
      if (state.searchQuery.isNotEmpty) {
        final query = state.searchQuery.toLowerCase();
        batteries = batteries.where((b) {
          return b.serialNumber.toLowerCase().contains(query) ||
                 b.id.toLowerCase().contains(query);
        }).toList();
      }

      // Apply Status Filter
      if (state.statusFilter != null) {
        batteries = batteries.where((b) => b.status == state.statusFilter).toList();
      }

      // Calculate stats
      final stats = {
        'total': _allBatteries.length,
        'active': _allBatteries.where((b) => b.status == BatteryStatus.inUse).length,
        'charging': _allBatteries.where((b) => b.status == BatteryStatus.charging).length,
        'maintenance': _allBatteries.where((b) => b.status == BatteryStatus.maintenance).length,
      };

      state = state.copyWith(
        batteries: batteries,
        isLoading: false,
        stats: stats,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addBattery(BatteryModel battery) async {
    _allBatteries.insert(0, battery);
    _fetchBatteries();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _fetchBatteries();
  }

  void setStatusFilter(BatteryStatus? status) {
    state = BatteryState(
      batteries: state.batteries,
      isLoading: state.isLoading,
      searchQuery: state.searchQuery,
      statusFilter: status,
      stats: state.stats,
    );
    _fetchBatteries();
  }
}
