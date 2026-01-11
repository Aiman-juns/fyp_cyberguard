import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 🛡️ Amazing Splash Screen Widget
/// 
/// A fully customizable, production-ready splash screen with:
/// - Morphing gradient backgrounds
/// - Particle system animation
/// - Logo reveal with pulse & defense effects
/// - Text animations with stagger effects
/// - Shimmer effects
/// - Smooth transitions
/// 
/// Parameters:
/// - [brandName]: Your app/brand name
/// - [tagline]: Tagline or slogan
/// - [logoIcon]: Icon to display as logo
/// - [duration]: Total animation duration
/// - [primaryColor], [secondaryColor], [accentColor]: Color scheme
/// - [particleCount]: Number of floating particles
/// - [onAnimationComplete]: Callback when animation finishes
class AmazingSplashScreen extends StatefulWidget {
  final String brandName;
  final String tagline;
  final IconData logoIcon;
  final Duration duration;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final int particleCount;
  final VoidCallback? onAnimationComplete;

  const AmazingSplashScreen({
    Key? key,
    required this.brandName,
    required this.tagline,
    required this.logoIcon,
    this.duration = const Duration(seconds: 4),
    this.primaryColor = const Color(0xFF4A6FA5),
    this.secondaryColor = const Color(0xFF6B7BB8),
    this.accentColor = const Color(0xFF4ECDC4),
    this.particleCount = 50,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<AmazingSplashScreen> createState() => _AmazingSplashScreenState();
}

class _AmazingSplashScreenState extends State<AmazingSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _particleController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _defenseController;
  
  // Animation objects
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _logoPulseAnimation;
  late Animation<double> _brandNameAnimation;
  late Animation<double> _taglineAnimation;
  late Animation<Offset> _brandNameSlideAnimation;
  late Animation<Offset> _taglineSlideAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _defenseRippleAnimation;
  
  // Particle system
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    
    // Master animation controller
    _masterController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Particle animation controller (continuous)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Shimmer effect controller
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Pulse animation controller (continuous heartbeat effect)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Defense ripple animation controller
    _defenseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Logo animations - Pulse effect instead of rotation
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Continuous pulse animation (smaller to bigger)
    _logoPulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Defense ripple effect
    _defenseRippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _defenseController,
        curve: Curves.easeOut,
      ),
    );

    // Brand name animation
    _brandNameAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    _brandNameSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    // Tagline animation
    _taglineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );

    _taglineSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );

    // Glow pulse animation
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Initialize particles
    _particles = List.generate(
      widget.particleCount,
      (index) => Particle(
        color: _getRandomColor(),
        size: math.Random().nextDouble() * 4 + 2,
        initialX: math.Random().nextDouble(),
        initialY: math.Random().nextDouble(),
        speedX: (math.Random().nextDouble() - 0.5) * 0.3,
        speedY: (math.Random().nextDouble() - 0.5) * 0.3,
        phase: math.Random().nextDouble() * math.pi * 2,
      ),
    );

    // Start animation
    _masterController.forward();

    // Call completion callback and stop repeating animations
    _masterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Stop all repeating animations when splash completes
        _pulseController.stop();
        _defenseController.stop();
        _shimmerController.stop();
        widget.onAnimationComplete?.call();
      }
    });
  }

  Color _getRandomColor() {
    final colors = [
      widget.primaryColor,
      widget.secondaryColor,
      widget.accentColor,
    ];
    return colors[math.Random().nextInt(colors.length)].withOpacity(0.6);
  }

  @override
  void dispose() {
    _masterController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _defenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _masterController,
        builder: (context, child) {
          return Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4A6FA5),
                  Color(0xFF6B7BB8),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Particle system background
                _buildParticleSystem(size),
                
                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with defense effect
                      _buildAnimatedLogo(),
                      
                      const SizedBox(height: 40),
                      
                      // Brand name
                      _buildAnimatedBrandName(),
                      
                      const SizedBox(height: 16),
                      
                      // Tagline
                      _buildAnimatedTagline(),
                      
                      const SizedBox(height: 60),
                      
                      // Loading indicator
                      _buildLoadingIndicator(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Particle system with floating animation
  Widget _buildParticleSystem(Size size) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          size: size,
          painter: ParticlePainter(
            particles: _particles,
            animationValue: _particleController.value,
            opacity: _masterController.value,
          ),
        );
      },
    );
  }

  // Animated logo with pulse and defense ripple effects
  Widget _buildAnimatedLogo() {
    return FadeTransition(
      opacity: _logoOpacityAnimation,
      child: ScaleTransition(
        scale: _logoScaleAnimation,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _defenseController]),
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Defense ripple effect (like shield blocking attacks)
                for (int i = 0; i < 3; i++)
                  Opacity(
                    opacity: (1 - _defenseRippleAnimation.value) * 0.3 * (3 - i) / 3,
                    child: Container(
                      width: 200 + (80 * _defenseRippleAnimation.value * (i + 1)),
                      height: 200 + (80 * _defenseRippleAnimation.value * (i + 1)),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00BCD4).withOpacity(0.6),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                
                // Pulsing CyberGuard logo
                Transform.scale(
                  scale: _logoPulseAnimation.value,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00BCD4).withOpacity(0.5 * _glowAnimation.value),
                          blurRadius: 50 * _glowAnimation.value,
                          spreadRadius: 15 * _glowAnimation.value,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3 * _glowAnimation.value),
                          blurRadius: 70 * _glowAnimation.value,
                          spreadRadius: 10 * _glowAnimation.value,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/cyberguard_logo3.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Animated brand name with shimmer effect
  Widget _buildAnimatedBrandName() {
    return FadeTransition(
      opacity: _brandNameAnimation,
      child: SlideTransition(
        position: _brandNameSlideAnimation,
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.white70,
                    widget.accentColor.withOpacity(0.8),
                    Colors.white,
                  ],
                  stops: [
                    _shimmerController.value - 0.3,
                    _shimmerController.value,
                    _shimmerController.value + 0.3,
                    _shimmerController.value + 0.6,
                  ],
                  tileMode: TileMode.mirror,
                ).createShader(bounds);
              },
              child: Text(
                widget.brandName,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Animated tagline
  Widget _buildAnimatedTagline() {
    return FadeTransition(
      opacity: _taglineAnimation,
      child: Text(
        widget.tagline,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 1,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }

  // Custom loading indicator
  Widget _buildLoadingIndicator() {
    return FadeTransition(
      opacity: _taglineAnimation,
      child: SizedBox(
        width: 200,
        child: AnimatedBuilder(
          animation: _masterController,
          builder: (context, child) {
            return Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _masterController.value,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(
                      Color.lerp(
                        Colors.white,
                        widget.accentColor,
                        _masterController.value,
                      ),
                    ),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${(_masterController.value * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 1,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Particle data class
class Particle {
  final Color color;
  final double size;
  final double initialX;
  final double initialY;
  final double speedX;
  final double speedY;
  final double phase;

  Particle({
    required this.color,
    required this.size,
    required this.initialX,
    required this.initialY,
    required this.speedX,
    required this.speedY,
    required this.phase,
  });
}

/// Custom painter for particle system
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final double opacity;

  ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Calculate particle position with wave motion
      final x = (particle.initialX +
              particle.speedX * animationValue +
              math.sin(animationValue * math.pi * 2 + particle.phase) * 0.05) *
          size.width;
      
      final y = (particle.initialY +
              particle.speedY * animationValue +
              math.cos(animationValue * math.pi * 2 + particle.phase) * 0.05) *
          size.height;

      // Wrap particles around screen
      final wrappedX = x % size.width;
      final wrappedY = y % size.height;

      // Draw particle with glow
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(
        Offset(wrappedX, wrappedY),
        particle.size,
        paint,
      );

      // Draw inner bright core
      final corePaint = Paint()
        ..color = particle.color.withOpacity(opacity * 0.9);

      canvas.drawCircle(
        Offset(wrappedX, wrappedY),
        particle.size * 0.5,
        corePaint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
