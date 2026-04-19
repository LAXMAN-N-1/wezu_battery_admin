import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InviteUsersDialog extends StatefulWidget {
  final Function(String email, String role) onSingleInvite;
  final Function(List<Map<String, String>>) onBulkInvite;

  const InviteUsersDialog({
    super.key,
    required this.onSingleInvite,
    required this.onBulkInvite,
  });

  @override
  State<InviteUsersDialog> createState() => _InviteUsersDialogState();
}

class _InviteUsersDialogState extends State<InviteUsersDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _bulkCsvController = TextEditingController();
  String _selectedRole = 'customer';
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _bulkCsvController.dispose();
    super.dispose();
  }

  void _handleSendInvite() {
    if (_tabController.index == 0) {
      if (_emailController.text.isNotEmpty) {
        widget.onSingleInvite(_emailController.text, _selectedRole);
        Navigator.pop(context);
      }
    } else {
      if (_bulkCsvController.text.isNotEmpty) {
        final invites = _parseCsv(_bulkCsvController.text);
        if (invites.isNotEmpty) {
          widget.onBulkInvite(invites);
          Navigator.pop(context);
        }
      }
    }
  }

  List<Map<String, String>> _parseCsv(String csvData) {
    final lines = csvData.trim().split('\n');
    final List<Map<String, String>> invites = [];
    for (var line in lines) {
      final parts = line.split(',');
      if (parts.length >= 2) {
        invites.add({'email': parts[0].trim(), 'role_name': parts[1].trim()});
      }
    }
    return invites;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 24,
      ),
      child: Container(
        width: 500,
        constraints: BoxConstraints(maxHeight: size.height * 0.9),
        decoration: BoxDecoration(
          color: const Color(
            0xFF1E293B,
          ), // Matches menus and snackbars in users_view.dart
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.mail_outline,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Invite Users',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 20,
                    ),
                    splashRadius: 24,
                  ),
                ],
              ),
            ),

            // Tabs Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.blue.withValues(
                      alpha: 0.2,
                    ), // Matches tab indicator in users_view.dart
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorPadding: const EdgeInsets.all(6),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Single Invite'),
                    Tab(text: 'Bulk CSV Import'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Content
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  height: 300,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSingleInviteView(),
                      _buildBulkInviteView(),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          foregroundColor: Colors.white70,
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSendInvite,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.green, // Standard green for action
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Send Invite',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleInviteView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.mail_outline,
          hint: 'Enter email address',
        ),
        const SizedBox(height: 20),
        Text(
          'Role',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _buildRoleDropdown(),
        const SizedBox(height: 20),
        _buildInfoBox('Invite link expires in 7 days'),
      ],
    );
  }

  Widget _buildBulkInviteView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.file_upload_outlined,
                    color: Colors.white54,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'CSV Format',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'email, role',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Paste CSV data:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TextField(
            controller: _bulkCsvController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'user1@email.com, customer\nuser2@email.com, driver',
              hintStyle: GoogleFonts.jetBrainsMono(
                color: Colors.white24,
                fontSize: 13,
              ),
              filled: true,
              fillColor: Colors.white.withValues(
                alpha: 0.05,
              ), // Consistent with cards/inputs in users_view.dart
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.blue, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          style: TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white38, size: 20),
            hintText: label,
            hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
            filled: true,
            fillColor: Colors.white.withValues(
              alpha: 0.05,
            ), // Consistent with search in users_view.dart
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
          isExpanded: true,
          style: TextStyle(color: Colors.white, fontSize: 15),
          items: const [
            DropdownMenuItem(value: 'customer', child: Text('Customer')),
            DropdownMenuItem(value: 'driver', child: Text('Driver')),
            DropdownMenuItem(value: 'dealer', child: Text('Dealer')),
            DropdownMenuItem(value: 'admin', child: Text('Admin')),
            DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
            DropdownMenuItem(value: 'support', child: Text('Support')),
          ],
          onChanged: (v) => setState(() => _selectedRole = v!),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 18),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.blue,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
