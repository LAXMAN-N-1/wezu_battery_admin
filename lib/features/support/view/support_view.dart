import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/repositories/support_repository.dart';

class SupportView extends StatefulWidget {
  const SupportView({super.key});

  @override
  State<SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends State<SupportView> {
  final SupportRepository _repository = SupportRepository();
  List<SupportTicket> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final tickets = await _repository.getTickets();
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<SupportTicket> _getTicketsByStatus(String status) {
    return _tickets.where((t) => t.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Help Desk',
            subtitle: 'Manage support tickets and resolve customer issues.',
            actionButton: ElevatedButton.icon(
              onPressed: () {}, 
              icon: const Icon(Icons.add, size: 20, color: Colors.white),
              label: const Text('New Ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
<<<<<<< HEAD
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('New Ticket'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
=======
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
>>>>>>> origin/main
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
<<<<<<< HEAD
                _buildKanbanColumn(
                  'To Do',
                  Colors.orange,
                  _getTicketsByStatus('todo'),
                ),
                const SizedBox(width: 24),
                _buildKanbanColumn(
                  'In Progress',
                  Colors.blue,
                  _getTicketsByStatus('in_progress'),
                ),
                const SizedBox(width: 24),
                _buildKanbanColumn(
                  'Done',
                  Colors.green,
                  _getTicketsByStatus('done'),
                ),
=======
                _buildKanbanColumn('To Do', Colors.orange, _getTicketsByStatus('todo'), 100),
                const SizedBox(width: 24),
                _buildKanbanColumn('In Progress', Colors.blue, _getTicketsByStatus('in_progress'), 200),
                const SizedBox(width: 24),
                _buildKanbanColumn('Done', Colors.green, _getTicketsByStatus('done'), 300),
>>>>>>> origin/main
              ],
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildKanbanColumn(
    String title,
    Color color,
    List<SupportTicket> tickets,
  ) {
=======
  Widget _buildKanbanColumn(String title, Color color, List<SupportTicket> tickets, int delayMs) {
>>>>>>> origin/main
    return Expanded(
      child: AdvancedCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(radius: 6, backgroundColor: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tickets.length.toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: tickets.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _buildTicketCard(tickets[index]),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms, delay: delayMs.ms).slideY(begin: 0.05),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
<<<<<<< HEAD
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(
                      ticket.prioritry,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ticket.prioritry.toUpperCase(),
                    style: TextStyle(
                      color: _getPriorityColor(ticket.prioritry),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
=======
                StatusBadge(status: ticket.prioritry),
>>>>>>> origin/main
                Text(
                  ticket.id,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ticket.title,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.person, size: 12, color: Colors.white70),
                ),
                const SizedBox(width: 8),
                Text(
                  ticket.assignedTo,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
=======
  // Custom priority colors removed, StatusBadge handles colors based on name now.
>>>>>>> origin/main
}
