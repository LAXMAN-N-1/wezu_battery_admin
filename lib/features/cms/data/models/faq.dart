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
    return FAQ(
      id: json['id'] as int,
      question: json['question'] as String,
      answer: json['answer'] as String,
      category: json['category'] as String? ?? 'general',
      isActive: json['is_active'] as bool? ?? true,
      helpfulCount: json['helpful_count'] as int? ?? 0,
      notHelpfulCount: json['not_helpful_count'] as int? ?? 0,
      targetAudience: (json['target_audience'] as List?)?.map((e) => e as String).toList() ?? ['All Users'],
      displayOrder: json['display_order'] as int? ?? 0,
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
