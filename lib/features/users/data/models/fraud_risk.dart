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

  factory FraudRisk.fromJson(Map<String, dynamic> json) {
    return FraudRisk(
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? '',
      score: json['score'] ?? 0,
      level: json['level'] ?? levelFromScore(json['score'] ?? 0),
      factors: (json['factors'] as List?)
              ?.map((e) => FraudFactor.fromJson(e))
              .toList() ??
          [],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : DateTime.now(),
      history: (json['history'] as List?)
              ?.map((e) => FraudScoreHistory.fromJson(e))
              .toList() ??
          [],
    );
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

  factory FraudFactor.fromJson(Map<String, dynamic> json) {
    return FraudFactor(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      contribution: json['contribution'] ?? 0,
      severity: json['severity'] ?? 'low',
    );
  }
}

class FraudScoreHistory {
  final DateTime date;
  final int score;

  const FraudScoreHistory({
    required this.date,
    required this.score,
  });

  factory FraudScoreHistory.fromJson(Map<String, dynamic> json) {
    return FraudScoreHistory(
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      score: json['score'] ?? 0,
    );
  }
}
