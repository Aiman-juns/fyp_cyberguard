import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../features/support/screens/emergency_support_screen.dart';
import '../../features/tools/screens/breach_checker_screen.dart';
import '../../features/training/screens/device_shield_screen.dart';

class SecurityFAB extends StatefulWidget {
  const SecurityFAB({Key? key}) : super(key: key);

  @override
  State<SecurityFAB> createState() => _SecurityFABState();
}

class _SecurityFABState extends State<SecurityFAB>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  late Animation<double> _expandAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    // Main expand/collapse animation
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Pulse animation for the main button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotate animation for icon
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_mainController.isAnimating)
      return; // Prevent multiple taps during animation

    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _pulseController.stop();
      _mainController.forward();
      _rotateController.forward();
    } else {
      _mainController.reverse();
      _rotateController.reverse().then((_) {
        if (!_isExpanded) {
          _pulseController.repeat(reverse: true);
        }
      });
    }
  }

  void _openEmergencySupport() {
    _toggle();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const EmergencySupportScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.0, 0.3),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _openDataBreachChecker() {
    _toggle();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const BreachCheckerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.0, 0.3),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _openDeviceShield() {
    _toggle();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DeviceShieldScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.0, 0.3),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop
        if (_isExpanded) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              child: Container(color: Colors.transparent),
            ),
          ),
        ],

        // Menu items
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Data Breach Checker Option
            _buildMenuItem(
              index: 2,
              icon: Icons.shield_outlined,
              label: 'Breach Checker',
              subtitle: 'Check email safety',
              gradientColors: [
                const Color(0xFF3B82F6),
                const Color(0xFF2563EB),
              ],
              onTap: _openDataBreachChecker,
            ),

            const SizedBox(height: 12),

            // Device Shield Option
            _buildMenuItem(
              index: 1,
              icon: Icons.security,
              label: 'Device Shield',
              subtitle: 'Scan your device',
              gradientColors: [
                const Color(0xFF10B981),
                const Color(0xFF059669),
              ],
              onTap: _openDeviceShield,
            ),

            const SizedBox(height: 12),

            // Emergency Option
            _buildMenuItem(
              index: 0,
              icon: Icons.emergency,
              label: 'Emergency',
              subtitle: 'Been Hacked?',
              gradientColors: [Colors.red.shade600, Colors.red.shade400],
              onTap: _openEmergencySupport,
            ),

            const SizedBox(height: 16),

            // Main FAB Button
            _buildMainFAB(),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String label,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final delay = index * 0.1;
        final animationProgress = _expandAnimation.value;
        final delayedProgress = math.max(
          0.0,
          math.min(1.0, (animationProgress - delay) / (1.0 - delay)),
        );
        final curvedProgress = Curves.easeOutCubic.transform(delayedProgress);

        if (animationProgress == 0.0) {
          return const SizedBox.shrink();
        }

        return Transform.translate(
          offset: Offset(0, 15 * (1 - curvedProgress)),
          child: Transform.scale(
            scale: 0.3 + (0.7 * curvedProgress),
            alignment: Alignment.bottomRight,
            child: Opacity(opacity: curvedProgress, child: child),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainFAB() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _rotateAnimation]),
      builder: (context, child) {
        final scaleValue = _isExpanded
            ? 1.0
            : 1.0 + (_pulseAnimation.value * 0.08);

        return Transform.scale(
          scale: scaleValue.clamp(0.9, 1.15),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _isExpanded
                    ? [const Color(0xFF374151), const Color(0xFF4B5563)]
                    : [const Color(0xFF667eea), const Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (_isExpanded
                              ? Colors.grey.shade600
                              : const Color(0xFF667eea))
                          .withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggle,
                borderRadius: BorderRadius.circular(30),
                child: Center(
                  child: Transform.rotate(
                    angle: _rotateAnimation.value * math.pi,
                    child: Icon(
                      _isExpanded ? Icons.close : Icons.security,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
