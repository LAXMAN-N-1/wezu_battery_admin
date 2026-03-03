import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/location_model.dart';
import 'dart:math';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository();
});

class LocationRepository {
  final List<LocationNode> _mockLocations = [];

  LocationRepository() {
    _generateMockData();
  }

  void _generateMockData() {
    // Continents
    _mockLocations.addAll([
      LocationNode(id: 1, name: 'North America'),
      LocationNode(id: 2, name: 'Europe'),
      LocationNode(id: 3, name: 'Asia'),
    ]);

    // Countries
    _mockLocations.addAll([
      LocationNode(id: 11, name: 'USA', parentId: 1),
      LocationNode(id: 12, name: 'Canada', parentId: 1),
      LocationNode(id: 21, name: 'Germany', parentId: 2),
      LocationNode(id: 22, name: 'France', parentId: 2),
      LocationNode(id: 31, name: 'India', parentId: 3),
      LocationNode(id: 32, name: 'Japan', parentId: 3),
    ]);

    // Regions
    _mockLocations.addAll([
      LocationNode(id: 111, name: 'California', parentId: 11),
      LocationNode(id: 112, name: 'New York', parentId: 11),
      LocationNode(id: 311, name: 'Karnataka', parentId: 31),
      LocationNode(id: 312, name: 'Maharashtra', parentId: 31),
    ]);
  }

  Future<List<LocationNode>> fetchLocations(LocationLevel level) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, we'd query by level. Here we have a flat list, but let's just return all for simplicity
    // or filter by some logic if we had level stored in model (we don't explicitely, but we can infer or just return relevant subset)
    
    // For this mock, we'll return all and let the provider filter by parentId. 
    // Ideally the model should have a 'level' field or we structure the mock better.
    // Let's rely on the Provider's parentId filtering for drill-down.
    // But for the root level (Continent), we need to return only nodes with no parent (or parentId 0/null?) 
    // actually, the model has optional parentId.
    
    // To make it simple: return everything. The provider filters by parentId.
    // If provider asks for continents (level 0), it expects nodes with parentId == null.
    return _mockLocations;
  }

  Future<LocationNode> createLocation(LocationLevel level, String name, int? parentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newId = _mockLocations.isNotEmpty ? _mockLocations.map((e) => e.id).reduce(max) + 1 : 1;
    final newNode = LocationNode(id: newId, name: name, parentId: parentId);
    _mockLocations.add(newNode);
    return newNode;
  }
}
