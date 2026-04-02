import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.watch(apiClientProvider));
});

class SupportTicket {
  final int id;
  final String subject;
  final String description;
  final String status;
  final String priority;
  final String category;
  final int userId;
  final String userName;
  final String userRole;
  final int? assignedTo;
  final String assigneeName;
  final int messageCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.userId,
    required this.userName,
    required this.userRole,
    this.assignedTo,
    required this.assigneeName,
    required this.messageCount,
    this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'],
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 'medium',
      category: json['category'] ?? 'general',
      userId: json['user_id'],
      userName: json['user_name'] ?? 'Unknown',
      userRole: json['user_role'] ?? 'customer',
      assignedTo: json['assigned_to'],
      assigneeName: json['assignee_name'] ?? 'Unassigned',
      messageCount: json['message_count'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
    );
  }
}

class TicketMessage {
  final int id;
  final int senderId;
  final String senderName;
  final String message;
  final bool isInternalNote;
  final DateTime? createdAt;

  const TicketMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.isInternalNote,
    this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'],
      senderId: json['sender_id'] ?? 0,
      senderName: json['sender_name'] ?? 'Unknown',
      message: json['message'] ?? '',
      isInternalNote: json['is_internal_note'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
}

class TicketDetail extends SupportTicket {
  final List<TicketMessage> messages;

  const TicketDetail({
    required super.id,
    required super.subject,
    required super.description,
    required super.status,
    required super.priority,
    required super.category,
    required super.userId,
    required super.userName,
    required super.userRole,
    super.assignedTo,
    required super.assigneeName,
    required super.messageCount,
    super.createdAt,
    super.updatedAt,
    super.resolvedAt,
    required this.messages,
  });

  factory TicketDetail.fromJson(Map<String, dynamic> json) {
    final t = SupportTicket.fromJson(json);
    final msgs = (json['messages'] as List?)?.map((m) => TicketMessage.fromJson(m)).toList() ?? [];
    return TicketDetail(
      id: t.id,
      subject: t.subject,
      description: t.description,
      status: t.status,
      priority: t.priority,
      category: t.category,
      userId: t.userId,
      userName: t.userName,
      userRole: t.userRole,
      assignedTo: t.assignedTo,
      assigneeName: t.assigneeName,
      messageCount: msgs.length,
      createdAt: t.createdAt,
      updatedAt: t.updatedAt,
      resolvedAt: t.resolvedAt,
      messages: msgs,
    );
  }
}

class KnowledgeBaseArticle {
  final int id;
  final String question;
  final String answer;
  final String category;
  final bool isActive;
  final int helpfulCount;
  final int notHelpfulCount;

  const KnowledgeBaseArticle({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.isActive,
    required this.helpfulCount,
    required this.notHelpfulCount,
  });

  factory KnowledgeBaseArticle.fromJson(Map<String, dynamic> json) {
    return KnowledgeBaseArticle(
      id: json['id'],
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      category: json['category'] ?? 'general',
      isActive: json['is_active'] ?? true,
      helpfulCount: json['helpful_count'] ?? 0,
      notHelpfulCount: json['not_helpful_count'] ?? 0,
    );
  }
}

class AgentPerformance {
  final int agentId;
  final String agentName;
  final int totalAssigned;
  final int resolved;
  final int open;
  final double resolutionRate;
  final double avgResolutionHours;
  final double csatScore;

  const AgentPerformance({
    required this.agentId,
    required this.agentName,
    required this.totalAssigned,
    required this.resolved,
    required this.open,
    required this.resolutionRate,
    required this.avgResolutionHours,
    required this.csatScore,
  });

  factory AgentPerformance.fromJson(Map<String, dynamic> json) {
    return AgentPerformance(
      agentId: json['agent_id'],
      agentName: json['agent_name'] ?? 'Unknown',
      totalAssigned: json['total_assigned'] ?? 0,
      resolved: json['resolved'] ?? 0,
      open: json['open'] ?? 0,
      resolutionRate: (json['resolution_rate'] ?? 0).toDouble(),
      avgResolutionHours: (json['avg_resolution_hours'] ?? 0).toDouble(),
      csatScore: (json['csat_score'] ?? 0).toDouble(),
    );
  }
}

class DailyTrend {
  final String date;
  final int created;
  final int resolved;

  const DailyTrend({required this.date, required this.created, required this.resolved});

  factory DailyTrend.fromJson(Map<String, dynamic> json) {
    return DailyTrend(
      date: json['date'] ?? '',
      created: json['created'] ?? 0,
      resolved: json['resolved'] ?? 0,
    );
  }
}

class SupportRepository {
  final ApiClient _apiClient;

  SupportRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  // TICKETS
  Future<Map<String, dynamic>> getTicketsStats() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/support/tickets/stats');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SupportTicket>> getTickets({String? status, String? priority, String? source, String? search}) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': 100,
      };
      if (status != null && status.isNotEmpty && status != 'all') queryParams['status'] = status;
      if (priority != null && priority.isNotEmpty && priority != 'all') queryParams['priority'] = priority;
      if (source != null && source.isNotEmpty && source != 'all') queryParams['source'] = source;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.get('/api/v1/admin/support/tickets', queryParameters: queryParams);
      return (response.data['tickets'] as List).map((json) => SupportTicket.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<TicketDetail?> getTicketDetail(int ticketId) async {
    try {
      final response = await _apiClient.get('/api/v1/admin/support/tickets/$ticketId');
      return TicketDetail.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateTicketStatus(int ticketId, String newStatus) async {
    try {
      await _apiClient.put('/api/v1/admin/support/tickets/$ticketId/status', queryParameters: {'new_status': newStatus});
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateTicketPriority(int ticketId, String priority) async {
    try {
      await _apiClient.put('/api/v1/admin/support/tickets/$ticketId/priority', queryParameters: {'priority': priority});
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> assignTicket(int ticketId, int agentId) async {
    try {
      await _apiClient.put('/api/v1/admin/support/tickets/$ticketId/assign', queryParameters: {'agent_id': agentId});
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> addTicketMessage(int ticketId, String message, {bool isInternal = false}) async {
    try {
      await _apiClient.post(
        '/api/v1/admin/support/tickets/$ticketId/messages',
        queryParameters: {
          'message': message,
          'is_internal': isInternal,
        },
      );
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // KNOWLEDGE BASE
  Future<Map<String, dynamic>> getKnowledgeBaseStats() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/support/knowledge-base/stats');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<KnowledgeBaseArticle>> getArticles({String? category, String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty && category != 'all') queryParams['category'] = category;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.get('/api/v1/admin/support/knowledge-base', queryParameters: queryParams);
      return (response.data['articles'] as List).map((json) => KnowledgeBaseArticle.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> createArticle(String question, String answer, String category, bool isActive) async {
    try {
      await _apiClient.post(
        '/api/v1/admin/support/knowledge-base',
        data: {
          'question': question,
          'answer': answer,
          'category': category,
          'is_active': isActive,
        },
      );
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateArticle(int id, String question, String answer, String category, bool isActive) async {
    try {
      await _apiClient.put(
        '/api/v1/admin/support/knowledge-base/$id',
        data: {
          'question': question,
          'answer': answer,
          'category': category,
          'is_active': isActive,
        },
      );
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteArticle(int id) async {
    try {
      await _apiClient.delete('/api/v1/admin/support/knowledge-base/$id');
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // TEAM PERFORMANCE
  Future<Map<String, dynamic>> getTeamPerformance() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/support/team/performance');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DailyTrend>> getTeamOverviewTrends() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/support/team/overview');
      return (response.data['daily_trends'] as List).map((j) => DailyTrend.fromJson(j)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
