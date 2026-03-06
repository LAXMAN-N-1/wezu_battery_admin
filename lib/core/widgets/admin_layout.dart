import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../../features/auth/provider/auth_provider.dart';

class AdminLayout extends ConsumerWidget {
  final Widget child;
  final String title;

  const AdminLayout({super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1100;

    return Scaffold(
      backgroundColor: isDark ? AppColors.deepBg : AppColors.lightBg,
      drawer: isMobile
          ? _buildSidebar(context, ref, isDark, isMobile: true)
          : null,
      body: Builder(
        builder: (context) {
          return Row(
            children: [
              if (!isMobile) _buildSidebar(context, ref, isDark),
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(context, ref, title, isDark, isMobile),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────── SIDEBAR ───────────────────────
  Widget _buildSidebar(
    BuildContext context,
    WidgetRef ref,
    bool isDark, {
    bool isMobile = false,
  }) {
    final sidebar = Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        border: isMobile
            ? null
            : Border(
                right: BorderSide(
                  color: isDark
                      ? AppColors.cardBorder
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
      ),
      child: Column(
        children: [
          // ── Logo ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: isDark ? 0.05 : 1.0),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryOrange.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Powerfrill',
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'ADMIN',
                      style: GoogleFonts.inter(
                        color: AppColors.primaryOrange,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                if (isMobile) ...[
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ],
            ),
          ),

          // ── Menu label ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MAIN MENU',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Nav items ──
          _navItem(
            ref,
            0,
            Icons.dashboard_rounded,
            'Dashboard',
            '/dashboard',
            isDark,
            isMobile: isMobile,
          ),
          _navItem(
            ref,
            1,
            Icons.inventory_2_outlined,
            'Fleet & Inventory',
            '/inventory/batteries',
            isDark,
            isMobile: isMobile,
          ),
          _navItem(
            ref,
            2,
            Icons.ev_station_outlined,
            'Stations',
            '/stations',
            isDark,
            isMobile: isMobile,
          ),
          _navItem(
            ref,
            3,
            Icons.people_outline,
            'Users',
            '/users',
            isDark,
            isMobile: isMobile,
          ),
          _navItem(
            ref,
            4,
            Icons.attach_money_outlined,
            'Finance',
            '/finance',
            isDark,
            isMobile: isMobile,
          ),
          _navItem(
            ref,
            5,
            Icons.support_agent_outlined,
            'Support',
            '/support',
            isDark,
            isMobile: isMobile,
          ),

          const Spacer(),

          if (!isMobile) // Hide help card in mobile drawer to save space
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryOrange.withValues(alpha: 0.08)
                      : AppColors.primaryOrange.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryOrange.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.primaryOrange,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Need Help?',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View documentation',
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'View Docs',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Logout ──
          _navItem(
            ref,
            -1,
            Icons.logout_rounded,
            'Sign Out',
            '/login',
            isDark,
            isMobile: isMobile,
            onTap: () {
              if (isMobile) Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (isMobile) return Drawer(child: sidebar);
    return sidebar;
  }

  // ─────────────────────── NAV ITEM ───────────────────────
  Widget _navItem(
    WidgetRef ref,
    int index,
    IconData icon,
    String label,
    String route,
    bool isDark, {
    VoidCallback? onTap,
    bool isMobile = false,
  }) {
    final selected = ref.watch(navigationProvider);
    final active = selected == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              onTap ??
              () {
                ref.read(navigationProvider.notifier).state = index;
                if (isMobile) Navigator.pop(ref.context);
                GoRouter.of(ref.context).go(route);
              },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primaryOrange.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: active
                      ? AppColors.primaryOrange
                      : (isDark ? Colors.white38 : Colors.black38),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active
                          ? (isDark ? Colors.white : AppColors.primaryOrange)
                          : (isDark ? Colors.white54 : Colors.black54),
                    ),
                  ),
                ),
                if (active)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────── HEADER ───────────────────────
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    String title,
    bool isDark,
    bool isMobile,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showSearch = screenWidth > 600;

    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.cardBorder
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ],
          if (title.isNotEmpty)
            Text(
              title,
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (!isMobile || screenWidth > 900) const SizedBox(width: 24),

          // ── Search Bar ──
          if (showSearch)
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.02),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: isDark ? Colors.white38 : Colors.black26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search dashboard...',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white24 : Colors.black26,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            const Spacer(),
            _headerIconBtn(Icons.search_rounded, isDark, () {}),
          ],

          const SizedBox(width: 4),

          // ── Theme toggle ──
          _headerIconBtn(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            isDark,
            () => ref.read(themeProvider.notifier).toggleTheme(),
          ),

          // ── Notifications ──
          Stack(
            children: [
              _headerIconBtn(Icons.notifications_none_rounded, isDark, () {}),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.crimsonError,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.surface : Colors.white,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 4),

          // ── Avatar ──
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.1),
              child: Text(
                'A',
                style: GoogleFonts.outfit(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          if (!isMobile) ...[
            const SizedBox(width: 4),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin User',
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Super Admin',
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more_rounded,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 18,
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerIconBtn(IconData icon, bool isDark, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 20,
        color: isDark ? Colors.white54 : Colors.black45,
      ),
      splashRadius: 20,
    );
  }
}
