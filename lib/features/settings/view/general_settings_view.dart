import 'dart:async';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_themes.dart';
import '../../../core/utils/responsive.dart';
import '../data/models/branding_info_model.dart';
import '../data/models/company_info_model.dart';
import '../data/models/email_config_model.dart';
import '../data/models/maintenance_mode_model.dart';
import '../data/models/notification_settings_model.dart';
import '../data/models/regional_info_model.dart';
import '../providers/general_settings_providers.dart';
import '../../../core/widgets/admin_ui_components.dart';

// ============================================================================
// General Settings — Two-Panel Layout (Desktop) / Single-Panel (Mobile)
// Route: /settings
//
// Desktop: Left sticky sidebar nav (20%) + Right scrollable content (80%).
// Tablet:  Collapsible drawer + full-width content.
// Mobile:  Top horizontal chips + full-width stacked content.
//
// All sections are fully responsive — zero overflow on any device size.
// ============================================================================

/// Section definition for the left navigation sidebar.
class _SettingsSection {
  final String id;
  final String label;
  final IconData icon;
  final GlobalKey sectionKey;

  _SettingsSection({
    required this.id,
    required this.label,
    required this.icon,
  }) : sectionKey = GlobalKey();
}

class GeneralSettingsView extends ConsumerStatefulWidget {
  const GeneralSettingsView({super.key});

  @override
  ConsumerState<GeneralSettingsView> createState() =>
      _GeneralSettingsViewState();
}

class _GeneralSettingsViewState extends ConsumerState<GeneralSettingsView> {
  final ScrollController _scrollController = ScrollController();

  /// All settings sections for the navigation.
  late final List<_SettingsSection> _sections = [
    _SettingsSection(
      id: 'company_info',
      label: 'Company Info',
      icon: Icons.business_outlined,
    ),
    _SettingsSection(
      id: 'branding',
      label: 'Branding',
      icon: Icons.palette_outlined,
    ),
    _SettingsSection(
      id: 'regional',
      label: 'Regional & Language',
      icon: Icons.language_outlined,
    ),
    _SettingsSection(
      id: 'email',
      label: 'Email Configuration',
      icon: Icons.email_outlined,
    ),
    _SettingsSection(
      id: 'notifications',
      label: 'Notification Settings',
      icon: Icons.notifications_outlined,
    ),
    _SettingsSection(
      id: 'maintenance',
      label: 'Maintenance Mode',
      icon: Icons.build_outlined,
    ),
  ];

  String _activeSection = 'company_info';

  @override
  void initState() {
    super.initState();
    // Reset global dirty state on mount to prevent leakage from previous screens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(settingsDirtyProvider.notifier).state = false;
        ref.read(settingsSavingProvider.notifier).state = false;
        ref.read(settingsSaveActionProvider.notifier).state = null;
        ref.read(settingsDiscardActionProvider.notifier).state = null;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Change the active section tab
  void _scrollToSection(String sectionId) {
    if (_activeSection != sectionId) {
      // Clear global dirty state and actions anytime we switch sections
      // This enforces the "Switching tabs discards unsaved changes" requirement
      ref.read(settingsDirtyProvider.notifier).state = false;
      ref.read(settingsSavingProvider.notifier).state = false;
      ref.read(settingsSaveActionProvider.notifier).state = null;
      ref.read(settingsDiscardActionProvider.notifier).state = null;
      
      setState(() => _activeSection = sectionId);
    }
  }

  @override
  Widget build(BuildContext context) {

    final isTablet = Responsive.isTablet(context);
    final isMobile = Responsive.isMobile(context);
    final colors = context.appColors;

    Widget child;

    // ── MOBILE / TABLET: single column with horizontal chip nav ──
    if (isMobile || isTablet) {
      child = _buildMobileLayout(colors, isMobile);
    } else {
      // ── DESKTOP: two-panel layout ──
      child = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left sidebar nav (fixed 260px)
          SizedBox(
            width: 260,
            child: _buildSidebarNav(colors),
          ),
          Container(width: 1, color: colors.border.withValues(alpha: 0.1)),
          // Right content area
          Expanded(
            child: _buildScrollableContent(colors, false),
          ),
        ],
      );
    }

    return Stack(
      children: [
        child,
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _StickySaveBar(),
        ),
      ],
    );
  }

  /// Mobile/Tablet layout — horizontal scrolling chip nav + stacked content.
  Widget _buildMobileLayout(AppColorsExtension colors, bool isMobile) {
    return Column(
      children: [
        // Horizontal scrolling nav chips
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: colors.cardBg.withValues(alpha: 0.6),
            border: Border(
              bottom: BorderSide(
                color: colors.border.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: 10,
            ),
            itemCount: _sections.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final section = _sections[index];
              final isActive = _activeSection == section.id;
              return GestureDetector(
                onTap: () => _scrollToSection(section.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? colors.accent.withValues(alpha: 0.12)
                        : colors.border.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? colors.accent.withValues(alpha: 0.3)
                          : colors.border.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        section.icon,
                        size: 16,
                        color: isActive
                            ? colors.accent
                            : colors.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        section.label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive
                              ? colors.accent
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Scrollable content
        Expanded(
          child: _buildScrollableContent(colors, true),
        ),
      ],
    );
  }

  /// The scrollable content area shared by both layouts.
  Widget _buildScrollableContent(AppColorsExtension colors, bool isMobile) {
    final padding = isMobile ? 16.0 : 32.0;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(padding, padding, padding, padding + 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Render only the active section
          _buildActiveSectionContent(colors, isMobile),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildActiveSectionContent(AppColorsExtension colors, bool isMobile) {
    switch (_activeSection) {
      case 'company_info':
        return _CompanyInfoSection(key: const ValueKey('company_info'), isMobile: isMobile);
      case 'branding':
        return _BrandingSection(key: const ValueKey('branding'), isMobile: isMobile);
      case 'regional':
        return _RegionalSection(key: const ValueKey('regional'), isMobile: isMobile);
      case 'email':
        return _EmailConfigSection(key: const ValueKey('email'), isMobile: isMobile);
      case 'notifications':
        return _NotificationSettingsSection(key: const ValueKey('notifications'), isMobile: isMobile);
      case 'maintenance':
        return _MaintenanceModeSection(key: const ValueKey('maintenance'), isMobile: isMobile);
      default:
        final section = _sections.firstWhere((s) => s.id == _activeSection);
        return _buildPlaceholderSection(
          section,
          _sectionDescriptions[section.id] ?? '',
          colors,
        );
    }
  }

  /// Section descriptions for placeholder sections.
  static const _sectionDescriptions = {
    'branding': 'Upload logos, set color themes, and customize the portal appearance.',
    'regional': 'Configure timezone, currency, date format, and language preferences.',
    'email': 'Set up SMTP server, sender address, and email templates.',
    'notifications': 'Configure push, email, and SMS notification preferences.',
    'maintenance': 'Enable maintenance mode to temporarily take the platform offline.',
  };

  /// Sticky left sidebar navigation (desktop only).
  Widget _buildSidebarNav(AppColorsExtension colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBg.withValues(alpha: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
            child: Text(
              'SETTINGS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textTertiary,
                letterSpacing: 1.5,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final section = _sections[index];
                final isActive = _activeSection == section.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: _NavItem(
                    label: section.label,
                    icon: section.icon,
                    isActive: isActive,
                    onTap: () => _scrollToSection(section.id),
                    delay: Duration(milliseconds: 50 * index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }



  /// Placeholder section for sections to be built later.
  Widget _buildPlaceholderSection(
    _SettingsSection section,
    String description,
    AppColorsExtension colors,
  ) {
    return Container(
      key: section.sectionKey,
      child: _GlassSettingsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: section.label, icon: section.icon),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
              decoration: BoxDecoration(
                color: colors.border.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    section.icon,
                    size: 40,
                    color: colors.textTertiary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.accent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      'Coming Soon',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Left Nav Item — Desktop sidebar
// ============================================================================

class _NavItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Duration delay;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isActive
                ? colors.accent.withValues(alpha: 0.08)
                : _isHovered
                    ? colors.border.withValues(alpha: 0.05)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                color: widget.isActive ? colors.accent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isActive
                    ? colors.accent
                    : _isHovered
                        ? colors.textSecondary
                        : colors.textTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight:
                        widget.isActive ? FontWeight.w600 : FontWeight.w400,
                    color: widget.isActive
                        ? colors.accent
                        : _isHovered
                            ? colors.textPrimary
                            : colors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: widget.delay)
        .fadeIn(duration: 300.ms)
        .slideX(begin: -0.15);
  }
}

// ============================================================================
// Glass Settings Card — GlassContainer equivalent with backdrop blur
// ============================================================================

class _GlassSettingsCard extends StatelessWidget {
  final Widget child;

  const _GlassSettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.cardBg.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05);
  }
}

// ============================================================================
// Section Header — with gradient underline
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final bool showRealData;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.subtitle,
    this.showRealData = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: colors.accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (showRealData) ...[
                        const SizedBox(width: 12),
                        const RealDataBadge(),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colors.textTertiary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.accent.withValues(alpha: 0.3),
                colors.border.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Section 1 — Company Information (Fully Responsive)
// ============================================================================

class _CompanyInfoSection extends ConsumerStatefulWidget {
  final bool isMobile;

  const _CompanyInfoSection({super.key, required this.isMobile});

  @override
  ConsumerState<_CompanyInfoSection> createState() =>
      _CompanyInfoSectionState();
}

class _CompanyInfoSectionState extends ConsumerState<_CompanyInfoSection> {
  final _companyNameCtrl = TextEditingController();
  final _companyEmailCtrl = TextEditingController();
  final _supportPhoneCtrl = TextEditingController();
  final _companyAddressCtrl = TextEditingController();
  final _companyWebsiteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  bool _hasChanges = false;
  bool _fieldsPopulated = false;
  bool _isInitializing = false; // Guard to prevent ghost dirty state
  String _selectedCountryCode = '+91';

  void _setDirty(bool isDirty) {
    if (_isInitializing) return;
    if (_hasChanges != isDirty) {
      setState(() => _hasChanges = isDirty);
      ref.read(settingsDirtyProvider.notifier).state = isDirty;
    }
  }

  void _setSaving(bool isSaving) {
    if (_isSaving != isSaving) {
      setState(() => _isSaving = isSaving);
      ref.read(settingsSavingProvider.notifier).state = isSaving;
    }
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _companyEmailCtrl.dispose();
    _supportPhoneCtrl.dispose();
    _companyAddressCtrl.dispose();
    _companyWebsiteCtrl.dispose();
    super.dispose();
  }

  /// Populate form fields from loaded data (only once).
  void _populateFields(CompanyInfoModel info) {
    if (_fieldsPopulated) return;
    _isInitializing = true;
    _fieldsPopulated = true;

    _companyNameCtrl.text = info.companyName;
    _companyEmailCtrl.text = info.companyEmail;
    _companyAddressCtrl.text = info.companyAddress;
    _companyWebsiteCtrl.text = info.companyWebsite;

    if (info.supportPhone.startsWith('+')) {
      final parts = info.supportPhone.split(' ');
      if (parts.length >= 2) {
        _selectedCountryCode = parts[0];
        _supportPhoneCtrl.text = parts.sublist(1).join(' ');
      } else {
        _supportPhoneCtrl.text = info.supportPhone;
      }
    } else {
      _supportPhoneCtrl.text = info.supportPhone;
    }
    
    _isInitializing = false;
  }

  /// Save company information via provider.
  Future<void> _saveCompanyInfo() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    _setSaving(true);

    final currentData = ref.read(companyInfoProvider).valueOrNull;
    final updated = (currentData ?? const CompanyInfoModel()).copyWith(
      companyName: _companyNameCtrl.text.trim(),
      companyEmail: _companyEmailCtrl.text.trim(),
      supportPhone: '$_selectedCountryCode ${_supportPhoneCtrl.text.trim()}',
      companyAddress: _companyAddressCtrl.text.trim(),
      companyWebsite: _companyWebsiteCtrl.text.trim(),
    );

    final success =
        await ref.read(companyInfoProvider.notifier).updateCompanyInfo(updated);

    if (mounted) {
      _setSaving(false);
      if (success) _setDirty(false);
      _showToast(
        success
            ? 'Company information updated successfully'
            : 'Failed to update company information',
        success,
      );
    }
  }

  /// Pick and upload a logo file.
  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'svg', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      if (file.size / (1024 * 1024) > 2) {
        _showToast('Logo must be smaller than 2MB', false);
        return;
      }
      final success = await ref
          .read(companyInfoProvider.notifier)
          .uploadLogo(file.bytes!, file.name);
      if (mounted) {
        _showToast(
          success ? 'Logo uploaded successfully' : 'Failed to upload logo',
          success,
        );
      }
    }
  }

  /// Pick and upload a favicon file.
  Future<void> _pickFavicon() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ico', 'png'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      final success = await ref
          .read(companyInfoProvider.notifier)
          .uploadFavicon(file.bytes!, file.name);
      if (mounted) {
        _showToast(
          success
              ? 'Favicon uploaded successfully'
              : 'Failed to upload favicon',
          success,
        );
      }
    }
  }

  /// Show a styled toast (green = success, red = error).
  void _showToast(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isSuccess ? const Color(0xFF43A047) : const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyInfoAsync = ref.watch(companyInfoProvider);
    final colors = context.appColors;

    return _GlassSettingsCard(
      child: companyInfoAsync.when(
        loading: () => _buildShimmerSkeleton(colors),
        error: (error, _) => _buildErrorState(error, colors),
        data: (info) {
          // Populate controllers once when data arrives
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _populateFields(info);
            // Register callbacks for sticky save bar
            ref.read(settingsSaveActionProvider.notifier).state = _saveCompanyInfo;
            ref.read(settingsDiscardActionProvider.notifier).state = () {
              _fieldsPopulated = false;
              _populateFields(info);
              _setDirty(false);
            };
          });
          return _buildForm(info, colors);
        },
      ),
    );
  }

  /// Shimmer skeleton matching the shape of company info form.
  Widget _buildShimmerSkeleton(AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Company Information',
          icon: Icons.business_outlined,
          showRealData: true,
        ),
        const SizedBox(height: 24),
        for (int i = 0; i < 5; i++) ...[
          const _ShimmerRow(),
          const SizedBox(height: 20),
        ],
        // Logo + favicon shimmer
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: const [
            _ShimmerBox(width: 160, height: 60),
            _ShimmerBox(width: 48, height: 48),
          ],
        ),
      ],
    );
  }

  /// Styled error card with retry button.
  Widget _buildErrorState(Object error, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Company Information',
          icon: Icons.business_outlined,
          showRealData: true,
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colors.danger.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.danger.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: colors.danger, size: 40),
              const SizedBox(height: 12),
              Text(
                'Failed to load company information',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                error.toString(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colors.textTertiary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(companyInfoProvider.notifier).reload(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The actual Company Information form — fully responsive.
  Widget _buildForm(CompanyInfoModel info, AppColorsExtension colors) {
    final isMobile = widget.isMobile;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Company Information',
            icon: Icons.business_outlined,
            subtitle:
                'Core identity reflected in emails, invoices, and app branding.',
            showRealData: true,
          ),
          const SizedBox(height: 28),

          // ─── Company Name ───
          _SettingsTextField(
            controller: _companyNameCtrl,
            label: 'Company Name',
            hint: 'e.g. WEZU Energy Pvt. Ltd.',
            icon: Icons.business,
            isRequired: true,
            onChanged: (_) => _setDirty(true),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Company name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),

          // ─── Company Email ───
          _SettingsTextField(
            controller: _companyEmailCtrl,
            label: 'Company Email',
            hint: 'e.g. contact@wezu.energy',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _setDirty(true),
            validator: (val) {
              if (val != null && val.isNotEmpty) {
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                if (!emailRegex.hasMatch(val)) {
                  return 'Enter a valid email address';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 22),

          // ─── Support Phone (with country code) ───
          _buildPhoneField(colors, isMobile),
          const SizedBox(height: 22),

          // ─── Company Address ───
          _SettingsTextField(
            controller: _companyAddressCtrl,
            label: 'Company Address',
            hint: 'Full postal address (max 300 characters)',
            icon: Icons.location_on_outlined,
            maxLines: 3,
            maxLength: 300,
            onChanged: (_) => _setDirty(true),
          ),
          const SizedBox(height: 22),

          // ─── Company Website ───
          _SettingsTextField(
            controller: _companyWebsiteCtrl,
            label: 'Company Website',
            hint: 'e.g. https://wezu.energy',
            icon: Icons.language,
            keyboardType: TextInputType.url,
            onChanged: (_) => _setDirty(true),
            validator: (val) {
              if (val != null && val.isNotEmpty) {
                final urlRegex = RegExp(
                  r'^https?://[^\s/$.?#].[^\s]*$',
                  caseSensitive: false,
                );
                if (!urlRegex.hasMatch(val)) {
                  return 'Enter a valid URL starting with http:// or https://';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 28),

          // ─── Logo & Favicon Upload ───
          _buildMediaUploadRow(info, colors, isMobile),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Phone input with country code selector — stacks on mobile.
  Widget _buildPhoneField(AppColorsExtension colors, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support Phone',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
            children: [
              // Country code dropdown
              Container(
                width: isMobile ? double.infinity : null,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCountryCode,
                    isExpanded: isMobile,
                    dropdownColor: const Color(0xFF1F2937),
                    style: GoogleFonts.robotoMono(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: colors.textTertiary,
                      size: 20,
                    ),
                    items: const [
                      DropdownMenuItem(value: '+91', child: Text('+91 🇮🇳')),
                      DropdownMenuItem(value: '+1', child: Text('+1 🇺🇸')),
                      DropdownMenuItem(value: '+44', child: Text('+44 🇬🇧')),
                      DropdownMenuItem(value: '+61', child: Text('+61 🇦🇺')),
                      DropdownMenuItem(value: '+971', child: Text('+971 🇦🇪')),
                      DropdownMenuItem(value: '+65', child: Text('+65 🇸🇬')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCountryCode = val;
                        });
                        _setDirty(true);
                      }
                    },
                  ),
                ),
              ),
              SizedBox(
                width: isMobile ? 0 : 10,
                height: isMobile ? 10 : 0,
              ),
              // Phone number input
              isMobile
                  ? _SettingsTextField(
                      controller: _supportPhoneCtrl,
                      label: '',
                      hint: 'e.g. 9876543210',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      showLabel: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                      onChanged: (_) => _setDirty(true),
                    )
                  : Expanded(
                      child: _SettingsTextField(
                        controller: _supportPhoneCtrl,
                        label: '',
                        hint: 'e.g. 9876543210',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        showLabel: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        onChanged: (_) => _setDirty(true),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  /// Company logo and favicon upload — stacks vertically on mobile.
  Widget _buildMediaUploadRow(
    CompanyInfoModel info,
    AppColorsExtension colors,
    bool isMobile,
  ) {
    final logoWidget = _buildLogoUpload(info, colors);
    final faviconWidget = _buildFaviconUpload(info, colors);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          logoWidget,
          const SizedBox(height: 24),
          faviconWidget,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: logoWidget),
        const SizedBox(width: 32),
        Expanded(flex: 2, child: faviconWidget),
      ],
    );
  }

  /// Logo upload widget.
  Widget _buildLogoUpload(CompanyInfoModel info, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Company Logo',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'PNG, SVG, or JPG • Max 2MB • Displayed at 160×60px',
          style: GoogleFonts.inter(fontSize: 11, color: colors.textTertiary),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickLogo,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 200,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.15),
                ),
              ),
              child: info.companyLogoUrl != null &&
                      info.companyLogoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.network(
                        info.companyLogoUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            _placeholderIcon(colors, '160 × 60 px'),
                      ),
                    )
                  : _placeholderIcon(colors, '160 × 60 px'),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _SmallActionButton(
          label: 'Replace Logo',
          icon: Icons.upload_file,
          onTap: _pickLogo,
        ),
      ],
    );
  }

  /// Favicon upload widget with browser tab preview.
  Widget _buildFaviconUpload(CompanyInfoModel info, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Favicon',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ICO or PNG • Shown in browser tab',
          style: GoogleFonts.inter(fontSize: 11, color: colors.textTertiary),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickFavicon,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Wrap(
              spacing: 14,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Favicon preview box
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.15),
                    ),
                  ),
                  child: info.faviconUrl != null && info.faviconUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.network(
                            info.faviconUrl!,
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.image_outlined,
                              size: 20,
                              color: colors.textTertiary.withValues(alpha: 0.4),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.image_outlined,
                          size: 20,
                          color: colors.textTertiary.withValues(alpha: 0.4),
                        ),
                ),
                // Browser tab mock
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A3A4A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Icon(
                          Icons.bolt,
                          size: 10,
                          color: colors.accent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'WEZU Admin',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _SmallActionButton(
          label: 'Replace Favicon',
          icon: Icons.upload_file,
          onTap: _pickFavicon,
        ),
      ],
    );
  }

  Widget _placeholderIcon(AppColorsExtension colors, String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 28,
            color: colors.textTertiary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: colors.textTertiary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Reusable Settings Text Field — with focus glow ring & validation
// ============================================================================

class _SettingsTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isRequired;
  final bool showLabel;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _SettingsTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isRequired = false,
    this.showLabel = true,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.validator,
    this.inputFormatters,
  });

  @override
  State<_SettingsTextField> createState() => _SettingsTextFieldState();
}

class _SettingsTextFieldState extends State<_SettingsTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel && widget.label.isNotEmpty) ...[
          Row(
            children: [
              Flexible(
                child: Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isRequired) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: TextStyle(
                    color: colors.danger,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        Focus(
          onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: colors.accent.withValues(alpha: 0.12),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: TextFormField(
              controller: widget.controller,
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              onChanged: widget.onChanged,
              validator: widget.validator,
              inputFormatters: widget.inputFormatters,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                prefixIcon: Icon(
                  widget.icon,
                  color: _isFocused ? colors.accent : colors.textTertiary,
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFF1F2937),
                counterStyle: GoogleFonts.inter(
                  fontSize: 11,
                  color: colors.textTertiary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colors.accent,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colors.danger,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colors.danger,
                    width: 1.5,
                  ),
                ),
                errorStyle: GoogleFonts.inter(
                  fontSize: 11,
                  color: colors.danger,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Small Action Button (Replace Logo / Favicon)
// ============================================================================

class _SmallActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_SmallActionButton> createState() => _SmallActionButtonState();
}

class _SmallActionButtonState extends State<_SmallActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? colors.accent.withValues(alpha: 0.12)
                : colors.accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered
                  ? colors.accent.withValues(alpha: 0.3)
                  : colors.accent.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: colors.accent),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Save Button with loading state & gradient
// ============================================================================

class _SaveButton extends StatefulWidget {
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final isMobile = Responsive.isMobile(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap:
            widget.isEnabled && !widget.isLoading ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 18 : 28,
            vertical: isMobile ? 12 : 14,
          ),
          decoration: BoxDecoration(
            gradient: widget.isEnabled
                ? LinearGradient(
                    colors: [
                      _isHovered
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF1E88E5),
                      _isHovered
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF1565C0),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isEnabled
                ? null
                : colors.border.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.isEnabled && _isHovered
                ? [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 10),
              ] else ...[
                Icon(
                  Icons.save_outlined,
                  size: 18,
                  color: widget.isEnabled
                      ? Colors.white
                      : colors.textTertiary,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.isLoading ? 'Saving...' : 'Save',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isEnabled
                      ? Colors.white
                      : colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Shimmer Skeleton Components
// ============================================================================

class _ShimmerRow extends StatelessWidget {
  const _ShimmerRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ShimmerBox(width: 120, height: 14),
        const SizedBox(height: 8),
        _ShimmerBox(width: double.infinity, height: 48),
      ],
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;

  const _ShimmerBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1500.ms,
          color: Colors.white.withValues(alpha: 0.06),
        );
  }
}

// ============================================================================
// Section 4 — Email Configuration
// ============================================================================

class _EmailConfigSection extends ConsumerStatefulWidget {
  final bool isMobile;

  const _EmailConfigSection({super.key, required this.isMobile});

  @override
  ConsumerState<_EmailConfigSection> createState() => _EmailConfigSectionState();
}

class _EmailConfigSectionState extends ConsumerState<_EmailConfigSection> {
  final _formKey = GlobalKey<FormState>();

  final _fromNameCtrl = TextEditingController();
  final _fromEmailCtrl = TextEditingController();
  final _replyToCtrl = TextEditingController();
  final _smtpHostCtrl = TextEditingController();
  final _smtpPortCtrl = TextEditingController();
  final _smtpUsernameCtrl = TextEditingController();
  final _smtpPasswordCtrl = TextEditingController();

  String _encryption = 'STARTTLS';
  bool _obscurePassword = true;

  bool _isSaving = false;
  bool _isTesting = false;
  bool _hasChanges = false;
  bool _fieldsPopulated = false;
  bool _isInitializing = false;

  void _setDirty(bool isDirty) {
    if (_isInitializing) return;
    if (_hasChanges != isDirty) {
      setState(() => _hasChanges = isDirty);
      ref.read(settingsDirtyProvider.notifier).state = isDirty;
    }
  }

  void _setSaving(bool isSaving) {
    if (_isSaving != isSaving) {
      setState(() => _isSaving = isSaving);
      ref.read(settingsSavingProvider.notifier).state = isSaving;
    }
  }

  final List<String> _encryptionOptions = ['None', 'STARTTLS', 'SSL/TLS'];

  @override
  void dispose() {
    _fromNameCtrl.dispose();
    _fromEmailCtrl.dispose();
    _replyToCtrl.dispose();
    _smtpHostCtrl.dispose();
    _smtpPortCtrl.dispose();
    _smtpUsernameCtrl.dispose();
    _smtpPasswordCtrl.dispose();
    super.dispose();
  }

  void _onFieldChanged(String _) {
    _setDirty(true);
  }

  void _populateFields(EmailConfigModel info) {
    if (_fieldsPopulated) return;
    _isInitializing = true;
    _fieldsPopulated = true;

    _fromNameCtrl.text = info.fromName;
    _fromEmailCtrl.text = info.fromEmail;
    _replyToCtrl.text = info.replyToEmail;
    _smtpHostCtrl.text = info.smtpHost;
    _smtpPortCtrl.text = info.smtpPort.toString();
    _encryption = info.encryption;
    _smtpUsernameCtrl.text = info.smtpUsername;
    _smtpPasswordCtrl.text = info.smtpPassword;
    
    _isInitializing = false;
  }

  Future<void> _saveEmailConfig() async {
    if (!_formKey.currentState!.validate()) return;
    
    _setSaving(true);

    final updated = EmailConfigModel(
      fromName: _fromNameCtrl.text.trim(),
      fromEmail: _fromEmailCtrl.text.trim(),
      replyToEmail: _replyToCtrl.text.trim(),
      smtpHost: _smtpHostCtrl.text.trim(),
      smtpPort: int.tryParse(_smtpPortCtrl.text.trim()) ?? 587,
      encryption: _encryption,
      smtpUsername: _smtpUsernameCtrl.text.trim(),
      smtpPassword: _smtpPasswordCtrl.text.trim(),
    );

    final success =
        await ref.read(emailConfigProvider.notifier).updateEmailConfig(updated);

    if (mounted) {
      _setSaving(false);
      if (success) _setDirty(false);
      _showToast(
        success
            ? 'Email configuration updated successfully'
            : 'Failed to update email configuration',
        success,
      );
    }
  }

  Future<void> _sendTestEmail() async {
    // Ideally, we'd save first before testing, or we warn the user.
    // We'll just run the test endpoint.
    setState(() => _isTesting = true);

    try {
      await ref.read(emailConfigProvider.notifier).sendTestEmail();
      if (mounted) {
        _showToast('Test email sent to admin successfully.', true);
      }
    } catch (e) {
      if (mounted) {
        _showToast(e.toString(), false);
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  void _showToast(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isSuccess ? const Color(0xFF43A047) : const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailConfigAsync = ref.watch(emailConfigProvider);
    final colors = context.appColors;

    return _GlassSettingsCard(
      child: emailConfigAsync.when(
        loading: () => _buildShimmerSkeleton(colors),
        error: (error, _) => _buildErrorState(error, colors),
        data: (info) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _populateFields(info);
            ref.read(settingsSaveActionProvider.notifier).state = _saveEmailConfig;
            ref.read(settingsDiscardActionProvider.notifier).state = () {
              _fieldsPopulated = false;
              _populateFields(info);
              _setDirty(false);
            };
          });
          return _buildForm(info, colors);
        },
      ),
    );
  }

  Widget _buildShimmerSkeleton(AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Email Configuration',
          icon: Icons.mark_email_read_outlined,
          showRealData: true,
        ),
        const SizedBox(height: 24),
        for (int i = 0; i < 4; i++) ...[
          const _ShimmerRow(),
          const SizedBox(height: 20),
        ],
        const _ShimmerBox(width: 160, height: 60),
      ],
    );
  }

  Widget _buildErrorState(Object error, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Email Configuration',
          icon: Icons.mark_email_read_outlined,
          showRealData: true,
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colors.danger.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.danger.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: colors.danger, size: 40),
              const SizedBox(height: 12),
              Text(
                'Failed to load email configuration',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                error.toString(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colors.textTertiary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ref.read(emailConfigProvider.notifier).reload(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm(EmailConfigModel info, AppColorsExtension colors) {
    final isMobile = widget.isMobile;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Email Configuration',
            icon: Icons.mark_email_read_outlined,
            subtitle: 'SMTP settings for system-generated outgoing emails.',
            showRealData: true,
          ),
          const SizedBox(height: 28),

          // Core Sender Headers
          // --- Row 1: From Name & Email ---
          _buildResponsiveRow(
            isMobile: isMobile,
            child1: _buildTextField(
              label: 'From Name',
              controller: _fromNameCtrl,
              hint: 'e.g., WEZU Energy Support',
              colors: colors,
              keyboardType: TextInputType.name,
            ),
            child2: _buildTextField(
              label: 'From Email Address',
              controller: _fromEmailCtrl,
              hint: 'e.g., noreply@wezuenergy.com',
              colors: colors,
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
          ),
          const SizedBox(height: 24),

          // --- Row 2: Reply-To & Empty ---
          _buildResponsiveRow(
            isMobile: isMobile,
            child1: _buildTextField(
              label: 'Reply-To Email',
              controller: _replyToCtrl,
              hint: 'Optional email input',
              colors: colors,
              keyboardType: TextInputType.emailAddress,
              validator: _optionalEmailValidator,
            ),
            child2: const SizedBox.shrink(),
          ),

          const SizedBox(height: 32),
          Divider(color: colors.border.withValues(alpha: 0.1)),
          const SizedBox(height: 32),

          // SMTP Settings
          // --- Row 3: Host & Port ---
          _buildResponsiveRow(
            isMobile: isMobile,
            child1: _buildTextField(
              label: 'SMTP Host',
              controller: _smtpHostCtrl,
              hint: 'e.g., smtp.sendgrid.net',
              colors: colors,
            ),
            child2: _buildTextField(
              label: 'SMTP Port',
              controller: _smtpPortCtrl,
              hint: '25 | 465 | 587',
              colors: colors,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          const SizedBox(height: 24),

          // --- Row 4: Encryption & Empty ---
          _buildResponsiveRow(
            isMobile: isMobile,
            child1: _buildSearchableDropdown(
              label: 'Encryption',
              value: _encryption,
              options: _encryptionOptions,
              colors: colors,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _encryption = val);
                  _setDirty(true);
                }
              },
            ),
            child2: const SizedBox.shrink(),
          ),

          const SizedBox(height: 32),
          
          // Credentials
          // --- Row 5: Username & Password ---
          _buildResponsiveRow(
            isMobile: isMobile,
            child1: _buildTextField(
              label: 'SMTP Username',
              controller: _smtpUsernameCtrl,
              hint: 'API Key or Username',
              colors: colors,
            ),
            child2: _buildTextField(
              label: 'SMTP Password',
              controller: _smtpPasswordCtrl,
              hint: '••••••••',
              colors: colors,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: colors.textTertiary,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Actions
          Wrap(
            alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Test Config Button
              OutlinedButton.icon(
                onPressed: _isTesting || _hasChanges ? null : _sendTestEmail,
                icon: _isTesting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_outlined, size: 18),
                label: Text(
                  _isTesting ? 'Sending...' : 'Send Test Email',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accent,
                  side: BorderSide(color: colors.accent.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Extracted reusable text field method
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required AppColorsExtension colors,
    String? hint,
    FormFieldValidator<String>? validator,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          validator: validator,
          onChanged: _onFieldChanged,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: colors.textTertiary.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: const Color(0xFF1F2937),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.border.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.accent,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.danger.withValues(alpha: 0.5),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.danger,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchableDropdown({
    required String label,
    required String value,
    required List<String> options,
    required AppColorsExtension colors,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            return Theme(
              data: Theme.of(context).copyWith(
                focusColor: Colors.transparent,
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: colors.accent,
                  selectionColor: colors.accent.withValues(alpha: 0.3),
                  selectionHandleColor: colors.accent,
                ),
              ),
              child: DropdownMenu<String>(
                initialSelection: options.contains(value) ? value : options.first,
                onSelected: onChanged,
                dropdownMenuEntries: options.map<DropdownMenuEntry<String>>((String val) {
                  return DropdownMenuEntry<String>(
                    value: val,
                    label: val,
                    style: MenuItemButton.styleFrom(
                      foregroundColor: Colors.white,
                      textStyle: GoogleFonts.inter(fontSize: 14),
                    ),
                  );
                }).toList(),
                width: constraints.maxWidth,
                enableSearch: false, // Small enum list, no search needed
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStatePropertyAll<Color>(const Color(0xFF1F2937)),
                  surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
                  elevation: const WidgetStatePropertyAll<double>(8),
                  shape: WidgetStatePropertyAll<OutlinedBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colors.border.withValues(alpha: 0.1)),
                    ),
                  ),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: const Color(0xFF1F2937),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.accent),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) return 'Invalid email format';
    return null;
  }

  String? _optionalEmailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) return 'Invalid email format';
    return null;
  }
}

// ============================================================================
// Section 3 — Regional & Language
// ============================================================================

class _RegionalSection extends ConsumerStatefulWidget {
  final bool isMobile;

  const _RegionalSection({super.key, required this.isMobile});

  @override
  ConsumerState<_RegionalSection> createState() => _RegionalSectionState();
}

class _RegionalSectionState extends ConsumerState<_RegionalSection> {
  // Hardcoded Language choices
  final List<String> _languages = [
    'English',
    'Telugu',
    'Hindi',
    'Tamil',
    'Kannada',
    'Malayalam',
    'Marathi',
    'Gujarati',
    'Bengali',
  ];

  // Hardcoded standard timezones
  final List<String> _timezones = [
    'Asia/Kolkata (IST +05:30)',
    'Asia/Dubai (GST +04:00)',
    'Asia/Riyadh (AST +03:00)',
    'Asia/Singapore (SGT +08:00)',
    'Europe/London (GMT +00:00)',
    'America/New_York (EST -05:00)',
    'America/Los_Angeles (PST -08:00)',
    'Australia/Sydney (AEDT +11:00)',
  ];

  final List<String> _dateFormats = [
    'DD/MM/YYYY',
    'MM/DD/YYYY',
    'YYYY-MM-DD',
  ];

  final List<String> _currencies = [
    'INR (₹)',
    'USD (\$)',
    'EUR (€)',
    'GBP (£)',
  ];

  final List<String> _numberFormats = [
    '1,234.56 (EN)',
    '1.234,56 (EU)',
    '1 234.56 (FR)',
  ];

  String _language = 'English';
  String _timezone = 'Asia/Kolkata (IST +05:30)';
  String _dateFormat = 'DD/MM/YYYY';
  String _timeFormat = '12-hour';
  String _currency = 'INR (₹)';
  String _numberFormat = '1,234.56 (EN)';

  bool _isSaving = false;
  bool _hasChanges = false;
  bool _fieldsPopulated = false;
  bool _isInitializing = false;

  void _setDirty(bool isDirty) {
    if (_isInitializing) return;
    if (_hasChanges != isDirty) {
      setState(() => _hasChanges = isDirty);
      ref.read(settingsDirtyProvider.notifier).state = isDirty;
    }
  }

  void _setSaving(bool isSaving) {
    if (_isSaving != isSaving) {
      setState(() => _isSaving = isSaving);
      ref.read(settingsSavingProvider.notifier).state = isSaving;
    }
  }

  void _populateFields(RegionalInfoModel info) {
    if (_fieldsPopulated) return;
    _isInitializing = true;
    _fieldsPopulated = true;
    _language = info.language;
    _timezone = info.timezone;
    _dateFormat = info.dateFormat;
    _timeFormat = info.timeFormat;
    _currency = info.currency;
    _numberFormat = info.numberFormat;
    _isInitializing = false;
  }

  Future<void> _saveRegionalInfo() async {
    _setSaving(true);

    final updated = RegionalInfoModel(
      language: _language,
      timezone: _timezone,
      dateFormat: _dateFormat,
      timeFormat: _timeFormat,
      currency: _currency,
      numberFormat: _numberFormat,
    );

    final success =
        await ref.read(regionalInfoProvider.notifier).updateRegionalInfo(updated);

    if (mounted) {
      _setSaving(false);
      if (success) _setDirty(false);
      _showToast(
        success
            ? 'Regional information updated successfully'
            : 'Failed to update regional information',
        success,
      );
    }
  }

  void _showToast(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isSuccess ? const Color(0xFF43A047) : const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Calculates an example date based on selected format to show inside the UI.
  String _getExampleDateFormatter() {
    switch (_dateFormat) {
      case 'MM/DD/YYYY':
        return '04/07/2026'; // April 7, 2026
      case 'YYYY-MM-DD':
        return '2026-04-07';
      case 'DD/MM/YYYY':
      default:
        return '07/04/2026'; // 7th April, 2026
    }
  }

  @override
  Widget build(BuildContext context) {
    final regionalInfoAsync = ref.watch(regionalInfoProvider);
    final colors = context.appColors;

    return _GlassSettingsCard(
      child: regionalInfoAsync.when(
        loading: () => _buildShimmerSkeleton(colors),
        error: (error, _) => _buildErrorState(error, colors),
        data: (info) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _populateFields(info);
            ref.read(settingsSaveActionProvider.notifier).state = _saveRegionalInfo;
            ref.read(settingsDiscardActionProvider.notifier).state = () {
              _fieldsPopulated = false;
              _populateFields(info);
              _setDirty(false);
            };
          });
          return _buildForm(info, colors);
        },
      ),
    );
  }

  Widget _buildShimmerSkeleton(AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Regional & Language',
          icon: Icons.language,
          showRealData: true,
        ),
        const SizedBox(height: 24),
        for (int i = 0; i < 4; i++) ...[
          const _ShimmerRow(),
          const SizedBox(height: 20),
        ],
        const _ShimmerBox(width: 160, height: 60),
      ],
    );
  }

  Widget _buildErrorState(Object error, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Regional & Language',
          icon: Icons.language,
          showRealData: true,
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colors.danger.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.danger.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: colors.danger, size: 40),
              const SizedBox(height: 12),
              Text(
                'Failed to load regional information',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                error.toString(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colors.textTertiary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ref.read(regionalInfoProvider.notifier).reload(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm(RegionalInfoModel info, AppColorsExtension colors) {
    final isMobile = widget.isMobile;

    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Regional & Language',
            icon: Icons.language,
            subtitle: 'Configure operational defaults for localization, time, and money presentation.',
            showRealData: true,
          ),
          const SizedBox(height: 28),

          // --- Row 1: Language & Time Format ---
          _buildResponsiveRow(
            isMobile: isMobile,
            child1: _buildSearchableDropdown(
              label: 'Default Language',
              value: _language,
              options: _languages,
              colors: colors,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _language = val);
                  _setDirty(true);
                }
              },
            ),
            child2: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time Format',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _TimeFormatRadio(
                      label: '12-hour (2:30 PM)',
                      value: '12-hour',
                      groupValue: _timeFormat,
                      onChanged: (val) {
                        setState(() => _timeFormat = val);
                        _setDirty(true);
                      },
                    ),
                    _TimeFormatRadio(
                      label: '24-hour (14:30)',
                      value: '24-hour',
                      groupValue: _timeFormat,
                      onChanged: (val) {
                        setState(() => _timeFormat = val);
                        _setDirty(true);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Row 2: Timezone & Currency ---
          _buildResponsiveRow(
            isMobile: isMobile,
            child1: _buildSearchableDropdown(
              label: 'Default Timezone',
              value: _timezone,
              options: _timezones,
              colors: colors,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _timezone = val);
                  _setDirty(true);
                }
              },
            ),
            child2: _buildStandardDropdown(
              label: 'Currency',
              value: _currency,
              options: _currencies,
              colors: colors,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _currency = val);
                  _setDirty(true);
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          // --- Row 3: Date Format & Number Format ---
          _buildResponsiveRow(
            isMobile: isMobile,
            child1: _buildStandardDropdown(
              label: 'Date Format',
              value: _dateFormat,
              options: _dateFormats,
              livePreviewHelp: 'e.g., ${_getExampleDateFormatter()}',
              colors: colors,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _dateFormat = val);
                  _setDirty(true);
                }
              },
            ),
            child2: _buildStandardDropdown(
              label: 'Number Format',
              value: _numberFormat,
              options: _numberFormats,
              colors: colors,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _numberFormat = val);
                  _setDirty(true);
                }
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Builds a Native Material 3 DropdownMenu which has built-in type-to-search.
  Widget _buildSearchableDropdown({
    required String label,
    required String value,
    required List<String> options,
    required AppColorsExtension colors,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            return Theme(
              data: Theme.of(context).copyWith(
                focusColor: Colors.transparent,
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: colors.accent,
                  selectionColor: colors.accent.withValues(alpha: 0.3),
                  selectionHandleColor: colors.accent,
                ),
              ),
              child: DropdownMenu<String>(
                initialSelection: options.contains(value) ? value : options.first,
                onSelected: onChanged,
                dropdownMenuEntries: options.map<DropdownMenuEntry<String>>((String val) {
                  return DropdownMenuEntry<String>(
                    value: val,
                    label: val,
                    style: MenuItemButton.styleFrom(
                      foregroundColor: Colors.white,
                      textStyle: GoogleFonts.inter(fontSize: 14),
                    ),
                  );
                }).toList(),
                width: constraints.maxWidth,
                enableSearch: true,
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStatePropertyAll<Color>(const Color(0xFF1F2937)),
                  surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
                  elevation: const WidgetStatePropertyAll<double>(8),
                  shape: WidgetStatePropertyAll<OutlinedBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colors.border.withValues(alpha: 0.1)),
                    ),
                  ),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: const Color(0xFF1F2937),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.accent),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Builds a standard styling form dropdown using regular DropdownButtonFormField to mix it up,
  /// or we could use DropdownMenu here too. DropdownMenu is preferred for M3.
  Widget _buildStandardDropdown({
    required String label,
    required String value,
    required List<String> options,
    required AppColorsExtension colors,
    required ValueChanged<String?> onChanged,
    String? livePreviewHelp,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
            if (livePreviewHelp != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  livePreviewHelp,
                  key: ValueKey(livePreviewHelp),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colors.accent,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: options.contains(value) ? value : options.first,
          onChanged: onChanged,
          icon: Icon(Icons.arrow_drop_down, color: colors.textSecondary),
          dropdownColor: const Color(0xFF1F2937),
          elevation: 4,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1F2937),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.accent),
            ),
          ),
          items: options.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TimeFormatRadio extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _TimeFormatRadio({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accent.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.accent : colors.border.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colors.accent : colors.textTertiary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isSelected ? Colors.white : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Section 2 — Branding
// ============================================================================

class _BrandingSection extends ConsumerStatefulWidget {
  final bool isMobile;

  const _BrandingSection({super.key, required this.isMobile});

  @override
  ConsumerState<_BrandingSection> createState() => _BrandingSectionState();
}

class _BrandingSectionState extends ConsumerState<_BrandingSection> {
  // Local state for live preview (instantly reflects color picker drag)
  Color _primaryColor = const Color(0xFF2563EB);
  Color _secondaryColor = const Color(0xFF1E40AF);
  String _themeMode = 'system';
  
  bool _isSaving = false;
  bool _hasChanges = false;
  bool _fieldsPopulated = false;
  bool _isInitializing = false;

  void _setDirty(bool isDirty) {
    if (_isInitializing) return;
    if (_hasChanges != isDirty) {
      setState(() => _hasChanges = isDirty);
      ref.read(settingsDirtyProvider.notifier).state = isDirty;
    }
  }

  void _setSaving(bool isSaving) {
    if (_isSaving != isSaving) {
      setState(() => _isSaving = isSaving);
      ref.read(settingsSavingProvider.notifier).state = isSaving;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Parse hex string to Color object.
  Color _colorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.tryParse(hexColor, radix: 16) ?? 0xFF2563EB);
  }

  /// Format Color object to hex string.
  String _hexFromColor(Color color) {
    return '#${color.r.toInt().toRadixString(16).padLeft(2, '0')}${color.g.toInt().toRadixString(16).padLeft(2, '0')}${color.b.toInt().toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  void _populateFields(BrandingInfoModel info) {
    if (_fieldsPopulated) return;
    _isInitializing = true;
    _fieldsPopulated = true;
    _primaryColor = _colorFromHex(info.primaryColor);
    _secondaryColor = _colorFromHex(info.secondaryColor);
    _themeMode = info.themeMode;
    _isInitializing = false;
  }

  Future<void> _saveBrandingInfo() async {
    _setSaving(true);

    final currentData = ref.read(brandingInfoProvider).valueOrNull;
    final updated = (currentData ?? const BrandingInfoModel()).copyWith(
      primaryColor: _hexFromColor(_primaryColor),
      secondaryColor: _hexFromColor(_secondaryColor),
      themeMode: _themeMode,
    );

    final success =
        await ref.read(brandingInfoProvider.notifier).updateBrandingInfo(updated);

    if (mounted) {
      _setSaving(false);
      if (success) _setDirty(false);
      _showToast(
        success
            ? 'Branding information updated successfully'
            : 'Failed to update branding information',
        success,
      );
    }
  }

  Future<void> _pickEmailLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'svg', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      if (file.size / (1024 * 1024) > 2) {
        _showToast('Logo must be smaller than 2MB', false);
        return;
      }
      final success = await ref
          .read(brandingInfoProvider.notifier)
          .uploadEmailLogo(file.bytes!, file.name);
      if (mounted) {
        _showToast(
          success
              ? 'Email logo uploaded successfully'
              : 'Failed to upload email logo',
          success,
        );
      }
    }
  }

  void _showToast(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isSuccess ? const Color(0xFF43A047) : const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brandingInfoAsync = ref.watch(brandingInfoProvider);
    final colors = context.appColors;

    return _GlassSettingsCard(
      child: brandingInfoAsync.when(
        loading: () => _buildShimmerSkeleton(colors),
        error: (error, _) => _buildErrorState(error, colors),
        data: (info) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _populateFields(info);
            // Register callbacks for sticky save bar
            ref.read(settingsSaveActionProvider.notifier).state = _saveBrandingInfo;
            ref.read(settingsDiscardActionProvider.notifier).state = () {
              _fieldsPopulated = false;
              _populateFields(info);
              _setDirty(false);
            };
          });
          return _buildForm(info, colors);
        },
      ),
    );
  }

  Widget _buildShimmerSkeleton(AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Branding',
          icon: Icons.palette_outlined,
          showRealData: true,
        ),
        const SizedBox(height: 24),
        for (int i = 0; i < 3; i++) ...[
          const _ShimmerRow(),
          const SizedBox(height: 20),
        ],
        const _ShimmerBox(width: 160, height: 60),
      ],
    );
  }

  Widget _buildErrorState(Object error, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Branding',
          icon: Icons.palette_outlined,
          showRealData: true,
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colors.danger.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.danger.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: colors.danger, size: 40),
              const SizedBox(height: 12),
              Text(
                'Failed to load branding information',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                error.toString(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colors.textTertiary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ref.read(brandingInfoProvider.notifier).reload(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BrandingInfoModel info, AppColorsExtension colors) {
    final isMobile = widget.isMobile;

    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Branding',
            icon: Icons.palette_outlined,
            subtitle: 'Upload logos, set color themes, and customize the portal appearance.',
            showRealData: true,
          ),
          const SizedBox(height: 28),

          // Main Layout: Controls on left (60%), live preview on right (40%)
          // On mobile: Stacked.
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Controls Column ──
              Flexible(
                flex: isMobile ? 0 : 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Primary Color
                    _buildColorPickerRow(
                      'Primary Color',
                      _primaryColor,
                      (c) {
                        setState(() {
                          _primaryColor = c;
                        });
                        _setDirty(true);
                      },
                      colors,
                    ),
                    const SizedBox(height: 24),

                    // Secondary Color
                    _buildColorPickerRow(
                      'Secondary Color',
                      _secondaryColor,
                      (c) {
                        setState(() {
                          _secondaryColor = c;
                        });
                        _setDirty(true);
                      },
                      colors,
                    ),
                    const SizedBox(height: 32),

                    // Theme Mode
                    Text(
                      'App Default Theme',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _ThemeModeChip(
                          label: 'Light Mode',
                          icon: Icons.light_mode,
                          isSelected: _themeMode == 'light',
                          onTap: () {
                            setState(() => _themeMode = 'light');
                            _setDirty(true);
                          },
                        ),
                        _ThemeModeChip(
                          label: 'Dark Mode',
                          icon: Icons.dark_mode,
                          isSelected: _themeMode == 'dark',
                          onTap: () {
                            setState(() => _themeMode = 'dark');
                            _setDirty(true);
                          },
                        ),
                        _ThemeModeChip(
                          label: 'System Default',
                          icon: Icons.settings_system_daydream,
                          isSelected: _themeMode == 'system',
                          onTap: () {
                            setState(() => _themeMode = 'system');
                            _setDirty(true);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Email Header Logo
                    Text(
                      'Email Header Logo',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PNG or JPG • Max 2MB • Displayed atop emails',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickEmailLogo,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 240,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: colors.border.withValues(alpha: 0.15),
                            ),
                          ),
                          child: info.emailHeaderLogoUrl != null &&
                                  info.emailHeaderLogoUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: Image.network(
                                    info.emailHeaderLogoUrl!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => _placeholderIcon(colors, 'Header Logo'),
                                  ),
                                )
                              : _placeholderIcon(colors, 'Header Logo'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SmallActionButton(
                      label: 'Replace Email Logo',
                      icon: Icons.upload_file,
                      onTap: _pickEmailLogo,
                    ),
                  ],
                ),
              ),

              if (isMobile) const SizedBox(height: 48),
              if (!isMobile) const SizedBox(width: 48),

              // ── Live Preview Panel ──
              Flexible(
                flex: isMobile ? 0 : 4,
                child: _buildLivePreview(colors, isMobile),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Save / Discard Actions
          AnimatedOpacity(
            opacity: _hasChanges ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 300),
            child: Wrap(
              alignment: isMobile ? WrapAlignment.center : WrapAlignment.end,
              spacing: 12,
              runSpacing: 8,
              children: [
                if (_hasChanges)
                  TextButton.icon(
                    onPressed: () {
                      _fieldsPopulated = false;
                      _populateFields(info);
                      setState(() => _hasChanges = false);
                    },
                    icon: const Icon(Icons.undo, size: 18),
                    label: Text(
                      'Discard Changes',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                _SaveButton(
                  isLoading: _isSaving,
                  isEnabled: _hasChanges,
                  onPressed: _saveBrandingInfo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPickerRow(
    String label,
    Color currentColor,
    ValueChanged<Color> onColorChanged,
    AppColorsExtension colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color Swatch Button
            GestureDetector(
              onTap: () => _openColorPicker(label, currentColor, onColorChanged),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: currentColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: currentColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Hex Display & Button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.1),
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(
                          _hexFromColor(currentColor),
                          style: GoogleFonts.robotoMono(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        _SmallActionButton(
                          label: 'Pick Color',
                          icon: Icons.colorize,
                          onTap: () => _openColorPicker(label, currentColor, onColorChanged),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openColorPicker(String title, Color initialColor, ValueChanged<Color> onColorChanged) {
    showDialog(
      context: context,
      builder: (ctx) {
        Color tempColor = initialColor;
        return AlertDialog(
          backgroundColor: const Color(0xFF141E2B),
          surfaceTintColor: Colors.transparent,
          title: Text(
            title,
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: initialColor,
              onColorChanged: (c) {
                tempColor = c;
                // Live update the UI underneath immediately!
                onColorChanged(c);
              },
              colorPickerWidth: 300,
              pickerAreaHeightPercent: 0.7,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
              pickerAreaBorderRadius: BorderRadius.circular(12),
              hexInputBar: true,
              portraitOnly: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Keep the last selected temp color and close
                onColorChanged(tempColor);
                Navigator.of(ctx).pop();
              },
              child: Text(
                'Done',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLivePreview(AppColorsExtension colors, bool isMobile) {
    // Generate a simple app mockup.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.visibility_outlined, size: 18, color: colors.textSecondary),
            const SizedBox(width: 8),
            Text(
              'Live Preview',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // The Mock App Window
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _themeMode == 'light' ? const Color(0xFFF3F4F6) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Mock App Header
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _primaryColor,
                ),
                child: Row(
                  children: [
                    Icon(Icons.menu, color: Colors.white.withValues(alpha: 0.9), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'App Preview',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.notifications, color: Colors.white.withValues(alpha: 0.9), size: 20),
                  ],
                ),
              ),

              // Mock App Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A secondary color badge
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _secondaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _secondaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Active Status',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _secondaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // A generic card list mockup
                    for (int i = 0; i < 2; i++) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _themeMode == 'light' ? Colors.white : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _themeMode == 'light' 
                                ? Colors.black.withValues(alpha: 0.05)
                                : Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.bolt, size: 16, color: _primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _themeMode == 'light' 
                                          ? Colors.black.withValues(alpha: 0.1)
                                          : Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: 120,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _themeMode == 'light' 
                                          ? Colors.black.withValues(alpha: 0.05)
                                          : Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Action Button Mock
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'View',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i == 0) const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholderIcon(AppColorsExtension colors, String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 28,
            color: colors.textTertiary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: colors.textTertiary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeModeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accent.withValues(alpha: 0.15) : const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.accent : colors.border.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? colors.accent : colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? colors.accent : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper to build a side-by-side row that stacks on mobile.
Widget _buildResponsiveRow({
  required bool isMobile,
  required Widget child1,
  required Widget child2,
}) {
  if (isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child1,
        const SizedBox(height: 24),
        child2,
      ],
    );
  }
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: child1),
      const SizedBox(width: 32),
      Expanded(child: child2),
    ],
  );
}

// ============================================================================
// Section 5 — Notification Settings (Fully Responsive)
// ============================================================================

class _NotificationSettingsSection extends ConsumerStatefulWidget {
  final bool isMobile;

  const _NotificationSettingsSection({super.key, required this.isMobile});

  @override
  ConsumerState<_NotificationSettingsSection> createState() =>
      _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState
    extends ConsumerState<_NotificationSettingsSection> {
  final _emailInputCtrl = TextEditingController();
  final _emailFocusNode = FocusNode();

  bool _isSaving = false;
  bool _hasChanges = false;
  bool _fieldsPopulated = false;
  bool _isInitializing = false;

  void _setDirty(bool isDirty) {
    if (_isInitializing) return;
    if (_hasChanges != isDirty) {
      setState(() => _hasChanges = isDirty);
      ref.read(settingsDirtyProvider.notifier).state = isDirty;
    }
  }

  void _setSaving(bool isSaving) {
    if (_isSaving != isSaving) {
      setState(() => _isSaving = isSaving);
      ref.read(settingsSavingProvider.notifier).state = isSaving;
    }
  }

  // ── Local mutable state (mirroring model until save) ──
  List<String> _emailRecipients = [];
  bool _notifyOnNewUser = false;
  bool _notifyOnFailedPayment = false;
  bool _notifyOnSystemError = false;
  bool _dailySummaryEnabled = false;
  String _dailySummaryTime = '09:00';
  bool _weeklyAnalyticsEnabled = false;
  String _weeklyAnalyticsDay = 'Monday';

  static const _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void dispose() {
    _emailInputCtrl.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  /// Populate local state from loaded data (only once).
  void _populateFields(NotificationSettingsModel info) {
    if (_fieldsPopulated) return;
    _isInitializing = true;
    _fieldsPopulated = true;

    _emailRecipients = List<String>.from(info.alertEmailRecipients);
    _notifyOnNewUser = info.notifyOnNewUser;
    _notifyOnFailedPayment = info.notifyOnFailedPayment;
    _notifyOnSystemError = info.notifyOnSystemError;
    _dailySummaryEnabled = info.dailySummaryEnabled;
    _dailySummaryTime = info.dailySummaryTime;
    _weeklyAnalyticsEnabled = info.weeklyAnalyticsEnabled;
    _weeklyAnalyticsDay = info.weeklyAnalyticsDay;
    
    _isInitializing = false;
  }

  /// Try to add the typed email to the tag list.
  void _addEmail() {
    final input = _emailInputCtrl.text.trim();
    if (input.isEmpty) return;

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(input)) {
      _showToast('Please enter a valid email address', false);
      return;
    }
    if (_emailRecipients.contains(input)) {
      _showToast('Email already added', false);
      _emailInputCtrl.clear();
      return;
    }

    setState(() => _emailRecipients.add(input));
    _setDirty(true);
    _emailInputCtrl.clear();
    _emailFocusNode.requestFocus();
  }

  void _removeEmail(String email) {
    setState(() => _emailRecipients.remove(email));
    _setDirty(true);
  }

  /// Save notification settings via provider.
  Future<void> _saveNotificationSettings() async {
    _setSaving(true);

    final currentData =
        ref.read(notificationSettingsProvider).valueOrNull;
    final updated =
        (currentData ?? const NotificationSettingsModel()).copyWith(
      alertEmailRecipients: _emailRecipients,
      notifyOnNewUser: _notifyOnNewUser,
      notifyOnFailedPayment: _notifyOnFailedPayment,
      notifyOnSecurityAlert: true, // always true — compliance
      notifyOnSystemError: _notifyOnSystemError,
      dailySummaryEnabled: _dailySummaryEnabled,
      dailySummaryTime: _dailySummaryTime,
      weeklyAnalyticsEnabled: _weeklyAnalyticsEnabled,
      weeklyAnalyticsDay: _weeklyAnalyticsDay,
    );

    final success = await ref
        .read(notificationSettingsProvider.notifier)
        .updateSettings(updated);

    if (mounted) {
      _setSaving(false);
      if (success) _setDirty(false);
      _showToast(
        success
            ? 'Notification settings updated successfully'
            : 'Failed to update notification settings',
        success,
      );
    }
  }

  /// Show a styled toast.
  void _showToast(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isSuccess ? const Color(0xFF43A047) : const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Open a time picker and update the daily summary time.
  Future<void> _pickDailySummaryTime() async {
    final parts = _dailySummaryTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        final colors = context.appColors;
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: colors.cardBg,
              hourMinuteColor: colors.accent.withValues(alpha: 0.1),
              hourMinuteTextColor: colors.textPrimary,
              dialHandColor: colors.accent,
              dialBackgroundColor: colors.border.withValues(alpha: 0.1),
              dialTextColor: colors.textPrimary,
              entryModeIconColor: colors.accent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dailySummaryTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
      _setDirty(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifAsync = ref.watch(notificationSettingsProvider);
    final colors = context.appColors;

    return _GlassSettingsCard(
      child: notifAsync.when(
        loading: () => _buildShimmerSkeleton(colors),
        error: (error, _) => _buildErrorState(error, colors),
        data: (info) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _populateFields(info);
            ref.read(settingsSaveActionProvider.notifier).state = _saveNotificationSettings;
            ref.read(settingsDiscardActionProvider.notifier).state = () {
              _fieldsPopulated = false;
              _populateFields(info);
              _setDirty(false);
            };
          });
          return _buildForm(info, colors);
        },
      ),
    );
  }

  /// Shimmer skeleton for loading state.
  Widget _buildShimmerSkeleton(AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Notification Settings',
          icon: Icons.notifications_outlined,
          showRealData: true,
        ),
        const SizedBox(height: 24),
        // Email input shimmer
        const _ShimmerRow(),
        const SizedBox(height: 20),
        // Toggle shimmers
        for (int i = 0; i < 5; i++) ...[
          Row(
            children: [
              const Expanded(child: _ShimmerBox(width: 200, height: 16)),
              const SizedBox(width: 16),
              const _ShimmerBox(width: 50, height: 28),
            ],
          ),
          const SizedBox(height: 16),
        ],
        // Time/day pickers shimmer
        const _ShimmerBox(width: 160, height: 44),
      ],
    );
  }

  /// Error state with retry button.
  Widget _buildErrorState(Object error, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Notification Settings',
          icon: Icons.notifications_outlined,
          showRealData: true,
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colors.danger.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.danger.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: colors.danger, size: 40),
              const SizedBox(height: 12),
              Text(
                'Failed to load notification settings',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                error.toString(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colors.textTertiary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(notificationSettingsProvider.notifier).reload(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Main form content.
  Widget _buildForm(NotificationSettingsModel info, AppColorsExtension colors) {
    final isMobile = widget.isMobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Notification Settings',
          icon: Icons.notifications_outlined,
          subtitle:
              'Configure who gets notified and when. Manage alert recipients and notification triggers.',
          showRealData: true,
        ),
        const SizedBox(height: 28),

        // ─── Alert Email Recipients ───
        _buildEmailRecipientsField(colors, isMobile),
        const SizedBox(height: 28),

        // ─── Divider ───
        Container(
          height: 1,
          color: colors.border.withValues(alpha: 0.08),
        ),
        const SizedBox(height: 24),

        // ─── Notification Toggles Title ───
        Text(
          'Notification Triggers',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose which events should trigger notifications.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: colors.textTertiary,
          ),
        ),
        const SizedBox(height: 20),

        // ─── Toggle Switches ───
        _buildToggleRow(
          colors: colors,
          icon: Icons.person_add_outlined,
          label: 'Notify on New User Registration',
          description: 'Receive an alert when a new user signs up.',
          value: _notifyOnNewUser,
          onChanged: (val) {
            setState(() => _notifyOnNewUser = val);
            _setDirty(true);
          },
        ),
        const SizedBox(height: 8),

        _buildToggleRow(
          colors: colors,
          icon: Icons.payment_outlined,
          label: 'Notify on Failed Payment',
          description: 'Get notified when a payment transaction fails.',
          value: _notifyOnFailedPayment,
          onChanged: (val) {
            setState(() => _notifyOnFailedPayment = val);
            _setDirty(true);
          },
        ),
        const SizedBox(height: 8),

        // Security Alert — locked ON
        _buildToggleRow(
          colors: colors,
          icon: Icons.shield_outlined,
          label: 'Notify on Security Alert',
          description: 'Required for compliance — cannot be disabled.',
          value: true,
          isLocked: true,
          onChanged: null,
        ),
        const SizedBox(height: 8),

        _buildToggleRow(
          colors: colors,
          icon: Icons.warning_amber_outlined,
          label: 'Notify on System Error (5xx)',
          description: 'Receive alerts for server-side errors.',
          value: _notifyOnSystemError,
          onChanged: (val) {
            setState(() => _notifyOnSystemError = val);
            _setDirty(true);
          },
        ),
        const SizedBox(height: 24),

        // ─── Divider ───
        Container(
          height: 1,
          color: colors.border.withValues(alpha: 0.08),
        ),
        const SizedBox(height: 24),

        // ─── Scheduled Reports Title ───
        Text(
          'Scheduled Reports',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Automated reports delivered to your inbox on a schedule.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: colors.textTertiary,
          ),
        ),
        const SizedBox(height: 20),

        // ─── Daily Summary Report ───
        _buildScheduledReportRow(
          colors: colors,
          isMobile: isMobile,
          icon: Icons.today_outlined,
          label: 'Daily Summary Report',
          description: 'A digest of the day\'s key metrics.',
          toggleValue: _dailySummaryEnabled,
          onToggleChanged: (val) {
            setState(() => _dailySummaryEnabled = val);
            _setDirty(true);
          },
          pickerWidget: _buildTimePicker(colors),
          showPicker: _dailySummaryEnabled,
        ),
        const SizedBox(height: 12),

        // ─── Weekly Analytics Report ───
        _buildScheduledReportRow(
          colors: colors,
          isMobile: isMobile,
          icon: Icons.date_range_outlined,
          label: 'Weekly Analytics Report',
          description: 'Comprehensive weekly analytics summary.',
          toggleValue: _weeklyAnalyticsEnabled,
          onToggleChanged: (val) {
            setState(() => _weeklyAnalyticsEnabled = val);
            _setDirty(true);
          },
          pickerWidget: _buildDayPicker(colors),
          showPicker: _weeklyAnalyticsEnabled,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Email Recipients — Multi-tag input
  // ──────────────────────────────────────────────────────────────

  Widget _buildEmailRecipientsField(
      AppColorsExtension colors, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alert Email Recipients',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Add email addresses that will receive notification alerts.',
          style: GoogleFonts.inter(fontSize: 11, color: colors.textTertiary),
        ),
        const SizedBox(height: 12),

        // Tags display
        if (_emailRecipients.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _emailRecipients
                .map((email) => _buildEmailTag(email, colors))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Email input row
        Row(
          children: [
            Expanded(
              child: Focus(
                onFocusChange: (_) {},
                child: TextFormField(
                  controller: _emailInputCtrl,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter email and press Enter',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    prefixIcon: Icon(
                      Icons.alternate_email,
                      color: colors.textTertiary,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1F2937),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colors.accent,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onFieldSubmitted: (_) => _addEmail(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _SmallActionButton(
              label: 'Add',
              icon: Icons.add,
              onTap: _addEmail,
            ),
          ],
        ),
      ],
    );
  }

  /// Individual email tag chip with × remove button.
  Widget _buildEmailTag(String email, AppColorsExtension colors) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.only(left: 12, right: 4, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mail_outline, size: 14, color: colors.accent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              email,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.accent,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _removeEmail(email),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                size: 14,
                color: colors.accent.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Toggle Row — reusable for all notification toggles
  // ──────────────────────────────────────────────────────────────

  Widget _buildToggleRow({
    required AppColorsExtension colors,
    required IconData icon,
    required String label,
    required String description,
    required bool value,
    bool isLocked = false,
    ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isLocked
            ? colors.border.withValues(alpha: 0.04)
            : colors.border.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLocked
              ? colors.warning.withValues(alpha: 0.12)
              : colors.border.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isLocked
                  ? colors.warning.withValues(alpha: 0.1)
                  : colors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isLocked ? colors.warning : colors.accent,
            ),
          ),
          const SizedBox(width: 14),
          // Label + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isLocked
                              ? colors.textTertiary
                              : colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLocked) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Required for compliance',
                        child: Icon(
                          Icons.lock_outlined,
                          size: 14,
                          color: colors.warning.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colors.textTertiary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Switch
          IgnorePointer(
            ignoring: isLocked,
            child: Opacity(
              opacity: isLocked ? 0.5 : 1.0,
              child: Switch.adaptive(
                value: value,
                activeThumbColor: isLocked ? colors.warning : colors.accent,
                activeTrackColor: isLocked
                    ? colors.warning.withValues(alpha: 0.3)
                    : colors.accent.withValues(alpha: 0.3),
                inactiveThumbColor: colors.textTertiary,
                inactiveTrackColor: colors.border.withValues(alpha: 0.15),
                onChanged: isLocked ? null : onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Scheduled Report Row — toggle + inline picker
  // ──────────────────────────────────────────────────────────────

  Widget _buildScheduledReportRow({
    required AppColorsExtension colors,
    required bool isMobile,
    required IconData icon,
    required String label,
    required String description,
    required bool toggleValue,
    required ValueChanged<bool> onToggleChanged,
    required Widget pickerWidget,
    required bool showPicker,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.border.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + label + toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: colors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colors.textTertiary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(
                value: toggleValue,
                activeThumbColor: colors.accent,
                activeTrackColor: colors.accent.withValues(alpha: 0.3),
                inactiveThumbColor: colors.textTertiary,
                inactiveTrackColor: colors.border.withValues(alpha: 0.15),
                onChanged: onToggleChanged,
              ),
            ],
          ),

          // Picker — slides in when enabled
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14, left: 4),
              child: pickerWidget,
            ),
            crossFadeState: showPicker
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Time Picker — for Daily Summary
  // ──────────────────────────────────────────────────────────────

  Widget _buildTimePicker(AppColorsExtension colors) {
    // Parse HH:MM into a readable format
    final parts = _dailySummaryTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    final displayTime =
        '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';

    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 16,
          color: colors.textTertiary,
        ),
        const SizedBox(width: 8),
        Text(
          'Send at:',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _pickDailySummaryTime,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.accent.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: colors.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    displayTime,
                    style: GoogleFonts.robotoMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.unfold_more,
                    size: 14,
                    color: colors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Day Picker — for Weekly Analytics
  // ──────────────────────────────────────────────────────────────

  Widget _buildDayPicker(AppColorsExtension colors) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 16,
          color: colors.textTertiary,
        ),
        const SizedBox(width: 8),
        Text(
          'Send on:',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colors.accent.withValues(alpha: 0.2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _weeklyAnalyticsDay,
              dropdownColor: const Color(0xFF1F2937),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              icon: Icon(
                Icons.unfold_more,
                size: 16,
                color: colors.textTertiary,
              ),
              items: _weekDays
                  .map(
                    (day) => DropdownMenuItem(
                      value: day,
                      child: Text(day),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _weeklyAnalyticsDay = val);
                  _setDirty(true);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Section 6 — Maintenance Mode (Fully Responsive)
// ============================================================================

class _MaintenanceModeSection extends ConsumerStatefulWidget {
  final bool isMobile;

  const _MaintenanceModeSection({super.key, required this.isMobile});

  @override
  ConsumerState<_MaintenanceModeSection> createState() =>
      _MaintenanceModeSectionState();
}

class _MaintenanceModeSectionState
    extends ConsumerState<_MaintenanceModeSection> {
  final _messageCtrl = TextEditingController();

  bool _isSaving = false;
  bool _hasChanges = false;
  bool _fieldsPopulated = false;
  bool _isInitializing = false;

  void _setDirty(bool isDirty) {
    if (_isInitializing) return;
    if (_hasChanges != isDirty) {
      setState(() => _hasChanges = isDirty);
      ref.read(settingsDirtyProvider.notifier).state = isDirty;
    }
  }

  void _setSaving(bool isSaving) {
    if (_isSaving != isSaving) {
      setState(() => _isSaving = isSaving);
      ref.read(settingsSavingProvider.notifier).state = isSaving;
    }
  }

  // ── Local mutable state ──
  bool _isEnabled = false;
  String _expectedEndTime = '';

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  /// Populate local state from loaded data (only once).
  void _populateFields(MaintenanceModeModel info) {
    if (_fieldsPopulated) return;
    _isInitializing = true;
    _fieldsPopulated = true;

    _isEnabled = info.isEnabled;
    _messageCtrl.text = info.maintenanceMessage;
    _expectedEndTime = info.expectedEndTime;
    
    _isInitializing = false;
  }

  /// Toggle maintenance mode with confirmation dialog.
  Future<void> _toggleMaintenanceMode(bool enable) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MaintenanceConfirmationDialog(
        isEnabling: enable,
      ),
    );

    if (confirmed != true) return;

    setState(() => _isEnabled = enable);
    _setDirty(true);

    // If disabling, save immediately for instant response
    if (!enable) {
      await _saveMaintenanceSettings(showDisabledToast: true);
    }
  }

  /// Save maintenance mode settings via provider.
  Future<void> _saveMaintenanceSettings({
    bool showDisabledToast = false,
  }) async {
    _setSaving(true);

    final currentData =
        ref.read(maintenanceModeProvider).valueOrNull;
    final updated =
        (currentData ?? const MaintenanceModeModel()).copyWith(
      isEnabled: _isEnabled,
      maintenanceMessage: _messageCtrl.text.trim(),
      expectedEndTime: _expectedEndTime,
    );

    final success = await ref
        .read(maintenanceModeProvider.notifier)
        .updateSettings(updated);

    if (mounted) {
      _setSaving(false);
      if (success) _setDirty(false);

      if (showDisabledToast && success) {
        _showToast(
          'Maintenance mode disabled. App is now live.',
          true,
        );
      } else {
        _showToast(
          success
              ? _isEnabled
                  ? 'Maintenance mode enabled. App is now offline for users.'
                  : 'Maintenance settings updated successfully'
              : 'Failed to update maintenance settings',
          success,
        );
      }
    }
  }

  /// Pick expected end date and time.
  Future<void> _pickExpectedEndTime() async {
    final colors = context.appColors;

    // Parse existing value or use tomorrow as default
    DateTime initialDate;
    TimeOfDay initialTime;
    if (_expectedEndTime.isNotEmpty) {
      try {
        final dt = DateTime.parse(_expectedEndTime);
        initialDate = dt;
        initialTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (_) {
        initialDate = DateTime.now().add(const Duration(hours: 2));
        initialTime = TimeOfDay(
          hour: initialDate.hour,
          minute: initialDate.minute,
        );
      }
    } else {
      initialDate = DateTime.now().add(const Duration(hours: 2));
      initialTime = TimeOfDay(
        hour: initialDate.hour,
        minute: initialDate.minute,
      );
    }

    // Date picker
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            datePickerTheme: DatePickerThemeData(
              backgroundColor: colors.cardBg,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: colors.accent.withValues(alpha: 0.1),
              headerForegroundColor: colors.textPrimary,
              dayForegroundColor: WidgetStatePropertyAll(colors.textPrimary),
              todayForegroundColor: WidgetStatePropertyAll(colors.accent),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    // Time picker
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: colors.cardBg,
              hourMinuteColor: colors.accent.withValues(alpha: 0.1),
              hourMinuteTextColor: colors.textPrimary,
              dialHandColor: colors.accent,
              dialBackgroundColor: colors.border.withValues(alpha: 0.1),
              dialTextColor: colors.textPrimary,
              entryModeIconColor: colors.accent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _expectedEndTime = combined.toIso8601String();
    });
    _setDirty(true);
  }

  /// Show a styled toast.
  void _showToast(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isSuccess ? const Color(0xFF43A047) : const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Format ISO datetime to readable string.
  String _formatDateTime(String isoString) {
    if (isoString.isEmpty) return 'Not set';
    try {
      final dt = DateTime.parse(isoString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final hour = dt.hour == 0
          ? 12
          : dt.hour > 12
              ? dt.hour - 12
              : dt.hour;
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at '
          '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maintAsync = ref.watch(maintenanceModeProvider);
    final colors = context.appColors;

    return _GlassSettingsCard(
      child: maintAsync.when(
        loading: () => _buildShimmerSkeleton(colors),
        error: (error, _) => _buildErrorState(error, colors),
        data: (info) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _populateFields(info);
            ref.read(settingsSaveActionProvider.notifier).state = () => _saveMaintenanceSettings();
            ref.read(settingsDiscardActionProvider.notifier).state = () {
              _fieldsPopulated = false;
              _populateFields(info);
              _setDirty(false);
            };
          });
          return _buildForm(info, colors);
        },
      ),
    );
  }

  /// Shimmer skeleton for loading state.
  Widget _buildShimmerSkeleton(AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionHeader(
          title: 'Maintenance Mode',
          icon: Icons.build_outlined,
          showRealData: true,
        ),
        SizedBox(height: 24),
        _ShimmerBox(width: double.infinity, height: 120),
        SizedBox(height: 24),
        _ShimmerRow(),
        SizedBox(height: 20),
        _ShimmerBox(width: 200, height: 44),
      ],
    );
  }

  /// Error state with retry button.
  Widget _buildErrorState(Object error, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Maintenance Mode',
          icon: Icons.build_outlined,
          showRealData: true,
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colors.danger.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.danger.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: colors.danger, size: 40),
              const SizedBox(height: 12),
              Text(
                'Failed to load maintenance settings',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                error.toString(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colors.textTertiary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(maintenanceModeProvider.notifier).reload(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Main form content.
  Widget _buildForm(MaintenanceModeModel info, AppColorsExtension colors) {
    final isMobile = widget.isMobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Maintenance Mode',
          icon: Icons.build_outlined,
          subtitle:
              'Take the app offline for planned maintenance. Admins can still access this portal.',
          showRealData: true,
        ),
        const SizedBox(height: 28),

        // ─── HIGH-IMPACT TOGGLE CARD ───
        _buildMaintenanceToggleCard(colors, isMobile),
        const SizedBox(height: 28),

        // ─── Status Indicator ───
        _buildStatusBanner(colors),
        const SizedBox(height: 24),

        // ─── Divider ───
        Container(
          height: 1,
          color: colors.border.withValues(alpha: 0.08),
        ),
        const SizedBox(height: 24),

        // ─── Maintenance Message ───
        Text(
          'Maintenance Message',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'This message is displayed to all users visiting the app during maintenance.',
          style: GoogleFonts.inter(fontSize: 11, color: colors.textTertiary),
        ),
        const SizedBox(height: 12),
        _buildMessageTextarea(colors),
        const SizedBox(height: 24),

        // ─── Expected End Time ───
        Text(
          'Expected End Time',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Shown to users: "We\'ll be back by …". Sets user expectations.',
          style: GoogleFonts.inter(fontSize: 11, color: colors.textTertiary),
        ),
        const SizedBox(height: 12),
        _buildEndTimePicker(colors, isMobile),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  // HIGH-IMPACT TOGGLE CARD
  // ──────────────────────────────────────────────────────────────

  Widget _buildMaintenanceToggleCard(
      AppColorsExtension colors, bool isMobile) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: _isEnabled
            ? colors.danger.withValues(alpha: 0.08)
            : colors.border.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isEnabled
              ? colors.danger.withValues(alpha: 0.3)
              : colors.border.withValues(alpha: 0.1),
          width: _isEnabled ? 2 : 1,
        ),
        boxShadow: _isEnabled
            ? [
                BoxShadow(
                  color: colors.danger.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          // Warning icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isEnabled
                  ? colors.danger.withValues(alpha: 0.12)
                  : colors.warning.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isEnabled
                  ? Icons.warning_rounded
                  : Icons.construction_outlined,
              size: 28,
              color: _isEnabled ? colors.danger : colors.warning,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'MAINTENANCE MODE',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _isEnabled ? colors.danger : colors.textPrimary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Warning text
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 0 : 32,
            ),
            child: Text(
              _isEnabled
                  ? '⚠️ The app is currently OFFLINE for all end users. Only admins can access this portal.'
                  : 'Enabling this will make the entire WEZU Energy app/website unavailable to ALL end users immediately.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _isEnabled
                    ? colors.danger.withValues(alpha: 0.8)
                    : colors.textTertiary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          // Large toggle
          Transform.scale(
            scale: 1.4,
            child: Switch.adaptive(
              value: _isEnabled,
              activeThumbColor: colors.danger,
              activeTrackColor: colors.danger.withValues(alpha: 0.3),
              inactiveThumbColor: colors.textTertiary,
              inactiveTrackColor: colors.border.withValues(alpha: 0.15),
              onChanged: (val) => _toggleMaintenanceMode(val),
            ),
          ),
          const SizedBox(height: 8),

          // Status label
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _isEnabled ? colors.danger : colors.success,
              letterSpacing: 0.5,
            ),
            child: Text(_isEnabled ? 'ENABLED — APP OFFLINE' : 'DISABLED — APP LIVE'),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Status Banner
  // ──────────────────────────────────────────────────────────────

  Widget _buildStatusBanner(AppColorsExtension colors) {
    if (!_isEnabled) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.danger.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Users will see: ',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colors.textTertiary,
                    ),
                  ),
                  TextSpan(
                    text: _expectedEndTime.isNotEmpty
                        ? '"We\'ll be back by ${_formatDateTime(_expectedEndTime)}"'
                        : '"We\'re currently undergoing maintenance"',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }

  // ──────────────────────────────────────────────────────────────
  // Maintenance Message Textarea
  // ──────────────────────────────────────────────────────────────

  Widget _buildMessageTextarea(AppColorsExtension colors) {
    return Focus(
      onFocusChange: (_) {},
      child: TextFormField(
        controller: _messageCtrl,
        maxLines: 4,
        maxLength: 300,
        onChanged: (_) => _setDirty(true),
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText:
              'e.g. We\'re performing scheduled maintenance to improve your experience. We\'ll be back shortly!',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.15),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 52),
            child: Icon(
              Icons.message_outlined,
              color: colors.textTertiary,
              size: 20,
            ),
          ),
          filled: true,
          fillColor: const Color(0xFF1F2937),
          counterStyle: GoogleFonts.inter(
            fontSize: 11,
            color: colors.textTertiary,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colors.accent,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Expected End Time Picker
  // ──────────────────────────────────────────────────────────────

  Widget _buildEndTimePicker(AppColorsExtension colors, bool isMobile) {
    final hasValue = _expectedEndTime.isNotEmpty;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GestureDetector(
          onTap: _pickExpectedEndTime,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasValue
                      ? colors.accent.withValues(alpha: 0.3)
                      : colors.border.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event,
                    size: 18,
                    color: hasValue ? colors.accent : colors.textTertiary,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      hasValue
                          ? _formatDateTime(_expectedEndTime)
                          : 'Select date & time',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight:
                            hasValue ? FontWeight.w600 : FontWeight.w400,
                        color: hasValue
                            ? colors.textPrimary
                            : colors.textTertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.unfold_more,
                    size: 16,
                    color: colors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Clear button
        if (hasValue)
          GestureDetector(
            onTap: () {
              setState(() => _expectedEndTime = '');
              _setDirty(true);
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.danger.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.danger.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 14, color: colors.danger),
                    const SizedBox(width: 6),
                    Text(
                      'Clear',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// Maintenance Mode Confirmation Dialog
// ============================================================================

class _MaintenanceConfirmationDialog extends StatefulWidget {
  final bool isEnabling;

  const _MaintenanceConfirmationDialog({required this.isEnabling});

  @override
  State<_MaintenanceConfirmationDialog> createState() =>
      _MaintenanceConfirmationDialogState();
}

class _MaintenanceConfirmationDialogState
    extends State<_MaintenanceConfirmationDialog> {
  int _countdown = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isEnabling) {
      // Anti-accidental-click: 3-second countdown before enable button is active
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _countdown--;
            if (_countdown <= 0) {
              timer.cancel();
            }
          });
        }
      });
    } else {
      _countdown = 0; // No delay for disabling
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isEnable = widget.isEnabling;
    final buttonEnabled = _countdown <= 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.cardBg.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isEnable
                    ? colors.danger.withValues(alpha: 0.3)
                    : colors.success.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isEnable ? colors.danger : colors.success)
                      .withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (isEnable ? colors.danger : colors.success)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEnable
                        ? Icons.warning_rounded
                        : Icons.check_circle_outline,
                    size: 32,
                    color: isEnable ? colors.danger : colors.success,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  isEnable
                      ? 'Enable Maintenance Mode?'
                      : 'Disable Maintenance Mode?',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Body text
                Text(
                  isEnable
                      ? 'Enabling maintenance will make the app unavailable to ALL users immediately. Are you sure?'
                      : 'This will bring the app back online. Users will be able to access the platform again.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Buttons
                Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(false),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: colors.border.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.border.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Confirm
                    Expanded(
                      child: GestureDetector(
                        onTap: buttonEnabled
                            ? () => Navigator.of(context).pop(true)
                            : null,
                        child: MouseRegion(
                          cursor: buttonEnabled
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.basic,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: buttonEnabled
                                  ? LinearGradient(
                                      colors: isEnable
                                          ? [
                                              const Color(0xFFE53935),
                                              const Color(0xFFD32F2F),
                                            ]
                                          : [
                                              const Color(0xFF43A047),
                                              const Color(0xFF388E3C),
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: buttonEnabled
                                  ? null
                                  : colors.border.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: buttonEnabled
                                  ? [
                                      BoxShadow(
                                        color: (isEnable
                                                ? colors.danger
                                                : colors.success)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                buttonEnabled
                                    ? (isEnable
                                        ? 'Enable Maintenance'
                                        : 'Disable Maintenance')
                                    : isEnable
                                        ? 'Wait ${_countdown}s...'
                                        : 'Disable Maintenance',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: buttonEnabled
                                      ? Colors.white
                                      : colors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                        ),
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
}

// ============================================================================
// Sticky Save Bar
// ============================================================================

class _StickySaveBar extends ConsumerWidget {
  const _StickySaveBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDirty = ref.watch(settingsDirtyProvider);
    final isSaving = ref.watch(settingsSavingProvider);
    final isMobile = Responsive.isMobile(context);
    final colors = context.appColors;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      bottom: isDirty ? 24 : -100, // Float slightly above bottom on desktop, adjust for mobile if needed
      left: isMobile ? 12 : 40,
      right: isMobile ? 12 : 40,
      child: Container(
        height: 64, // Exact height as requested
        decoration: BoxDecoration(
          color: colors.cardBg.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 32,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.warning,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colors.warning.withValues(alpha: 0.4),
                                blurRadius: 4,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ).animate(onPlay: (c) => c.repeat()).fade(duration: 1000.ms),
                        const SizedBox(width: 12),
                        if (!isMobile || MediaQuery.of(context).size.width > 350)
                          Flexible(
                            child: Text(
                              'Unsaved changes',
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 12 : 14,
                                fontWeight: FontWeight.w500,
                                color: colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Action buttons
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            final discardAction =
                                ref.read(settingsDiscardActionProvider);
                            if (discardAction != null) discardAction();
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 16,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Discard',
                      style: GoogleFonts.inter(fontSize: isMobile ? 12 : 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _SaveButton(
                    isLoading: isSaving,
                    isEnabled: isDirty && !isSaving,
                    onPressed: () async {
                      final saveAction = ref.read(settingsSaveActionProvider);
                      // Use a timeout fallback just in case some bug prevents the bar from closing
                      // The providers will handle resetting dirty state
                      if (saveAction != null) {
                        try {
                          await saveAction();
                        } catch (_) {}
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
