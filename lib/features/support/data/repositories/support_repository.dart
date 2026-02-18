class SupportTicket {
  final String id;
  final String title;
  final String description;
  final String status; // 'todo', 'in_progress', 'done'
  final String prioritry; // 'low', 'medium', 'high'
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
}

class SupportRepository {
  Future<List<SupportTicket>> getTickets() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      SupportTicket(
        id: 'TICKET-101',
        title: 'Battery overheating issue',
        description: 'Customer reported battery ID 445 getting hot during charging.',
        status: 'todo',
        prioritry: 'high',
        assignedTo: 'Tech Team',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      SupportTicket(
        id: 'TICKET-102',
        title: 'Payment gateway timeout',
        description: 'User unable to complete payment for monthly sub.',
        status: 'in_progress',
        prioritry: 'medium',
        assignedTo: 'Dev Team',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      SupportTicket(
        id: 'TICKET-103',
        title: 'Station map marker missing',
        description: 'Gachibowli station not appearing on map.',
        status: 'done',
        prioritry: 'low',
        assignedTo: 'Frontend Team',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      SupportTicket(
        id: 'TICKET-104',
        title: 'KYC Document Verification',
        description: 'Verify documents for bulk dealer onboarding.',
        status: 'todo',
        prioritry: 'medium',
        assignedTo: 'Ops Team',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];
  }
}
