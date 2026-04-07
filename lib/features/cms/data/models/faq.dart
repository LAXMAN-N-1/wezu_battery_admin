class FAQ {
  final int id;
  final String question;
  final String answer;
  final String category;
  final bool isActive;
  final int helpfulCount;
  final int notHelpfulCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.isActive,
    required this.helpfulCount,
    required this.notHelpfulCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id'] ?? 0,
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      category: json['category'] ?? 'general',
      isActive: json['is_active'] ?? true,
      helpfulCount: json['helpful_count'] ?? 0,
      notHelpfulCount: json['not_helpful_count'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      'category': category,
      'is_active': isActive,
    };
  }

  FAQ copyWith({
    String? question,
    String? answer,
    String? category,
    bool? isActive,
  }) {
    return FAQ(
      id: id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      helpfulCount: helpfulCount,
      notHelpfulCount: notHelpfulCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
