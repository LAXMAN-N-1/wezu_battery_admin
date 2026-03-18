import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/analytics_repository.dart';
import '../data/models/user.dart';
import '../data/models/suspension_record.dart';

class SuspendedAccountsView extends StatefulWidget {
  const SuspendedAccountsView({super.key});

  @override
  State<SuspendedAccountsView> createState() => _SuspendedAccountsViewState();
}

class _SuspendedAccountsViewState extends State<SuspendedAccountsView> {
  final UserRepository _userRepo = UserRepository();
  final AnalyticsRepository _analyticsRepo = AnalyticsRepository();
  List<User> _suspendedUsers = [];
  List<SuspensionRecord> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final response = await _userRepo.getUsers(status: 'suspended');
    final users = response.users;
    final history = await _analyticsRepo.getSuspensionHistory();
    setState(() {
      _suspendedUsers = users;
      _history = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Suspended Accounts', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text('${_suspendedUsers.length} Active Suspensions', style: GoogleFonts.inter(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Currently Suspended Users
          Text('Currently Suspended', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 12),

          if (_suspendedUsers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green.withValues(alpha: 0.5), size: 48),
                  const SizedBox(height: 12),
                  Text('No currently suspended accounts', style: GoogleFonts.inter(color: Colors.white54)),
                ],
              ),
            )
          else
            ..._suspendedUsers.map((user) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.red.withValues(alpha: 0.2),
                    child: Text(user.fullName[0], style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName, style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                        Text(user.email, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                        if (user.suspensionReason != null)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Reason: ${user.suspensionReason!.replaceAll('_', ' ').toUpperCase()}',
                              style: GoogleFonts.inter(color: Colors.red.shade300, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (user.suspendedAt != null)
                        Text('Since ${DateFormat('MMM d, y').format(user.suspendedAt!)}', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                      if (user.suspendedUntil != null)
                        Text('Until ${DateFormat('MMM d, y').format(user.suspendedUntil!)}', style: GoogleFonts.inter(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _userRepo.reactivateUser(user.id);
                      _loadData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${user.fullName} reactivated'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Reactivate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            )),

          const SizedBox(height: 32),

          // Suspension History
          Text('Suspension History', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 12),

          ..._history.map((record) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (record.isActive ? Colors.red : Colors.green).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    record.isActive ? Icons.block : Icons.check_circle_outline,
                    color: record.isActive ? Colors.red : Colors.green,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(record.userName, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (record.isActive ? Colors.red : Colors.green).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(record.status, style: TextStyle(color: record.isActive ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      Text('${record.reasonLabel} — by ${record.suspendedBy}', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                      if (record.notes != null) Text(record.notes!, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                Text(DateFormat('MMM d, y').format(record.suspendedAt), style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
