import '../../../../core/api/api_client.dart';
import '../models/transaction.dart';

class FinanceRepository {
  final ApiClient _api;
  FinanceRepository([ApiClient? api]) : _api = api ?? ApiClient();

  // ─── DASHBOARD ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getFinanceDashboardData({String period = '30d'}) async {
    try {
      final response = await _api.get('/api/v1/admin/finance/dashboard', queryParameters: {'period': period});
      final data = response.data as Map<String, dynamic>;

      // Parse recent transactions
      final txnList = (data['recent_transactions'] as List?)?.map((t) => Transaction(
        id: t['id']?.toString() ?? '',
        userId: t['user_id']?.toString() ?? '',
        userName: t['user_name'] ?? 'Unknown',
        amount: (t['amount'] as num?)?.toDouble() ?? 0.0,
        type: t['type'] ?? '',
        status: t['status'] ?? '',
        timestamp: DateTime.tryParse(t['timestamp'] ?? '') ?? DateTime.now(),
      )).toList() ?? [];

      return {
        'totalRevenue': (data['total_revenue'] as num?)?.toDouble() ?? 0.0,
        'periodRevenue': (data['period_revenue'] as num?)?.toDouble() ?? 0.0,
        'monthlyGrowth': (data['monthly_growth'] as num?)?.toDouble() ?? 0.0,
        'revenueChart': List<Map<String, dynamic>>.from(data['revenue_chart'] ?? []),
        'revenueByType': List<Map<String, dynamic>>.from(data['revenue_by_type'] ?? []),
        'recentTransactions': txnList,
        'totalTransactions': data['total_transactions'] ?? 0,
        'successRate': (data['success_rate'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      rethrow;
    }
  }

  // ─── TRANSACTIONS ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTransactions({int skip = 0, int limit = 100, String? type, String? status}) async {
    try {
      final params = <String, dynamic>{'skip': skip, 'limit': limit};
      if (type != null) params['type'] = type;
      if (status != null) params['status'] = status;
      final response = await _api.get('/api/v1/admin/finance/transactions', queryParameters: params);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTransactionStats() async {
    try {
      final response = await _api.get('/api/v1/admin/finance/transactions/stats');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ─── SETTLEMENTS ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSettlements({int skip = 0, int limit = 50, String? status}) async {
    try {
      final params = <String, dynamic>{'skip': skip, 'limit': limit};
      if (status != null) params['status'] = status;
      final response = await _api.get('/api/v1/admin/finance/settlements', queryParameters: params);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSettlementStats() async {
    try {
      final response = await _api.get('/api/v1/admin/finance/settlements/stats');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> approveSettlement(int id) async {
    try {
      await _api.put('/api/v1/admin/finance/settlements/$id/approve');
      return true;
    } catch (e) { rethrow; }
  }

  // ─── INVOICES ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getInvoices({int skip = 0, int limit = 50, String? search}) async {
    try {
      final params = <String, dynamic>{'skip': skip, 'limit': limit};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final response = await _api.get('/api/v1/admin/finance/invoices', queryParameters: params);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getInvoiceStats() async {
    try {
      final response = await _api.get('/api/v1/admin/finance/invoices/stats');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ─── PROFIT ANALYSIS ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfitAnalysis() async {
    try {
      final response = await _api.get('/api/v1/admin/finance/profit/analysis');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
