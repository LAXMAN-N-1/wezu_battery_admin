import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the selected index of the sidebar navigation
final navigationProvider = StateProvider<int>((ref) => 0);
