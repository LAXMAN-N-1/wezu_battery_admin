import '../models/transaction.dart';

class FinanceRepository {
  Future<Map<String, dynamic>> getFinanceDashboardData() async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Mock Monthly Revenue Data (Last 6 Months)
    final revenueData = [
      {'month': 'Jan', 'value': 45000.0},
      {'month': 'Feb', 'value': 52000.0},
      {'month': 'Mar', 'value': 49000.0},
      {'month': 'Apr', 'value': 61000.0},
      {'month': 'May', 'value': 58000.0},
      {'month': 'Jun', 'value': 75000.0},
    ];

    final transactions = [
      Transaction(
        id: 'TXN_1001',
        userId: 'USER_882',
        userName: 'Murari Vama',
        amount: 250.0,
        type: 'rental',
        status: 'success',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      Transaction(
        id: 'TXN_1002',
        userId: 'USER_104',
        userName: 'Rahul Sharma',
        amount: 5000.0,
        type: 'subscription',
        status: 'success',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Transaction(
        id: 'TXN_1003',
        userId: 'USER_332',
        userName: 'Priya Singh',
        amount: 150.0,
        type: 'refund',
        status: 'pending',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
       Transaction(
        id: 'TXN_1004',
        userId: 'USER_445',
        userName: 'Amit Patel',
        amount: 350.0,
        type: 'rental',
        status: 'failed',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    return {
      'totalRevenue': 340000.0,
      'monthlyGrowth': 12.5,
      'revenueChart': revenueData,
      'recentTransactions': transactions,
    };
  }
}
