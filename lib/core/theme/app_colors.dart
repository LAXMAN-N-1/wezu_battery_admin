import 'package:flutter/material.dart';

class AppColors {
  // ─── Powerfrill Brand (from logo) ───
  static const Color primaryOrange = Color(0xFFEB8921);
  static const Color accentRed = Color(0xFFE53935);
  static const Color accentBlue = Color(0xFF42A5F5);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color accentPurple = Color(0xFFAB47BC);

  // ─── Dark Theme ───
  static const Color deepBg = Color(0xFF0B1120);
  static const Color surface = Color(0xFF111827);
  static const Color cardBorder = Color(0xFF1F2937);
  static const Color glassSurface = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // ─── Light Theme ───
  static const Color lightBg = Color(0xFFF0F2F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightGlassSurface = Color(0x0D000000);
  static const Color lightGlassBorder = Color(0x1A000000);

  // ─── Premium Gradients ───
  static const List<Color> primaryGradient = [
    Color(0xFFEB8921),
    Color(0xFFF5A623),
  ];
  static const List<Color> blueGradient = [
    Color(0xFF42A5F5),
    Color(0xFF1E88E5),
  ];
  static const List<Color> purpleGradient = [
    Color(0xFFAB47BC),
    Color(0xFF8E24AA),
  ];
  static const List<Color> greenGradient = [
    Color(0xFF66BB6A),
    Color(0xFF43A047),
  ];

  // ─── Status ───
  static const Color emeraldSuccess = Color(0xFF10B981);
  static const Color crimsonError = Color(0xFFEF4444);
  static const Color azureInfo = Color(0xFF3B82F6);
  static const Color amberWarning = Color(0xFFF59E0B);

  // Legacy alias
  static const Color energyOrange = primaryOrange;
}
