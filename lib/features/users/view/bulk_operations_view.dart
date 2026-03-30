import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/user.dart';
import '../data/repositories/user_repository.dart';

class BulkOperationsView extends StatefulWidget {
  const BulkOperationsView({super.key});

  @override
  State<BulkOperationsView> createState() => _BulkOperationsViewState();
}

class _BulkOperationsViewState extends State<BulkOperationsView> {
  final UserRepository _repository = UserRepository();
  List<User> _users = [];
  final Set<int> _selectedIds = {};
  bool _isLoading = true;
  bool _isProcessing = false;
  String _messageType = 'email';
  String _selectedTemplate = 'welcome';
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final response = await _repository.getUsers(limit: 1000); // Load all for bulk ops
    setState(() {
      _users = response.users;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Row(
      children: [
        // Left — User selection
        SizedBox(
          width: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bulk Operations', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('${_selectedIds.length} of ${_users.length} users selected', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildQuickSelect('All', () => setState(() => _selectedIds.addAll(_users.map((u) => u.id)))),
                        const SizedBox(width: 8),
                        _buildQuickSelect('None', () => setState(() => _selectedIds.clear())),
                        const SizedBox(width: 8),
                        _buildQuickSelect('Customers', () {
                          setState(() {
                            _selectedIds.clear();
                            _selectedIds.addAll(_users.where((u) => u.role == 'customer').map((u) => u.id));
                          });
                        }),
                        const SizedBox(width: 8),
                        _buildQuickSelect('Dealers', () {
                          setState(() {
                            _selectedIds.clear();
                            _selectedIds.addAll(_users.where((u) => u.role == 'dealer').map((u) => u.id));
                          });
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final isSelected = _selectedIds.contains(user.id);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedIds.add(user.id);
                            } else {
                              _selectedIds.remove(user.id);
                            }
                          });
                        },
                        activeColor: Colors.blue,
                        checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        secondary: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue.withValues(alpha: 0.2),
                          child: Text(user.fullName[0], style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(user.fullName, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                        subtitle: Text('${user.email} • ${user.role}', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Container(width: 1, color: Colors.white.withValues(alpha: 0.06)),

        // Right — Message composer
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Compose Message', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 20),

                // Type selector
                Row(
                  children: [
                    _buildTypeChip('Email', Icons.email_outlined, _messageType == 'email', () => setState(() => _messageType = 'email')),
                    const SizedBox(width: 10),
                    _buildTypeChip('SMS', Icons.sms_outlined, _messageType == 'sms', () => setState(() => _messageType = 'sms')),
                  ],
                ),
                const SizedBox(height: 20),

                // Template
                Text('Template', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTemplate,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                      items: const [
                        DropdownMenuItem(value: 'welcome', child: Text('Welcome Message')),
                        DropdownMenuItem(value: 'promo', child: Text('Promotional Offer')),
                        DropdownMenuItem(value: 'update', child: Text('Platform Update')),
                        DropdownMenuItem(value: 'reminder', child: Text('Rental Reminder')),
                        DropdownMenuItem(value: 'custom', child: Text('Custom Message')),
                      ],
                      onChanged: (v) => setState(() => _selectedTemplate = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_messageType == 'email') ...[
                  Text('Subject', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _subjectController,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Enter email subject...',
                      hintStyle: GoogleFonts.inter(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Text('Message Body', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: _bodyController,
                  maxLines: 6,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Type your message here...\n\nUse {{name}} for personalization.',
                    hintStyle: GoogleFonts.inter(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue)),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['{{name}}', '{{email}}', '{{role}}'].map((token) {
                    return ActionChip(
                      label: Text(token, style: GoogleFonts.firaCode(color: Colors.blue, fontSize: 11)),
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      side: BorderSide(color: Colors.blue.withValues(alpha: 0.2)),
                      onPressed: () {
                        _bodyController.text += ' $token';
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_selectedIds.isEmpty || _isProcessing) ? null : _handleExport,
                        icon: const Icon(Icons.download, size: 18),
                        label: Text(_isProcessing ? 'Wait...' : 'Export CSV', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.teal.withValues(alpha: 0.3)),
                          foregroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_selectedIds.isEmpty || _isProcessing) ? null : _handleBulkAction,
                        icon: _isProcessing 
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send, size: 18),
                        label: Text(_isProcessing ? 'Processing...' : 'Send ${_messageType == 'email' ? 'Email' : 'SMS'}', 
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleBulkAction() async {
    if (_selectedIds.isEmpty) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final String action = 'message';
      final Map<String, dynamic> additionalData = {
        'message_type': _messageType,
        'template': _selectedTemplate,
        'subject': _subjectController.text,
        'body': _bodyController.text,
      };

      final result = await _repository.bulkUserAction(
        _selectedIds.toList(),
        action,
        additionalData: additionalData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status: ${result['status']}. Processed ${result['processed']} users.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleExport() async {
    setState(() => _isProcessing = true);
    try {
      // For now, we use general export endpoint. 
      // It returns CSV data as a string/stream.
      final result = await _repository.exportUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Users list exported successfully.'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      // Note: Real file download implementation would require path_provider and dart:io
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildQuickSelect(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildTypeChip(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? Colors.blue.withValues(alpha: 0.3) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.blue : Colors.white54, size: 18),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(color: isActive ? Colors.blue : Colors.white54, fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
