import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../shared/widgets/glitch_effect.dart';

/// Infection Simulator Screen - Educational Malware Simulation
///
/// This feature simulates a ransomware attack lifecycle to educate users
/// about the dangers of clicking malicious links through experiential learning.
///
/// States:
/// 1. The Bait - Fake prize/update popup
/// 2. The Glitch - Visual chaos with screen shake and haptic feedback
/// 3. Data Theft - Fake terminal showing data exfiltration
/// 4. Ransomware Lock - Red alert with countdown timer
/// 5. The Lesson - Educational explanation
class InfectionSimulatorScreen extends StatefulWidget {
  const InfectionSimulatorScreen({Key? key}) : super(key: key);

  @override
  State<InfectionSimulatorScreen> createState() =>
      _InfectionSimulatorScreenState();
}

class _InfectionSimulatorScreenState extends State<InfectionSimulatorScreen>
    with SingleTickerProviderStateMixin {
  // Simulation states
  SimulationState _currentState = SimulationState.bait;

  // Audio players
  late AudioPlayer _audioPlayer;
  late AudioPlayer _uploadAudioPlayer;
  bool _audioPreloaded = false;

  // Timers
  Timer? _progressTimer;
  Timer? _hapticTimer;
  Timer? _countdownTimer;

  // Animation controllers
  late AnimationController _glitchController;
  bool _showTerminal = false;
  int _terminalLineIndex = 0;
  double _uploadProgress = 0.0;
  int _countdownSeconds = 180; // 3 minutes in seconds
  bool _filesDeleted = false;

  // Terminal messages
  final List<String> _terminalMessages = [
    '> Injecting payload...',
    '> Bypassing firewall...',
    '> Accessing root directory...',
    '> Found /DCIM/Camera...',
    '> Found /Documents/Banking...',
    '> Extracting contact list...',
    '> Copying gallery photos...',
    '> Accessing location data...',
    '> Opening microphone...',
    '> Scanning for passwords...',
    '> Establishing remote connection...',
    '> Uploading data to server...',
  ];

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Initialize audio players
    _audioPlayer = AudioPlayer();
    _uploadAudioPlayer = AudioPlayer();
    _uploadAudioPlayer.setReleaseMode(ReleaseMode.loop);
    _preloadSound();
  }

  Future<void> _preloadSound() async {
    try {
      await _audioPlayer.setSource(AssetSource('sounds/glitch_sound.mp3'));
      await _audioPlayer.setVolume(1.0);
      _audioPreloaded = true;
    } catch (e) {
      debugPrint('Error preloading sound: $e');
    }
  }

  @override
  void dispose() {
    _glitchController.dispose();
    _audioPlayer.dispose();
    _uploadAudioPlayer.dispose();
    _progressTimer?.cancel();
    _hapticTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startSimulation() {
    setState(() {
      _currentState = SimulationState.glitch;
    });

    // Play glitch sound immediately
    _audioPlayer.play(AssetSource('sounds/glitch_sound.mp3'), volume: 1.0);

    // Start glitch animation - ramps from 0 to 1 over 3 seconds
    _glitchController.forward(from: 0.0);

    // Start heavy haptic feedback
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_currentState == SimulationState.glitch) {
        HapticFeedback.heavyImpact();
      } else {
        timer.cancel();
      }
    });

    // Transition to data theft after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      // Stop the glitch sound
      _audioPlayer.stop();

      if (mounted) {
        setState(() {
          _currentState = SimulationState.dataTheft;
          _showTerminal = true;
        });
        _startTerminalAnimation();
        _startUploadProgress();
      }
    });

    // Transition to ransomware after 8 seconds total
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        // Stop upload sound
        _uploadAudioPlayer.stop();

        HapticFeedback.vibrate();
        setState(() {
          _currentState = SimulationState.ransomware;
        });
        _startCountdown();
      }
    });
  }

  void _startTerminalAnimation() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (_terminalLineIndex < _terminalMessages.length) {
        setState(() {
          _terminalLineIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _startUploadProgress() async {
    // Start upload sound on loop
    try {
      await _uploadAudioPlayer.setVolume(0.5);
      // Try upload_sound first, fallback to glitch_sound if it fails
      try {
        await _uploadAudioPlayer.setSource(
          AssetSource('sounds/upload_sound.mp3'),
        );
      } catch (e) {
        debugPrint(
          'upload_sound.mp3 format error, using glitch_sound.mp3 as fallback',
        );
        await _uploadAudioPlayer.setSource(
          AssetSource('sounds/glitch_sound.mp3'),
        );
      }
      await _uploadAudioPlayer.resume();
      debugPrint('Upload sound started playing');
    } catch (e) {
      debugPrint('Error playing upload sound: $e');
      debugPrint('Continuing simulation without upload sound...');
      // Continue simulation even if sound fails
    }

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_uploadProgress < 0.95 &&
          _currentState == SimulationState.dataTheft) {
        setState(() {
          _uploadProgress += 0.02;
        });
      } else {
        timer.cancel();
        // Stop upload sound when complete
        _uploadAudioPlayer.stop();
      }
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
        // Trigger file deletion effect when countdown reaches 0
        setState(() {
          _filesDeleted = true;
        });
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _skipToFileDeletion() {
    _countdownTimer?.cancel();
    setState(() {
      _countdownSeconds = 0;
      _filesDeleted = true;
    });
    HapticFeedback.heavyImpact();
  }

  void _endSimulation() {
    _glitchController.stop();
    _glitchController.reset();
    _audioPlayer.stop();
    _uploadAudioPlayer.stop();
    _hapticTimer?.cancel();
    _progressTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _currentState = SimulationState.lesson;
      _filesDeleted = false;
      _countdownSeconds = 180; // Reset for next time
    });
  }

  String _formatCountdown() {
    int minutes = _countdownSeconds ~/ 60;
    int seconds = _countdownSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Prevent back navigation during active simulation
    return PopScope(
      canPop:
          _currentState == SimulationState.bait ||
          _currentState == SimulationState.lesson,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentState != SimulationState.bait) {
          // Show emergency stop button hint
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Simulation in progress. Use emergency stop button.',
              ),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _getBackgroundColor(),
        body: Stack(
          children: [
            // Main content based on state
            _buildStateContent(),

            // Emergency stop button (hidden but accessible)
            if (_currentState != SimulationState.bait &&
                _currentState != SimulationState.lesson)
              Positioned(
                top: 40,
                right: 10,
                child: GestureDetector(
                  onLongPress: () {
                    _endSimulation();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Emergency stop activated')),
                    );
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    color: Colors.transparent,
                    child: const Center(
                      child: Icon(
                        Icons.stop_circle_outlined,
                        color: Colors.white24,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (_currentState) {
      case SimulationState.bait:
        return Colors.white;
      case SimulationState.glitch:
        return Colors.black;
      case SimulationState.dataTheft:
        return Colors.black;
      case SimulationState.ransomware:
        return Colors.red.shade900;
      case SimulationState.lesson:
        return Colors.green.shade50;
    }
  }

  Widget _buildStateContent() {
    switch (_currentState) {
      case SimulationState.bait:
        return _buildBaitState();
      case SimulationState.glitch:
        return _buildGlitchState();
      case SimulationState.dataTheft:
        return _buildDataTheftState();
      case SimulationState.ransomware:
        return _buildRansomwareState();
      case SimulationState.lesson:
        return _buildLessonState();
    }
  }

  // STATE 1: THE BAIT
  Widget _buildBaitState() {
    return SafeArea(
      child: Stack(
        children: [
          // Background content (fake article/page)
          Column(
            children: [
              AppBar(
                title: const Text('CyberGuard Training'),
                centerTitle: true,
                backgroundColor: Colors.blue,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Interactive Training Exercise',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'This exercise will help you understand how malicious links and downloads can compromise your device.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: Colors.blue,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'You are safe during this simulation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'This is a controlled environment designed to demonstrate attack techniques.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Popup overlay (the bait)
          Container(
            color: Colors.black54,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.celebration,
                      size: 64,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '🎉 CONGRATULATIONS! 🎉',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You\'ve been selected to receive a',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade400,
                            Colors.blue.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'FREE iPhone 15 Pro Max',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Limited time offer!\nClaim now before it expires.',
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _startSimulation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 8,
                            ),
                            child: const Text(
                              'CLAIM NOW',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(duration: 2000.ms, color: Colors.white54)
                        .then()
                        .shake(duration: 300.ms, delay: 2000.ms),
                    const SizedBox(height: 12),
                    const Text(
                      'Only 2 prizes left!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STATE 2: THE GLITCH - Realistic Digital Corruption
  Widget _buildGlitchState() {
    return GlitchEffect(
      controller: _glitchController,
      intensity: 1.0,
      child: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 120,
              ),
              const SizedBox(height: 24),
              Text(
                'SYSTEM COMPROMISED',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.shade900, width: 2),
                  color: Colors.black87,
                ),
                child: Text(
                  'MALWARE DETECTED',
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontSize: 16,
                    fontFamily: 'Courier',
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STATE 3: DATA THEFT
  Widget _buildDataTheftState() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Terminal header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.terminal, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'System Terminal',
                    style: TextStyle(color: Colors.green, fontSize: 14),
                  ),
                  Spacer(),
                  Icon(Icons.circle, color: Colors.red, size: 10),
                  SizedBox(width: 4),
                  Icon(Icons.circle, color: Colors.yellow, size: 10),
                  SizedBox(width: 4),
                  Icon(Icons.circle, color: Colors.green, size: 10),
                ],
              ),
            ),

            // Terminal content
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.green.shade900),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < _terminalLineIndex; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _terminalMessages[i],
                            style: const TextStyle(
                              color: Colors.green,
                              fontFamily: 'Courier',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      if (_terminalLineIndex < _terminalMessages.length)
                        Text(
                              '█',
                              style: TextStyle(color: Colors.green.shade300),
                            )
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .fadeOut(duration: 500.ms)
                            .then()
                            .fadeIn(duration: 500.ms),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Progress indicators
            _buildProgressCard(
              icon: Icons.photo_library,
              label: 'Uploading Personal Photos',
              progress: _uploadProgress,
              count: '${(_uploadProgress * 1020).toInt()}/1020',
            ),
            const SizedBox(height: 8),
            _buildProgressCard(
              icon: Icons.contacts,
              label: 'Exporting Contacts',
              progress: _uploadProgress * 0.8,
              count: '${(_uploadProgress * 856).toInt()}/856',
            ),
            const SizedBox(height: 8),
            _buildProgressCard(
              icon: Icons.account_balance,
              label: 'Accessing Banking Apps',
              progress: _uploadProgress * 0.6,
              count: 'In Progress...',
            ),

            const SizedBox(height: 16),

            // System alerts
            _buildSystemAlert(
              icon: Icons.camera_alt,
              text: 'Camera Active',
              color: Colors.red,
            ),
            const SizedBox(height: 8),
            _buildSystemAlert(
              icon: Icons.mic,
              text: 'Microphone Recording',
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildSystemAlert(
              icon: Icons.location_on,
              text: 'Location Tracking Enabled',
              color: Colors.yellow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard({
    required IconData icon,
    required String label,
    required double progress,
    required String count,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade900),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              Text(
                count,
                style: TextStyle(color: Colors.red.shade300, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade600),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemAlert({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(text, style: TextStyle(color: color, fontSize: 13)),
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeOut(duration: 800.ms)
        .then()
        .fadeIn(duration: 800.ms);
  }

  // STATE 4: RANSOMWARE
  Widget _buildRansomwareState() {
    return Container(
      color: Colors.red.shade900,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.lock, size: 120, color: Colors.white)
                    .animate(onPlay: (controller) => controller.repeat())
                    .shake(duration: 1000.ms, hz: 2),
                const SizedBox(height: 32),
                const Text(
                      '⚠️ YOUR DEVICE HAS BEEN ENCRYPTED ⚠️',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeOut(duration: 500.ms)
                    .then()
                    .fadeIn(duration: 500.ms),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'All your files have been encrypted',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Files will be permanently deleted in:',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatCountdown(),
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'To decrypt your files:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Send \$500 in Bitcoin to:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
                              style: TextStyle(
                                color: Colors.yellow,
                                fontSize: 11,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  '🚨 DO NOT CLOSE THIS WINDOW 🚨',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // Show different UI based on whether files are deleted
                if (!_filesDeleted) ...[
                  ElevatedButton(
                    onPressed: _skipToFileDeletion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'SKIP TO WHAT HAPPENS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  // Show file deletion effect
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red, width: 3),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '💀 FILES DELETED 💀',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'All your personal data has been\npermanently erased.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '❌ 1,247 photos deleted',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'Courier',
                                ),
                              ),
                              Text(
                                '❌ 856 contacts deleted',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'Courier',
                                ),
                              ),
                              Text(
                                '❌ 43 documents deleted',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'Courier',
                                ),
                              ),
                              Text(
                                '❌ Banking apps wiped',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'Courier',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms).shake(duration: 300.ms),
                  const SizedBox(height: 8),
                ],
                ElevatedButton(
                  onPressed: _endSimulation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'END SIMULATION',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // STATE 5: THE LESSON
  Widget _buildLessonState() {
    return Container(
      color: Colors.green.shade50,
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              title: const Text('Simulation Complete'),
              centerTitle: true,
              backgroundColor: Colors.green,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Success badge
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.shieldCheck,
                              size: 80,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'You\'re Safe Now',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'That was a simulation',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // What happened section
                    _buildLessonCard(
                      icon: LucideIcons.alertTriangle,
                      title: 'What Just Happened?',
                      color: Colors.orange,
                      content:
                          'You experienced a simulated ransomware attack. Ransomware is malicious software that encrypts your files and demands payment for their release. In real attacks:\n\n'
                          '• Your files become inaccessible\n'
                          '• Personal photos and documents are locked\n'
                          '• Attackers demand payment (usually cryptocurrency)\n'
                          '• Payment does NOT guarantee file recovery\n'
                          '• The average ransom is \$500-\$10,000',
                    ),

                    const SizedBox(height: 16),

                    // How it starts
                    _buildLessonCard(
                      icon: LucideIcons.mousePointerClick,
                      title: 'How Attacks Start',
                      color: Colors.red,
                      content:
                          'Real malware infections begin with:\n\n'
                          '• Fake prize/giveaway popups\n'
                          '• "Urgent" software update notices\n'
                          '• Email attachments from unknown senders\n'
                          '• Downloading pirated software\n'
                          '• Clicking suspicious links in messages\n'
                          '• Visiting compromised websites',
                    ),

                    const SizedBox(height: 16),

                    // Protection tips
                    _buildLessonCard(
                      icon: LucideIcons.shield,
                      title: 'How to Protect Yourself',
                      color: Colors.blue,
                      content:
                          '✓ Never click on suspicious popups or links\n'
                          '✓ No legitimate company gives away prizes randomly\n'
                          '✓ Real updates come through official app stores\n'
                          '✓ Enable 2-factor authentication everywhere\n'
                          '✓ Keep regular backups of important files\n'
                          '✓ Use reputable antivirus software\n'
                          '✓ Think before you click - if it seems too good to be true, it is',
                    ),

                    const SizedBox(height: 16),

                    // Red flags
                    _buildLessonCard(
                      icon: LucideIcons.eye,
                      title: 'Red Flags to Watch For',
                      color: Colors.purple,
                      content:
                          '🚩 Urgent language ("Act now!")\n'
                          '🚩 Too good to be true offers\n'
                          '🚩 Spelling/grammar mistakes\n'
                          '🚩 Requests for personal information\n'
                          '🚩 Unknown sender addresses\n'
                          '🚩 Shortened or suspicious URLs\n'
                          '🚩 Unexpected attachments',
                    ),

                    const SizedBox(height: 32),

                    // Statistics
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade400, Colors.orange.shade400],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'Real-World Impact',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatWidget(
                                value: '493M',
                                label: 'Ransomware\nattacks in 2023',
                              ),
                              _StatWidget(
                                value: '\$20B',
                                label: 'Global damages\nper year',
                              ),
                              _StatWidget(
                                value: '14%',
                                label: 'Victims who\npay ransom',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Call to action
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            LucideIcons.lightbulb,
                            size: 48,
                            color: Colors.green,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Remember This Experience',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Next time you see a suspicious popup or too-good-to-be-true offer, remember how this simulation made you feel. That moment of hesitation could save you from a real attack.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Exit button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.home),
                        label: const Text(
                          'Return to Training Hub',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard({
    required IconData icon,
    required String title,
    required Color color,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}

class _StatWidget extends StatelessWidget {
  final String value;
  final String label;

  const _StatWidget({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

enum SimulationState { bait, glitch, dataTheft, ransomware, lesson }
