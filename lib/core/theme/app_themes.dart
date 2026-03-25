import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized theme definitions for the Wezu Admin Portal.
/// Both themes share the same structure — only colors differ.

class AppThemes {
  AppThemes._();

  // ─────────────────────────────────────────
  // DARK THEME
  // ─────────────────────────────────────────

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0D1117),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.bold, fontFeatures: const [FontFeature.tabularFigures()]),
      displayMedium: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.bold, fontFeatures: const [FontFeature.tabularFigures()]),
      titleLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white),
      titleMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
      labelMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: const Color(0xFF94A3B8)),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B82F6),
      onPrimary: Colors.white,
      secondary: Color(0xFF8B5CF6),
      onSecondary: Colors.white,
      surface: Color(0xFF1A2332),
      onSurface: Colors.white,
      error: Color(0xFFEF4444),
      onError: Colors.white,
      outline: Color(0x14FFFFFF), // ~8% white
      surfaceContainerHighest: Color(0xFF243044), // Hover bg
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A2332), // Proper semantic card layer
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x14FFFFFF), width: 1),
      ),
    ),
    dividerColor: const Color(0x14FFFFFF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A2332),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    iconTheme: const IconThemeData(color: Colors.white54),
    extensions: const [
      AppColorsExtension(
        cardBg: Color(0xFF1A2332),
        scaffoldBg: Color(0xFF0D1117),
        sidebarBg: Color(0xFF1A2332),
        textPrimary: Colors.white,
        textSecondary: Colors.white54,
        textTertiary: Colors.white38,
        border: Color(0x14FFFFFF),
        success: Color(0xFF22C55E), // Emerald Green
        warning: Color(0xFFF59E0B), // Amber
        danger: Color(0xFFEF4444),  // Critical Red
        info: Color(0xFF06B6D4),    // Electric Blue
        accent: Color(0xFF3B82F6),
        secondary: Color(0xFF8B5CF6),
      ),
    ],
  );

  // ─────────────────────────────────────────
  // LIGHT THEME
  // ─────────────────────────────────────────

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF3B82F6),
      onPrimary: Colors.white,
      secondary: Color(0xFF8B5CF6),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF1E293B),
      error: Color(0xFFEF4444),
      onError: Colors.white,
      outline: Color(0x1A000000), // ~10% black
      surfaceContainerHighest: Color(0xFFE2E8F0),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x1A000000)),
      ),
    ),
    dividerColor: const Color(0x1A000000),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1E293B),
      elevation: 0,
    ),
    iconTheme: const IconThemeData(color: Color(0xFF64748B)),
    extensions: const [
      AppColorsExtension(
        cardBg: Colors.white,
        scaffoldBg: Colors.white,
        sidebarBg: Color(0xFFF1F5F9),
        textPrimary: Color(0xFF1E293B),
        textSecondary: Color(0xFF64748B),
        textTertiary: Color(0xFF94A3B8),
        border: Color(0x1A000000),
        success: Color(0xFF16A34A),
        warning: Color(0xFFD97706),
        danger: Color(0xFFDC2626),
        info: Color(0xFF0891B2),
        accent: Color(0xFF2563EB),
        secondary: Color(0xFF8B5CF6),
      ),
    ],
  );
}

/// Custom theme extension for app-specific colors that Material
/// ColorScheme doesn't cover.
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color cardBg;
  final Color scaffoldBg;
  final Color sidebarBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color accent;
  final Color secondary;

  const AppColorsExtension({
    required this.cardBg,
    required this.scaffoldBg,
    required this.sidebarBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.accent,
    required this.secondary,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? cardBg,
    Color? scaffoldBg,
    Color? sidebarBg,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? accent,
    Color? secondary,
  }) {
    return AppColorsExtension(
      cardBg: cardBg ?? this.cardBg,
      scaffoldBg: scaffoldBg ?? this.scaffoldBg,
      sidebarBg: sidebarBg ?? this.sidebarBg,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      accent: accent ?? this.accent,
      secondary: secondary ?? this.secondary,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      scaffoldBg: Color.lerp(scaffoldBg, other.scaffoldBg, t)!,
      sidebarBg: Color.lerp(sidebarBg, other.sidebarBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
    );
  }
}

/// Helper extension to quickly access AppColorsExtension from context
extension AppThemeExtension on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>()!;
}
