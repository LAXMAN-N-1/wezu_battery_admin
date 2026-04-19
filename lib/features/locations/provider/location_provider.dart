import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/location_model.dart';
import '../repository/location_repository.dart';

class LocationState {
  final bool isLoading;
  final List<LocationNode> nodes;
  final List<LocationNode> path; // For breadcrumbs
  final LocationLevel currentLevel;
  final String? error;

  LocationState({
    this.isLoading = false,
    this.nodes = const [],
    this.path = const [],
    this.currentLevel = LocationLevel.continent,
    this.error,
  });

  LocationState copyWith({
    bool? isLoading,
    List<LocationNode>? nodes,
    List<LocationNode>? path,
    LocationLevel? currentLevel,
    String? error,
  }) {
    return LocationState(
      isLoading: isLoading ?? this.isLoading,
      nodes: nodes ?? this.nodes,
      path: path ?? this.path,
      currentLevel: currentLevel ?? this.currentLevel,
      error: error,
    );
  }
}

final locationProvider = StateNotifierProvider.autoDispose<LocationNotifier, LocationState>((ref) {
  return LocationNotifier(ref.read(locationRepositoryProvider));
});

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationRepository _repository;

  LocationNotifier(this._repository) : super(LocationState()) {
    loadLocations(LocationLevel.continent);
  }

  Future<void> loadLocations(LocationLevel level, {LocationNode? parent}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final nodes = await _repository.fetchLocations(level);
      
      // Filter by parent if necessary (frontend filtering for demo, ideally backend filters)
      final filteredNodes = parent == null 
        ? nodes 
        : nodes.where((n) => n.parentId == parent.id).toList();

      List<LocationNode> newPath = List.from(state.path);
      if (parent != null) {
        // If we are diving deeper, add to path. But wait, we need to handle jumping back too.
        // For simplicity: if parent is null, reset path to empty. 
        // If parent is provided, we assumes it's the next level down.
      } else {
        newPath = [];
      }

      state = state.copyWith(
        isLoading: false,
        nodes: filteredNodes,
        currentLevel: level,
        path: newPath,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load ${level.label}');
    }
  }

  void dive(LocationNode node) {
    final nextLevel = state.currentLevel.next;
    if (nextLevel != null) {
      List<LocationNode> newPath = List.from(state.path)..add(node);
      state = state.copyWith(path: newPath);
      loadLocations(nextLevel, parent: node);
    }
  }

  void resetToLevel(int pathIndex) {
    if (pathIndex == -1) {
      state = state.copyWith(path: []);
      loadLocations(LocationLevel.continent);
    } else {
      final node = state.path[pathIndex];
      final level = LocationLevel.values[pathIndex + 1];
      state = state.copyWith(path: state.path.sublist(0, pathIndex + 1));
      loadLocations(level, parent: node);
    }
  }

  Future<void> addLocation(String name) async {
    final parentId = state.path.isEmpty ? null : state.path.last.id;
    try {
      await _repository.createLocation(state.currentLevel, name, parentId);
      loadLocations(state.currentLevel, parent: state.path.isEmpty ? null : state.path.last);
    } catch (e) {
      state = state.copyWith(error: 'Failed to create location');
    }
  }
}
