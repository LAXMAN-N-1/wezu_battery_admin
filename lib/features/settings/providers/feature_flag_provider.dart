import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/feature_flag_model.dart';
import '../data/repositories/feature_flag_repository.dart';

final featureFlagRepositoryProvider = Provider((ref) => FeatureFlagRepository());

final featureFlagsProvider = AsyncNotifierProvider<FeatureFlagsNotifier, List<FeatureFlagModel>>(
  FeatureFlagsNotifier.new,
);

class FeatureFlagsNotifier extends AsyncNotifier<List<FeatureFlagModel>> {
  @override
  Future<List<FeatureFlagModel>> build() async {
    final repo = ref.read(featureFlagRepositoryProvider);
    return repo.fetchFlags();
  }

  /// Toggle a flag state with an optimistic UI update.
  Future<void> toggleFlag(String key, bool newValue) async {
    final repo = ref.read(featureFlagRepositoryProvider);
    final previousState = state.valueOrNull ?? [];

    // Optimistic Update
    state = AsyncValue.data(
      previousState.map((f) => f.key == key ? f.copyWith(isEnabled: newValue) : f).toList(),
    );

    try {
      await repo.toggleFlag(key, newValue);
      // Update success metadata locally (mocked)
      state = AsyncValue.data(
        state.value!.map((f) {
           if (f.key == key) {
             return f.copyWith(
               lastChangedBy: 'You (Admin)',
               lastChangedAt: DateTime.now(),
             );
           }
           return f;
        }).toList(),
      );
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(previousState);
      rethrow;
    }
  }

  Future<void> addFlag(FeatureFlagModel flag) async {
    final repo = ref.read(featureFlagRepositoryProvider);
    state = const AsyncValue.loading();
    try {
      await repo.createFlag(flag);
      state = AsyncValue.data([...state.value ?? [], flag]);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(featureFlagRepositoryProvider).fetchFlags());
  }
}

/// A search provider that filters the feature flags.
final featureFlagSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredFeatureFlagsProvider = Provider<AsyncValue<List<FeatureFlagModel>>>((ref) {
  final flagsAsync = ref.watch(featureFlagsProvider);
  final query = ref.watch(featureFlagSearchQueryProvider).toLowerCase();

  return flagsAsync.whenData((flags) {
    if (query.isEmpty) return flags;
    return flags.where((f) {
      return f.name.toLowerCase().contains(query) || 
             f.key.toLowerCase().contains(query) ||
             f.description.toLowerCase().contains(query);
    }).toList();
  });
});
