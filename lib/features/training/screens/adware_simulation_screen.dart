import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';

/// Adware Simulation Screen - Educational Infinite Ad Spam Attack
///
/// This screen demonstrates the dangers of malicious "Booster" apps
/// by simulating an overwhelming adware attack.
class AdwareSimulationScreen extends StatefulWidget {
  const AdwareSimulationScreen({Key? key}) : super(key: key);

  @override
  State<AdwareSimulationScreen> createState() => _AdwareSimulationScreenState();
}

class _AdwareSimulationScreenState extends State<AdwareSimulationScreen> {
  // Simulation state
  int _currentState = 1; // 1: Bait, 2: Attack, 3: Relief
  final List<Widget> _adPopups = [];
  Timer? _adTimer;
  int _adCount = 0;
  int _timerInterval = 800; // Start at 800ms
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _canPop = true;

  // Random generators
  final Random _random = Random();
  final List<String> _adTexts = [
    'WINNER! 🎉',
    'VIRUS DETECTED! ⚠️',
    'HOT SINGLES! 💋',
    'DOWNLOAD NOW! ⬇️',
    'CLAIM YOUR PRIZE! 🎁',
    'YOU WON \$1000! 💰',
    'SECURITY ALERT! 🚨',
    'CLICK HERE! 👆',
    'FREE IPHONE! 📱',
    'CONGRATULATIONS! 🎊',
    'URGENT UPDATE! ⚡',
    'LIMITED OFFER! ⏰',
  ];

  final List<Color> _adColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.teal,
  ];

  @override
  void dispose() {
    _adTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startAdAttack() async {
    setState(() {
      _currentState = 2;
      _canPop = false;
    });

    // Start spawning ads
    _spawnNextAd();
  }

  void _spawnNextAd() {
    if (_adCount >= 30) {
      // Trigger system crash after 30 ads
      _triggerSystemCrash();
      return;
    }

    // Add a new ad popup
    setState(() {
      _adPopups.add(_buildAdPopup());
      _adCount++;
    });

    // Play sound and vibrate
    _playErrorSound();
    HapticFeedback.heavyImpact();

    // Speed up over time (800ms -> 100ms)
    if (_timerInterval > 100) {
      _timerInterval = max(100, _timerInterval - 50);
    }

    // Schedule next ad
    _adTimer = Timer(Duration(milliseconds: _timerInterval), () {
      if (mounted) {
        _spawnNextAd();
      }
    });
  }

  void _playErrorSound() async {
    try {
      // Using glitch_sound.mp3 which already exists in assets
      await _audioPlayer.play(AssetSource('sounds/glitch_sound.mp3'));
    } catch (e) {
      // Ignore if sound not available
      debugPrint('Error playing sound: $e');
    }
  }

  void _triggerSystemCrash() {
    _adTimer?.cancel();

    setState(() {
      _currentState = 3;
    });

    // Auto-show safe mode after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _canPop = true;
        });
      }
    });
  }

  Widget _buildAdPopup() {
    final text = _adTexts[_random.nextInt(_adTexts.length)];
    final color = _adColors[_random.nextInt(_adColors.length)];
    final left = _random.nextDouble() * 200;
    final top = _random.nextDouble() * 400 + 100;

    return Positioned(
      left: left,
      top: top,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: color,
              ),
              child: const Text('CLICK NOW!'),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 200.ms).shake();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvoked: (didPop) {
        if (!didPop && !_canPop) {
          HapticFeedback.heavyImpact();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Base layer - shows different states
            if (_currentState == 1) _buildBaitScreen(),
            if (_currentState == 2) _buildAttackScreen(),
            if (_currentState == 3) _buildReliefScreen(),
          ],
        ),
      ),
    );
  }

  // State 1: The Bait
  Widget _buildBaitScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // App Bar
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'RAM Booster Ultimate',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Main Content
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.speed, size: 80, color: Color(0xFF4CAF50)),
                    const SizedBox(height: 16),
                    const Text(
                      'Your Phone is Slow!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Clean junk files instantly and boost your RAM!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),

                    // Fake stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('RAM Used', '87%', Colors.red),
                        _buildStat('Junk Files', '2.4 GB', Colors.orange),
                        _buildStat('Speed', 'Slow', Colors.red),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // The Bait Button
                    GestureDetector(
                          onTap: _startAdAttack,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4CAF50,
                                  ).withOpacity(0.5),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Text(
                              'BOOST RAM NOW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(duration: 2000.ms)
                        .scale(
                          duration: 1000.ms,
                          begin: const Offset(1, 1),
                          end: const Offset(1.05, 1.05),
                        ),
                  ],
                ),
              ),

              const Spacer(),

              // Trust badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTrustBadge(Icons.verified, 'Trusted'),
                  const SizedBox(width: 16),
                  _buildTrustBadge(Icons.star, '4.9 Rating'),
                  const SizedBox(width: 16),
                  _buildTrustBadge(Icons.download, '10M+ Downloads'),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildTrustBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // State 2: The Attack
  Widget _buildAttackScreen() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Background chaos
          Center(
            child:
                Text(
                      'LOADING...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeIn(duration: 500.ms)
                    .fadeOut(duration: 500.ms),
          ),

          // Ad popups
          ..._adPopups,

          // Warning overlay
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    '⚠️ ADWARE ATTACK IN PROGRESS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ads spawned: $_adCount/30',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // State 3: The Relief
  Widget _buildReliefScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // System crash effect
              const Icon(
                Icons.warning_rounded,
                size: 100,
                color: Colors.white,
              ).animate().shake(duration: 500.ms),

              const SizedBox(height: 24),

              const Text(
                'SYSTEM OVERLOAD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Safe Mode explanation
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.school, color: Color(0xFF3B82F6)),
                        SizedBox(width: 8),
                        Text(
                          'What Just Happened?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This was a simulation of Adware - malicious software that floods your device with unwanted advertisements.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLesson(
                      '❌',
                      'Never install "Booster" apps from unknown sources',
                    ),
                    _buildLesson(
                      '❌',
                      'Fake optimization apps often contain adware',
                    ),
                    _buildLesson(
                      '✅',
                      'Only download apps from official stores',
                    ),
                    _buildLesson('✅', 'Read app reviews and check permissions'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Exit button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Return to Safety',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLesson(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
