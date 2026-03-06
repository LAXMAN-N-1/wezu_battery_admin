// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stations_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$stationRepositoryHash() => r'cccb30dd044677a82a425782e1c99b670709c20b';

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
String _$stationsHash() => r'81d92e14aca0e34875572c09f996aba5a7e8fc4d';

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
