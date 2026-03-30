class FraudRisk {
  final int userId;
  final String userName;
  final int score; // 0-100
  final String level; // 'low', 'medium', 'high', 'critical'
  final List<FraudFactor> factors;
  final DateTime lastUpdated;
  final List<FraudScoreHistory> history;

  const FraudRisk({
    required this.userId,
    required this.userName,
    required this.score,
    required this.level,
    required this.factors,
    required this.lastUpdated,
    this.history = const [],
  });

  static String levelFromScore(int score) {
    if (score >= 75) return 'critical';
    if (score >= 50) return 'high';
    if (score >= 25) return 'medium';
    return 'low';
  }
}

class FraudFactor {
  final String name;
  final String description;
  final int contribution; // 0-100 how much this factor adds to the score
  final String severity; // 'low', 'medium', 'high'

  const FraudFactor({
    required this.name,
    required this.description,
    required this.contribution,
    required this.severity,
  });
}

class FraudScoreHistory {
  final DateTime date;
  final int score;

  const FraudScoreHistory({
    required this.date,
    required this.score,
  });
}
