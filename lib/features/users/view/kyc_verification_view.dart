import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/models/kyc_document.dart';
import '../data/repositories/kyc_repository.dart';

class KycVerificationView extends StatefulWidget {
  const KycVerificationView({super.key});

  @override
  State<KycVerificationView> createState() => _KycVerificationViewState();
}

class _KycVerificationViewState extends State<KycVerificationView> {
  final KycRepository _repository = KycRepository();
  List<KycDocument> _documents = [];
  KycDocument? _selectedDocument;
  bool _isLoading = true;
  String _statusFilter = 'pending';
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final docs = await _repository.getDocuments(
      status: _statusFilter == 'all' ? null : _statusFilter,
    );
    setState(() {
      _documents = docs;
      _isLoading = false;
      if (_selectedDocument != null) {
        _selectedDocument = docs
            .where((d) => d.id == _selectedDocument!.id)
            .firstOrNull;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'KYC Verification',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              _buildFilterChip('All', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Pending', 'pending'),
              const SizedBox(width: 8),
              _buildFilterChip('Approved', 'approved'),
              const SizedBox(width: 8),
              _buildFilterChip('Rejected', 'rejected'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Split view
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left — Queue list
                      SizedBox(width: 380, child: _buildQueueList()),
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

  Widget _buildFilterChip(String label, String value) {
    final isActive = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _statusFilter = value);
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.blue.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Colors.blue.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.blue : Colors.white54,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildQueueList() {
    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.green.withValues(alpha: 0.4),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No documents in this queue',
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final doc = _documents[index];
        final isSelected = _selectedDocument?.id == doc.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedDocument = doc),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? Colors.blue.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _statusColor(doc.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _docTypeIcon(doc.documentType),
                    color: _statusColor(doc.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.userName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doc.typeLabel,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, y • HH:mm').format(doc.uploadedAt),
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusPill(doc.status),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentViewer() {
    if (_selectedDocument == null) {
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
              Icon(
                Icons.description_outlined,
                color: Colors.white.withValues(alpha: 0.2),
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                'Select a document to review',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final doc = _selectedDocument!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          // Document header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.withValues(alpha: 0.2),
                  child: Text(
                    doc.userName[0],
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.userName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${doc.typeLabel} • ${doc.userEmail}',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusPill(doc.status),
              ],
            ),
          ),

          // Document image area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Document Preview',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '(${doc.typeLabel})',
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (doc.qualityScore != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (doc.qualityScore! >= 70
                                        ? Colors.green
                                        : Colors.orange)
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Quality Score: ${doc.qualityScore!.toInt()}%',
                            style: TextStyle(
                              color: doc.qualityScore! >= 70
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Actions
          if (doc.status == 'pending' || doc.status == 'manual_review')
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _notesController,
                    style: TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Review notes...',
                      hintStyle: TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _repository.rejectDocument(
                              doc.id,
                              _notesController.text.isEmpty
                                  ? 'Rejected by admin'
                                  : _notesController.text,
                            );
                            _notesController.clear();
                            _loadData();
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reject Doc'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _repository.approveDocument(
                              doc.id,
                              _notesController.text.isEmpty
                                  ? 'Approved'
                                  : _notesController.text,
                            );
                            _notesController.clear();
                            _loadData();
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Approve Doc'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.withValues(
                              alpha: 0.8,
                            ),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showVerifyUserDialog(doc.userId, doc.userName),
                      icon: const Icon(Icons.verified_user_outlined, size: 18),
                      label: Text(
                        'Finalize User Verification',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (doc.reviewedBy != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    doc.status == 'approved'
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: doc.status == 'approved' ? Colors.green : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${doc.status == 'approved' ? 'Approved' : 'Rejected'} by ${doc.reviewedBy}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (doc.reviewNotes != null)
                          Text(
                            doc.reviewNotes!,
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (doc.reviewedAt != null)
                    Text(
                      DateFormat('MMM d, y').format(doc.reviewedAt!),
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showVerifyUserDialog(int userId, String name) {
    showDialog(
      context: context,
      builder: (context) {
        String decision = 'approved';
        final reasonController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Text(
                'Verify User: $name',
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioGroup<String>(
                    groupValue: decision,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => decision = value);
                      }
                    },
                    child: Column(
                      children: const [
                        RadioListTile<String>(
                          title: Text(
                            'Approve KYC',
                            style: TextStyle(color: Colors.green),
                          ),
                          value: 'approved',
                        ),
                        RadioListTile<String>(
                          title: Text(
                            'Reject KYC',
                            style: TextStyle(color: Colors.red),
                          ),
                          value: 'rejected',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: decision == 'approved'
                          ? 'Approval notes (optional)'
                          : 'Rejection reason (required)',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (decision == 'rejected' &&
                        reasonController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reason is required for rejection'),
                        ),
                      );
                      return;
                    }

                    try {
                      await _repository.verifyKycSubmission(
                        userId,
                        decision: decision,
                        notes: reasonController.text,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('User KYC $decision successfully'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: decision == 'approved'
                        ? Colors.green
                        : Colors.red,
                  ),
                  child: Text(
                    'Submit Decision',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusPill(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'manual_review':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _docTypeIcon(String type) {
    switch (type) {
      case 'national_id':
        return Icons.badge;
      case 'passport':
        return Icons.flight;
      case 'driving_license':
        return Icons.directions_car;
      case 'address_proof':
        return Icons.home;
      default:
        return Icons.insert_drive_file;
    }
  }
}
