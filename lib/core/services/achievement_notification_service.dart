import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../features/performance/providers/performance_provider.dart';

class AchievementNotificationService {
  static OverlayEntry? _overlayEntry;
  static ConfettiController? _confettiController;

  static void showAchievementUnlocked(
    BuildContext context,
    Achievement achievement,
  ) {
    // Initialize confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Remove any existing overlay
    _overlayEntry?.remove();

    // Create overlay entry
    _overlayEntry = OverlayEntry(
      builder: (context) => _AchievementNotificationOverlay(
        achievement: achievement,
        confettiController: _confettiController!,
        onDismiss: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
          _confettiController?.dispose();
          _confettiController = null;
        },
      ),
    );

    // Show overlay
    Overlay.of(context).insert(_overlayEntry!);

    // Start confetti
    _confettiController?.play();

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _confettiController?.dispose();
      _confettiController = null;
    });
  }
}

class _AchievementNotificationOverlay extends StatefulWidget {
  final Achievement achievement;
  final ConfettiController confettiController;
  final VoidCallback onDismiss;

  const _AchievementNotificationOverlay({
    required this.achievement,
    required this.confettiController,
    required this.onDismiss,
  });

  @override
  State<_AchievementNotificationOverlay> createState() =>
      _AchievementNotificationOverlayState();
}

class _AchievementNotificationOverlayState
    extends State<_AchievementNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getIconData(IconType type) {
    return switch (type) {
      IconType.trophy => Icons.emoji_events,
      IconType.flash => Icons.flash_on,
      IconType.verified => Icons.verified,
      IconType.star => Icons.star,
      IconType.shield => Icons.shield,
      IconType.rocket => Icons.rocket_launch,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Stack(
        children: [
          // Tap to dismiss
          GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Confetti from top center
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: widget.confettiController,
              blastDirection: 1.57, // radians - 90 degrees (down)
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                Colors.amber,
                Colors.orange,
                Colors.yellow,
                Colors.red,
                Colors.blue,
                Colors.green,
              ],
            ),
          ),
          // Achievement card
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sparkling achievement icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withOpacity(0.6),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          _getIconData(widget.achievement.iconType),
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Achievement unlocked text
                      const Text(
                        '🎉 Achievement Unlocked! 🎉',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Achievement title
                      Text(
                        widget.achievement.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF78350F),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Achievement description
                      Text(
                        widget.achievement.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.brown.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // Tap to continue
                      Text(
                        'Tap anywhere to continue',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.brown.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
