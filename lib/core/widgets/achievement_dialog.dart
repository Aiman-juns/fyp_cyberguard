import 'dart:ui';
import 'package:flutter/material.dart';
import '../../features/performance/providers/performance_provider.dart';

/// Elegant achievement unlock dialog with blur background
class AchievementDialog extends StatefulWidget {
  final Achievement achievement;
  
  const AchievementDialog({
    Key? key,
    required this.achievement,
  }) : super(key: key);

  @override
  State<AchievementDialog> createState() => _AchievementDialogState();
  
  /// Show the achievement dialog
  static Future<void> show(BuildContext context, Achievement achievement) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => AchievementDialog(achievement: achievement),
    );
  }
}

class _AchievementDialogState extends State<AchievementDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIcon() {
    switch (widget.achievement.iconType) {
      case IconType.trophy:
        return Icons.emoji_events;
      case IconType.flash:
        return Icons.flash_on;
      case IconType.shield:
        return Icons.shield;
      case IconType.star:
        return Icons.star;
      case IconType.verified:
        return Icons.verified;
      case IconType.rocket:
        return Icons.rocket_launch;
      default:
        return Icons.emoji_events;
    }
  }

  Color _getIconColor() {
    switch (widget.achievement.iconType) {
      case IconType.trophy:
        return Colors.amber;
      case IconType.flash:
        return Colors.orange;
      case IconType.shield:
        return Colors.blue;
      case IconType.star:
        return Colors.yellow;
      case IconType.verified:
        return Colors.green;
      case IconType.rocket:
        return Colors.purple;
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _getIconColor().withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sparkle icon
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.amber,
                    size: 32,
                  ),
                  const SizedBox(height: 16),
                  
                  // Achievement badge icon with glow
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _getIconColor().withOpacity(0.2),
                          _getIconColor().withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Icon(
                      _getIcon(),
                      size: 64,
                      color: _getIconColor(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // "Achievement Unlocked" text
                  Text(
                    'Achievement Unlocked!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Achievement title
                  Text(
                    widget.achievement.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getIconColor(),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Achievement description
                  Text(
                    widget.achievement.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getIconColor(),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Awesome!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
