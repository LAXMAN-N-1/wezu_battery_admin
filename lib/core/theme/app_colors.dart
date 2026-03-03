import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const primary = Color(0xFF3B82F6); // Blue 500
  static const primaryDark = Color(0xFF2563EB); // Blue 600
  static const primaryLight = Color(0xFF60A5FA); // Blue 400

  // Background Colors
  static const background = Color(0xFF0F172A); // Slate 900
  static const surface = Color(0xFF1E293B); // Slate 800
  static const surfaceHighlight = Color(0xFF334155); // Slate 700

  // Text Colors
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white70;
  static const textTertiary = Colors.white38;

  // Status Colors
  static const success = Color(0xFF10B981); // Emerald 500
  static const warning = Color(0xFFF59E0B); // Amber 500
  static const error = Color(0xFFEF4444); // Red 500
  static const info = Color(0xFF3B82F6); // Blue 500
  static const purple = Color(0xFF8B5CF6); // Violet 500
  static const gray = Color(0xFF64748B); // Slate 500

  // Borders & Dividers
  static final border = Colors.white.withOpacity(0.1);
  static final divider = Colors.white.withOpacity(0.05);

  // Status Backgrounds (Opacity 10%)
  static final successBg = success.withOpacity(0.1);
  static final warningBg = warning.withOpacity(0.1);
  static final errorBg = error.withOpacity(0.1);
  static final infoBg = info.withOpacity(0.1);
  static final purpleBg = purple.withOpacity(0.1);
  static final grayBg = gray.withOpacity(0.1);
}
