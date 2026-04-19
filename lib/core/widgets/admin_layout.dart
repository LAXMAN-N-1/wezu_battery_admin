import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_themes.dart';
import '../theme/theme_provider.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../utils/responsive.dart';
import '../config/menu_config.dart';

class AdminLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String title;

  const AdminLayout({super.key, required this.child, required this.title});

  @override
  ConsumerState<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends ConsumerState<AdminLayout> {
  bool _sidebarCollapsed = false;

  static const double _expandedWidth = 270.0;
  static const double _collapsedWidth = 72.0;
  static const Duration _animDuration = Duration(milliseconds: 250);
  static const Curve _animCurve = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      drawer: isDesktop ? null : Drawer(child: _buildSidebar(context, forceExpanded: true)),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context),
          Expanded(
            child: Column(
              children: [
                _buildHeader(context, widget.title, isDesktop),
                Expanded(
                  child: Container(
                    color: colors.scaffoldBg,
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {bool forceExpanded = false}) {
    final colors = context.appColors;
    final menuSections = ref.watch(sidebarMenuProvider);
    final currentRoute = GoRouterState.of(context).uri.path;
    final collapsed = forceExpanded ? false : _sidebarCollapsed;
    final targetWidth = collapsed ? _collapsedWidth : _expandedWidth;

    return AnimatedContainer(
      duration: _animDuration,
      curve: _animCurve,
      width: targetWidth,
      decoration: BoxDecoration(
        color: colors.sidebarBg,
        border: Border(
          right: BorderSide(color: colors.border.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          // Logo header — must match _buildHeader height (72px)
          _buildSidebarHeader(colors, collapsed),
          Divider(color: colors.border.withValues(alpha: 0.1), height: 1),

          // Scrollable menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? 8 : 12,
                vertical: 4,
              ),
              children: [
                for (final section in menuSections)
                  _SectionWidget(
                    section: section,
                    currentRoute: currentRoute,
                    collapsed: collapsed,
                  ),
              ],
            ),
          ),

          // Collapse toggle
          if (!forceExpanded) ...[
            Divider(color: colors.border.withValues(alpha: 0.1), height: 1),
            _buildCollapseToggle(colors, collapsed),
          ],

          // Sign out
          Divider(color: colors.border.withValues(alpha: 0.1), height: 1),
          _buildSignOutButton(colors, collapsed),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(AppColorsExtension colors, bool collapsed) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 24),
      alignment: Alignment.center,
      child: collapsed
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade400],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 22),
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'WEZU Energy',
                        style: GoogleFonts.outfit(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Admin Portal',
                        style: GoogleFonts.inter(
                          color: colors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCollapseToggle(AppColorsExtension colors, bool collapsed) {
    return Tooltip(
      message: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
      preferBelow: false,
      child: InkWell(
        onTap: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: AnimatedRotation(
            turns: collapsed ? 0.5 : 0.0,
            duration: _animDuration,
            child: Icon(
              Icons.chevron_left_rounded,
              color: colors.textTertiary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(AppColorsExtension colors, bool collapsed) {
    if (collapsed) {
      return Tooltip(
        message: 'Sign Out',
        preferBelow: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: InkWell(
            onTap: () => ref.read(authProvider.notifier).logout(),
            borderRadius: BorderRadius.circular(10),
            hoverColor: Colors.red.withValues(alpha: 0.05),
            child: SizedBox(
              height: 40,
              width: 40,
              child: Icon(
                Icons.logout_outlined,
                color: Colors.red.shade300,
                size: 18,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListTile(
        onTap: () => ref.read(authProvider.notifier).logout(),
        dense: true,
        leading: Icon(
          Icons.logout_outlined,
          color: Colors.red.shade300,
          size: 18,
        ),
        title: Text(
          'Sign Out',
          style: GoogleFonts.inter(
            color: Colors.red.shade300,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        hoverColor: Colors.red.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String title,
    bool isDesktop,
  ) {
    final colors = context.appColors;
    final user = ref.watch(authProvider).user;
    final userName = user?['first_name'] ?? user?['name'] ?? 'Admin';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';
    final userRole = user?['role'] ?? user?['current_role'] ?? 'Administrator';

    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
      decoration: BoxDecoration(
        color: colors.sidebarBg,
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop) ...[
            Builder(
              builder: (ctx) => IconButton(
                icon: Icon(Icons.menu, color: colors.textPrimary),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: GoogleFonts.inter(
               color: colors.textPrimary,
              fontSize: isDesktop ? 17 : 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
            icon: Icon(
              ref.watch(themeProvider) == ThemeMode.dark
                  ? Icons.wb_sunny_outlined
                  : Icons.nightlight_round_outlined,
              color: colors.textSecondary,
              size: 20,
            ),
            tooltip: 'Toggle Theme',
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.notifications_none,
              color: colors.textSecondary,
              size: 20,
            ),
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 16),
          Container(
            height: 28,
            width: 1,
            color: colors.border.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.shade600,
            child: Text(
              userInitial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: GoogleFonts.inter(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                 userRole.toString().replaceAll('_', ' ').toUpperCase(),
                style: GoogleFonts.inter(
                  color: colors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionWidget extends ConsumerStatefulWidget {
  final MenuSection section;
  final String currentRoute;
  final bool collapsed;

  const _SectionWidget({
    required this.section,
    required this.currentRoute,
    this.collapsed = false,
  });

  @override
  ConsumerState<_SectionWidget> createState() => _SectionWidgetState();
}

class _SectionWidgetState extends ConsumerState<_SectionWidget> with SingleTickerProviderStateMixin {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = _isSectionActive();
  }

  @override
  void didUpdateWidget(covariant _SectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand if a new route makes this section active
    if (!_expanded && _isSectionActive()) {
      _expanded = true;
    }
  }

  bool _isSectionActive() {
    if (widget.section.id == 'dashboard') {
      return widget.currentRoute == '/dashboard' || widget.currentRoute.startsWith('/dashboard/');
    }
    return widget.currentRoute.startsWith('/${widget.section.id}') ||
           widget.section.children.any((c) => widget.currentRoute == c.route) ||
           (widget.section.route != null && widget.currentRoute == widget.section.route);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.collapsed) {
      return _buildCollapsedItem(context);
    }
    return _buildExpandedItem(context);
  }

  // ── Collapsed mode: icon-only with tooltip ──
  Widget _buildCollapsedItem(BuildContext context) {
    final colors = context.appColors;
    final isActive = _isSectionActive();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: widget.section.label,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 400),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            hoverColor: colors.accent.withValues(alpha: 0.08),
            onTap: () {
              if (widget.section.route != null) {
                context.go(widget.section.route!);
              } else if (widget.section.children.isNotEmpty) {
                context.go(widget.section.children.first.route);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isActive
                    ? colors.accent.withValues(alpha: 0.12)
                    : Colors.transparent,
              ),
              alignment: Alignment.center,
              child: Icon(
                widget.section.icon,
                color: isActive ? colors.accent : colors.textTertiary,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Expanded mode: full labels + children ──
  Widget _buildExpandedItem(BuildContext context) {
    final colors = context.appColors;
    final isActive = _isSectionActive();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              hoverColor: colors.accent.withValues(alpha: 0.05),
              onTap: () {
                if (widget.section.children.isNotEmpty) {
                  setState(() {
                    _expanded = !_expanded;
                  });
                } else if (widget.section.route != null) {
                  context.go(widget.section.route!);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isActive && !_expanded
                      ? colors.accent.withValues(alpha: 0.1)
                      : Colors.transparent,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      widget.section.icon,
                      color: isActive ? colors.accent : colors.textTertiary,
                      size: 19,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.section.label,
                        style: GoogleFonts.inter(
                          color: isActive ? colors.textPrimary : colors.textSecondary,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.section.children.length > 1)
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more,
                          color: colors.textTertiary,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Submenu children via implicitly animated clip
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: (_expanded && widget.section.children.length > 1) ? null : 0,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 4, top: 2),
              child: Column(
                children: widget.section.children.map((item) {
                  final isChildActive = widget.currentRoute == item.route;
                  return _buildChildItem(item, isChildActive, context);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChildItem(
    MenuItem item,
    bool isActive,
    BuildContext context,
  ) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          hoverColor: colors.accent.withValues(alpha: 0.05),
          onTap: () {
            context.go(item.route);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isActive
                  ? colors.accent.withValues(alpha: 0.06)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? colors.accent : colors.border.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.inter(
                      color: isActive ? colors.accent : colors.textSecondary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
