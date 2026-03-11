import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/transaction.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(ref.read(apiClientProvider));
});

class FinanceRepository {
  final ApiClient _apiClient;

  FinanceRepository(this._apiClient);

  Future<Map<String, dynamic>> getFinanceDashboardData() async {
    final response = await _apiClient.get('/api/v1/admin/finance/transactions');
    
    List<Transaction> transactions = [];
    if (response.data is List) {
      transactions = (response.data as List).map((e) => Transaction.fromJson(e)).toList();
    }

    // Since backend doesn't provide a combined dashboard endpoint yet,
    // we'll calculate stats from the transactions we have.
    double totalRevenue = 0;
    for (var tx in transactions) {
      if (tx.status == 'success') {
        totalRevenue += tx.amount.abs();
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'monthlyGrowth': 0.0,
      'recentTransactions': transactions,
    };
  }
}
