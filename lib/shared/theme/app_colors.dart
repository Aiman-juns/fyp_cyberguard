import 'package:flutter/material.dart';

/// CyberGuard Color Palette - Following 60-30-10 Rule
/// 60% Dominant/Neutral - Backgrounds and surfaces
/// 30% Secondary/Brand - Headers, cards, major UI blocks
/// 10% Accent - CTAs, highlights, critical actions
class AppColors {
  // 60% - Dominant/Neutral Colors (Backgrounds & Surfaces)
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF8F9FA);
  static const Color darkBg = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  
  // 30% - Secondary/Brand Color (CyberGuard Blue)
  static const Color primaryBlue = Color(0xFF0066CC);
  static const Color primaryBlueDark = Color(0xFF004A99);
  
  // 10% - Accent Color (Electric Blue for CTAs)
  static const Color accentBlue = Color(0xFF3385DD);
  
  // Semantic Colors (for specific use cases only)
  static const Color successGreen = Color(0xFF00CC66);
  static const Color warningRed = Color(0xFFFF3333);
  
  // Text Colors
  static const Color black = Color(0xFF000000);
  static const Color mediumGray = Color(0xFF6B7280);
  static const Color darkGray = Color(0xFF374151);
}
