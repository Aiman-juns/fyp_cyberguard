import 'package:flutter/material.dart';

/// Animation Constants for CyberGuard App
class AnimationConstants {
  // Durations
  static const Duration cardHover = Duration(milliseconds: 300);
  static const Duration standard = Duration(milliseconds: 400);
  static const Duration cardStagger = Duration(milliseconds: 50);
  static const Duration shimmer = Duration(milliseconds: 2000);
  static const Duration pulse = Duration(milliseconds: 1500);

  // Scale values
  static const double pressScale = 0.95;
  static const double hoverScaleUp = 1.05;

  // Curves
  static const Curve easeInSmooth = Curves.easeInCubic;
  static const Curve easeOutSmooth = Curves.easeOutCubic;
}
