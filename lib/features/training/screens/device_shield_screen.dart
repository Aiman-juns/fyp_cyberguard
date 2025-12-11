import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:io';

class DeviceShieldScreen extends StatefulWidget {
  const DeviceShieldScreen({Key? key}) : super(key: key);

  @override
  State<DeviceShieldScreen> createState() => _DeviceShieldScreenState();
}

class _DeviceShieldScreenState extends State<DeviceShieldScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _scanComplete = false;
  int _securityScore = 0;
  
  // Scan results
  bool? _isRooted;
  bool? _hasSecureLock;
  bool? _hasBiometrics;
  String _deviceModel = '';
  
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _runScan() async {
    setState(() {
      _isScanning = true;
      _scanComplete = false;
      _securityScore = 0;
    });

    // Start rotation animation
    _rotationController.repeat();

    try {
      // Check 1: Root/Jailbreak Detection
      try {
        _isRooted = await FlutterJailbreakDetection.jailbroken;
      } catch (e) {
        _isRooted = false; // Assume not rooted if check fails
      }

      // Check 2: Secure Lock
      final LocalAuthentication auth = LocalAuthentication();
      try {
        _hasSecureLock = await auth.isDeviceSupported();
      } catch (e) {
        _hasSecureLock = false;
      }

      // Check 3: Biometrics
      try {
        final availableBiometrics = await auth.getAvailableBiometrics();
        _hasBiometrics = availableBiometrics.isNotEmpty;
      } catch (e) {
        _hasBiometrics = false;
      }

      // Check 4: Device Info
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      try {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          _deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          _deviceModel = iosInfo.model;
        } else {
          _deviceModel = 'Unknown Device';
        }
      } catch (e) {
        _deviceModel = 'Unknown Device';
      }

      // Calculate Security Score
      int score = 0;
      if (_isRooted == false) score += 40; // Not rooted/jailbroken (highest priority)
      if (_hasSecureLock == true) score += 30; // Has screen lock
      if (_hasBiometrics == true) score += 30; // Has biometrics

      // Wait for animation to complete
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _securityScore = score;
        _isScanning = false;
        _scanComplete = true;
      });

      _rotationController.stop();
    } catch (e) {
      setState(() {
        _isScanning = false;
        _scanComplete = false;
      });
      _rotationController.stop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
      }
    }
  }

  Color _getScoreColor() {
    if (_securityScore >= 80) return Colors.green;
    if (_securityScore >= 50) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel() {
    if (_securityScore >= 80) return 'Highly Secure';
    if (_securityScore >= 50) return 'Moderately Secure';
    return 'At Risk';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Shield'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Header Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueGrey.shade700,
                          Colors.blueGrey.shade900,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.security_update_good,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Device Security Scan',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Check your device for vulnerabilities',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Radar Scanner / Score Display
                if (!_scanComplete)
                  Container(
                    height: 250,
                    child: Center(
                      child: _isScanning
                          ? RotationTransition(
                              turns: _rotationController,
                              child: Icon(
                                Icons.radar,
                                size: 120,
                                color: Colors.blueGrey.shade400,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.security,
                                  size: 80,
                                  color: Colors.blueGrey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Ready to Scan',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                if (_scanComplete)
                  Column(
                    children: [
                      CircularPercentIndicator(
                        radius: 100,
                        lineWidth: 15,
                        percent: _securityScore / 100,
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$_securityScore%',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Secure',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        progressColor: _getScoreColor(),
                        backgroundColor: Colors.grey.shade300,
                        circularStrokeCap: CircularStrokeCap.round,
                        animation: true,
                        animationDuration: 1000,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getScoreColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getScoreColor(),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _getScoreLabel(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),

                // Scan Button
                if (!_isScanning)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _runScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.search, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Start Security Scan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_isScanning)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Scanning...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Results List
                if (_scanComplete) ...[
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Security Checks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Device Info
                  _buildCheckCard(
                    icon: Icons.phone_android,
                    title: 'Device Information',
                    status: _deviceModel,
                    isPassed: true,
                    advice: '',
                    isDark: isDark,
                  ),

                  // Root/Jailbreak Check
                  _buildCheckCard(
                    icon: Icons.shield,
                    title: 'Root/Jailbreak Status',
                    status: _isRooted == false ? 'Not Detected' : 'Detected',
                    isPassed: _isRooted == false,
                    advice: _isRooted == true
                        ? 'Your device appears to be rooted/jailbroken. This significantly reduces security!'
                        : '',
                    isDark: isDark,
                  ),

                  // Screen Lock Check
                  _buildCheckCard(
                    icon: Icons.lock,
                    title: 'Secure Lock Screen',
                    status: _hasSecureLock == true ? 'Enabled' : 'Disabled',
                    isPassed: _hasSecureLock == true,
                    advice: _hasSecureLock != true
                        ? 'Enable a screen lock (PIN, pattern, or password) immediately!'
                        : '',
                    isDark: isDark,
                  ),

                  // Biometrics Check
                  _buildCheckCard(
                    icon: Icons.fingerprint,
                    title: 'Biometric Authentication',
                    status: _hasBiometrics == true ? 'Available' : 'Not Available',
                    isPassed: _hasBiometrics == true,
                    advice: _hasBiometrics != true
                        ? 'Set up fingerprint or face unlock for extra security.'
                        : '',
                    isDark: isDark,
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckCard({
    required IconData icon,
    required String title,
    required String status,
    required bool isPassed,
    required String advice,
    required bool isDark,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPassed ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPassed
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPassed ? Icons.check_circle : Icons.warning,
                color: isPassed ? Colors.green : Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPassed ? Colors.green : Colors.red,
                    ),
                  ),
                  if (advice.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: Colors.orange.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              advice,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
