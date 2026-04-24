import '../../../../core/api/api_client.dart';

class LogisticsRepository {
  final ApiClient _api;
  LogisticsRepository([ApiClient? api]) : _api = api ?? ApiClient();

  // ─── DELIVERY ORDERS ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> getOrders({
    int skip = 0,
    int limit = 50,
    String? status,
    String? orderType,
  }) async {
    try {
      final params = <String, dynamic>{
        'skip': skip,
        'offset': skip,
        'limit': limit,
      };
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (orderType != null && orderType.isNotEmpty) {
        params['order_type'] = orderType;
      }

      final r = await _getAny(<String>[
        '/api/v1/admin/logistics/orders',
        '/api/v1/admin/logistics/orders/',
      ], queryParameters: params);

      final map = _asMap(r.data);
      final orders = _extractList(map.isEmpty ? r.data : map, keys: <String>[
        'orders',
        'items',
        'data',
        'results',
      ]);

      return <String, dynamic>{
        'orders': orders,
        'total_count': _toInt(
          map['total_count'] ?? map['total'] ?? map['count'] ?? orders.length,
          orders.length,
        ),
      };
    } catch (_) {
      return <String, dynamic>{'orders': <dynamic>[], 'total_count': 0};
    }
  }

  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final r = await _getAny(<String>[
        '/api/v1/admin/logistics/orders/stats',
        '/api/v1/admin/logistics/orders/summary',
      ]);
      final map = _asMap(r.data);
      return <String, dynamic>{
        'total_orders': _toInt(map['total_orders'] ?? map['total']),
        'pending': _toInt(map['pending']),
        'in_transit': _toInt(map['in_transit']),
        'delivered': _toInt(map['delivered']),
        'failed': _toInt(map['failed']),
      };
    } catch (_) {
      final ordersData = await getOrders(limit: 500);
      final orders = _extractList(ordersData['orders']);

      var pending = 0;
      var inTransit = 0;
      var delivered = 0;
      var failed = 0;

      for (final raw in orders) {
        final status = (raw is Map ? raw['status'] : null)
                ?.toString()
                .toLowerCase() ??
            '';
        if (status == 'pending' || status == 'assigned') pending++;
        if (status == 'in_transit' || status == 'in-progress') inTransit++;
        if (status == 'delivered' || status == 'completed') delivered++;
        if (status == 'failed' || status == 'cancelled') failed++;
      }

      return <String, dynamic>{
        'total_orders': orders.length,
        'pending': pending,
        'in_transit': inTransit,
        'delivered': delivered,
        'failed': failed,
      };
    }
  }

  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    try {
      await _putAny(<String>[
        '/api/v1/admin/logistics/orders/$orderId/status',
      ], queryParameters: <String, dynamic>{'new_status': newStatus});
      return true;
    } catch (_) {
      try {
        await _patchAny(<String>[
          '/api/v1/admin/logistics/orders/$orderId/status',
        ], data: <String, dynamic>{'new_status': newStatus, 'status': newStatus});
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  // ─── DRIVERS ──────────────────────────────────────────────────────────

  Future<List<dynamic>> getDrivers() async {
    try {
      final r = await _getAny(<String>[
        '/api/v1/admin/logistics/drivers',
        '/api/v1/admin/logistics/drivers/',
      ]);
      return _extractList(r.data, keys: <String>['drivers', 'items', 'data']);
    } catch (_) {
      return <dynamic>[];
    }
  }

  Future<Map<String, dynamic>> getDriverStats() async {
    try {
      final r = await _getAny(<String>[
        '/api/v1/admin/logistics/drivers/stats',
      ]);
      final map = _asMap(r.data);
      return <String, dynamic>{
        'total_drivers': _toInt(map['total_drivers'] ?? map['total']),
        'online_drivers': _toInt(map['online_drivers'] ?? map['online']),
        'offline_drivers': _toInt(map['offline_drivers'] ?? map['offline']),
        'avg_rating': _toDouble(map['avg_rating']),
        'total_deliveries': _toInt(
          map['total_deliveries'] ?? map['deliveries_total'],
        ),
      };
    } catch (_) {
      final drivers = await getDrivers();
      final online = drivers.where((d) {
        if (d is! Map) return false;
        return d['is_online'] == true ||
            d['status']?.toString().toLowerCase() == 'online';
      }).length;

      final total = drivers.length;
      return <String, dynamic>{
        'total_drivers': total,
        'online_drivers': online,
        'offline_drivers': total - online,
        'avg_rating': 0.0,
        'total_deliveries': 0,
      };
    }
  }

  // ─── ROUTES ───────────────────────────────────────────────────────────

  Future<List<dynamic>> getRoutes({String? status}) async {
    try {
      final params = <String, dynamic>{};
      if (status != null && status.isNotEmpty) params['status'] = status;
      final r = await _getAny(
        <String>['/api/v1/admin/logistics/routes', '/api/v1/admin/logistics/routes/'],
        queryParameters: params,
      );
      return _extractList(r.data, keys: <String>['routes', 'items', 'data']);
    } catch (_) {
      return <dynamic>[];
    }
  }

  // ─── RETURNS ──────────────────────────────────────────────────────────

  Future<List<dynamic>> getReturns({String? status}) async {
    try {
      final params = <String, dynamic>{};
      if (status != null && status.isNotEmpty) params['status'] = status;
      final r = await _getAny(
        <String>['/api/v1/admin/logistics/returns', '/api/v1/admin/logistics/returns/'],
        queryParameters: params,
      );
      return _extractList(r.data, keys: <String>['returns', 'items', 'data']);
    } catch (_) {
      return <dynamic>[];
    }
  }

  Future<Map<String, dynamic>> getReturnStats() async {
    try {
      final r = await _getAny(<String>['/api/v1/admin/logistics/returns/stats']);
      final map = _asMap(r.data);
      return <String, dynamic>{
        'total_returns': _toInt(map['total_returns'] ?? map['total']),
        'pending': _toInt(map['pending']),
        'completed': _toInt(map['completed']),
        'total_refund_amount': _toDouble(
          map['total_refund_amount'] ?? map['refund_total'],
        ),
      };
    } catch (_) {
      final returns = await getReturns();
      final pending = returns.where((r) {
        if (r is! Map) return false;
        final status = r['status']?.toString().toLowerCase() ?? '';
        return status.contains('pending') || status.contains('assigned');
      }).length;
      final completed = returns.where((r) {
        if (r is! Map) return false;
        final status = r['status']?.toString().toLowerCase() ?? '';
        return status == 'completed' || status == 'received';
      }).length;
      return <String, dynamic>{
        'total_returns': returns.length,
        'pending': pending,
        'completed': completed,
        'total_refund_amount': 0.0,
      };
    }
  }

  Future<bool> updateReturnStatus(
    int returnId,
    String newStatus, {
    String? notes,
  }) async {
    final params = <String, dynamic>{'new_status': newStatus};
    if (notes != null && notes.isNotEmpty) params['notes'] = notes;

    try {
      await _putAny(<String>['/api/v1/admin/logistics/returns/$returnId/status'],
          queryParameters: params);
      return true;
    } catch (_) {
      try {
        await _patchAny(<String>[
          '/api/v1/admin/logistics/returns/$returnId/status',
        ], data: params);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  // ─── TRACKING ─────────────────────────────────────────────────────────

  Future<List<dynamic>> getLiveTracking() async {
    try {
      final r = await _getAny(<String>[
        '/api/v1/admin/logistics/tracking',
        '/api/v1/admin/logistics/live-tracking',
      ]);
      return _extractList(r.data, keys: <String>['tracking', 'items', 'data']);
    } catch (_) {
      return <dynamic>[];
    }
  }

  Future<dynamic> _getAny(
    List<String> paths, {
    Map<String, dynamic>? queryParameters,
  }) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _api.get(path, queryParameters: queryParameters);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('GET failed for all logistics endpoints');
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
    throw lastError ?? Exception('PUT failed for all logistics endpoints');
  }

  Future<dynamic> _patchAny(
    List<String> paths, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _api.patch(
          path,
          data: data,
          queryParameters: queryParameters,
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('PATCH failed for all logistics endpoints');
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

  int _toInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _toDouble(dynamic value, [double fallback = 0.0]) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
