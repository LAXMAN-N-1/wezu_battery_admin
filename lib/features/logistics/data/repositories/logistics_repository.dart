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
      final r = await _api.get('/api/v1/admin/logistics/orders', queryParameters: params);
      return r.data as Map<String, dynamic>;
    } catch (e) { return {'orders': [], 'total_count': 0}; }
  }

  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final r = await _api.get('/api/v1/admin/logistics/orders/stats');
      return r.data as Map<String, dynamic>;
    } catch (e) { return {'total_orders': 0, 'pending': 0, 'in_transit': 0, 'delivered': 0, 'failed': 0}; }
  }

  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    try {
      await _api.put('/api/v1/admin/logistics/orders/$orderId/status', queryParameters: {'new_status': newStatus});
      return true;
    } catch (e) { return false; }
  }

  // ─── DRIVERS ──────────────────────────────────────────────────────────

  Future<List<dynamic>> getDrivers() async {
    try {
      final r = await _api.get('/api/v1/admin/logistics/drivers');
      return r.data as List<dynamic>;
    } catch (e) { return []; }
  }

  Future<Map<String, dynamic>> getDriverStats() async {
    try {
      final r = await _api.get('/api/v1/admin/logistics/drivers/stats');
      return r.data as Map<String, dynamic>;
    } catch (e) { return {'total_drivers': 0, 'online_drivers': 0, 'offline_drivers': 0, 'avg_rating': 0.0, 'total_deliveries': 0}; }
  }

  // ─── ROUTES ───────────────────────────────────────────────────────────

  Future<List<dynamic>> getRoutes({String? status}) async {
    try {
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;
      final r = await _api.get('/api/v1/admin/logistics/routes', queryParameters: params);
      return r.data as List<dynamic>;
    } catch (e) { return []; }
  }

  // ─── RETURNS ──────────────────────────────────────────────────────────

  Future<List<dynamic>> getReturns({String? status}) async {
    try {
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;
      final r = await _api.get('/api/v1/admin/logistics/returns', queryParameters: params);
      return r.data as List<dynamic>;
    } catch (e) { return []; }
  }

  Future<Map<String, dynamic>> getReturnStats() async {
    try {
      final r = await _api.get('/api/v1/admin/logistics/returns/stats');
      return r.data as Map<String, dynamic>;
    } catch (e) { return {'total_returns': 0, 'pending': 0, 'completed': 0, 'total_refund_amount': 0.0}; }
  }

  Future<bool> updateReturnStatus(int returnId, String newStatus, {String? notes}) async {
    try {
      final params = <String, dynamic>{'new_status': newStatus};
      if (notes != null) params['notes'] = notes;
      await _api.put('/api/v1/admin/logistics/returns/$returnId/status', queryParameters: params);
      return true;
    } catch (e) { return false; }
  }

  // ─── TRACKING ─────────────────────────────────────────────────────────

  Future<List<dynamic>> getLiveTracking() async {
    try {
      final r = await _api.get('/api/v1/admin/logistics/tracking');
      return r.data as List<dynamic>;
    } catch (e) { return []; }
  }
}
