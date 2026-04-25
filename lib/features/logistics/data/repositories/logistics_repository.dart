import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/retry_interceptor.dart';

class LogisticsRepository {
  final ApiClient _api;
  LogisticsRepository([ApiClient? api]) : _api = api ?? ApiClient();

  dynamic _unwrapData(dynamic payload) {
    if (payload is Map && payload.containsKey('data')) {
      return payload['data'];
    }
    return payload;
  }

  Map<String, dynamic> _asMap(dynamic payload) {
    final unwrapped = _unwrapData(payload);
    if (unwrapped is Map<String, dynamic>) {
      return unwrapped;
    }
    if (unwrapped is Map) {
      return Map<String, dynamic>.from(unwrapped);
    }
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic payload) {
    final unwrapped = _unwrapData(payload);
    if (unwrapped is List) {
      return List<dynamic>.from(unwrapped);
    }
    return const <dynamic>[];
  }

  // ─── DELIVERY ORDERS ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> getOrders({
    int skip = 0,
    int limit = 50,
    String? status,
    String? orderType,
  }) async {
    try {
      final params = <String, dynamic>{'skip': skip, 'limit': limit};
      if (status != null) params['status'] = status;
      if (orderType != null) params['order_type'] = orderType;
      final r = await _api.get(
        '/api/v1/admin/logistics/orders',
        queryParameters: params,
      );
      final body = _asMap(r.data);
      if (body.containsKey('orders')) {
        return body;
      }
      final rows = _asList(r.data);
      return {'orders': rows, 'total_count': rows.length};
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPendingApprovals() async {
    try {
      final r = await _api.get(
        '/api/v1/deliveries/',
        queryParameters: {'status': 'pending_admin_approval'},
      );
      final rows = _asList(r.data);
      return {'orders': rows, 'total_count': rows.length};
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> approveOrder(String orderId, {String? notes}) async {
    try {
      final body = <String, dynamic>{};
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }
      await _api.post('/api/v1/deliveries/$orderId/actions/approve', data: body);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> rejectOrder(String orderId, String reason) async {
    try {
      final body = <String, dynamic>{'reason': reason};
      await _api.post('/api/v1/deliveries/$orderId/actions/reject', data: body);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final r = await _api.get(
        '/api/v1/admin/logistics/orders/stats',
        options: Options(
          receiveTimeout: const Duration(seconds: 20),
          extra: const {RetryInterceptor.disableRetryKey: true},
        ),
      );
      return _asMap(r.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateOrderStatus(Object orderId, String newStatus) async {
    try {
      await _api.put(
        '/api/v1/admin/logistics/orders/$orderId/status',
        queryParameters: {'new_status': newStatus},
      );
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // ─── DRIVERS ──────────────────────────────────────────────────────────

  Future<List<dynamic>> getDrivers() async {
    try {
      final r = await _api.get('/api/v1/admin/logistics/drivers');
      return _asList(r.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDriverStats() async {
    try {
      final r = await _api.get('/api/v1/admin/logistics/drivers/stats');
      return _asMap(r.data);
    } catch (e) {
      rethrow;
    }
  }

  // ─── ROUTES ───────────────────────────────────────────────────────────

  Future<List<dynamic>> getRoutes({String? status}) async {
    try {
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;
      final r = await _api.get(
        '/api/v1/admin/logistics/routes',
        queryParameters: params,
      );
      return _asList(r.data);
    } catch (e) {
      rethrow;
    }
  }

  // ─── RETURNS ──────────────────────────────────────────────────────────

  Future<List<dynamic>> getReturns({String? status}) async {
    try {
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;
      final r = await _api.get(
        '/api/v1/admin/logistics/returns',
        queryParameters: params,
      );
      return _asList(r.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getReturnStats() async {
    try {
      final r = await _api.get('/api/v1/admin/logistics/returns/stats');
      return _asMap(r.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateReturnStatus(
    int returnId,
    String newStatus, {
    String? notes,
  }) async {
    try {
      final params = <String, dynamic>{'new_status': newStatus};
      if (notes != null) params['notes'] = notes;
      await _api.put(
        '/api/v1/admin/logistics/returns/$returnId/status',
        queryParameters: params,
      );
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // ─── TRACKING ─────────────────────────────────────────────────────────

  Future<List<dynamic>> getLiveTracking() async {
    try {
      final r = await _api.get('/api/v1/admin/logistics/tracking');
      return _asList(r.data);
    } catch (e) {
      rethrow;
    }
  }

  // ─── CENTRAL INVENTORY → WAREHOUSE ASSIGNMENT ─────────────────────────

  /// Batteries in central inventory (location_type=warehouse, location_id=null).
  Future<Map<String, dynamic>> getCentralInventoryBatteries({
    String? search,
    String? batteryType,
    int offset = 0,
    int limit = 100,
  }) async {
    final params = <String, dynamic>{'offset': offset, 'limit': limit};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (batteryType != null && batteryType != 'All') params['battery_type'] = batteryType;
    final r = await _api.get(
      '/api/v1/admin/batteries/central-inventory',
      queryParameters: params,
    );
    final data = _asMap(r.data);
    return {
      'items': _asList(data['items'] ?? r.data),
      'total_count': data['total_count'] ?? 0,
    };
  }

  /// All active warehouses for the dropdown selector.
  Future<List<Map<String, dynamic>>> getWarehouses() async {
    final r = await _api.get('/api/v1/warehouses/', queryParameters: {'limit': 200});
    return _asList(r.data).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Assign selected batteries from central inventory to a warehouse.
  Future<Map<String, dynamic>> assignBatteriesToWarehouse({
    required List<int> batteryIds,
    required int warehouseId,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'battery_ids': batteryIds,
      'warehouse_id': warehouseId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    final r = await _api.post('/api/v1/admin/batteries/assign-warehouse', data: body);
    return _asMap(r.data);
  }
}
