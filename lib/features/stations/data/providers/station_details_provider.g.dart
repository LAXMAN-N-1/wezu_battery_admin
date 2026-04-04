// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'station_details_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$stationAlertsHash() => r'7a9c313f424903e13d51993e3577ecc880b8bd25';

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

/// See also [stationAlerts].
@ProviderFor(stationAlerts)
const stationAlertsProvider = StationAlertsFamily();

/// See also [stationAlerts].
class StationAlertsFamily
    extends Family<AsyncValue<List<BackendStationAlert>>> {
  /// See also [stationAlerts].
  const StationAlertsFamily();

  /// See also [stationAlerts].
  StationAlertsProvider call(int stationId) {
    return StationAlertsProvider(stationId);
  }

  @override
  StationAlertsProvider getProviderOverride(
    covariant StationAlertsProvider provider,
  ) {
    return call(provider.stationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'stationAlertsProvider';
}

/// See also [stationAlerts].
class StationAlertsProvider
    extends AutoDisposeFutureProvider<List<BackendStationAlert>> {
  /// See also [stationAlerts].
  StationAlertsProvider(int stationId)
    : this._internal(
        (ref) => stationAlerts(ref as Ref, stationId),
        from: stationAlertsProvider,
        name: r'stationAlertsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$stationAlertsHash,
        dependencies: StationAlertsFamily._dependencies,
        allTransitiveDependencies:
            StationAlertsFamily._allTransitiveDependencies,
        stationId: stationId,
      );

  StationAlertsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.stationId,
  }) : super.internal();

  final int stationId;

  @override
  Override overrideWith(
    FutureOr<List<BackendStationAlert>> Function(StationAlertsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StationAlertsProvider._internal(
        (ref) => create(ref as StationAlertsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        stationId: stationId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<BackendStationAlert>> createElement() {
    return _StationAlertsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StationAlertsProvider && other.stationId == stationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, stationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StationAlertsRef
    on AutoDisposeFutureProviderRef<List<BackendStationAlert>> {
  /// The parameter `stationId` of this provider.
  int get stationId;
}

class _StationAlertsProviderElement
    extends AutoDisposeFutureProviderElement<List<BackendStationAlert>>
    with StationAlertsRef {
  _StationAlertsProviderElement(super.provider);

  @override
  int get stationId => (origin as StationAlertsProvider).stationId;
}

String _$chargingQueueHash() => r'0ae9ad6c0c136789dcdca1d9106299038a26f184';

/// See also [chargingQueue].
@ProviderFor(chargingQueue)
const chargingQueueProvider = ChargingQueueFamily();

/// See also [chargingQueue].
class ChargingQueueFamily extends Family<AsyncValue<ChargingQueueResponse>> {
  /// See also [chargingQueue].
  const ChargingQueueFamily();

  /// See also [chargingQueue].
  ChargingQueueProvider call(int stationId) {
    return ChargingQueueProvider(stationId);
  }

  @override
  ChargingQueueProvider getProviderOverride(
    covariant ChargingQueueProvider provider,
  ) {
    return call(provider.stationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chargingQueueProvider';
}

/// See also [chargingQueue].
class ChargingQueueProvider
    extends AutoDisposeFutureProvider<ChargingQueueResponse> {
  /// See also [chargingQueue].
  ChargingQueueProvider(int stationId)
    : this._internal(
        (ref) => chargingQueue(ref as Ref, stationId),
        from: chargingQueueProvider,
        name: r'chargingQueueProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$chargingQueueHash,
        dependencies: ChargingQueueFamily._dependencies,
        allTransitiveDependencies:
            ChargingQueueFamily._allTransitiveDependencies,
        stationId: stationId,
      );

  ChargingQueueProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.stationId,
  }) : super.internal();

  final int stationId;

  @override
  Override overrideWith(
    FutureOr<ChargingQueueResponse> Function(ChargingQueueRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChargingQueueProvider._internal(
        (ref) => create(ref as ChargingQueueRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        stationId: stationId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ChargingQueueResponse> createElement() {
    return _ChargingQueueProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChargingQueueProvider && other.stationId == stationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, stationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChargingQueueRef on AutoDisposeFutureProviderRef<ChargingQueueResponse> {
  /// The parameter `stationId` of this provider.
  int get stationId;
}

class _ChargingQueueProviderElement
    extends AutoDisposeFutureProviderElement<ChargingQueueResponse>
    with ChargingQueueRef {
  _ChargingQueueProviderElement(super.provider);

  @override
  int get stationId => (origin as ChargingQueueProvider).stationId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
