import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/dealer_application.dart';
import '../data/repositories/dealer_repository.dart';

class DealerKycView extends StatefulWidget {
  const DealerKycView({super.key});

  @override
  State<DealerKycView> createState() => _DealerKycViewState();
}

class _DealerKycViewState extends State<DealerKycView> {
  final DealerRepository _repository = DealerRepository();
  List<DealerKycDocument> _documents = [];
  bool _isLoading = true;

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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dealer KYC & Verification', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Review business licenses, tax documents and track field verification status.', style: GoogleFonts.inter(fontSize: 16, color: Colors.white54)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Docs'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 32),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_documents.isEmpty)
            Center(child: Text('No pending documents for review.', style: GoogleFonts.inter(color: Colors.white54)))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final doc = _documents[index];
                return AdvancedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(
                            image: NetworkImage('https://via.placeholder.com/300x140?text=Document+Preview'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: const Center(child: Icon(Icons.description, size: 48, color: Colors.white24)),
                      ),
                      const SizedBox(height: 16),
                      Text(doc.businessName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(doc.documentType.toUpperCase(), style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600, fontSize: 12)),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _verifyDoc(doc.id, false),
                              style: OutlinedButton.styleFrom(foregroundColor: Color(0xFFEF4444), side: BorderSide(color: Color(0xFFEF4444).withValues(alpha: 0.3))),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _verifyDoc(doc.id, true),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
                              child: const Text('Verify'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: (index * 100).ms).scale(begin: const Offset(0.9, 0.9));
              },
            ),
        ],
      ),
    );
  }

  void _verifyDoc(int docId, bool verified) async {
    final ok = await _repository.verifyDocument(docId, verified);
    if (ok) _loadData();
  }
}
