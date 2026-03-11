import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.read(apiClientProvider));
});

class SupportTicket {
  final String id;
  final String title;
  final String description;
  final String status; // 'todo', 'in_progress', 'done', 'open', 'closed'
  final String prioritry; // Keeping the typo for UI compatibility
  final String assignedTo;
  final DateTime createdAt;

  const SupportTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.prioritry,
    required this.assignedTo,
    required this.createdAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'].toString(),
      title: json['subject'] ?? 'No Subject',
      description: json['category'] ?? 'General Support',
      status: json['status'] ?? 'open',
      prioritry: json['priority'] ?? 'medium',
      assignedTo: json['assigned_to_id']?.toString() ?? 'Unassigned',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}

class SupportRepository {
  final ApiClient _apiClient;

  SupportRepository(this._apiClient);

  Future<List<SupportTicket>> getTickets() async {
    final response = await _apiClient.get('/api/v1/support/');
    
    if (response.data is List) {
      return (response.data as List).map((e) => SupportTicket.fromJson(e)).toList();
    }
    
    return [];
  }
}
