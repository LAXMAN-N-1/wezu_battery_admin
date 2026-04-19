import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_themes.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/feature_flag_model.dart';
import '../providers/feature_flag_provider.dart';
import 'components/add_flag_modal.dart';
import 'components/flag_details_drawer.dart';

class FeatureFlagsView extends ConsumerStatefulWidget {
  const FeatureFlagsView({super.key});

  @override
  ConsumerState<FeatureFlagsView> createState() => _FeatureFlagsViewState();
}

class _FeatureFlagsViewState extends ConsumerState<FeatureFlagsView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddModal() {
    showDialog(
      context: context,
      builder: (context) => const AddFlagModal(),
    );
  }

  void _openDetails(FeatureFlagModel flag) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Flag Details',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: MediaQuery.of(context).size.width < 450 ? MediaQuery.of(context).size.width : 450,
              height: MediaQuery.of(context).size.height,
              child: FlagDetailsDrawer(flag: flag),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final flagsAsync = ref.watch(filteredFeatureFlagsProvider);
    final colors = context.appColors;

    final isMobile = Responsive.isMobile(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header Row ---
          if (isMobile) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Feature Flags',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const RealDataBadge(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Control platform features without code deployments.',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              onChanged: (val) => ref.read(featureFlagSearchQueryProvider.notifier).state = val,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search flags...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AdminButton(
              label: 'Add Flag',
              onPressed: _showAddModal,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Feature Flags',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const RealDataBadge(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Control platform features without code deployments.',
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => ref.read(featureFlagSearchQueryProvider.notifier).state = val,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search flags...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.03),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 150,
                  child: AdminButton(
                    label: 'Add Flag',
                    onPressed: _showAddModal,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),

          // --- Content ---
          flagsAsync.when(
            data: (flags) => _buildGroups(flags, colors),
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 100),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
              ),
            ),
            error: (err, _) => Center(
              child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroups(List<FeatureFlagModel> flags, AppColorsExtension colors) {
    if (flags.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              Text(
                'No flags found for "${_searchCtrl.text}"',
                style: GoogleFonts.inter(color: Colors.white24),
              ),
            ],
          ),
        ),
      );
    }

    // Group by category
    final grouped = <FeatureFlagCategory, List<FeatureFlagModel>>{};
    for (final flag in flags) {
      grouped.putIfAbsent(flag.category, () => []).add(flag);
    }

    final sortedCategories =
        FeatureFlagCategory.values.where((c) => grouped.containsKey(c)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sortedCategories.map((cat) {
        final categoryFlags = grouped[cat]!;
        return Container(
          margin: const EdgeInsets.only(bottom: 32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryHeader(cat, colors),
                const SizedBox(height: 24),
                ...categoryFlags.map((flag) => Column(
                  children: [
                    _FlagTile(
                      flag: flag,
                      onTap: () => _openDetails(flag),
                    ),
                    if (flag != categoryFlags.last)
                      Divider(
                        color: Colors.white.withValues(alpha: 0.03),
                        height: 1,
                      ),
                  ],
                )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryHeader(FeatureFlagCategory cat, AppColorsExtension colors) {
    return Row(
      children: [
        Text(
          cat.label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: colors.accent,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: colors.accent.withValues(alpha: 0.2))),
      ],
    );
  }
}

class _FlagTile extends ConsumerStatefulWidget {
  final FeatureFlagModel flag;
  final VoidCallback onTap;

  const _FlagTile({required this.flag, required this.onTap});

  @override
  ConsumerState<_FlagTile> createState() => _FlagTileState();
}

class _FlagTileState extends ConsumerState<_FlagTile> {
  bool _isChanging = false;
  bool _showPulse = false;

  void _handleToggle(bool val) async {
    setState(() => _isChanging = true);
    try {
      await ref.read(featureFlagsProvider.notifier).toggleFlag(widget.flag.key, val);
      if (mounted) {
        setState(() {
          _isChanging = false;
          _showPulse = true;
        });
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) setState(() => _showPulse = false);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChanging = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update flag: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            // Left side: name, description, tags
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.flag.name,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_showPulse) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.flag.description,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: widget.flag.affectedApps.map((app) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        app,
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right side: toggle
            if (_isChanging)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF3B82F6),
                ),
              )
            else
              Switch(
                value: widget.flag.isEnabled,
                activeColor: const Color(0xFF3B82F6),
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                onChanged: _handleToggle,
              ),
          ],
        ),
      ),
    );
  }
}
