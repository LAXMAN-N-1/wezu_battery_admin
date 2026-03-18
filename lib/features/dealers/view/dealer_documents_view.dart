import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';

class DealerDocumentsView extends StatelessWidget {
  const DealerDocumentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Dealer Documents',
            subtitle: 'Central repository for all business licenses, GST certificates, and partnership agreements.',
            actionButton: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upload_file),
              label: const Text('Bulk Upload'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 32),

          // Search and Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by dealer name or document ID...',
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildFilterChip('GST Licenses'),
              const SizedBox(width: 8),
              _buildFilterChip('PAN Cards'),
              const SizedBox(width: 8),
              _buildFilterChip('Agreements'),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 24),

          // Documents Grid
          _buildDocsGrid(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return FilterChip(
      label: Text(label),
      onSelected: (val) {},
      backgroundColor: const Color(0xFF1E293B),
      labelStyle: const TextStyle(color: Colors.white70),
    );
  }

  Widget _buildDocsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: 15, // Mock count for UI
      itemBuilder: (context, index) {
        return AdvancedCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf, size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text('DOC_00${index + 124}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const Text('GST Certificate', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const Spacer(),
              const Divider(color: Colors.white12),
              TextButton(onPressed: () {}, child: const Text('Download')),
            ],
          ),
        );
      },
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.1);
  }
}
