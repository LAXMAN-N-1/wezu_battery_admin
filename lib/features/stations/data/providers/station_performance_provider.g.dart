// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'station_performance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$stationPerformanceHash() =>
    r'd0fe0c1fe2e2e984a2b8b7921ae50440f8258efc';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [stationPerformance].
@ProviderFor(stationPerformance)
const stationPerformanceProvider = StationPerformanceFamily();

/// See also [stationPerformance].
class StationPerformanceFamily extends Family<AsyncValue<StationPerformance>> {
  /// See also [stationPerformance].
  const StationPerformanceFamily();

  /// See also [stationPerformance].
  StationPerformanceProvider call({
    required int stationId,
    DateTime? start,
    DateTime? end,
  }) {
    return StationPerformanceProvider(
      stationId: stationId,
      start: start,
      end: end,
    );
  }

  @override
  StationPerformanceProvider getProviderOverride(
    covariant StationPerformanceProvider provider,
  ) {
    return call(
      stationId: provider.stationId,
      start: provider.start,
      end: provider.end,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'stationPerformanceProvider';
}

/// See also [stationPerformance].
class StationPerformanceProvider
    extends AutoDisposeFutureProvider<StationPerformance> {
  /// See also [stationPerformance].
  StationPerformanceProvider({
    required int stationId,
    DateTime? start,
    DateTime? end,
  }) : this._internal(
         (ref) => stationPerformance(
           ref as StationPerformanceRef,
           stationId: stationId,
           start: start,
           end: end,
         ),
         from: stationPerformanceProvider,
         name: r'stationPerformanceProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$stationPerformanceHash,
         dependencies: StationPerformanceFamily._dependencies,
         allTransitiveDependencies:
             StationPerformanceFamily._allTransitiveDependencies,
         stationId: stationId,
         start: start,
         end: end,
       );

  StationPerformanceProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.stationId,
    required this.start,
    required this.end,
  }) : super.internal();

  final int stationId;
  final DateTime? start;
  final DateTime? end;

  @override
  Override overrideWith(
    FutureOr<StationPerformance> Function(StationPerformanceRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StationPerformanceProvider._internal(
        (ref) => create(ref as StationPerformanceRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        stationId: stationId,
        start: start,
        end: end,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<StationPerformance> createElement() {
    return _StationPerformanceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StationPerformanceProvider &&
        other.stationId == stationId &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, stationId.hashCode);
    hash = _SystemHash.combine(hash, start.hashCode);
    hash = _SystemHash.combine(hash, end.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StationPerformanceRef
    on AutoDisposeFutureProviderRef<StationPerformance> {
  /// The parameter `stationId` of this provider.
  int get stationId;

  /// The parameter `start` of this provider.
  DateTime? get start;

  /// The parameter `end` of this provider.
  DateTime? get end;
}

class _StationPerformanceProviderElement
    extends AutoDisposeFutureProviderElement<StationPerformance>
    with StationPerformanceRef {
  _StationPerformanceProviderElement(super.provider);

  @override
  int get stationId => (origin as StationPerformanceProvider).stationId;
  @override
  DateTime? get start => (origin as StationPerformanceProvider).start;
  @override
  DateTime? get end => (origin as StationPerformanceProvider).end;
}

String _$stationRankingsHash() => r'b4e75b8603e08cbe42418bdd521ccca4e40f37e2';

/// See also [stationRankings].
@ProviderFor(stationRankings)
const stationRankingsProvider = StationRankingsFamily();

/// See also [stationRankings].
class StationRankingsFamily extends Family<AsyncValue<List<StationRanking>>> {
  /// See also [stationRankings].
  const StationRankingsFamily();

  /// See also [stationRankings].
  StationRankingsProvider call({String metric = 'revenue', int limit = 10}) {
    return StationRankingsProvider(metric: metric, limit: limit);
  }

  @override
  StationRankingsProvider getProviderOverride(
    covariant StationRankingsProvider provider,
  ) {
    return call(metric: provider.metric, limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'stationRankingsProvider';
}

/// See also [stationRankings].
class StationRankingsProvider
    extends AutoDisposeFutureProvider<List<StationRanking>> {
  /// See also [stationRankings].
  StationRankingsProvider({String metric = 'revenue', int limit = 10})
    : this._internal(
        (ref) => stationRankings(
          ref as StationRankingsRef,
          metric: metric,
          limit: limit,
        ),
        from: stationRankingsProvider,
        name: r'stationRankingsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$stationRankingsHash,
        dependencies: StationRankingsFamily._dependencies,
        allTransitiveDependencies:
            StationRankingsFamily._allTransitiveDependencies,
        metric: metric,
        limit: limit,
      );

  StationRankingsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.metric,
    required this.limit,
  }) : super.internal();

  final String metric;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<StationRanking>> Function(StationRankingsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StationRankingsProvider._internal(
        (ref) => create(ref as StationRankingsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        metric: metric,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<StationRanking>> createElement() {
    return _StationRankingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StationRankingsProvider &&
        other.metric == metric &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, metric.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StationRankingsRef on AutoDisposeFutureProviderRef<List<StationRanking>> {
  /// The parameter `metric` of this provider.
  String get metric;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _StationRankingsProviderElement
    extends AutoDisposeFutureProviderElement<List<StationRanking>>
    with StationRankingsRef {
  _StationRankingsProviderElement(super.provider);

  @override
  String get metric => (origin as StationRankingsProvider).metric;
  @override
  int get limit => (origin as StationRankingsProvider).limit;
}

String _$performanceDateRangeHash() =>
    r'05d70d999001d49f4f6e96e7807c80c8bd785133';

/// See also [PerformanceDateRange].
@ProviderFor(PerformanceDateRange)
final performanceDateRangeProvider =
    AutoDisposeNotifierProvider<PerformanceDateRange, DateTimeRange>.internal(
      PerformanceDateRange.new,
      name: r'performanceDateRangeProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$performanceDateRangeHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PerformanceDateRange = AutoDisposeNotifier<DateTimeRange>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
