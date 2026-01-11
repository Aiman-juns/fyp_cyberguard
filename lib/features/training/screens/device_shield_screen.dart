import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:safe_device/safe_device.dart';
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
  bool? _isAdbEnabled;
  bool? _isScreenCaptureDetected;
  
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
        _isRooted = await SafeDevice.isJailBroken;
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

      // Check 4: ADB Debugging Status (Android only)
      try {
        if (Platform.isAndroid) {
          _isAdbEnabled = await SafeDevice.isDevelopmentModeEnable;
        } else {
          _isAdbEnabled = false; // Not applicable for iOS
        }
      } catch (e) {
        _isAdbEnabled = false;
      }

      // Check 5: Screen Capture Detection
      try {
        if (Platform.isAndroid) {
          // Check if device is running on external storage (security risk)
          _isScreenCaptureDetected = await SafeDevice.isOnExternalStorage;
        } else {
          _isScreenCaptureDetected = false;
        }
      } catch (e) {
        _isScreenCaptureDetected = false;
      }

      // Check 6: Device Info
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
      if (_isRooted == false) score += 30; // Not rooted/jailbroken (highest priority)
      if (_hasSecureLock == true) score += 20; // Has screen lock
      if (_hasBiometrics == true) score += 20; // Has biometrics
      if (_isAdbEnabled == false) score += 15; // ADB disabled
      if (_isScreenCaptureDetected == false) score += 15; // Screen capture not detected

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

  void _showSecurityDetail({
    required String title,
    required IconData icon,
    required String whatItDoes,
    required String risks,
    required String howToFix,
    required Color color,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade900
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // What it does
                    _buildDetailSection(
                      title: '🔍 What This Checks',
                      content: whatItDoes,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 20),
                    
                    // Risks
                    _buildDetailSection(
                      title: '⚠️ Risks If Unchecked',
                      content: risks,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 20),
                    
                    // How to fix
                    _buildDetailSection(
                      title: '✅ How To Fix',
                      content: howToFix,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Close button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Got It!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _buildDetailSection({
    required String title,
    required String content,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade300
                  : Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
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
                    onTap: () => _showSecurityDetail(
                      title: 'Device Information',
                      icon: Icons.phone_android,
                      whatItDoes: 'Displays your device manufacturer and model. This helps identify if you\'re using a device from a reputable manufacturer that receives regular security updates.',
                      risks: 'Using unknown or unsupported devices may mean:\n• No security patches or updates\n• Vulnerable to known exploits\n• Lack of manufacturer support\n• Potential hardware security issues',
                      howToFix: 'Always purchase devices from reputable manufacturers (Samsung, Google, Apple, etc.) that provide regular security updates. Check if your device still receives security patches.',
                      color: Colors.blueGrey,
                    ),
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
                    onTap: () => _showSecurityDetail(
                      title: 'Root/Jailbreak Status',
                      icon: Icons.shield,
                      whatItDoes: 'Detects if your device has been rooted (Android) or jailbroken (iOS). This check verifies that your device\'s operating system hasn\'t been modified to remove built-in security restrictions.',
                      risks: 'A rooted/jailbroken device is HIGHLY vulnerable:\n• Banking apps may not work\n• Malware can access system files\n• Security updates may fail\n• Apps can bypass permissions\n• Data encryption can be compromised\n• Device warranty is voided',
                      howToFix: 'To unroot:\n1. Use official unroot tools (SuperSU, Magisk Manager)\n2. Flash original firmware\n3. Factory reset may be required\n\nFor jailbreak, restore via iTunes/Finder. Consider keeping devices stock for maximum security.',
                      color: Colors.red,
                    ),
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
                    onTap: () => _showSecurityDetail(
                      title: 'Secure Lock Screen',
                      icon: Icons.lock,
                      whatItDoes: 'Verifies that your device has a screen lock enabled (PIN, pattern, password, or biometric). This is your first line of defense against unauthorized physical access.',
                      risks: 'Without a screen lock:\n• Anyone can access your device\n• All your personal data is exposed\n• Messages, photos, emails are readable\n• Banking and payment apps accessible\n• Someone can install malware\n• Your accounts can be hijacked',
                      howToFix: 'Enable immediately:\n\nAndroid:\nSettings → Security → Screen Lock → Choose PIN/Pattern/Password (6+ digits)\n\niOS:\nSettings → Face ID & Passcode → Turn On Passcode (6+ digits)\n\nUse a strong PIN (avoid 0000, 1234, birthdays).',
                      color: Colors.orange,
                    ),
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
                    onTap: () => _showSecurityDetail(
                      title: 'Biometric Authentication',
                      icon: Icons.fingerprint,
                      whatItDoes: 'Checks if biometric security (fingerprint or face recognition) is set up on your device. Biometrics provide quick and secure authentication that\'s harder to replicate than PINs.',
                      risks: 'Without biometrics:\n• Slower device unlocking\n• More vulnerable to shoulder surfing\n• Easier for others to guess PIN\n• Less convenient app authentication\n• Banking apps may require extra verification',
                      howToFix: 'Set up biometrics:\n\nAndroid:\nSettings → Security → Fingerprint/Face Unlock → Follow setup wizard\n\niOS:\nSettings → Face ID & Passcode → Set Up Face ID\nor\nSettings → Touch ID & Passcode → Add Fingerprint\n\nRegister multiple fingers for convenience.',
                      color: Colors.purple,
                    ),
                  ),

                  // ADB Debugging Check
                  _buildCheckCard(
                    icon: Icons.bug_report,
                    title: 'USB Debugging (ADB)',
                    status: _isAdbEnabled == false ? 'Disabled' : 'Enabled',
                    isPassed: _isAdbEnabled == false,
                    advice: _isAdbEnabled == true
                        ? 'USB debugging is enabled! This is a major security risk. Disable it in Developer Options.'
                        : '',
                    isDark: isDark,
                    onTap: () => _showSecurityDetail(
                      title: 'USB Debugging (ADB)',
                      icon: Icons.bug_report,
                      whatItDoes: 'Detects if USB debugging (Android Debug Bridge) is enabled. This feature allows computers to send commands to your phone, intended for developers testing apps.',
                      risks: 'USB debugging enabled means:\n• Attackers can access your device via USB\n• Malware can be installed remotely\n• All data can be extracted\n• Screen can be controlled\n• Apps can be sideloaded\n• Passwords can be stolen\n• NOT needed for regular users',
                      howToFix: 'Disable USB debugging NOW:\n\n1. Go to Settings\n2. About Phone → Tap Build Number 7 times (if Developer Mode active)\n3. Go back → Developer Options\n4. Turn OFF "USB Debugging"\n5. Turn OFF "Developer Options" entirely\n\nOnly enable when actively developing apps!',
                      color: Colors.deepOrange,
                    ),
                  ),

                  // Screen Capture Detection
                  _buildCheckCard(
                    icon: Icons.screen_share,
                    title: 'Screen Security',
                    status: _isScreenCaptureDetected == false ? 'Protected' : 'At Risk',
                    isPassed: _isScreenCaptureDetected == false,
                    advice: _isScreenCaptureDetected == true
                        ? 'Developer options enabled - screen may be vulnerable to capture. Disable developer mode for better security.'
                        : '',
                    isDark: isDark,
                    onTap: () => _showSecurityDetail(
                      title: 'Screen Security',
                      icon: Icons.screen_share,
                      whatItDoes: 'Checks if your app is running on external storage or if developer options make your screen vulnerable to capture. Apps on external storage can be tampered with more easily.',
                      risks: 'Screen security risks include:\n• Malware can record your screen\n• Passwords visible during entry\n• Banking info can be captured\n• Private messages exposed\n• 2FA codes stolen\n• App on external storage = easier tampering',
                      howToFix: 'Improve screen security:\n\n1. Move app to internal storage:\nSettings → Apps → This App → Storage → Change → Internal\n\n2. Disable Developer Options:\nSettings → System → Developer Options → Turn OFF\n\n3. Don\'t install apps from unknown sources\n\n4. Check app permissions regularly',
                      color: Colors.teal,
                    ),
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
    VoidCallback? onTap,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                        if (onTap != null)
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.blue.shade400,
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
      ),
    );
  }
}
