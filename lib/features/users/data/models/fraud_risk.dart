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

  factory FraudRisk.fromJson(Map<String, dynamic> json) {
    var rawScore = (json['score'] ?? json['risk_score'] ?? 0) as num;
    var score = rawScore.toInt();
    
    return FraudRisk(
      userId: json['id'] ?? json['user_id'] ?? 0,
      userName: json['full_name'] ?? json['user_name'] ?? 'Unknown User',
      score: score,
      level: levelFromScore(score),
      factors: (json['factors'] as List? ?? [])
          .map((f) => FraudFactor.fromJson(f))
          .toList(),
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated']) 
          : DateTime.now(),
      history: (json['history'] as List? ?? [])
          .map((h) => FraudScoreHistory.fromJson(h))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'score': score,
      'level': level,
      'factors': factors.map((e) => e.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
      'history': history.map((e) => e.toJson()).toList(),
    };
  }

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

  factory FraudFactor.fromJson(Map<String, dynamic> json) {
    return FraudFactor(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      contribution: json['contribution'] ?? 0,
      severity: json['severity'] ?? 'low',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'contribution': contribution,
      'severity': severity,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'score': score,
    };
  }
}
