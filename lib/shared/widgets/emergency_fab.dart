import 'package:flutter/material.dart';
import '../../features/support/screens/emergency_support_screen.dart';

class EmergencyFAB extends StatefulWidget {
  const EmergencyFAB({Key? key}) : super(key: key);

  @override
  State<EmergencyFAB> createState() => _EmergencyFABState();
}

class _EmergencyFABState extends State<EmergencyFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _pulseController.stop();
      } else {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  void _openEmergencySupport() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const EmergencySupportScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          var offsetAnimation = animation.drive(tween);
          var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
            ),
          );

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
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
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: _isExpanded ? 200 : 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade700, Colors.red.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(_isExpanded ? 28 : 28),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isExpanded ? null : _toggleExpand,
              borderRadius: BorderRadius.circular(28),
              child: _isExpanded
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Emergency',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Been Hacked?',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: _openEmergencySupport,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: _toggleExpand,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Transform.scale(
                      scale: _isExpanded ? 1.0 : _pulseAnimation.value,
                      child: Icon(
                        Icons.shield_outlined,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
