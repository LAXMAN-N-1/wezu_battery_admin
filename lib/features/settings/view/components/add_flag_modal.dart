import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/widgets/admin_ui_components.dart';
import '../../data/models/feature_flag_model.dart';
import '../../providers/feature_flag_provider.dart';

class AddFlagModal extends ConsumerStatefulWidget {
  const AddFlagModal({super.key});

  @override
  ConsumerState<AddFlagModal> createState() => _AddFlagModalState();
}

class _AddFlagModalState extends ConsumerState<AddFlagModal> {
  final _formKey = GlobalKey<FormState>();
  final _keyCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  FeatureFlagCategory _selectedCategory = FeatureFlagCategory.experimental;
  final List<String> _selectedApps = [];
  bool _defaultEnabled = false;

  final List<String> _availableApps = [
    'Customer App',
    'Dealer Portal',
    'Admin Portal',
    'IoT Core',
    'Billing Service',
  ];

  @override
  void dispose() {
    _keyCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final newFlag = FeatureFlagModel(
      key: _keyCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      isEnabled: _defaultEnabled,
      category: _selectedCategory,
      affectedApps: _selectedApps,
      lastChangedBy: 'You (Admin)',
      lastChangedAt: DateTime.now(),
    );

    await ref.read(featureFlagsProvider.notifier).addFlag(newFlag);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      child: Container(
        width: isMobile ? screenWidth : 500,
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create New Feature Flag', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Define a new flag to control platform behavior at runtime.', style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
                const SizedBox(height: 32),
                
                AdminTextField(
                  controller: _keyCtrl,
                  label: 'Flag Key (snake_case)',
                  hint: 'e.g. enable_v3_payments',
                  icon: Icons.vpn_key_outlined,
                ),
                const SizedBox(height: 20),
                
                AdminTextField(
                  controller: _nameCtrl,
                  label: 'Display Name',
                  hint: 'e.g. Enable V3 Payments',
                  icon: Icons.title,
                ),
                const SizedBox(height: 20),
                
                AdminTextField(
                  controller: _descCtrl,
                  label: 'Description',
                  hint: 'Explain what this flag controls...',
                  icon: Icons.description_outlined,
                ),
                const SizedBox(height: 24),
                
                Text('Category', style: GoogleFonts.inter(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
                    if (isAndroid) {
                      return _buildCategoryDropdown();
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: FeatureFlagCategory.values.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat.label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white24)),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategory = cat);
                          },
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          selectedColor: const Color(0xFF3B82F6),
                          showCheckmark: false,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                Text('Affected Apps', style: GoogleFonts.inter(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
                    if (isAndroid) {
                      return _buildAppsDropdown();
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableApps.map((app) {
                        final isSelected = _selectedApps.contains(app);
                        return FilterChip(
                          label: Text(app, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.white24)),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              if (val) _selectedApps.add(app);
                              else _selectedApps.remove(app);
                            });
                          },
                          backgroundColor: Colors.white.withValues(alpha: 0.03),
                          selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                          showCheckmark: true,
                          checkmarkColor: const Color(0xFF3B82F6),
                          side: BorderSide(color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        );
                      }).toList(),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                Row(
                  children: [
                     Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Discard', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AdminButton(
                        label: 'Create Flag',
                        onPressed: _submit,
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

  Widget _buildCategoryDropdown() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FeatureFlagCategory>(
          value: _selectedCategory,
          dropdownColor: const Color(0xFF1E293B),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white24),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          items: FeatureFlagCategory.values.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Text(cat.label),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedCategory = val);
          },
        ),
      ),
    );
  }

  Widget _buildAppsDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            offset: const Offset(0, 56),
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedApps.isEmpty
                        ? 'Select Apps...'
                        : '${_selectedApps.length} Apps Selected',
                    style: GoogleFonts.inter(
                      color: _selectedApps.isEmpty ? Colors.white24 : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white24),
              ],
            ),
            onSelected: (app) {
              setState(() {
                if (_selectedApps.contains(app)) {
                  _selectedApps.remove(app);
                } else {
                  _selectedApps.add(app);
                }
              });
            },
            itemBuilder: (context) => _availableApps.map((app) {
              final isSelected = _selectedApps.contains(app);
              return PopupMenuItem<String>(
                value: app,
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      color: isSelected ? const Color(0xFF3B82F6) : Colors.white24,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      app,
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        if (_selectedApps.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedApps.map((app) => Chip(
              label: Text(app, style: const TextStyle(fontSize: 10, color: Colors.white70)),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
              onDeleted: () => setState(() => _selectedApps.remove(app)),
              deleteIcon: const Icon(Icons.close, size: 12, color: Colors.white24),
            )).toList(),
          ),
        ],
      ],
    );
  }
}
