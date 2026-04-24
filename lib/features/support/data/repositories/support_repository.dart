import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';

int _toInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _toDouble(dynamic value, [double fallback = 0.0]) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
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

DateTime? _toDate(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const <dynamic>[];
}

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
      id: _toInt(json['id']),
      subject: (json['subject'] ?? json['title'] ?? '').toString(),
      description: (json['description'] ?? json['message'] ?? '').toString(),
      status: (json['status'] ?? 'open').toString(),
      priority: (json['priority'] ?? 'medium').toString(),
      category: (json['category'] ?? 'general').toString(),
      userId: _toInt(json['user_id'] ?? json['customer_id']),
      userName:
          (json['user_name'] ?? json['customer_name'] ?? 'Unknown').toString(),
      userRole: (json['user_role'] ?? json['source'] ?? 'customer').toString(),
      assignedTo:
          json['assigned_to'] == null ? null : _toInt(json['assigned_to']),
      assigneeName: (json['assignee_name'] ?? json['agent_name'] ?? 'Unassigned')
          .toString(),
      messageCount: _toInt(json['message_count'] ?? json['messages_count']),
      createdAt: _toDate(json['created_at']),
      updatedAt: _toDate(json['updated_at']),
      resolvedAt: _toDate(json['resolved_at']),
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
      id: _toInt(json['id']),
      senderId: _toInt(json['sender_id'] ?? json['user_id']),
      senderName: (json['sender_name'] ?? json['user_name'] ?? 'Unknown')
          .toString(),
      message: (json['message'] ?? '').toString(),
      isInternalNote: _toBool(json['is_internal_note']),
      createdAt: _toDate(json['created_at']),
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
    final ticket = SupportTicket.fromJson(json);
    final messages = _asList(json['messages'])
        .whereType<Map>()
        .map((m) => TicketMessage.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    return TicketDetail(
      id: ticket.id,
      subject: ticket.subject,
      description: ticket.description,
      status: ticket.status,
      priority: ticket.priority,
      category: ticket.category,
      userId: ticket.userId,
      userName: ticket.userName,
      userRole: ticket.userRole,
      assignedTo: ticket.assignedTo,
      assigneeName: ticket.assigneeName,
      messageCount: messages.isEmpty ? ticket.messageCount : messages.length,
      createdAt: ticket.createdAt,
      updatedAt: ticket.updatedAt,
      resolvedAt: ticket.resolvedAt,
      messages: messages,
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
      id: _toInt(json['id']),
      question: (json['question'] ?? json['title'] ?? '').toString(),
      answer: (json['answer'] ?? json['content'] ?? '').toString(),
      category: (json['category'] ?? 'general').toString(),
      isActive: _toBool(json['is_active'], true),
      helpfulCount: _toInt(json['helpful_count'] ?? json['likes']),
      notHelpfulCount: _toInt(json['not_helpful_count'] ?? json['dislikes']),
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
      agentId: _toInt(json['agent_id'] ?? json['id'] ?? json['user_id']),
      agentName:
          (json['agent_name'] ?? json['name'] ?? json['user_name'] ?? 'Unknown')
              .toString(),
      totalAssigned: _toInt(json['total_assigned'] ?? json['assigned']),
      resolved: _toInt(json['resolved']),
      open: _toInt(json['open'] ?? json['pending']),
      resolutionRate: _toDouble(json['resolution_rate']),
      avgResolutionHours: _toDouble(
        json['avg_resolution_hours'] ?? json['avg_resolution_time_hours'],
      ),
      csatScore: _toDouble(json['csat_score'] ?? json['rating']),
    );
  }
}

class DailyTrend {
  final String date;
  final int created;
  final int resolved;

  const DailyTrend({
    required this.date,
    required this.created,
    required this.resolved,
  });

  factory DailyTrend.fromJson(Map<String, dynamic> json) {
    return DailyTrend(
      date: (json['date'] ?? json['day'] ?? '').toString(),
      created: _toInt(json['created'] ?? json['created_count']),
      resolved: _toInt(json['resolved'] ?? json['resolved_count']),
    );
  }
}

class SupportRepository {
  final ApiClient _apiClient;

  SupportRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  // TICKETS
  Future<Map<String, dynamic>> getTicketsStats() async {
    try {
      final response = await _getAny(<String>[
        '/api/v1/admin/support/tickets/stats',
        '/api/v1/support/tickets/stats',
      ]);
      return _asMap(response.data);
    } catch (_) {
      return <String, dynamic>{
        'total_tickets': 0,
        'open': 0,
        'in_progress': 0,
        'resolved': 0,
        'closed': 0,
        'overdue': 0,
        'today_new': 0,
        'avg_resolution_hours': 0.0,
        'priority_breakdown': <String, dynamic>{},
        'category_breakdown': <String, dynamic>{},
        'source_breakdown': <String, dynamic>{},
      };
    }
  }

  Future<List<SupportTicket>> getTickets({
    String? status,
    String? priority,
    String? source,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': 100};
      if (status != null && status.isNotEmpty && status != 'all') {
        queryParams['status'] = status;
      }
      if (priority != null && priority.isNotEmpty && priority != 'all') {
        queryParams['priority'] = priority;
      }
      if (source != null && source.isNotEmpty && source != 'all') {
        queryParams['source'] = source;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
        queryParams['q'] = search;
      }

      final response = await _getAny(<String>[
        '/api/v1/admin/support/tickets',
        '/api/v1/support/tickets',
      ], queryParameters: queryParams);

      final map = _asMap(response.data);
      final rows = _asList(
        map.isEmpty ? response.data : (map['tickets'] ?? map['items'] ?? map['data']),
      );

      return rows
          .whereType<Map>()
          .map((json) => SupportTicket.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (_) {
      return <SupportTicket>[];
    }
  }

  Future<TicketDetail?> getTicketDetail(int ticketId) async {
    try {
      final response = await _getAny(<String>[
        '/api/v1/admin/support/tickets/$ticketId',
        '/api/v1/support/tickets/$ticketId',
      ]);
      return TicketDetail.fromJson(_asMap(response.data));
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateTicketStatus(int ticketId, String newStatus) async {
    try {
      await _putAny(<String>['/api/v1/admin/support/tickets/$ticketId/status'],
          queryParameters: <String, dynamic>{'new_status': newStatus});
      return true;
    } catch (_) {
      try {
        await _putAny(<String>['/api/v1/admin/support/tickets/$ticketId/status'],
            data: <String, dynamic>{'new_status': newStatus, 'status': newStatus});
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<bool> updateTicketPriority(int ticketId, String priority) async {
    try {
      await _putAny(<String>['/api/v1/admin/support/tickets/$ticketId/priority'],
          queryParameters: <String, dynamic>{'priority': priority});
      return true;
    } catch (_) {
      try {
        await _putAny(<String>['/api/v1/admin/support/tickets/$ticketId/priority'],
            data: <String, dynamic>{'priority': priority});
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<bool> assignTicket(int ticketId, int agentId) async {
    try {
      await _putAny(<String>['/api/v1/admin/support/tickets/$ticketId/assign'],
          queryParameters: <String, dynamic>{'agent_id': agentId});
      return true;
    } catch (_) {
      try {
        await _putAny(<String>['/api/v1/admin/support/tickets/$ticketId/assign'],
            data: <String, dynamic>{'agent_id': agentId});
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<bool> addTicketMessage(
    int ticketId,
    String message, {
    bool isInternal = false,
  }) async {
    try {
      await _postAny(<String>['/api/v1/admin/support/tickets/$ticketId/messages'],
          data: <String, dynamic>{
            'message': message,
            'is_internal': isInternal,
          });
      return true;
    } catch (_) {
      return false;
    }
  }

  // KNOWLEDGE BASE
  Future<Map<String, dynamic>> getKnowledgeBaseStats() async {
    try {
      final response = await _getAny(<String>[
        '/api/v1/admin/support/knowledge-base/stats',
        '/api/v1/support/faq/stats',
      ]);
      return _asMap(response.data);
    } catch (_) {
      return <String, dynamic>{
        'total_articles': 0,
        'active_articles': 0,
        'total_helpful': 0,
        'total_not_helpful': 0,
        'satisfaction_rate': 0.0,
        'categories': <String, dynamic>{},
      };
    }
  }

  Future<List<KnowledgeBaseArticle>> getArticles({
    String? category,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty && category != 'all') {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
        queryParams['q'] = search;
      }

      final response = await _getAny(
        <String>[
          '/api/v1/admin/support/knowledge-base',
          '/api/v1/support/faq/search',
        ],
        queryParameters: queryParams,
      );

      final map = _asMap(response.data);
      final rows = _asList(
        map.isEmpty
            ? response.data
            : (map['articles'] ?? map['items'] ?? map['data']),
      );

      return rows
          .whereType<Map>()
          .map(
            (json) =>
                KnowledgeBaseArticle.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } catch (_) {
      return <KnowledgeBaseArticle>[];
    }
  }

  Future<bool> createArticle(
    String question,
    String answer,
    String category,
    bool isActive,
  ) async {
    try {
      await _postAny(<String>['/api/v1/admin/support/knowledge-base'], data: <String, dynamic>{
        'question': question,
        'answer': answer,
        'category': category,
        'is_active': isActive,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateArticle(
    int id,
    String question,
    String answer,
    String category,
    bool isActive,
  ) async {
    try {
      await _putAny(<String>['/api/v1/admin/support/knowledge-base/$id'], data: <String, dynamic>{
        'question': question,
        'answer': answer,
        'category': category,
        'is_active': isActive,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteArticle(int id) async {
    try {
      await _apiClient.delete('/api/v1/admin/support/knowledge-base/$id');
      return true;
    } catch (_) {
      return false;
    }
  }

  // TEAM PERFORMANCE
  Future<Map<String, dynamic>> getTeamPerformance() async {
    try {
      final response = await _getAny(<String>['/api/v1/admin/support/team/performance']);
      final raw = _asMap(response.data);
      final rawAgents = _asList(raw['agents']);
      final agents = rawAgents
          .whereType<Map>()
          .map((a) => AgentPerformance.fromJson(Map<String, dynamic>.from(a)))
          .toList();

      return <String, dynamic>{
        'agents': agents,
        'sla_metrics': _asMap(raw['sla_metrics']),
      };
    } catch (_) {
      return <String, dynamic>{
        'agents': <AgentPerformance>[],
        'sla_metrics': <String, dynamic>{
          'critical_breach_4h': 0,
          'general_breach_24h': 0,
          'avg_first_response_minutes': 0,
        },
      };
    }
  }

  Future<List<DailyTrend>> getTeamOverviewTrends() async {
    try {
      final response = await _getAny(<String>['/api/v1/admin/support/team/overview']);
      final map = _asMap(response.data);
      final rows = _asList(map['daily_trends'] ?? map['trends'] ?? response.data);
      return rows
          .whereType<Map>()
          .map((j) => DailyTrend.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    } catch (_) {
      return <DailyTrend>[];
    }
  }

  Future<dynamic> _getAny(
    List<String> paths, {
    Map<String, dynamic>? queryParameters,
  }) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _apiClient.get(path, queryParameters: queryParameters);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('GET failed for all support endpoints');
  }

  Future<dynamic> _postAny(
    List<String> paths, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _apiClient.post(
          path,
          data: data,
          queryParameters: queryParameters,
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('POST failed for all support endpoints');
  }

  Future<dynamic> _putAny(
    List<String> paths, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _apiClient.put(
          path,
          data: data,
          queryParameters: queryParameters,
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('PUT failed for all support endpoints');
  }
}
