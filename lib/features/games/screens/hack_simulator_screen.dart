import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/password_analyzer.dart';

enum SimulationPhase { input, analyzing, hacking, result }

class HackSimulatorScreen extends StatefulWidget {
  const HackSimulatorScreen({Key? key}) : super(key: key);

  @override
  State<HackSimulatorScreen> createState() => _HackSimulatorScreenState();
}

class _HackSimulatorScreenState extends State<HackSimulatorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();

  SimulationPhase _phase = SimulationPhase.input;
  PasswordAnalysis? _analysis;

  // Simulation state
  double _hackProgress = 0.0;
  int _elapsedSeconds = 0;
  String _currentAttackMethod = '';
  List<String> _terminalOutput = [];
  Timer? _simulationTimer;
  Timer? _progressTimer;
  int _currentScore = 0;
  bool _soundEnabled = true;

  // Animations
  late AnimationController _glitchController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _audioPlayer.dispose();
    _glitchController.dispose();
    _particleController.dispose();
    _simulationTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }


  void _startSimulation() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a password to test')),
      );
      return;
    }

    setState(() {
      _phase = SimulationPhase.analyzing;
      _terminalOutput.clear();
      _hackProgress = 0.0;
      _elapsedSeconds = 0;
    });

    _addTerminalLine('> Initializing hack sequence...');
    _addTerminalLine('> Target acquired');
    _addTerminalLine('> Analyzing password complexity...');

    if (_soundEnabled) {
      _playSound('typing');
    }

    // Analyze password
    Future.delayed(const Duration(seconds: 2), () {
      final analysis = PasswordAnalyzer.analyzePassword(password);
      setState(() {
        _analysis = analysis;
        _phase = SimulationPhase.hacking;
      });

      _addTerminalLine('> Analysis complete');
      _addTerminalLine('> Password strength: ${analysis.strengthText}');
      _addTerminalLine(
        '> Estimated crack time: ${analysis.crackTimeFormatted}',
      );
      _addTerminalLine('> Initiating attack sequence...');
      _addTerminalLine('');

      _startHackingSimulation();
    });
  }

  void _startHackingSimulation() {
    if (_analysis == null) return;

    // Calculate simulation duration (accelerated for UX)
    final realCrackSeconds = _analysis!.estimatedCrackTime.inSeconds;
    int simulationDuration;

    if (realCrackSeconds < 60) {
      simulationDuration = 3; // 3 seconds for very weak
    } else if (realCrackSeconds < 86400) {
      simulationDuration = 8; // 8 seconds for weak
    } else if (realCrackSeconds < 31536000) {
      simulationDuration = 15; // 15 seconds for medium
    } else {
      simulationDuration = 25; // 25 seconds for strong
    }

    final attacks = _analysis!.vulnerableToAttacks;
    int attackIndex = 0;

    // Start elapsed timer
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });

    // Simulate hacking progress
    int progressUpdates = 0;
    final updateInterval =
        (simulationDuration * 1000) ~/ 20; // 20 updates total

    _simulationTimer = Timer.periodic(Duration(milliseconds: updateInterval), (
      timer,
    ) {
      progressUpdates++;
      final progress = progressUpdates / 20;

      setState(() {
        _hackProgress = progress;
      });

      // Update attack method
      if (attacks.isNotEmpty) {
        final newAttackIndex = (progressUpdates * attacks.length) ~/ 20;
        if (newAttackIndex != attackIndex && newAttackIndex < attacks.length) {
          attackIndex = newAttackIndex;
          final method = attacks[attackIndex];
          _currentAttackMethod = PasswordAnalyzer.getAttackName(method);
          _addTerminalLine('> ${PasswordAnalyzer.getAttackName(method)}');
          _addTerminalLine(
            '  ${PasswordAnalyzer.getAttackDescription(method)}',
          );

          if (_soundEnabled) {
            _playSound('alert');
          }
        }
      }

      // Add random progress messages
      if (progressUpdates % 5 == 0) {
        _addRandomProgressMessage();
      }

      // Check if simulation complete
      if (progress >= 1.0) {
        timer.cancel();
        _completeSimulation();
      }
    });
  }

  void _completeSimulation() {
    _progressTimer?.cancel();

    if (_analysis!.strength == PasswordStrength.strong) {
      _addTerminalLine('');
      _addTerminalLine('> ERROR: Password complexity too high');
      _addTerminalLine('> Attack failed - System overload');
      _addTerminalLine('> Target survived the attack!');

      if (_soundEnabled) {
        _audioPlayer.play(AssetSource('sounds/glitch_sound.mp3'));
      }

      _glitchController.forward(from: 0.0);
    } else {
      _addTerminalLine('');
      _addTerminalLine('> PASSWORD CRACKED!');
      _addTerminalLine('> Access granted');
      _addTerminalLine('> Time elapsed: $_elapsedSeconds seconds');

      if (_soundEnabled) {
        _playSound('success');
      }
    }

    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _currentScore = _analysis!.score;
        _phase = SimulationPhase.result;
      });
    });
  }

  void _addTerminalLine(String line) {
    setState(() {
      _terminalOutput.add(line);
      if (_terminalOutput.length > 50) {
        _terminalOutput.removeAt(0);
      }
    });
  }

  void _addRandomProgressMessage() {
    final messages = [
      '> Testing password combinations...',
      '> Checking character sequences...',
      '> Running hash calculations...',
      '> Bypassing security measures...',
      '> Attempting credential match...',
      '> Decrypting password hash...',
      '> Processing ${_random.nextInt(1000000)} combinations/sec',
      '> Analyzing pattern weaknesses...',
      '> Exploiting vulnerabilities...',
      '> ${_random.nextInt(100)}% of keyspace explored',
    ];
    _addTerminalLine(messages[_random.nextInt(messages.length)]);
  }

  void _playSound(String sound) {
    // Placeholder for sound playback
    // You can add actual sound files later
  }

  void _resetSimulation() {
    setState(() {
      _phase = SimulationPhase.input;
      _passwordController.clear();
      _analysis = null;
      _hackProgress = 0.0;
      _elapsedSeconds = 0;
      _terminalOutput.clear();
      _currentAttackMethod = '';
      _currentScore = 0;
    });
    _simulationTimer?.cancel();
    _progressTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Password Cracker',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _soundEnabled ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _soundEnabled = !_soundEnabled;
              });
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _glitchController,
        builder: (context, child) {
          final glitchOffset = _glitchController.isAnimating
              ? Offset(_random.nextDouble() * 4 - 2, 0)
              : Offset.zero;
          return Transform.translate(offset: glitchOffset, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A0E27),
                const Color(0xFF1A1F3A),
                const Color(0xFF0D1B2A),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Matrix background
              _buildMatrixBackground(),

              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        Colors.white.withOpacity(0.02),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              SafeArea(child: _buildPhaseContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatrixBackground() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.1,
        child: CustomPaint(painter: MatrixPainter(_particleController)),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case SimulationPhase.input:
        return _buildInputPhase();
      case SimulationPhase.analyzing:
        return _buildAnalyzingPhase();
      case SimulationPhase.hacking:
        return _buildHackingPhase();
      case SimulationPhase.result:
        return _buildResultPhase();
    }
  }

  Widget _buildInputPhase() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1E3A5F), const Color(0xFF0D1B2A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.security, size: 64, color: Colors.white)
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(
                      duration: 2000.ms,
                      color: Colors.white.withOpacity(0.5),
                    ),
                const SizedBox(height: 16),
                const Text(
                  'PASSWORD CRACKER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Test your password against password cracking attacks',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              border: Border.all(color: Colors.orange, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '⚠️ Passwords are never stored or transmitted. All simulation is local.',
                    style: TextStyle(
                      color: Colors.orange.shade200,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Password input
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1A1F3A), const Color(0xFF0D1B2A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4A5568), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: TextField(
              controller: _passwordController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Courier',
                fontWeight: FontWeight.w500,
              ),
              cursorColor: const Color(0xFF64748B),
              decoration: InputDecoration(
                hintText: 'Enter password to test...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontFamily: 'Courier',
                  fontSize: 16,
                ),
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF64748B),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                filled: false,
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          const SizedBox(height: 16),

          // Real-time strength indicator
          if (_passwordController.text.isNotEmpty)
            _buildStrengthMeter(_passwordController.text),

          const SizedBox(height: 24),

          // Example passwords
          Text(
            'Try these examples:',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildExampleChip('123456', Colors.red),
              _buildExampleChip('password', Colors.red),
              _buildExampleChip('MyP@ssw0rd', Colors.orange),
              _buildExampleChip('C0mpl3x!P@ssw0rd#2024', Colors.green),
            ],
          ),

          const SizedBox(height: 32),

          // Start button
          ElevatedButton(
            onPressed: _passwordController.text.isEmpty
                ? null
                : _startSimulation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
            ),
            child: const Text(
              'START CRACKING',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(height: 24),

        ],
      ),
    );
  }

  Widget _buildStrengthMeter(String password) {
    final analysis = PasswordAnalyzer.analyzePassword(password);
    Color color;

    switch (analysis.strength) {
      case PasswordStrength.veryWeak:
        color = Colors.red;
        break;
      case PasswordStrength.weak:
        color = Colors.orange;
        break;
      case PasswordStrength.medium:
        color = Colors.yellow;
        break;
      case PasswordStrength.strong:
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Strength: ${analysis.strengthText}',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Score: ${analysis.score}/100',
                style: TextStyle(color: color, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: analysis.score / 100,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.vpn_key, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Length: ${analysis.length} chars | ${analysis.hasUppercase ? '✓' : '✗'} Upper | ${analysis.hasLowercase ? '✓' : '✗'} Lower | ${analysis.hasNumbers ? '✓' : '✗'} Numbers | ${analysis.hasSymbols ? '✓' : '✗'} Symbols',
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildExampleChip(String password, Color color) {
    return ActionChip(
      label: Text(password),
      labelStyle: TextStyle(color: color, fontFamily: 'Courier'),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
      onPressed: () {
        setState(() {
          _passwordController.text = password;
        });
      },
    );
  }

  Widget _buildAnalyzingPhase() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [Colors.white.withOpacity(0.05), Colors.transparent],
          stops: const [0.0, 0.7],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      strokeWidth: 8,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF64748B),
                      ),
                    ),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .rotate(duration: 2000.ms),
            const SizedBox(height: 32),
            const Text(
                  'ANALYZING PASSWORD...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(duration: 1000.ms)
                .then()
                .fadeOut(duration: 1000.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildHackingPhase() {
    return Column(
      children: [
        // Hacker avatar
        Expanded(
          flex: 2,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Colors.red.shade700, Colors.red.shade900],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 64,
                        color: Colors.white,
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shake(duration: 500.ms, hz: 2),
                const SizedBox(height: 16),
                Text(
                  _currentAttackMethod.isEmpty
                      ? 'HACKING...'
                      : _currentAttackMethod,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Elapsed: $_elapsedSeconds sec',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ],
            ),
          ),
        ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ATTACK PROGRESS',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${(_hackProgress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _hackProgress,
                  backgroundColor: Colors.grey.shade900,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                  minHeight: 12,
                ),
              ),
            ],
          ),
        ),

        // Terminal output
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, const Color(0xFF0A1A0A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.green),
                Expanded(
                  child: ListView.builder(
                    reverse: false,
                    itemCount: _terminalOutput.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          _terminalOutput[index],
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontFamily: 'Courier',
                            height: 1.4,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultPhase() {
    if (_analysis == null) return const SizedBox();

    final bool survived = _analysis!.strength == PasswordStrength.strong;
    final Color resultColor = survived ? Colors.green : Colors.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Result header
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: survived
                    ? [Colors.green.shade700, Colors.green.shade900]
                    : [Colors.red.shade700, Colors.red.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: resultColor.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  survived ? Icons.check_circle : Icons.dangerous,
                  size: 80,
                  color: Colors.white,
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text(
                  survived ? 'PASSWORD SURVIVED!' : 'PASSWORD CRACKED!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  survived
                      ? 'Your password was too strong to crack!'
                      : 'Your password was compromised in $_elapsedSeconds seconds',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0),

          const SizedBox(height: 24),

          // Score
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1A1F3A), Colors.grey.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4A5568), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreStat(
                  'Score',
                  _currentScore.toString(),
                  const Color(0xFF3B82F6),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade700),
                _buildScoreStat('Time', '$_elapsedSeconds sec', Colors.orange),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Password analysis
          _buildAnalysisCard(
            'Password Details',
            Icons.info_outline,
            Colors.blue,
            [
              'Length: ${_analysis!.length} characters',
              'Entropy: ${_analysis!.entropy.toStringAsFixed(1)} bits',
              'Estimated crack time: ${_analysis!.crackTimeFormatted}',
              'Strength: ${_analysis!.strengthText}',
            ],
          ),

          const SizedBox(height: 16),

          // Character types
          _buildAnalysisCard(
            'Character Composition',
            Icons.settings,
            Colors.purple,
            [
              '${_analysis!.hasUppercase ? '✓' : '✗'} Uppercase letters',
              '${_analysis!.hasLowercase ? '✓' : '✗'} Lowercase letters',
              '${_analysis!.hasNumbers ? '✓' : '✗'} Numbers',
              '${_analysis!.hasSymbols ? '✓' : '✗'} Special symbols',
            ],
          ),

          const SizedBox(height: 16),

          // Vulnerabilities
          if (_analysis!.vulnerabilities.isNotEmpty)
            _buildAnalysisCard(
              'Vulnerabilities Found',
              Icons.warning,
              Colors.orange,
              _analysis!.vulnerabilities,
            ),

          const SizedBox(height: 16),

          // Improvements
          if (_analysis!.improvements.isNotEmpty)
            _buildAnalysisCard(
              'Recommendations',
              Icons.lightbulb_outline,
              Colors.green,
              _analysis!.improvements,
            ),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _resetSimulation,
                  icon: const Icon(Icons.refresh),
                  label: const Text('TRY AGAIN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // Share functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Score: $_currentScore - ${survived ? "Password Survived!" : "Password Cracked!"}',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('SHARE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Educational note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              border: Border.all(color: Colors.blue, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.school, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Security Best Practices',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Use passwords with 12+ characters\n'
                  '• Mix uppercase, lowercase, numbers, and symbols\n'
                  '• Avoid common words and patterns\n'
                  '• Use unique passwords for each account\n'
                  '• Consider using a password manager\n'
                  '• Enable two-factor authentication',
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(
    String title,
    IconData icon,
    Color color,
    List<String> items,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                item,
                style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Matrix background painter
class MatrixPainter extends CustomPainter {
  final Animation<double> animation;

  MatrixPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // Fixed seed for consistency
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y =
          (random.nextDouble() * size.height + animation.value * size.height) %
          size.height;

      canvas.drawCircle(Offset(x, y), 2, paint);
    }
  }

  @override
  bool shouldRepaint(MatrixPainter oldDelegate) => true;
}
