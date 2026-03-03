import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_widgets.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/models/kyc_model.dart';
import '../../../core/providers/kyc_provider.dart';

class KycVerificationView extends ConsumerStatefulWidget {
  final KycRequest request;

  const KycVerificationView({super.key, required this.request});

  @override
  ConsumerState<KycVerificationView> createState() => _KycVerificationViewState();
}

class _KycVerificationViewState extends ConsumerState<KycVerificationView> {
  final _reasonController = TextEditingController();
  String? _selectedReason;
  int _currentDocIndex = 0;
  double _zoomLevel = 1.0;
  int _rotation = 0;

  final List<String> _rejectionReasons = [
    'Document not clear / blurry',
    'Name on document does not match profile',
    'Document expired',
    'Profile photo mismatch',
    'Suspected fraud / Tampered document',
    'Other (Specify)',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: Responsive.isMobile(context) ? MediaQuery.of(context).size.width * 0.95 : 1200,
        height: Responsive.isMobile(context) ? MediaQuery.of(context).size.height * 0.85 : null,
        constraints: BoxConstraints(
          maxWidth: 1200,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            Divider(height: 1, color: AppColors.divider),
            
            // Content
            Expanded(
              child: Responsive.isMobile(context)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Document Viewer (Top)
                        Expanded(
                          flex: 1, 
                          child: _buildDocumentViewer(),
                        ),
                        // Sidebar (Bottom)
                        Expanded(
                          flex: 2, 
                          child: _buildSidebar(context),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Document Viewer (Left)
                        Expanded(
                          child: _buildDocumentViewer(),
                        ),
                        // Sidebar (Right)
                        SizedBox(
                          width: 400,
                          child: _buildSidebar(context),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentViewer() {
    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Image
          InteractiveViewer(
            scaleEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            transformationController: TransformationController(Matrix4.identity()..scale(_zoomLevel, _zoomLevel, 1.0)..rotateZ(_rotation * 3.14159 / 180)),
            child: Image.network(
              widget.request.documentUrls[_currentDocIndex],
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white24, size: 48),
                    SizedBox(height: 16),
                    Text('Failed to load image', style: TextStyle(color: Colors.white24)),
                  ],
                ));
              },
            ),
          ),

          // Controls Overlay
          Positioned(
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_out, color: Colors.white),
                    onPressed: () => setState(() => _zoomLevel = (_zoomLevel - 0.2).clamp(0.5, 4.0)),
                  ),
                  Text('${(_zoomLevel * 100).toInt()}%', style: const TextStyle(color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.zoom_in, color: Colors.white),
                    onPressed: () => setState(() => _zoomLevel = (_zoomLevel + 0.2).clamp(0.5, 4.0)),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.rotate_left, color: Colors.white),
                    onPressed: () => setState(() => _rotation -= 90),
                  ),
                  IconButton(
                    icon: const Icon(Icons.rotate_right, color: Colors.white),
                    onPressed: () => setState(() => _rotation += 90),
                  ),
                ],
              ),
            ),
          ),

          // Pagination (if multiple docs)
          if (widget.request.documentUrls.length > 1)
            Positioned(
              top: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: widget.request.documentUrls.asMap().entries.map((entry) {
                    final isActive = entry.key == _currentDocIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _currentDocIndex = entry.key),
                      child: Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? AppColors.primary : Colors.white24,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: Responsive.isMobile(context) ? BorderSide(color: AppColors.divider) : BorderSide.none,
          left: Responsive.isMobile(context) ? BorderSide.none : BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: 'Request Details'),
                  const SizedBox(height: 16),
                  _buildDetailRow('User Name', widget.request.userName),
                  _buildDetailRow('User ID', widget.request.userId),
                  _buildDetailRow('Document Type', widget.request.documentType.label),
                  _buildDetailRow('Submitted', DateFormat.yMMMd().add_jm().format(widget.request.submittedAt)),
                  
                  const SizedBox(height: 32),
                  SectionHeader(title: 'Verification Checklist'),
                  const SizedBox(height: 16),
                  _buildChecklistItem('Name matches profile'),
                  _buildChecklistItem('Photo matches profile'),
                  _buildChecklistItem('Document is clearly visible'),
                  _buildChecklistItem('Document is valid (not expired)'),

                  const SizedBox(height: 32),
                  const Text('Rejection Reason (If rejecting)', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedReason,
                    isExpanded: true,
                    items: _rejectionReasons.map((reason) => DropdownMenuItem(value: reason, child: Text(reason, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) => setState(() => _selectedReason = val),
                    style: const TextStyle(color: AppColors.textPrimary),
                    dropdownColor: AppColors.surface,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                    ),
                  ),
                  if (_selectedReason == 'Other (Specify)') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter specific reason...',
                        hintStyle: const TextStyle(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Actions Footer
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final reason = _selectedReason == 'Other (Specify)' ? _reasonController.text : _selectedReason;
                      if (reason == null || reason.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a rejection reason')));
                        return;
                      }
                      ref.read(kycProvider.notifier).rejectRequest(widget.request.id, reason);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(kycProvider.notifier).approveRequest(widget.request.id);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verify Identity',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ID: ${widget.request.id}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_box_outline_blank, color: AppColors.textTertiary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
