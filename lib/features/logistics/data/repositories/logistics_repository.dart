import '../../../../core/api/api_client.dart';

class LogisticsRepository {
  final ApiClient _api;
  LogisticsRepository([ApiClient? api]) : _api = api ?? ApiClient();

  // ─── DELIVERY ORDERS ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> getOrders({int skip = 0, int limit = 50, String? status, String? orderType}) async {
    try {
      final params = <String, dynamic>{'skip': skip, 'limit': limit};
      if (status != null) params['status'] = status;
      if (orderType != null) params['order_type'] = orderType;
      final r = await _api.get('/api/v1/logistics/orders', queryParameters: params);
      return r.data as Map<String, dynamic>;
    } catch (e) { rethrow; }
  }

  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final r = await _api.get('/api/v1/logistics/dashboard');
      return r.data as Map<String, dynamic>;
    } catch (e) { rethrow; }
  }

  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    try {
      await _api.put('/api/v1/logistics/orders/$orderId/status', queryParameters: {'new_status': newStatus});
      return true;
    } catch (e) { rethrow; }
  }

  // ─── DRIVERS ──────────────────────────────────────────────────────────

  Future<List<dynamic>> getDrivers() async {
    try {
      final r = await _api.get('/api/v1/logistics/drivers');
      return r.data as List<dynamic>;
    } catch (e) { rethrow; }
  }

  Future<Map<String, dynamic>> getDriverStats() async {
    try {
      final r = await _api.get('/api/v1/logistics/performance');
      return r.data as Map<String, dynamic>;
    } catch (e) { rethrow; }
  }

  // ─── ROUTES ───────────────────────────────────────────────────────────

  Future<List<dynamic>> getRoutes({String? status}) async {
    try {
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;
      final r = await _api.get('/api/v1/logistics/routes/history', queryParameters: params);
      return r.data as List<dynamic>;
    } catch (e) { rethrow; }
  }

  // ─── RETURNS ──────────────────────────────────────────────────────────

  Future<List<dynamic>> getReturns({String? status}) async {
    try {
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;
      params['order_type'] = 'return';
      final r = await _api.get('/api/v1/logistics/orders', queryParameters: params);
      return r.data as List<dynamic>;
    } catch (e) { rethrow; }
  }

  Future<Map<String, dynamic>> getReturnStats() async {
    try {
      final r = await _api.get('/api/v1/logistics/dashboard');
      return r.data as Map<String, dynamic>;
    } catch (e) { rethrow; }
  }

  Future<bool> updateReturnStatus(int returnId, String newStatus, {String? notes}) async {
    try {
      final params = <String, dynamic>{'new_status': newStatus};
      if (notes != null) params['notes'] = notes;
      await _api.put('/api/v1/logistics/orders/$returnId/status', queryParameters: params);
      return true;
    } catch (e) { rethrow; }
  }

  // ─── TRACKING ─────────────────────────────────────────────────────────

  Future<List<dynamic>> getLiveTracking() async {
    try {
      final r = await _api.get('/api/v1/logistics/deliveries/active');
      return r.data as List<dynamic>;
    } catch (e) { rethrow; }
  }
}
