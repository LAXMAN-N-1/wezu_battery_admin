import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../providers/webhooks_provider.dart';

class AddWebhookDialog extends ConsumerStatefulWidget {
  const AddWebhookDialog({super.key});

  @override
  ConsumerState<AddWebhookDialog> createState() => _AddWebhookDialogState();
}

class _AddWebhookDialogState extends ConsumerState<AddWebhookDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _secretController = TextEditingController();
  
  bool _isActive = true;
  bool _isLoading = false;
  
  final List<String> _availableEvents = [
    'payment.completed', 'payment.failed', 'payment.refunded',
    'battery.low', 'battery.swap', 'battery.emergency',
    'system.maintenance', 'user.signup', 'user.alert'
  ];
  
  final List<String> _selectedEvents = [];

  @override
  void dispose() {
    _urlController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one event trigger.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(webhooksProvider.notifier).createWebhook(
      _urlController.text.trim(),
      _selectedEvents,
      secret: _secretController.text.trim().isEmpty ? null : _secretController.text.trim(),
      active: _isActive,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Webhook endpoint added successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add webhook. Check your URL.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: isMobile ? screenWidth : 500,
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Webhook Endpoint',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure a URL to receive real-time notifications for system events.',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
                ),
                const SizedBox(height: 32),
                
                AdminTextField(
                  controller: _urlController,
                  label: 'Payload URL *',
                  hint: 'https://api.yourdomain.com/webhook',
                  icon: Icons.link_outlined,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Event Triggers *',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                _buildEventSelector(),
                const SizedBox(height: 24),
                
                AdminTextField(
                  controller: _secretController,
                  label: 'Signing Secret (Optional)',
                  hint: 'Enter a key to sign the visual payload',
                  icon: Icons.key_outlined,
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Text(
                      'Active Status',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isActive,
                      onChanged: (val) => setState(() => _isActive = val),
                      activeTrackColor: const Color(0xFF22C55E),
                      activeThumbColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Discard',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AdminButton(
                        label: 'Add Endpoint',
                        onPressed: _handleSave,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      constraints: const BoxConstraints(maxHeight: 150),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _availableEvents.length,
        itemBuilder: (context, index) {
          final event = _availableEvents[index];
          final isSelected = _selectedEvents.contains(event);
          return CheckboxListTile(
            value: isSelected,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedEvents.add(event);
                } else {
                  _selectedEvents.remove(event);
                }
              });
            },
            title: Text(
              event,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
            dense: true,
            activeColor: const Color(0xFF3B82F6),
            checkColor: Colors.white,
            controlAffinity: ListTileControlAffinity.trailing,
          );
        },
      ),
    );
  }
}
