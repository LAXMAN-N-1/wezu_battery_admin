import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location_model.dart';

class LocationState {
  final List<LocationNode> nodes;
  final bool isLoading;
  final LocationNode currentLevel;
  final List<LocationNode> breadcrumbs;
  List<LocationNode> get path => breadcrumbs;

  LocationState({
    this.nodes = const [],
    this.isLoading = false,
    required this.currentLevel,
    this.breadcrumbs = const [],
  });

  LocationState copyWith({
    List<LocationNode>? nodes,
    bool? isLoading,
    LocationNode? currentLevel,
    List<LocationNode>? breadcrumbs,
  }) {
    return LocationState(
      nodes: nodes ?? this.nodes,
      isLoading: isLoading ?? this.isLoading,
      currentLevel: currentLevel ?? this.currentLevel,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
    );
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(LocationState(
    currentLevel: LocationNode(id: 0, name: 'Root', type: LocationLevel.continent),
    isLoading: true,
  )) {
    _fetchLocations();
  }

  List<LocationNode> _allNodes = [];

  Future<void> _fetchLocations() async {
    try {
      state = state.copyWith(isLoading: true);
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Initialize Mock Data only once
      if (_allNodes.isEmpty) {
        _allNodes = [
          LocationNode(id: 1, name: 'North America', type: LocationLevel.continent),
          LocationNode(id: 2, name: 'Europe', type: LocationLevel.continent),
          LocationNode(id: 3, name: 'Asia', type: LocationLevel.continent),
        ];
      }
      
      // Filter nodes based on current level (mock implementation)
      // In a real app, this would query based on parentId
      // For this mock, we just show the root nodes if at root, or children if not
      
      List<LocationNode> nodesToShow;
      if (state.currentLevel.id == 0) {
         nodesToShow = _allNodes.where((n) => n.type == LocationLevel.continent).toList();
      } else {
         // If we are deep diving, we usually generate mock children on the fly in `dive`
         // But if we added a node, we want it to show up.
         // Let's assume _allNodes holds ALL nodes flatly for this simple mock correction
         nodesToShow = _allNodes.where((n) => n.parentId == state.currentLevel.id).toList();
      }

      state = state.copyWith(
        nodes: nodesToShow.isEmpty && state.currentLevel.id == 0 ? _allNodes : nodesToShow, // Fallback for root
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void dive(LocationNode node) {
    final newBreadcrumbs = List<LocationNode>.from(state.breadcrumbs)..add(node);
    
    // Check if we have children in our static list
    var children = _allNodes.where((n) => n.parentId == node.id).toList();
    
    // If no children exist yet (first time diving here), generate mock ones and add to _allNodes
    if (children.isEmpty) {
       final generatedChildren = List.generate(3, (i) => LocationNode(
        id: node.id * 10 + i + 1, 
        name: '${node.name} Sub ${i+1}', 
        type: LocationLevel.values[(node.type.index + 1) % LocationLevel.values.length],
        parentId: node.id,
      ));
      _allNodes.addAll(generatedChildren);
      children = generatedChildren;
    }

    state = state.copyWith(
      currentLevel: node,
      nodes: children,
      breadcrumbs: newBreadcrumbs,
    );
  }

  void resetToLevel(int index) {
    if (index >= -1 && index < state.breadcrumbs.length) {
      final newBreadcrumbs = index == -1 ? <LocationNode>[] : state.breadcrumbs.sublist(0, index + 1);
      final rawNode = index == -1 
          ? LocationNode(id: 0, name: 'Global', type: LocationLevel.continent) 
          : state.breadcrumbs[index];
      
      // Determine nodes to show for the target level
      List<LocationNode> nodesToShow;
      if (rawNode.id == 0) {
         nodesToShow = _allNodes.where((n) => n.type == LocationLevel.continent).toList();
      } else {
         nodesToShow = _allNodes.where((n) => n.parentId == rawNode.id).toList();
      }

      state = state.copyWith(
        currentLevel: rawNode,
        nodes: nodesToShow, 
        breadcrumbs: newBreadcrumbs,
      );
    }
  }

  Future<void> addLocation(LocationNode location) async {
    _allNodes.add(location);
    
    // Refresh current view
    if (state.currentLevel.id == location.parentId) {
      final currentNodes = _allNodes.where((n) => n.parentId == state.currentLevel.id).toList();
       state = state.copyWith(nodes: currentNodes);
    } else if (state.currentLevel.id == 0 && location.type == LocationLevel.continent) {
       // Root case
       final currentNodes = _allNodes.where((n) => n.type == LocationLevel.continent).toList();
       state = state.copyWith(nodes: currentNodes);
    }
  }
}
