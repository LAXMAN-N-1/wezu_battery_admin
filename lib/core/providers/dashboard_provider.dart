import 'package:flutter_riverpod/flutter_riverpod.dart';

// View expects navigationProvider to be a StateProvider<int>
final navigationProvider = StateProvider<int>((ref) {
  return 0;
});

// Keep dashboardProvider for compatibility if used elsewhere, or just alias
final dashboardProvider = navigationProvider;
