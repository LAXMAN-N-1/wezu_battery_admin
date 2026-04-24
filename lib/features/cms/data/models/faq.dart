int _toInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _toBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return fallback;
}

class FAQ {
  final int id;
  final String question;
  final String answer;
  final String category;
  final bool isActive;
  final int helpfulCount;
  final int notHelpfulCount;
  final List<String> targetAudience;
  final int displayOrder;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.isActive,
    required this.helpfulCount,
    required this.notHelpfulCount,
    this.targetAudience = const ['All Users'],
    this.displayOrder = 0,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    final audienceRaw = json['target_audience'];
    final audience = audienceRaw is List
        ? audienceRaw.map((e) => e.toString()).toList()
        : <String>['All Users'];

    return FAQ(
      id: _toInt(json['id']),
      question: (json['question'] ?? '').toString(),
      answer: (json['answer'] ?? '').toString(),
      category: (json['category'] ?? 'general').toString(),
      isActive: _toBool(json['is_active'], true),
      helpfulCount: _toInt(json['helpful_count']),
      notHelpfulCount: _toInt(json['not_helpful_count']),
      targetAudience: audience,
      displayOrder: _toInt(json['display_order']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      'category': category,
      'is_active': isActive,
      'target_audience': targetAudience,
      'display_order': displayOrder,
    };
  }

  FAQ copyWith({
    int? id,
    String? question,
    String? answer,
    String? category,
    bool? isActive,
    int? helpfulCount,
    int? notHelpfulCount,
    List<String>? targetAudience,
    int? displayOrder,
  }) {
    return FAQ(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      notHelpfulCount: notHelpfulCount ?? this.notHelpfulCount,
      targetAudience: targetAudience ?? this.targetAudience,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}
