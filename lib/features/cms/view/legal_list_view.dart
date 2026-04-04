import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/legal_document.dart';
import '../data/repositories/legal_repository.dart';

class LegalListView extends StatefulWidget {
  const LegalListView({super.key});

  @override
  State<LegalListView> createState() => _LegalListViewState();
}

class _LegalListViewState extends State<LegalListView> {
  final LegalRepository _repository = LegalRepository();
  List<LegalDocument> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final docs = await _repository.getLegalDocuments();
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading legal documents: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Legal & Compliance',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to create view
                },
                icon: const Icon(Icons.gavel_outlined),
                label: const Text('New Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _documents.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: _documents.length,
                      itemBuilder: (context, index) {
                        return _buildDocCard(_documents[index]);
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildDocCard(LegalDocument doc) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Version ${doc.version}',
                        style: const TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _buildStatusDot(doc.isActive),
              ],
            ),
            const Spacer(),
            Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (doc.forceUpdate)
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.redAccent, size: 12),
                        const SizedBox(width: 4),
                        Text('FORCE UPDATE', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                
                TextButton(
                  onPressed: () {},
                  child: const Text('Edit Content'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white38, size: 20),
                  onPressed: () {},
                  tooltip: 'Version History',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDot(bool isActive) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.gavel_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          Text(
            'No legal documents found',
            style: GoogleFonts.outfit(fontSize: 20, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ensure your platform is compliant by adding T&C and Privacy Policy.',
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
