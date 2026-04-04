import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/models/kyc_document.dart';
import '../provider/kyc_provider.dart';

class KycVerificationView extends ConsumerStatefulWidget {
  const KycVerificationView({super.key});

  @override
  ConsumerState<KycVerificationView> createState() => _KycVerificationViewState();
}

class _KycVerificationViewState extends ConsumerState<KycVerificationView> {
  dynamic _selectedUser;
  KycDocument? _selectedDocument;
  String _statusFilter = 'pending';
  String _userTypeFilter = 'all';
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kycProvider.notifier).loadPendingQueue();
      ref.read(kycProvider.notifier).loadDashboard();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.read(kycProvider.notifier).loadPendingQueue(
      userType: _userTypeFilter == 'all' ? null : _userTypeFilter,
    );
    ref.read(kycProvider.notifier).loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final kycState = ref.watch(kycProvider);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('KYC Verification', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterChip('All Types', 'all', isUserType: true),
                  const SizedBox(width: 8),
                  _buildFilterChip('Customer', 'customer', isUserType: true),
                  const SizedBox(width: 8),
                  _buildFilterChip('Driver', 'driver', isUserType: true),
                  const VerticalDivider(color: Colors.white10),
                  const SizedBox(width: 8),
                  _buildFilterChip('All Status', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', 'pending'),
                ],
              ),
              
              IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh, color: Colors.blue)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Split view
        Expanded(
          child: kycState.isLoading && kycState.pendingQueue.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left — Pending User Queue
                      SizedBox(
                        width: 400,
                        child: _buildPendingUserList(kycState.pendingQueue),
                      ),
                      const SizedBox(width: 24),
                      // Right — Detailed Review & Actions
                      Expanded(child: _buildUserReviewPanel()),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, {bool isUserType = false}) {
    final isActive = isUserType ? _userTypeFilter == value : _statusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isUserType) {
            _userTypeFilter = value;
            _refresh();
          } else {
            _statusFilter = value;
            // Note: status filter can be added to loadPendingQueue if backend supports it
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.blue.withValues(alpha: 0.3) : Colors.transparent),
        ),
        child: Text(label, style: GoogleFonts.inter(color: isActive ? Colors.blue : Colors.white54, fontSize: 12, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }

  Widget _buildPendingUserList(List<dynamic> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green.withValues(alpha: 0.4), size: 48),
            const SizedBox(height: 12),
            Text('No pending KYC submissions', style: GoogleFonts.inter(color: Colors.white38)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isSelected = _selectedUser?['user_id'] == user['user_id'];
        final submittedAt = user['submitted_at'] != null ? DateTime.parse(user['submitted_at']) : DateTime.now();
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedUser = user;
              final docs = user['documents'] as List;
              if (docs.isNotEmpty) {
                _selectedDocument = KycDocument.fromJson(docs.first, defaultUserName: user['full_name'], defaultUserEmail: user['email']);
              } else {
                _selectedDocument = null;
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? Colors.blue.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: Text(user['full_name']?[0] ?? '?', style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['full_name'] ?? 'Unknown', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('${user['user_type'] ?? 'user'} • ${user['email'] ?? ''}', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis),
                      Text(DateFormat('MMM d, HH:mm').format(submittedAt), style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('PENDING', style: GoogleFonts.inter(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getDocumentIcon(String type) {
    switch (type) {
      case 'passport': return Icons.flight_takeoff;
      case 'national_id': return Icons.badge_outlined;
      case 'driving_license': return Icons.drive_eta_outlined;
      default: return Icons.description_outlined;
    }
  }

  Widget _buildUserReviewPanel() {
    if (_selectedUser == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_search_outlined, color: Colors.white.withValues(alpha: 0.1), size: 64),
              const SizedBox(height: 16),
              Text('Select a user to begin verification', style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    final user = _selectedUser!;
    final documents = (user['documents'] as List).map((d) => KycDocument.fromJson(d, defaultUserName: user['full_name'], defaultUserEmail: user['email'])).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          // User Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['full_name'] ?? '', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${user['phone_number'] ?? ''} • ${user['email'] ?? ''}', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
                _buildStatusPill('PENDING'),
              ],
            ),
          ),

          // Document Tabs
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                final isSelected = _selectedDocument?.id == doc.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDocument = doc),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: isSelected ? Colors.blue : Colors.transparent, width: 2)),
                    ),
                    child: Center(
                      child: Text(doc.typeLabel, style: GoogleFonts.inter(color: isSelected ? Colors.blue : Colors.white54, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                    ),
                  ),
                );
              },
            ),
          ),

          // Document Viewer
          Expanded(
            child: _selectedDocument == null
                ? const Center(child: Text('No documents available'))
                : _buildSelectedDocumentDetail(_selectedDocument!),
          ),

          // Final Actions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Final Decision', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Add verification notes or rejection details...',
                    hintStyle: GoogleFonts.inter(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleFinalDecision(user['user_id'], 'rejected'),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject Submission'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleFinalDecision(user['user_id'], 'approved'),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve Submission'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.withValues(alpha: 0.8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDocumentDetail(KycDocument doc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Document Information', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              _buildStatusPill(doc.status),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Number', doc.documentNumber ?? 'N/A'),
          _buildDetailRow('Type', doc.typeLabel),
          const SizedBox(height: 24),
          Container(
            height: 350,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: InteractiveViewer(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_outlined, size: 64, color: Colors.white.withValues(alpha: 0.05)),
                    const SizedBox(height: 12),
                    Text(doc.fileUrl, style: GoogleFonts.inter(color: Colors.blue.withValues(alpha: 0.4), fontSize: 10)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _handleDocAction(doc.id, 'reject'),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Flag for Correction'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => ref.read(kycProvider.notifier).approveDocument(doc.id),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Pre-approve Doc'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleFinalDecision(int userId, String decision) async {
    if (decision == 'rejected' && _notesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide rejection notes')));
      return;
    }

    try {
      await ref.read(kycProvider.notifier).finalizeVerification(userId, decision, _notesController.text);
      _notesController.clear();
      setState(() {
        _selectedUser = null;
        _selectedDocument = null;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission $decision successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 13))),
          Expanded(child: Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Future<void> _handleDocAction(int docId, String action) async {
    if (action == 'reject') {
      final reasonController = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('Reject Document', style: GoogleFonts.outfit(color: Colors.white)),
          content: TextField(
            controller: reasonController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Rejection Reason',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (reasonController.text.isNotEmpty) {
                  ref.read(kycProvider.notifier).rejectDocument(docId, reasonController.text);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatusPill(String status) {
    Color color = Colors.grey;
    if (status.contains('approved')) color = Colors.green;
    if (status.contains('pending')) color = Colors.orange;
    if (status.contains('rejected')) color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
