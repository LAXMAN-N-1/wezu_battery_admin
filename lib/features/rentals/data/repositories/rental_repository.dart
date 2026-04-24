import '../../../../core/api/api_client.dart';
import '../models/late_fee_model.dart';
import '../models/purchase_model.dart';
import '../models/rental_model.dart';
import '../models/swap_model.dart';

class RentalRepository {
  final ApiClient _api = ApiClient();

  Future<RentalStats> getRentalStats() async {
    try {
      final response = await _getAny(<String>[
        '/api/v1/admin/rentals/stats',
        '/api/v1/admin/main/stats',
      ]);
      return RentalStats.fromJson(_asMap(response.data));
    } catch (_) {
      return const RentalStats(
        activeRentals: 0,
        overdueRentals: 0,
        totalSwapsCompleted: 0,
        todayRevenue: 0.0,
      );
    }
  }

  Future<List<Rental>> getActiveRentals({int skip = 0, int limit = 100}) async {
    try {
      final response = await _getAny(
        <String>['/api/v1/admin/rentals/active', '/api/v1/admin/main/rentals/'],
        <String, dynamic>{
          'skip': skip,
          'offset': skip,
          'limit': limit,
          'status': 'active',
        },
      );
      return _extractRentals(response.data);
    } catch (_) {
      return <Rental>[];
    }
  }

  Future<List<Rental>> getRentalHistory({
    int skip = 0,
    int limit = 50,
    String? search,
  }) async {
    final params = <String, dynamic>{
      'skip': skip,
      'offset': skip,
      'limit': limit,
    };
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
      params['q'] = search;
    }

    try {
      final response = await _getAny(
        <String>['/api/v1/admin/rentals/history', '/api/v1/admin/main/rentals/'],
        params,
      );
      return _extractRentals(response.data);
    } catch (_) {
      return <Rental>[];
    }
  }

  Future<List<SwapSession>> getSwaps({int skip = 0, int limit = 100}) async {
    try {
      final response = await _getAny(
        <String>[
          '/api/v1/admin/rentals/swaps',
          '/api/v1/admin/main/rentals/swaps',
        ],
        <String, dynamic>{'skip': skip, 'offset': skip, 'limit': limit},
      );
      final list = _extractList(response.data, keys: <String>['swaps', 'items']);
      return list
          .whereType<Map>()
          .map((s) => SwapSession.fromJson(Map<String, dynamic>.from(s)))
          .toList();
    } catch (_) {
      return <SwapSession>[];
    }
  }

  Future<List<PurchaseOrder>> getPurchases({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _getAny(
        <String>[
          '/api/v1/admin/rentals/purchases',
          '/api/v1/admin/main/finance/transactions',
        ],
        <String, dynamic>{
          'skip': skip,
          'offset': skip,
          'limit': limit,
          'type': 'purchase',
        },
      );
      final list = _extractList(
        response.data,
        keys: <String>['purchases', 'items', 'transactions'],
      );
      return list
          .whereType<Map>()
          .map((p) => PurchaseOrder.fromJson(Map<String, dynamic>.from(p)))
          .toList();
    } catch (_) {
      return <PurchaseOrder>[];
    }
  }

  Future<List<LateFee>> getLateFees() async {
    try {
      final response = await _getAny(<String>[
        '/api/v1/admin/rentals/late-fees',
        '/api/v1/admin/main/finance/refunds',
      ]);
      final list = _extractList(
        response.data,
        keys: <String>['late_fees', 'items', 'refunds'],
      );
      return list
          .whereType<Map>()
          .map((l) => LateFee.fromJson(Map<String, dynamic>.from(l)))
          .toList();
    } catch (_) {
      return <LateFee>[];
    }
  }

  Future<bool> reviewWaiver(
    int waiverId,
    String status, {
    double? approvedAmount,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{'status': status};
      if (approvedAmount != null) data['approved_amount'] = approvedAmount;
      if (notes != null && notes.isNotEmpty) data['admin_notes'] = notes;

      await _putAny(<String>[
        '/api/v1/admin/rentals/late-fees/waivers/$waiverId/review',
      ], data: data);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> terminateRental(int rentalId, String reason) async {
    try {
      await _putAny(<String>[
        '/api/v1/admin/rentals/$rentalId/terminate',
        '/api/v1/admin/main/rentals/$rentalId/terminate',
      ], queryParameters: <String, dynamic>{'reason': reason});
      return true;
    } catch (_) {
      return false;
    }
  }

  List<Rental> _extractRentals(dynamic rawData) {
    final list = _extractList(
      rawData,
      keys: <String>['rentals', 'items', 'data', 'results'],
    );

    return list
        .whereType<Map>()
        .map((r) => Rental.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<dynamic> _getAny(
    List<String> paths, [
    Map<String, dynamic>? queryParameters,
  ]) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _api.get(path, queryParameters: queryParameters);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('GET failed for all rental endpoints');
  }

  Future<dynamic> _putAny(
    List<String> paths, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _api.put(
          path,
          data: data,
          queryParameters: queryParameters,
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('PUT failed for all rental endpoints');
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  List<dynamic> _extractList(dynamic value, {List<String> keys = const []}) {
    if (value is List) return value;

    final map = _asMap(value);
    for (final key in keys) {
      final item = map[key];
      if (item is List) return item;
    }

    if (map['data'] is List) return map['data'] as List;
    return const <dynamic>[];
  }
}
