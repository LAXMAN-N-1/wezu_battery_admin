import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/kyc_document.dart';
import '../data/repositories/kyc_repository.dart';
import '../../../core/api/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KYCDocumentsView extends StatefulWidget {
  const KYCDocumentsView({super.key});

  @override
  State<KYCDocumentsView> createState() => _KYCDocumentsViewState();
}

class _KYCDocumentsViewState extends State<KYCDocumentsView> with SingleTickerProviderStateMixin {
  final KycRepository _repository = KycRepository(ApiClient());
  List<KycDocument> _documents = [];
  KYCStats _stats = const KYCStats(totalDocuments: 0, totalPending: 0, totalVerified: 0, totalRejected: 0, pendingUsers: 0);
  bool _isLoading = true;
  String _statusFilter = 'all';
  late TabController _tabController;

  final List<_TabItem> _tabs = [
    _TabItem('All', 'all', Icons.list_alt),
    _TabItem('Pending', 'pending', Icons.hourglass_empty),
    _TabItem('Verified', 'verified', Icons.check_circle_outline),
    _TabItem('Rejected', 'rejected', Icons.cancel_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _statusFilter = _tabs[_tabController.index].key;
        });
        _loadDocuments();
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repository.getStats(),
        _repository.getDocuments(status: _statusFilter == 'all' ? null : _statusFilter),
      ]);
      setState(() {
        _stats = results[0] as KYCStats;
        final docsData = results[1] as Map<String, dynamic>;
        _documents = docsData['documents'] as List<KycDocument>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final docsData = await _repository.getDocuments(
        status: _statusFilter == 'all' ? null : _statusFilter,
      );
      setState(() {
        _documents = docsData['documents'] as List<KycDocument>;
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
            title: 'KYC Documents',
            subtitle: 'Review, approve, and reject user identity verification documents.',
            actionButton: _buildRefreshButton(),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

          // Stats Row
          Row(
            children: [
              _buildStatCard('Total Docs', _stats.totalDocuments.toString(), Icons.description_outlined, const Color(0xFF3B82F6)),
              const SizedBox(width: 16),
              _buildStatCard('Pending', _stats.totalPending.toString(), Icons.hourglass_empty, const Color(0xFFF59E0B)),
              const SizedBox(width: 16),
              _buildStatCard('Verified', _stats.totalVerified.toString(), Icons.check_circle_outline, const Color(0xFF22C55E)),
              const SizedBox(width: 16),
              _buildStatCard('Rejected', _stats.totalRejected.toString(), Icons.cancel_outlined, const Color(0xFFEF4444)),
              const SizedBox(width: 16),
              _buildStatCard('Users Waiting', _stats.pendingUsers.toString(), Icons.people_outline, const Color(0xFF8B5CF6)),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05),
          const SizedBox(height: 24),

          // Tab Bar
          AdvancedCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorColor: const Color(0xFF3B82F6),
              indicatorWeight: 3,
              labelColor: const Color(0xFF3B82F6),
              unselectedLabelColor: Colors.white54,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 13),
              tabs: _tabs.map((t) => Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.icon, size: 16),
                    const SizedBox(width: 6),
                    Text(t.label),
                    if (t.key == 'pending' && _stats.totalPending > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _stats.totalPending.toString(),
                          style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              )).toList(),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
          const SizedBox(height: 16),

          // Data Table
          AdvancedCard(
            padding: EdgeInsets.zero,
            child: _isLoading
                ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
                : _documents.isEmpty
                    ? SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_outlined, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                              const SizedBox(height: 12),
                              Text(
                                _statusFilter == 'all' ? 'No KYC documents found' : 'No $_statusFilter documents',
                                style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      )
                    : AdvancedTable(
                        columns: const ['User', 'Document Type', 'Status', 'Uploaded', 'Actions'],
                        rows: _documents.map((doc) {
                          return [
                            // User
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                                  child: Text(
                                    doc.userName.isNotEmpty ? doc.userName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(doc.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis),
                                      Text(doc.userEmail, style: const TextStyle(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Document Type
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getDocTypeIcon(doc.documentType), size: 16, color: Colors.white54),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    doc.documentTypeDisplay,
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            // Status
                            StatusBadge(status: doc.status),
                            // Uploaded
                            Text(
                              doc.uploadedAt != null ? DateFormat('MMM d, y').format(doc.uploadedAt!) : '—',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            // Actions
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (doc.status == 'pending') ...[
                                  _actionIconButton(Icons.check_circle, const Color(0xFF22C55E), 'Approve', () => _approveDocument(doc)),
                                  const SizedBox(width: 4),
                                  _actionIconButton(Icons.cancel, const Color(0xFFEF4444), 'Reject', () => _showRejectDialog(doc)),
                                ],
                                _actionIconButton(Icons.visibility_outlined, Colors.white54, 'View', () => _showDocumentDetail(doc)),
                              ],
                            ),
                          ];
                        }).toList(),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionIconButton(IconData icon, Color color, String tooltip, VoidCallback onPressed) {
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

  IconData _getDocTypeIcon(String type) {
    switch (type) {
      case 'aadhaar': return Icons.credit_card;
      case 'pan': return Icons.badge;
      case 'driving_license': return Icons.directions_car;
      case 'passport': return Icons.flight;
      default: return Icons.description;
    }
  }

  Future<void> _approveDocument(KycDocument doc) async {
    final success = await _repository.approveDocument(doc.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document #${doc.id} approved'), backgroundColor: Colors.green),
      );
      _loadData();
    }
  }

  void _showRejectDialog(KycDocument doc) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Document', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rejecting ${doc.documentTypeDisplay} for ${doc.userName}',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Rejection reason *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'e.g., Document is blurry, information mismatch...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
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
              final success = await _repository.rejectDocument(doc.id, reasonController.text);
              if (context.mounted) Navigator.pop(context);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Document #${doc.id} rejected'), backgroundColor: Colors.orange),
                );
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDocumentDetail(KycDocument doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_getDocTypeIcon(doc.documentType), color: const Color(0xFF3B82F6), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(doc.documentTypeDisplay, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            StatusBadge(status: doc.status),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('User', doc.userName),
              _detailRow('Email', doc.userEmail),
              _detailRow('Phone', doc.userPhone),
              _detailRow('Document Number', doc.documentNumber ?? 'Not provided'),
              _detailRow('Status', doc.status.toUpperCase()),
              _detailRow('Uploaded', doc.uploadedAt != null ? DateFormat('MMM d, yyyy HH:mm').format(doc.uploadedAt!) : '—'),
              if (doc.verifiedAt != null)
                _detailRow('Verified At', DateFormat('MMM d, yyyy HH:mm').format(doc.verifiedAt!)),
              if (doc.rejectionReason != null)
                _detailRow('Rejection Reason', doc.rejectionReason!),
              const SizedBox(height: 16),
              // Document preview placeholder
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image_outlined, size: 32, color: Colors.white38),
                    const SizedBox(height: 8),
                    Text('Document Preview', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                    if (doc.fileUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          doc.fileUrl,
                          style: GoogleFonts.inter(color: const Color(0xFF3B82F6), fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (doc.status == 'pending') ...[
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                _approveDocument(doc);
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showRejectDialog(doc);
              },
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Reject'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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

class _TabItem {
  final String label;
  final String key;
  final IconData icon;
  const _TabItem(this.label, this.key, this.icon);
}
