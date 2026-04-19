import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../providers/api_keys_provider.dart';

class GenerateKeyDialog extends ConsumerStatefulWidget {
  final String? initialKey;
  final String? initialService;

  const GenerateKeyDialog({
    super.key, 
    this.initialKey,
    this.initialService,
  });

  @override
  ConsumerState<GenerateKeyDialog> createState() => _GenerateKeyDialogState();
}

class _GenerateKeyDialogState extends ConsumerState<GenerateKeyDialog> {
  final _formKey = GlobalKey<FormState>();
  late bool _isRevealState;
  bool _isLoading = false;
  bool _hasCopied = false;

  // Form Controllers
  late final TextEditingController _serviceNameController;
  final _keyNameController = TextEditingController();
  late final TextEditingController _keyValueController;
  final _apiSecretController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _isRevealState = widget.initialKey != null;
    _serviceNameController = TextEditingController(text: widget.initialService);
    _keyValueController = TextEditingController(text: widget.initialKey);
  }
  String _category = 'Payments';
  String _environment = 'production';
  DateTime? _expiresAt;
  bool _noExpiry = true;
  bool _obscureSecret = true;

  final Map<String, bool> _permissions = {
    'Read': true,
    'Write': true,
    'Delete': false,
    'Webhook': false,
  };

  @override
  void dispose() {
    _serviceNameController.dispose();
    _keyNameController.dispose();
    _keyValueController.dispose();
    _apiSecretController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref.read(apiKeysProvider.notifier).createApiKey(
      serviceName: _serviceNameController.text.trim(),
      keyName: _keyNameController.text.trim(),
      keyValue: _keyValueController.text.trim(),
      environment: _environment,
      apiSecret: _apiSecretController.text.trim().isEmpty ? null : _apiSecretController.text.trim(),
      category: _category,
      expiresAt: _noExpiry ? null : _expiresAt?.toIso8601String(),
      permissions: _permissions.entries.where((e) => e.value).map((e) => e.key).toList(),
    );

    setState(() => _isLoading = false);

    if (success) {
      setState(() => _isRevealState = true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save API key. Please try again.')),
        );
      }
    }
  }

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: _keyValueController.text.trim()));
    setState(() => _hasCopied = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _hasCopied = false);
    });
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
        width: isMobile ? screenWidth : 560,
        constraints: BoxConstraints(maxHeight: isMobile ? double.infinity : 850),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _isRevealState ? _buildRevealScreen() : _buildFormScreen(),
        ),
      ),
    );
  }

  Widget _buildFormScreen() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Generate New API Key',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in the details below to register a new third-party service key.',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
            ),
            const SizedBox(height: 32),

            if (isMobile) ...[
              AdminTextField(
                controller: _serviceNameController,
                label: 'Service Name',
                hint: 'e.g. Razorpay',
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCategoryDropdown(),
                ],
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: AdminTextField(
                      controller: _serviceNameController,
                      label: 'Service Name',
                      hint: 'e.g. Razorpay',
                      icon: Icons.business_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildCategoryDropdown(),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            AdminTextField(
              controller: _keyNameController,
              label: 'Key Label / Description *',
              hint: 'e.g. Production Main Key',
              icon: Icons.label_outline,
            ),
            const SizedBox(height: 20),

            AdminTextField(
              controller: _keyValueController,
              label: 'API Key Value *',
              hint: 'Paste the key from provider dashboard',
              icon: Icons.vpn_key_outlined,
            ),
            const SizedBox(height: 20),

            AdminTextField(
              controller: _apiSecretController,
              label: 'API Secret (Optional)',
              hint: 'Enter secret if provided',
              icon: Icons.lock_outline,
              obscureText: _obscureSecret,
              onToggleObscure: () => setState(() => _obscureSecret = !_obscureSecret),
            ),
            const SizedBox(height: 24),

            _buildSectionLabel('Environment'),
            const SizedBox(height: 12),
            _buildEnvironmentRadios(),
            const SizedBox(height: 24),

            _buildSectionLabel('Expiration'),
            const SizedBox(height: 12),
            _buildExpirationPicker(),
            const SizedBox(height: 24),

            _buildSectionLabel('Permissions Scope'),
            const SizedBox(height: 12),
            _buildPermissionsCheckboxes(),
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
                    label: 'Save',
                    onPressed: _handleSave,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevealScreen() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF59E0B), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Save This Key — You Won\'t See It Again',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          Text(
            'Copy the full key below now. For security, it will be masked permanently once you close this dialog.',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: SelectableText(
              _keyValueController.text,
              style: GoogleFonts.firaCode(
                color: const Color(0xFF60A5FA),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          AdminButton(
            label: _hasCopied ? '✓ Copied!' : '📋 Copy to Clipboard',
            onPressed: _handleCopy,
          ),
          const SizedBox(height: 24),

          Text(
            'This key will NOT be shown again. Make sure to store it securely in a password manager or vault.',
            style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _hasCopied || !_hasCopied ? () => Navigator.pop(context) : null, // Fix: Actually enforce copy
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _hasCopied ? Colors.white24 : Colors.white10),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'I\'ve Saved the Key',
                style: GoogleFonts.inter(
                  color: _hasCopied ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        color: Colors.white54,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = ['Payments', 'SMS / Messaging', 'Email Service', 'Storage', 'Analytics', 'Webhooks', 'Custom'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _category,
          dropdownColor: const Color(0xFF1F2937),
          icon: const Icon(Icons.expand_more, color: Colors.white24),
          isExpanded: true,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          items: categories.map((c) {
            return DropdownMenuItem(value: c, child: Text(c));
          }).toList(),
          onChanged: (val) => setState(() => _category = val!),
        ),
      ),
    );
  }

  Widget _buildEnvironmentRadios() {
    final envs = [
      {'val': 'production', 'label': 'Production'},
      {'val': 'sandbox', 'label': 'Sandbox'},
      {'val': 'development', 'label': 'Development'},
    ];

    return Row(
      children: envs.map((env) {
        final isSelected = _environment == env['val'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _environment = env['val']!),
            child: Container(
              margin: EdgeInsets.only(right: env['val'] == 'development' ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : Colors.white10),
              ),
              child: Center(
                child: Text(
                  env['label']!,
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : Colors.white38,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpirationPicker() {
    return Row(
      children: [
        Checkbox(
          value: _noExpiry,
          onChanged: (val) => setState(() => _noExpiry = val!),
          activeColor: const Color(0xFF3B82F6),
        ),
        Text('No Expiry', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
        const Spacer(),
        if (!_noExpiry)
          TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 365)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFF3B82F6),
                        onPrimary: Colors.white,
                        surface: Color(0xFF1F2937),
                        onSurface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) setState(() => _expiresAt = picked);
            },
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(
              _expiresAt == null 
                ? 'Select Date' 
                : '${_expiresAt!.year}-${_expiresAt!.month}-${_expiresAt!.day}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6)),
          ),
      ],
    );
  }

  Widget _buildPermissionsCheckboxes() {
    return Wrap(
      spacing: 16,
      children: _permissions.keys.map((p) {
        return InkWell(
          onTap: () => setState(() => _permissions[p] = !_permissions[p]!),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _permissions[p],
                  onChanged: (val) => setState(() => _permissions[p] = val!),
                  activeColor: const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 8),
              Text(p, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
