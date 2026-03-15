import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/user.dart';
import '../data/repositories/user_repository.dart';

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  final UserRepository _repository = UserRepository();
  List<User> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _filterRole;
  String? _filterStatus;
  int _totalCount = 0;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repository.getUsers(
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          userType: _filterRole,
          status: _filterStatus,
        ),
        _repository.getUserStats(),
      ]);

      final usersData = results[0] as Map<String, dynamic>;
      final statsData = results[1] as Map<String, dynamic>;

      setState(() {
        _users = usersData['users'] as List<User>;
        _totalCount = usersData['total_count'] as int;
        _stats = statsData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          PageHeader(
            title: 'User Management',
            subtitle: 'Manage users, roles, KYC status, and monitor activity.',
            actionButton: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRefreshButton(),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showInviteDialog(context),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Invite User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            searchField: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                _searchQuery = value;
                _loadData();
              },
              decoration: InputDecoration(
                hintText: 'Search by name, email, phone...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

          // Stats Row
          Row(
            children: [
              _buildStatCard('Total Users', (_stats['total_users'] ?? _totalCount).toString(), Icons.people_outline, const Color(0xFF3B82F6)),
              const SizedBox(width: 16),
              _buildStatCard('Active', (_stats['active_users'] ?? 0).toString(), Icons.check_circle_outline, const Color(0xFF22C55E)),
              const SizedBox(width: 16),
              _buildStatCard('Suspended', (_stats['suspended_users'] ?? 0).toString(), Icons.block_outlined, const Color(0xFFEF4444)),
              const SizedBox(width: 16),
              _buildStatCard('Pending KYC', (_stats['pending_kyc'] ?? 0).toString(), Icons.verified_user_outlined, const Color(0xFFF59E0B)),
              const Spacer(),
              // Filter Dropdowns
              _buildFilterDropdown(
                value: _filterStatus,
                hint: 'All Status',
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Status')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                  DropdownMenuItem(value: 'pending_verification', child: Text('Pending')),
                ],
                onChanged: (v) { _filterStatus = v; _loadData(); },
              ),
              const SizedBox(width: 12),
              _buildFilterDropdown(
                value: _filterRole,
                hint: 'All Types',
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Types')),
                  DropdownMenuItem(value: 'customer', child: Text('Customer')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'dealer', child: Text('Dealer')),
                  DropdownMenuItem(value: 'logistics', child: Text('Logistics')),
                  DropdownMenuItem(value: 'support_agent', child: Text('Support')),
                ],
                onChanged: (v) { _filterRole = v; _loadData(); },
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05),
          const SizedBox(height: 24),

          // Data Table
          AdvancedCard(
            padding: EdgeInsets.zero,
            child: _isLoading
                ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
                : Column(
                    children: [
                      // Table header info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Text(
                              '$_totalCount users found',
                              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      AdvancedTable(
                        columns: const ['User', 'Type', 'Status', 'KYC', 'Role', 'Joined', 'Actions'],
                        rows: _users.map((user) {
                          return [
                            // User column
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                  backgroundImage: user.profilePicture != null
                                      ? NetworkImage(user.profilePicture!)
                                      : null,
                                  child: user.profilePicture == null
                                      ? Text(
                                          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                                          style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(user.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                      Text(user.email, style: const TextStyle(color: Colors.white54, fontSize: 12), overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            StatusBadge(status: user.userType),
                            StatusBadge(status: user.status),
                            StatusBadge(status: user.kycStatus),
                            Text(user.role ?? '—', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            Text(
                              DateFormat('MMM d, y').format(user.createdAt),
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            // Actions
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildActionMenuButton(user),
                              ],
                            ),
                          ];
                        }).toList(),
                      ),
                    ],
                  ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: IconButton(
        icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
        onPressed: _loadData,
        tooltip: 'Refresh',
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return AdvancedCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      width: 180,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    String? value,
    required String hint,
    required List<DropdownMenuItem<String?>> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: DropdownButton<String?>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          items: items,
          onChanged: (v) => setState(() => onChanged(v)),
        ),
      ),
    );
  }

  Widget _buildActionMenuButton(User user) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 20, color: Colors.white54),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (action) => _handleAction(action, user),
      itemBuilder: (context) => [
        _buildPopupItem('view', Icons.visibility_outlined, 'View Details'),
        if (user.status != 'suspended')
          _buildPopupItem('suspend', Icons.block_outlined, 'Suspend Account', color: const Color(0xFFEF4444)),
        if (user.status == 'suspended')
          _buildPopupItem('reactivate', Icons.check_circle_outline, 'Reactivate', color: const Color(0xFF22C55E)),
        _buildPopupItem('toggle', Icons.power_settings_new, user.isActive ? 'Deactivate' : 'Activate'),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String text, {Color? color}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.white70),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: color ?? Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  void _handleAction(String action, User user) async {
    switch (action) {
      case 'view':
        _showUserDetailDialog(user);
        break;
      case 'suspend':
        _showSuspendDialog(user);
        break;
      case 'reactivate':
        final success = await _repository.reactivateUser(user.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.fullName} reactivated'), backgroundColor: Colors.green),
          );
          _loadData();
        }
        break;
      case 'toggle':
        final success = await _repository.toggleUserActive(user.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.fullName} ${user.isActive ? "deactivated" : "activated"}'), backgroundColor: Colors.green),
          );
          _loadData();
        }
        break;
    }
  }

  void _showUserDetailDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
              child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(user.email, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Phone', user.phoneNumber),
              _detailRow('User Type', user.userType.toUpperCase()),
              _detailRow('Status', user.status.toUpperCase()),
              _detailRow('KYC Status', user.kycStatus.toUpperCase()),
              _detailRow('Role', user.role ?? 'No role assigned'),
              _detailRow('Superuser', user.isSuperuser ? 'Yes' : 'No'),
              _detailRow('Joined', DateFormat('MMM d, yyyy').format(user.createdAt)),
              if (user.lastLoginAt != null)
                _detailRow('Last Login', DateFormat('MMM d, yyyy HH:mm').format(user.lastLoginAt!)),
              if (user.suspensionReason != null)
                _detailRow('Suspension Reason', user.suspensionReason!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog(User user) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Suspend ${user.fullName}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This will suspend the user\'s account immediately.', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Reason for suspension *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) return;
              final success = await _repository.suspendUser(user.id, reasonController.text);
              if (context.mounted) Navigator.pop(context);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.fullName} suspended'), backgroundColor: Colors.orange),
                );
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Suspend', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    String selectedRole = 'customer';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Invite New User', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Full Name (Optional)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Role',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'customer', child: Text('Customer')),
                      DropdownMenuItem(value: 'driver', child: Text('Driver')),
                      DropdownMenuItem(value: 'dealer', child: Text('Dealer')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) => setState(() => selectedRole = value!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (emailController.text.isEmpty) return;
                        setState(() => isSubmitting = true);
                        try {
                          await _repository.inviteUser(
                            email: emailController.text,
                            role: selectedRole,
                            fullName: nameController.text.isNotEmpty ? nameController.text : null,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User invited successfully!'), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          setState(() => isSubmitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Invite', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}
