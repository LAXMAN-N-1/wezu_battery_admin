import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/repositories/support_repository.dart';

class SupportView extends StatefulWidget {
  const SupportView({super.key});

  @override
  State<SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends State<SupportView> {
  final SupportRepository _repository = SupportRepository();
  bool _isLoading = true;
  
  Map<String, dynamic> _stats = {};
  List<SupportTicket> _tickets = [];

  String _statusFilter = 'all';
  String _sourceFilter = 'all'; // customer, dealer, driver, internal
  bool _isKanbanView = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final statsResult = await _repository.getTicketsStats();
      final ticketsResult = await _repository.getTickets(
        status: _statusFilter,
        source: _sourceFilter,
      );
      
      setState(() {
        _stats = statsResult;
        _tickets = ticketsResult;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStatsCards(),
          const SizedBox(height: 24),
          _buildFilters(),
          const SizedBox(height: 24),
          Expanded(
            child: _isKanbanView ? _buildKanbanBoard() : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return PageHeader(
      title: 'Support Tickets',
      subtitle: 'Manage and resolve tickets across all WEZU users.',
      actionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.view_kanban, color: _isKanbanView ? const Color(0xFF3B82F6) : Colors.white54, size: 20),
                  onPressed: () => setState(() => _isKanbanView = true),
                  tooltip: 'Kanban View',
                ),
                Container(width: 1, height: 24, color: Colors.white12),
                IconButton(
                  icon: Icon(Icons.list, color: !_isKanbanView ? const Color(0xFF3B82F6) : Colors.white54, size: 20),
                  onPressed: () => setState(() => _isKanbanView = false),
                  tooltip: 'List View',
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _loadData(),
            icon: const Icon(Icons.refresh, size: 20, color: Colors.white),
            label: const Text('Refresh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: StatCard(label: 'Total Tickets', value: '${_stats['total_tickets'] ?? 0}', icon: Icons.receipt_long)),
        const SizedBox(width: 16),
        Expanded(child: StatCard(label: 'Open / Pending', value: '${_stats['open'] ?? 0}', icon: Icons.pending_actions)),
        const SizedBox(width: 16),
        Expanded(child: StatCard(label: 'Overdue SLA', value: '${_stats['overdue'] ?? 0}', icon: Icons.warning_amber)),
        const SizedBox(width: 16),
        Expanded(child: StatCard(label: 'Resolved', value: '${_stats['resolved'] ?? 0}', icon: Icons.check_circle_outline)),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Text('Source:', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          _buildFilterChip('All', 'all', _sourceFilter, (v) { _sourceFilter = v; _loadData(); }),
          _buildFilterChip('Customers', 'customer', _sourceFilter, (v) { _sourceFilter = v; _loadData(); }),
          _buildFilterChip('Dealers', 'dealer', _sourceFilter, (v) { _sourceFilter = v; _loadData(); }),
          _buildFilterChip('Drivers', 'driver', _sourceFilter, (v) { _sourceFilter = v; _loadData(); }),
          _buildFilterChip('Internal', 'internal', _sourceFilter, (v) { _sourceFilter = v; _loadData(); }),
          
          if (!_isKanbanView) ...[
            const SizedBox(width: 24),
            const Text('Status:', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            _buildFilterChip('All', 'all', _statusFilter, (v) { _statusFilter = v; _loadData(); }),
            _buildFilterChip('Open', 'open', _statusFilter, (v) { _statusFilter = v; _loadData(); }),
            _buildFilterChip('In Progress', 'in_progress', _statusFilter, (v) { _statusFilter = v; _loadData(); }),
            _buildFilterChip('Resolved', 'resolved', _statusFilter, (v) { _statusFilter = v; _loadData(); }),
            _buildFilterChip('Closed', 'closed', _statusFilter, (v) { _statusFilter = v; _loadData(); }),
          ]
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildFilterChip(String label, String value, String groupValue, Function(String) onSelected) {
    final isSelected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(value),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.3),
        checkmarkColor: const Color(0xFF3B82F6),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        side: BorderSide(
          color: isSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.5) : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildKanbanBoard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildKanbanColumn('Open', Colors.orange, _getTicketsByStatus('open'), 300),
        const SizedBox(width: 24),
        _buildKanbanColumn('In Progress', Colors.blue, _getTicketsByStatus('in_progress'), 400),
        const SizedBox(width: 24),
        _buildKanbanColumn('Resolved', Colors.green, _getTicketsByStatus('resolved'), 500),
      ],
    );
  }

  Widget _buildKanbanColumn(String title, Color color, List<SupportTicket> columnTickets, int delayMs) {
    return Expanded(
      child: AdvancedCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CircleAvatar(radius: 5, backgroundColor: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    columnTickets.length.toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: columnTickets.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildKanbanTicketCard(columnTickets[index]),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms, delay: delayMs.ms).slideY(begin: 0.05),
    );
  }

  Widget _buildKanbanTicketCard(SupportTicket ticket) {
    return InkWell(
      onTap: () => _openTicketDetail(ticket.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
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
                  StatusBadge(status: ticket.priority.toUpperCase()),
                  Text(
                    '#${ticket.id}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket.subject,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                ticket.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _getSourceIcon(ticket.userRole),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ticket.userName,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.forum_outlined, size: 14, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    '${ticket.messageCount}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return AdvancedCard(
      padding: EdgeInsets.zero,
      child: AdvancedTable(
        columns: const ['ID', 'Subject / Source', 'User', 'Category', 'Priority', 'Status', 'Assigned To', 'Created'],
        rows: _tickets.map((t) => <Widget>[
          Text('#${t.id}', style: const TextStyle(color: Colors.white70)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(t.subject, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(
                children: [
                  _getSourceIcon(t.userRole, size: 12),
                  const SizedBox(width: 4),
                  Text(t.userRole.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              )
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(t.userName, style: const TextStyle(color: Colors.white)),
            ],
          ),
          Text(t.category, style: const TextStyle(color: Colors.white70)),
          StatusBadge(status: t.priority.toUpperCase()),
          StatusBadge(status: t.status.toUpperCase()),
          Row(
            children: [
              if (t.assignedTo != null) const CircleAvatar(radius: 10, backgroundColor: Colors.white12, child: Icon(Icons.support_agent, size: 12, color: Colors.white70)),
              if (t.assignedTo != null) const SizedBox(width: 8),
              Text(t.assigneeName, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          Text(t.createdAt != null ? DateFormat('MMM d, HH:mm').format(t.createdAt!.toLocal()) : 'N/A', style: const TextStyle(color: Colors.white70)),
        ]).toList(),
        onRowTap: (index) => _openTicketDetail(_tickets[index].id),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.05);
  }

  Widget _getSourceIcon(String role, {double size = 14}) {
    IconData icon;
    Color color;
    switch (role.toLowerCase()) {
      case 'dealer':
        icon = Icons.storefront;
        color = Colors.orange;
        break;
      case 'driver':
        icon = Icons.local_shipping;
        color = Colors.blue;
        break;
      case 'internal':
      case 'admin':
        icon = Icons.admin_panel_settings;
        color = Colors.purple;
        break;
      default:
        icon = Icons.person;
        color = Colors.green;
    }
    return Icon(icon, size: size, color: color);
  }

  void _openTicketDetail(int ticketId) {
    showDialog(
      context: context,
      builder: (context) => _TicketDetailDialog(ticketId: ticketId, repository: _repository),
    ).then((_) => _loadData());
  }
}

class _TicketDetailDialog extends StatefulWidget {
  final int ticketId;
  final SupportRepository repository;

  const _TicketDetailDialog({required this.ticketId, required this.repository});

  @override
  State<_TicketDetailDialog> createState() => _TicketDetailDialogState();
}

class _TicketDetailDialogState extends State<_TicketDetailDialog> {
  TicketDetail? _ticket;
  bool _isLoading = true;
  final TextEditingController _msgController = TextEditingController();
  bool _isInternalNote = false;

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  Future<void> _loadTicket() async {
    setState(() => _isLoading = true);
    final t = await widget.repository.getTicketDetail(widget.ticketId);
    setState(() {
      _ticket = t;
      _isLoading = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    
    final success = await widget.repository.addTicketMessage(widget.ticketId, text, isInternal: _isInternalNote);
    if (success) {
      _msgController.clear();
      if (_isInternalNote) {
        setState(() => _isInternalNote = false);
      }
      _loadTicket();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : _ticket == null 
              ? const Center(child: Text('Failed to load ticket', style: TextStyle(color: Colors.red)))
              : _buildDialogContent(),
      ),
    );
  }

  Widget _buildDialogContent() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              StatusBadge(status: _ticket!.status.toUpperCase()),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '[#${_ticket!.id}] ${_ticket!.subject}',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text('${_ticket!.userName} (${_ticket!.userRole.toUpperCase()})', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(width: 16),
                        const Icon(Icons.category, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(_ticket!.category.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(width: 16),
                        const Icon(Icons.support_agent, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(_ticket!.assigneeName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // Body: Chat thread
        Expanded(
          child: Container(
            color: const Color(0xFF1E293B).withValues(alpha: 0.3),
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _ticket!.messages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final msg = _ticket!.messages[index];
                final isCustomer = msg.senderId == _ticket!.userId;
                return _buildMessageBubble(msg, isCustomer);
              },
            ),
          ),
        ),

        // Action Bar (Change Status + Reply Box)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Column(
            children: [
              // Admin Controls Row
              Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Update Status: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  _buildStatusDropdown(),
                  const SizedBox(width: 24),
                  const Text('Priority: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  _buildPriorityDropdown(),
                  
                  // Internal Note Toggle
                  Row(
                    children: [
                      const Text('Internal Note', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Switch(
                        value: _isInternalNote,
                        onChanged: (v) => setState(() => _isInternalNote = v),
                        activeThumbColor: Colors.amber,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Chat input
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _isInternalNote ? 'Type an internal note (only visible to team)...' : 'Type your reply to customer...',
                        hintStyle: TextStyle(color: _isInternalNote ? Colors.amber.withValues(alpha: 0.5) : Colors.white38),
                        fillColor: _isInternalNote ? Colors.amber.withValues(alpha: 0.1) : Colors.black26,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: _isInternalNote ? Colors.amber[700] : const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _ticket!.status,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 20),
          items: const [
            DropdownMenuItem(value: 'open', child: Text('Open')),
            DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
            DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
            DropdownMenuItem(value: 'closed', child: Text('Closed')),
          ],
          onChanged: (val) async {
            if (val != null && val != _ticket!.status) {
              await widget.repository.updateTicketStatus(widget.ticketId, val);
              _loadTicket();
            }
          },
        ),
      ),
    );
  }

  Widget _buildPriorityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _ticket!.priority,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 20),
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Low')),
            DropdownMenuItem(value: 'medium', child: Text('Medium')),
            DropdownMenuItem(value: 'high', child: Text('High')),
            DropdownMenuItem(value: 'critical', child: Text('Critical')),
          ],
          onChanged: (val) async {
            if (val != null && val != _ticket!.priority) {
              await widget.repository.updateTicketPriority(widget.ticketId, val);
              _loadTicket();
            }
          },
        ),
      ),
    );
  }

  Widget _buildMessageBubble(TicketMessage msg, bool isCustomer) {
    return Padding(
      padding: EdgeInsets.only(
        left: isCustomer ? 0 : 80,
        right: isCustomer ? 80 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isCustomer ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isCustomer) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white12,
              child: Text(msg.senderName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isCustomer ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: isCustomer ? MainAxisAlignment.start : MainAxisAlignment.end,
                  children: [
                    Text(
                      msg.senderName,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      msg.createdAt != null ? DateFormat('MMM d, HH:mm').format(msg.createdAt!.toLocal()) : '',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    if (msg.isInternalNote) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                        child: const Text('INTERNAL NOTE', style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: msg.isInternalNote 
                        ? Colors.amber.withValues(alpha: 0.1) 
                        : (isCustomer ? const Color(0xFF1E293B) : const Color(0xFF3B82F6)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isCustomer ? Radius.zero : const Radius.circular(16),
                      bottomRight: isCustomer ? const Radius.circular(16) : Radius.zero,
                    ),
                    border: msg.isInternalNote ? Border.all(color: Colors.amber.withValues(alpha: 0.3)) : null,
                  ),
                  child: Text(
                    msg.message,
                    style: TextStyle(
                      color: msg.isInternalNote ? Colors.amber[100] : Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isCustomer) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
              child: const Icon(Icons.support_agent, size: 16, color: Color(0xFF3B82F6)),
            ),
          ],
        ],
      ),
    );
  }
}
