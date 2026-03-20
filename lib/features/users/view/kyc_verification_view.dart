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
                      // Left — Queue list
                      SizedBox(
                        width: 380,
                        child: _buildQueueList(kycState.pendingQueue),
                      ),
                      const SizedBox(width: 20),
                      // Right — Document viewer
                      Expanded(child: _buildDocumentViewer()),
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

  Widget _buildQueueList(List<dynamic> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green.withValues(alpha: 0.4), size: 48),
            const SizedBox(height: 12),
            Text('No users in this queue', style: GoogleFonts.inter(color: Colors.white38)),
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
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isSelected ? Colors.blue.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: Text(user['full_name']?[0] ?? '?', style: const TextStyle(color: Colors.blue, fontSize: 12)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['full_name'] ?? 'Unknown', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
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

  Widget _buildDocumentViewer() {
    if (_selectedUser == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined, color: Colors.white.withValues(alpha: 0.2), size: 56),
              const SizedBox(height: 16),
              Text('Select a user to review documents', style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          // User info header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['full_name'] ?? '', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      Text('${user['phone_number'] ?? ''} • ${user['email'] ?? ''}', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
                _buildStatusPill('PENDING'),
              ],
            ),
          ),

          // Document Selector Tabs
          if (documents.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)))),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final doc = documents[index];
                  final isSelected = _selectedDocument?.id == doc.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDocument = doc),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: isSelected ? Colors.blue : Colors.transparent, width: 2)),
                      ),
                      child: Text(doc.typeLabel, style: GoogleFonts.inter(color: isSelected ? Colors.blue : Colors.white54, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                    ),
                  );
                },
              ),
            ),

          // Document Detail area
          Expanded(
            child: _selectedDocument == null 
              ? const Center(child: Text('No documents available', style: TextStyle(color: Colors.white24)))
              : _buildSelectedDocumentDetail(_selectedDocument!),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _notesController,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Final review notes...',
                    hintStyle: GoogleFonts.inter(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleSubmitDecision(user['user_id'], 'rejected'),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject KYC'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleSubmitDecision(user['user_id'], 'approved'),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve KYC'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.withValues(alpha: 0.8),
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
        ],
      ),
    );
  }

  Widget _buildSelectedDocumentDetail(KycDocument doc) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${doc.typeLabel} Info', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              _buildStatusPill(doc.status),
            ],
          ),
          const SizedBox(height: 12),
          Text('Number: ${doc.documentNumber ?? "N/A"}', style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: InteractiveViewer(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_outlined, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                      const SizedBox(height: 12),
                      Text('Document Preview', style: GoogleFonts.inter(color: Colors.white24, fontSize: 13)),
                      Text(doc.fileUrl, style: GoogleFonts.inter(color: Colors.blue.withValues(alpha: 0.4), fontSize: 10), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => ref.read(kycProvider.notifier).rejectDocument(doc.id, 'Image unclear'),
                icon: const Icon(Icons.report_problem_outlined, size: 16),
                label: const Text('Reject Doc'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => ref.read(kycProvider.notifier).approveDocument(doc.id),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Approve Doc'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.withValues(alpha: 0.2), foregroundColor: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmitDecision(int userId, String decision) async {
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User $decision successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
