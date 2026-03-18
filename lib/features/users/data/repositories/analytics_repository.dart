import '../models/fraud_risk.dart';
import '../models/suspension_record.dart';
import '../models/invite_link.dart';

class AnalyticsRepository {
  Future<List<FraudRisk>> getFraudRisks() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      FraudRisk(
        userId: 10, userName: 'Kavita Reddy', score: 78, level: 'critical',
        lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
        factors: const [
          FraudFactor(name: 'Spending Spike', description: '340% increase in spending over 7 days', contribution: 35, severity: 'high'),
          FraudFactor(name: 'Geographic Jump', description: 'Logged in from 3 cities in one day', contribution: 25, severity: 'high'),
          FraudFactor(name: 'Device Changes', description: '4 new devices in last week', contribution: 18, severity: 'medium'),
        ],
        history: [
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 30)), score: 15),
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 25)), score: 20),
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 20)), score: 28),
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 15)), score: 45),
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 10)), score: 62),
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 5)), score: 72),
          FraudScoreHistory(date: DateTime.now(), score: 78),
        ],
      ),
      FraudRisk(
        userId: 5, userName: 'Suresh Kumar', score: 62, level: 'high',
        lastUpdated: DateTime.now().subtract(const Duration(hours: 6)),
        factors: const [
          FraudFactor(name: 'Non-Compliance', description: 'Multiple policy violations in 30 days', contribution: 30, severity: 'high'),
          FraudFactor(name: 'Rental Anomaly', description: 'Unusual rental pattern detected', contribution: 20, severity: 'medium'),
          FraudFactor(name: 'Late Returns', description: '5 consecutive late battery returns', contribution: 12, severity: 'medium'),
        ],
        history: [
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 30)), score: 30),
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 20)), score: 42),
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 10)), score: 55),
          FraudScoreHistory(date: DateTime.now(), score: 62),
        ],
      ),
      FraudRisk(
        userId: 9, userName: 'Vikram Malhotra', score: 45, level: 'medium',
        lastUpdated: DateTime.now().subtract(const Duration(hours: 12)),
        factors: const [
          FraudFactor(name: 'Spending Pattern', description: 'Irregular spending pattern detected', contribution: 25, severity: 'medium'),
          FraudFactor(name: 'Multiple Accounts', description: 'Possible duplicate account detected', contribution: 20, severity: 'medium'),
        ],
        history: [
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 20)), score: 22),
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 10)), score: 35),
          FraudScoreHistory(date: DateTime.now(), score: 45),
        ],
      ),
      FraudRisk(
        userId: 4, userName: 'Priya Singh', score: 22, level: 'low',
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
        factors: const [
          FraudFactor(name: 'New User', description: 'Account less than 30 days old', contribution: 12, severity: 'low'),
          FraudFactor(name: 'KYC Pending', description: 'KYC not yet submitted', contribution: 10, severity: 'low'),
        ],
        history: [
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 10)), score: 18),
          FraudScoreHistory(date: DateTime.now(), score: 22),
        ],
      ),
    ];
  }

  Future<List<SuspensionRecord>> getSuspensionHistory() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      SuspensionRecord(
        id: 1, userId: 5, userName: 'Suresh Kumar', reason: 'non_compliance',
        notes: 'Repeated policy violations regarding battery handling',
        suspendedBy: 'Murari Varma', suspendedAt: DateTime(2025, 2, 28),
        reactivateAt: DateTime(2025, 3, 14), isActive: true,
      ),
      SuspensionRecord(
        id: 2, userId: 10, userName: 'Kavita Reddy', reason: 'fraud',
        notes: 'Suspicious financial activity detected — under investigation',
        suspendedBy: 'Murari Varma', suspendedAt: DateTime(2025, 2, 25),
        isActive: true,
      ),
      SuspensionRecord(
        id: 3, userId: 4, userName: 'Priya Singh', reason: 'user_request',
        notes: 'User requested temporary account deactivation',
        suspendedBy: 'Deepak Verma', suspendedAt: DateTime(2025, 2, 10),
        reactivateAt: DateTime(2025, 2, 20),
        reactivatedAt: DateTime(2025, 2, 20), reactivatedBy: 'Deepak Verma',
        isActive: false,
      ),
    ];
  }

  Future<List<InviteLink>> getInviteLinks() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      InviteLink(
        id: 1, token: 'inv-a1b2c3d4', email: 'newdriver@gmail.com', role: 'driver',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: DateTime.now().add(const Duration(days: 5)),
        createdBy: 'Murari Varma',
      ),
      InviteLink(
        id: 2, token: 'inv-e5f6g7h8', email: 'partner@energyco.in', role: 'dealer',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        expiresAt: DateTime.now().add(const Duration(days: 2)),
        createdBy: 'Murari Varma',
      ),
      InviteLink(
        id: 3, token: 'inv-i9j0k1l2', email: 'oldinvite@test.com', role: 'customer',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        expiresAt: DateTime.now().subtract(const Duration(days: 3)),
        createdBy: 'Deepak Verma',
      ),
      InviteLink(
        id: 4, token: 'inv-m3n4o5p6', email: 'usedinvite@test.com', role: 'driver',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        createdBy: 'Murari Varma',
        usedAt: DateTime.now().subtract(const Duration(days: 6)),
        isUsed: true,
      ),
    ];
  }

  /// Login history data for charts
  Future<List<Map<String, dynamic>>> getLoginHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.generate(30, (i) {
      final date = DateTime.now().subtract(Duration(days: 29 - i));
      return {
        'date': date,
        'logins': 50 + (i * 3) + (i % 7 == 0 ? -20 : i % 5 == 0 ? 15 : 0),
      };
    });
  }

  /// Rental frequency data for charts
  Future<List<Map<String, dynamic>>> getRentalFrequency() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {'month': 'Sep', 'rentals': 120},
      {'month': 'Oct', 'rentals': 185},
      {'month': 'Nov', 'rentals': 210},
      {'month': 'Dec', 'rentals': 168},
      {'month': 'Jan', 'rentals': 245},
      {'month': 'Feb', 'rentals': 290},
    ];
  }

  /// Device breakdown for pie chart
  Future<Map<String, int>> getDeviceBreakdown() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'Android App': 58,
      'iOS App': 24,
      'Web Browser': 12,
      'Other': 6,
    };
  }
}
