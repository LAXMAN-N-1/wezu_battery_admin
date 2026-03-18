import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/user.dart';
import '../data/repositories/user_repository.dart';

class SuspendedAccountsView extends StatefulWidget {
  const SuspendedAccountsView({super.key});

  @override
  State<SuspendedAccountsView> createState() => _SuspendedAccountsViewState();
}

class _SuspendedAccountsViewState extends State<SuspendedAccountsView> {
  final UserRepository _repository = UserRepository();
  List<User> _suspendedUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
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
        _repository.getSuspendedUsers(
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
        ),
        _repository.getUserStats(),
      ]);

      final usersData = results[0] as Map<String, dynamic>;
      final statsData = results[1] as Map<String, dynamic>;

      setState(() {
        _suspendedUsers = usersData['users'] as List<User>;
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
            title: 'Suspended Accounts',
            subtitle: 'View and manage suspended user accounts. Reactivate or permanently disable.',
            actionButton: _buildRefreshButton(),
            searchField: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                _searchQuery = value;
                _loadData();
              },
              decoration: InputDecoration(
                hintText: 'Search suspended users...',
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
              _buildStatCard(
                'Suspended', 
                (_stats['suspended_users'] ?? _totalCount).toString(), 
                Icons.block_outlined, 
                const Color(0xFFEF4444),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Total Users', 
                (_stats['total_users'] ?? 0).toString(), 
                Icons.people_outline, 
                const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Active Users', 
                (_stats['active_users'] ?? 0).toString(), 
                Icons.check_circle_outline, 
                const Color(0xFF22C55E),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Suspension Rate', 
                _getSuspensionRate(), 
                Icons.trending_down, 
                const Color(0xFFF59E0B),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05),
          const SizedBox(height: 24),

          // Warning Banner
          if (_totalCount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEF4444).withValues(alpha: 0.1),
                    const Color(0xFFEF4444).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber, color: Color(0xFFEF4444), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_totalCount account${_totalCount == 1 ? '' : 's'} currently suspended',
                          style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Review suspended accounts and reactivate or permanently disable as needed.',
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideX(begin: -0.05),

          // Data Table
          AdvancedCard(
            padding: EdgeInsets.zero,
            child: _isLoading
                ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
                : _suspendedUsers.isEmpty
                    ? SizedBox(
                        height: 250,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF22C55E)),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No suspended accounts',
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'All user accounts are currently active.',
                                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Text('$_totalCount suspended account${_totalCount == 1 ? '' : 's'}',
                                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                              ],
                            ),
                          ),
                          AdvancedTable(
                            columns: const ['User', 'Type', 'Reason', 'Suspended', 'KYC', 'Actions'],
                            rows: _suspendedUsers.map((user) {
                              return [
                                // User
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                      child: Text(
                                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                                      ),
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
                                // Type
                                StatusBadge(status: user.userType),
                                // Reason
                                Expanded(
                                  child: Text(
                                    user.suspensionReason ?? 'No reason provided',
                                    style: TextStyle(
                                      color: user.suspensionReason != null ? Colors.white70 : Colors.white38,
                                      fontSize: 13,
                                      fontStyle: user.suspensionReason == null ? FontStyle.italic : FontStyle.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                                // Suspended Date
                                Text(
                                  DateFormat('MMM d, y').format(user.createdAt),
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                // KYC
                                StatusBadge(status: user.kycStatus),
                                // Actions
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildActionButton(
                                      icon: Icons.check_circle_outline,
                                      color: const Color(0xFF22C55E),
                                      tooltip: 'Reactivate',
                                      onPressed: () => _confirmReactivate(user),
                                    ),
                                    const SizedBox(width: 4),
                                    _buildActionButton(
                                      icon: Icons.visibility_outlined,
                                      color: Colors.white54,
                                      tooltip: 'View Details',
                                      onPressed: () => _showUserDetail(user),
                                    ),
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

  String _getSuspensionRate() {
    final total = _stats['total_users'] ?? 0;
    final suspended = _stats['suspended_users'] ?? 0;
    if (total == 0) return '0%';
    return '${((suspended / total) * 100).toStringAsFixed(1)}%';
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
    return Expanded(
      child: AdvancedCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  void _confirmReactivate(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reactivate Account', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFF22C55E), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reactivate ${user.fullName}?',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This will restore full access to their account.',
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (user.suspensionReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Suspension Reason:', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(user.suspensionReason!, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _repository.reactivateUser(user.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${user.fullName} has been reactivated'),
                    backgroundColor: const Color(0xFF22C55E),
                  ),
                );
                _loadData();
              }
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Reactivate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetail(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Row(
                    children: [
                      const StatusBadge(status: 'suspended'),
                      const SizedBox(width: 8),
                      Text(user.email, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
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
              _detailRow('KYC Status', user.kycStatus.toUpperCase()),
              _detailRow('Account Created', DateFormat('MMM d, yyyy').format(user.createdAt)),
              if (user.suspensionReason != null) ...[
                const Divider(color: Colors.white12, height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
                          const SizedBox(width: 6),
                          Text('Suspension Reason', style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(user.suspensionReason!, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _confirmReactivate(user);
            },
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Reactivate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
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
}
