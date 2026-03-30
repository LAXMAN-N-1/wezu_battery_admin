import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/repositories/dealer_repository.dart';
import '../data/models/dealer.dart';

class DealerKycView extends StatefulWidget {
  const DealerKycView({super.key});

  @override
  State<DealerKycView> createState() => _DealerKycViewState();
}

class _DealerKycViewState extends State<DealerKycView> {
  final DealerRepository _repository = DealerRepository();
  List<DealerKycDocument> _documents = [];
  bool _isLoading = true;

  final _docTypeIcons = {
    'gst_certificate': Icons.receipt_long_outlined,
    'pan_card': Icons.credit_card,
    'business_license': Icons.business_center_outlined,
    'bank_statement': Icons.account_balance_outlined,
    'address_proof': Icons.home_outlined,
    'partnership_agreement': Icons.handshake_outlined,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final docs = await _repository.getKycDocuments();
    setState(() {
      _documents = docs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'KYC & Verification',
            subtitle: 'Review and approve dealer KYC documents. Documents pending verification are shown below.',
            actionButton: IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _loadData),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              _buildMiniStat('Pending Review', '${_documents.length}', Icons.pending_outlined, const Color(0xFFF59E0B)),
              const SizedBox(width: 16),
              _buildMiniStat('Doc Types', '${_documents.map((d) => d.documentType).toSet().length}', Icons.folder_outlined, const Color(0xFF3B82F6)),
              const SizedBox(width: 16),
              _buildMiniStat('Dealers Involved', '${_documents.map((d) => d.dealerId).toSet().length}', Icons.storefront_outlined, const Color(0xFF8B5CF6)),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 24),

          // Documents
          _isLoading
            ? const SizedBox(height: 400, child: Center(child: CircularProgressIndicator()))
            : _documents.isEmpty
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, color: const Color(0xFF22C55E).withValues(alpha: 0.5), size: 64),
                        const SizedBox(height: 16),
                        Text('All Caught Up!', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        const Text('No pending KYC documents to review.', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: _documents.length,
                  itemBuilder: (ctx, i) => _buildKycCard(_documents[i]).animate().fadeIn(duration: 300.ms, delay: (60 * i).ms).slideY(begin: 0.08),
                ),
        ],
      ),
    );
  }

  Widget _buildKycCard(DealerKycDocument doc) {
    final icon = _docTypeIcons[doc.documentType] ?? Icons.description_outlined;

    return AdvancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: const Color(0xFFF59E0B), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.documentType.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(doc.businessName, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text('PENDING', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ],
          ),
          const Spacer(),
          // Info
          Row(
            children: [
              const Icon(Icons.person_outline, color: Colors.white38, size: 14),
              const SizedBox(width: 6),
              Text('Dealer #${doc.dealerId}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const Spacer(),
              if (doc.uploadedAt != null)
                Text(DateFormat('MMM dd, yyyy').format(doc.uploadedAt!), style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final success = await _repository.verifyDocument(doc.id, false);
                  if (success) _loadData();
                },
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final success = await _repository.verifyDocument(doc.id, true);
                  if (success) {
                    _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document verified!'), backgroundColor: Color(0xFF22C55E)));
                    }
                  }
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: AdvancedCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
