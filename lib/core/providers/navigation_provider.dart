import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the selected route path for sidebar navigation
final selectedRouteProvider = StateProvider<String>((ref) => '/dashboard');

/// Manages which sidebar sections are expanded
final expandedSectionsProvider = StateNotifierProvider<ExpandedSectionsNotifier, Set<String>>((ref) {
  return ExpandedSectionsNotifier();
});

class ExpandedSectionsNotifier extends StateNotifier<Set<String>> {
  ExpandedSectionsNotifier() : super({});

  void toggle(String section) {
    if (state.contains(section)) {
      state = {...state}..remove(section);
    } else {
      state = {...state, section};
    }
  }

  bool isExpanded(String section) => state.contains(section);
}

// Keep legacy provider for backward compat
final navigationProvider = StateProvider<int>((ref) => 0);

/// Manages the visibility of the sidebar
final sidebarOpenProvider = StateProvider<bool>((ref) => true);
