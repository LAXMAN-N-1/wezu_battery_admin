
import '../models/battery.dart';

class InventoryRepository {
  Future<List<Battery>> getBatteries() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      Battery(
        id: 1,
        serialNumber: 'BAT-2024-001',
        modelNumber: 'Model-X',
        status: 'rented',
        healthPercentage: 98.5,
        locationName: 'Station A',
        cycleCount: 45,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Battery(
        id: 2,
        serialNumber: 'BAT-2024-002',
        modelNumber: 'Model-Y',
        status: 'available',
        healthPercentage: 100.0,
        locationName: 'Warehouse',
        cycleCount: 0,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Battery(
        id: 3,
        serialNumber: 'BAT-2024-003',
        modelNumber: 'Model-X',
        status: 'maintenance',
        healthPercentage: 78.2,
        locationName: 'Service Center',
        cycleCount: 320,
        lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Battery(
        id: 4,
        serialNumber: 'BAT-2024-004',
        modelNumber: 'Model-Z',
        status: 'available',
        healthPercentage: 99.1,
        locationName: 'Station B',
        cycleCount: 12,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      Battery(
        id: 5,
        serialNumber: 'BAT-2024-005',
        modelNumber: 'Model-X',
        status: 'rented',
        healthPercentage: 95.0,
        locationName: 'Station C',
        cycleCount: 89,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      Battery(
        id: 6,
        serialNumber: 'BAT-2024-006',
        modelNumber: 'Model-X',
        status: 'retired',
        healthPercentage: 45.0,
        locationName: 'Recycling Plant',
        cycleCount: 1200,
        lastUpdated: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];
  }
}
