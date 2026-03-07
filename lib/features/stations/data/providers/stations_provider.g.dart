// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stations_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$stationRepositoryHash() => r'3c3a7a70cd95bcb77feec52f711b9954ad566bbe';

/// See also [stationRepository].
@ProviderFor(stationRepository)
final stationRepositoryProvider =
    AutoDisposeProvider<StationRepository>.internal(
      stationRepository,
      name: r'stationRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$stationRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StationRepositoryRef = AutoDisposeProviderRef<StationRepository>;
String _$stationsHash() => r'c63cdc933dafd18e19bb9f7a0bd5cbaad54e7d32';

/// See also [Stations].
@ProviderFor(Stations)
final stationsProvider =
    AutoDisposeAsyncNotifierProvider<Stations, List<Station>>.internal(
      Stations.new,
      name: r'stationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$stationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Stations = AutoDisposeAsyncNotifier<List<Station>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
