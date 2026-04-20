import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/repositories/dealer_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class DealerDocumentsView extends StatefulWidget {
  const DealerDocumentsView({super.key});

  @override
  State<DealerDocumentsView> createState() => _DealerDocumentsViewState();
}

class _DealerDocumentsViewState extends SafeState<DealerDocumentsView> {
  final DealerRepository _repository = DealerRepository();
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _typeFilter = 'all';

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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final docs = await _repository.getAllDocuments(search: _searchQuery.isNotEmpty ? _searchQuery : null);
      setState(() {
        _documents = docs;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Dealer documents are unavailable: $e';
      });
    }
  }

  void _applyFilters() {
    _filtered = _documents.where((d) {
      if (_typeFilter != 'all' && d['document_type'] != _typeFilter) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
        ),
      );
    }
    final docTypes = _documents.map((d) => d['document_type'] as String).toSet().toList();
    final verified = _filtered.where((d) => d['is_verified'] == true).length;
    final pending = _filtered.where((d) => d['is_verified'] == false).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Dealer Documents',
            subtitle: 'Manage all documents uploaded by dealer partners.',
            actionButton: Row(
              children: [
                IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _loadData),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          const SizedBox(height: 24),

          // Stats
          Row(
            children: [
              _buildMiniStat('Total Docs', '${_filtered.length}', const Color(0xFF3B82F6)),
              const SizedBox(width: 16),
              _buildMiniStat('Verified', '$verified', const Color(0xFF22C55E)),
              const SizedBox(width: 16),
              _buildMiniStat('Pending', '$pending', const Color(0xFFF59E0B)),
              const SizedBox(width: 16),
              _buildMiniStat('Doc Types', '${docTypes.length}', const Color(0xFF8B5CF6)),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 24),

          // Filters
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) {
                    _searchQuery = v;
                    _loadData();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by business name or document type...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _typeFilter,
                    dropdownColor: const Color(0xFF1E293B),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('All Types', style: TextStyle(color: Colors.white))),
                      ...docTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)))),
                    ],
                    onChanged: (v) => setState(() { _typeFilter = v ?? 'all'; _applyFilters(); }),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
          const SizedBox(height: 24),

          // Documents Grid
          _isLoading
            ? const SizedBox(height: 400, child: Center(child: CircularProgressIndicator()))
            : _filtered.isEmpty
              ? const SizedBox(height: 300, child: Center(child: Text('No documents found.', style: TextStyle(color: Colors.white54))))
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (ctx, i) => _buildDocCard(_filtered[i]).animate().fadeIn(duration: 300.ms, delay: (50 * i).ms).slideY(begin: 0.1),
                ),
        ],
      ),
    );
  }

  Widget _buildDocCard(Map<String, dynamic> doc) {
    final docType = doc['document_type'] as String? ?? '';
    final isVerified = doc['is_verified'] == true;
    final icon = _docTypeIcons[docType] ?? Icons.description_outlined;
    final uploadedAt = DateTime.tryParse(doc['uploaded_at']?.toString() ?? '');

    return AdvancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isVerified ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isVerified ? const Color(0xFF22C55E) : const Color(0xFFF59E0B), size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isVerified ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isVerified ? 'Verified' : 'Pending',
                  style: TextStyle(color: isVerified ? const Color(0xFF22C55E) : const Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(docType.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(doc['business_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              if (uploadedAt != null)
                Text(DateFormat('MMM dd, yyyy').format(uploadedAt), style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isVerified)
                TextButton.icon(
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Verify', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF22C55E)),
                  onPressed: () async {
                    final success = await _repository.verifyDocument(doc['id'] as int, true);
                    if (success) _loadData();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: AdvancedCard(
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color))),
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
