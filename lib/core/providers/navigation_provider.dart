import 'package:flutter_riverpod/flutter_riverpod.dart';

// Legacy provider for backward compat if any deep widgets still use it
final navigationProvider = StateProvider<int>((ref) => 0);

/// Manages the visibility of the sidebar
final sidebarOpenProvider = StateProvider<bool>((ref) => true);
