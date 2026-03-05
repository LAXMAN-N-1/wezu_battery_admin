import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the selected index of the sidebar navigation
final navigationProvider = StateProvider<int>((ref) => 0);

/// Manages the visibility of the sidebar
final sidebarOpenProvider = StateProvider<bool>((ref) => true);
