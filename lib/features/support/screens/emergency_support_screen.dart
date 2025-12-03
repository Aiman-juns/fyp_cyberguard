import 'package:flutter/material.dart';

class EmergencySupportScreen extends StatefulWidget {
  const EmergencySupportScreen({Key? key}) : super(key: key);

  @override
  State<EmergencySupportScreen> createState() => _EmergencySupportScreenState();
}

class _EmergencySupportScreenState extends State<EmergencySupportScreen> {
  final List<EmergencyAction> _actions = [
    EmergencyAction(
      title: '1. Disconnect from Wi-Fi/Internet',
      description: 'Turn off Wi-Fi or disconnect your internet cable immediately to stop any ongoing attack.',
      icon: Icons.wifi_off,
      isDone: false,
    ),
    EmergencyAction(
      title: '2. Change Your Passwords',
      description: 'Use a different device to change passwords for important accounts (email, bank, social media).',
      icon: Icons.lock_reset,
      isDone: false,
    ),
    EmergencyAction(
      title: '3. Log Out Everywhere',
      description: 'Sign out of all active sessions on your accounts. Most apps have a "log out all devices" option.',
      icon: Icons.logout,
      isDone: false,
    ),
    EmergencyAction(
      title: '4. Tell a Trusted Adult',
      description: 'Inform a parent, guardian, or teacher about what happened. They can help you take further steps.',
      icon: Icons.family_restroom,
      isDone: false,
    ),
    EmergencyAction(
      title: '5. Run Security Scan',
      description: 'If possible, run a full antivirus/security scan on your device to check for malware.',
      icon: Icons.security,
      isDone: false,
    ),
    EmergencyAction(
      title: '6. Monitor Your Accounts',
      description: 'Check your bank statements and account activities for any suspicious transactions or changes.',
      icon: Icons.visibility,
      isDone: false,
    ),
  ];

  void _toggleAction(int index) {
    setState(() {
      _actions[index].isDone = !_actions[index].isDone;
    });
  }

  int get _completedCount => _actions.where((a) => a.isDone).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _completedCount / _actions.length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A0000) : const Color(0xFFFFEBEE),
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        title: const Text(
          '🚨 Emergency Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Alert Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade700, Colors.red.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Stay Calm!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Follow these steps immediately to protect yourself',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Progress indicator
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$_completedCount/${_actions.length} completed',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0 ? Colors.green : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action checklist
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Immediate Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._actions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final action = entry.value;
                    return _buildActionCard(action, index, isDark);
                  }).toList(),
                  const SizedBox(height: 24),

                  // Additional help section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Need More Help?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'If you\'ve completed these steps and still need assistance, contact:\n\n'
                          '• Your school\'s IT department\n'
                          '• Local cybersecurity helpline\n'
                          '• Police (for serious incidents)\n'
                          '• Your internet service provider',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(EmergencyAction action, int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: action.isDone
            ? (isDark ? Colors.green.shade900 : Colors.green.shade50)
            : (isDark ? Colors.grey.shade900 : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: action.isDone
              ? Colors.green
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggleAction(index),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: action.isDone ? Colors.green : Colors.transparent,
                    border: Border.all(
                      color: action.isDone
                          ? Colors.green
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: action.isDone
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: action.isDone
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    action.icon,
                    color: action.isDone ? Colors.green : Colors.red.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          decoration: action.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: action.isDone
                              ? Colors.grey.shade600
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        action.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmergencyAction {
  final String title;
  final String description;
  final IconData icon;
  bool isDone;

  EmergencyAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.isDone,
  });
}
