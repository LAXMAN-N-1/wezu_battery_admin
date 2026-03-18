import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
<<<<<<< HEAD
=======
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
>>>>>>> origin/main
import '../data/models/legal_document.dart';
import '../data/repositories/legal_repository.dart';

class LegalListView extends ConsumerStatefulWidget {
  const LegalListView({super.key});

  @override
  ConsumerState<LegalListView> createState() => _LegalListViewState();
}

class _LegalListViewState extends ConsumerState<LegalListView> {
  late final LegalRepository _repository;
  List<LegalDocument> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(legalRepositoryProvider);
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
          PageHeader(
            title: 'Legal & Compliance',
            subtitle: 'Manage terms, privacy policies, and compliance documents.',
            actionButton: ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to create view
              },
              icon: const Icon(Icons.gavel_outlined, size: 20, color: Colors.white),
              label: const Text('New Document', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
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
                        return _buildDocCard(_documents[index]).animate().fadeIn(duration: 400.ms, delay: (100 + index * 100).ms).slideY(begin: 0.05);
                      },
                    ),
        ],
      ),
    );
  }
  Widget _buildDocCard(LegalDocument doc) {
    return AdvancedCard(
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
                StatusBadge(status: doc.isActive ? 'Active' : 'Inactive'),
              ],
            ),
            const Spacer(),
            Row(
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
                const Spacer(),
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
