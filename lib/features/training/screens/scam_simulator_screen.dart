import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/services/ai_service.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';

class ScamSimulatorScreen extends StatefulWidget {
  final String scenario;

  const ScamSimulatorScreen({Key? key, required this.scenario})
    : super(key: key);

  @override
  State<ScamSimulatorScreen> createState() => _ScamSimulatorScreenState();
}

class _ScamSimulatorScreenState extends State<ScamSimulatorScreen>
    with TickerProviderStateMixin {
  final AiService _aiService = AiService();
  late ChatSession _chatSession;
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  List<String> _quickReplies = [];
  bool _showTips = false;
  bool _showQuickReplies = false;
  late AnimationController _tipsAnimationController;
  late AnimationController _quickRepliesAnimationController;
  late Animation<double> _tipsAnimation;
  late Animation<double> _quickRepliesAnimation;
  late AnimationController _thinkingController;
  late AnimationController _glowController;
  late AnimationController _morphController;
  OverlayEntry? _notificationOverlay;
  String? _currentScamAction;

  @override
  void initState() {
    super.initState();
    _tipsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _quickRepliesAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tipsAnimation = CurvedAnimation(
      parent: _tipsAnimationController,
      curve: Curves.easeInOut,
    );
    _quickRepliesAnimation = CurvedAnimation(
      parent: _quickRepliesAnimationController,
      curve: Curves.easeInOut,
    );
    _thinkingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);

    _chatSession = _aiService.startChatSession(widget.scenario);

    // Get the AI's opening message
    final openingMessage = await _aiService.sendChatMessage(
      _chatSession,
      'Start the simulation.',
    );

    setState(() {
      _messages.add(
        ChatMessage(
          text: openingMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = false;
      _updateQuickReplies();
    });
  }

  void _updateQuickReplies() {
    final isDiscord = widget.scenario == 'discord';

    // Get the last AI message to generate context-aware replies
    final lastAiMessage = _messages
        .lastWhere(
          (msg) => !msg.isUser,
          orElse: () =>
              ChatMessage(text: '', isUser: false, timestamp: DateTime.now()),
        )
        .text
        .toLowerCase();

    // Generate dynamic replies based on conversation context
    List<String> goodReplies = [];
    List<String> badReplies = [];

    if (isDiscord) {
      // Comprehensive Discord scam response patterns

      // Email/Login credential requests
      if (lastAiMessage.contains('email') &&
          (lastAiMessage.contains('what') ||
              lastAiMessage.contains('provide') ||
              lastAiMessage.contains('send') ||
              lastAiMessage.contains('give'))) {
        badReplies = [
          "✅ My email is user@example.com",
          "✅ It's myemail123@gmail.com",
        ];
        goodReplies = [
          "❌ Why do you need my email?",
          "❌ Discord staff already have that information",
        ];
      }
      // Password requests
      else if (lastAiMessage.contains('password') ||
          (lastAiMessage.contains('login') &&
              lastAiMessage.contains('credential'))) {
        badReplies = [
          "✅ My password is MyPass123",
          "✅ Sure, let me share it: password123",
        ];
        goodReplies = [
          "❌ I will NEVER share my password with anyone",
          "❌ This is clearly a scam attempt",
        ];
      }
      // Phone number requests
      else if (lastAiMessage.contains('phone') ||
          lastAiMessage.contains('number') ||
          lastAiMessage.contains('contact')) {
        badReplies = [
          "✅ My phone is +1234567890",
          "✅ Here's my number: 012-3456789",
        ];
        goodReplies = [
          "❌ Discord doesn't need my phone for verification",
          "❌ This is suspicious, I'm not sharing personal info",
        ];
      }
      // Verification/2FA code requests
      else if (lastAiMessage.contains('code') ||
          lastAiMessage.contains('verification') ||
          lastAiMessage.contains('2fa') ||
          lastAiMessage.contains('authenticate')) {
        badReplies = [
          "✅ The code is 123456",
          "✅ Sure, here's the verification code: 789012",
        ];
        goodReplies = [
          "❌ Discord staff never ask for verification codes",
          "❌ This is a phishing attempt",
        ];
      }
      // Link clicking
      else if (lastAiMessage.contains('link') ||
          lastAiMessage.contains('click') ||
          lastAiMessage.contains('visit') ||
          lastAiMessage.contains('check this')) {
        badReplies = ["✅ Clicking the link now", "✅ Sure, let me open that"];
        goodReplies = [
          "❌ That link looks suspicious",
          "❌ I'll verify through official Discord only",
        ];
      }
      // Account verification
      else if (lastAiMessage.contains('verify') ||
          lastAiMessage.contains('confirm') ||
          lastAiMessage.contains('validate')) {
        badReplies = ["✅ How do I verify?", "✅ What information do you need?"];
        goodReplies = [
          "❌ Real Discord verification happens in-app only",
          "❌ This is a scam, Discord doesn't DM for verification",
        ];
      }
      // Download/install requests
      else if (lastAiMessage.contains('download') ||
          lastAiMessage.contains('install') ||
          lastAiMessage.contains('file')) {
        badReplies = [
          "✅ Downloading it now",
          "✅ Sure, what file should I install?",
        ];
        goodReplies = [
          "❌ I won't download suspicious files",
          "❌ This could be malware",
        ];
      }
      // Gift/prize/nitro scams
      else if (lastAiMessage.contains('free') ||
          lastAiMessage.contains('gift') ||
          lastAiMessage.contains('nitro') ||
          lastAiMessage.contains('prize')) {
        badReplies = [
          "✅ Yes! How do I claim it?",
          "✅ Wow, free Nitro! What do I do?",
        ];
        goodReplies = [
          "❌ If it's too good to be true, it probably is",
          "❌ Real Discord giveaways don't happen in DMs",
        ];
      }
      // Screenshot/screen share requests
      else if (lastAiMessage.contains('screenshot') ||
          lastAiMessage.contains('screen') ||
          lastAiMessage.contains('share')) {
        badReplies = ["✅ Let me take a screenshot", "✅ Sharing my screen now"];
        goodReplies = [
          "❌ Screenshots can reveal sensitive info",
          "❌ This is unnecessary, seems suspicious",
        ];
      }
      // Payment method/credit card
      else if (lastAiMessage.contains('payment') ||
          lastAiMessage.contains('card') ||
          lastAiMessage.contains('credit') ||
          lastAiMessage.contains('paypal')) {
        badReplies = [
          "✅ My card number is 1234-5678-9012",
          "✅ Let me give you my PayPal",
        ];
        goodReplies = [
          "❌ NEVER share payment information in DMs",
          "❌ This is definitely a scam",
        ];
      }
      // Urgent/threatening messages
      else if (lastAiMessage.contains('urgent') ||
          lastAiMessage.contains('ban') ||
          lastAiMessage.contains('suspend') ||
          lastAiMessage.contains('immediately')) {
        badReplies = [
          "✅ Oh no! What should I do?",
          "✅ Please don't ban me! I'll do anything",
        ];
        goodReplies = [
          "❌ Creating urgency is a common scam tactic",
          "❌ Real Discord doesn't threaten via DM",
        ];
      }
      // Asking for help/being friendly
      else if (lastAiMessage.contains('help') ||
          lastAiMessage.contains('issue') ||
          lastAiMessage.contains('problem')) {
        badReplies = [
          "✅ Yes please help me!",
          "✅ What information do you need from me?",
        ];
        goodReplies = [
          "❌ I'll use Discord's official support system",
          "❌ Real support doesn't reach out first",
        ];
      }
      // Generic greeting/conversation
      else if (lastAiMessage.contains('hello') ||
          lastAiMessage.contains('hi') ||
          lastAiMessage.contains('hey')) {
        badReplies = [
          "✅ Hi! How can I help you?",
          "✅ Hello! Thanks for reaching out",
        ];
        goodReplies = [
          "❌ Who are you? Why are you messaging me?",
          "❌ I don't accept messages from strangers",
        ];
      }
      // Questions about user
      else if (lastAiMessage.contains('?') &&
          (lastAiMessage.contains('you') || lastAiMessage.contains('your'))) {
        badReplies = [
          "✅ Yes, that's correct",
          "✅ Let me tell you about myself...",
        ];
        goodReplies = [
          "❌ I'm not comfortable sharing personal information",
          "❌ How did you get my username?",
        ];
      }
      // Default fallback with context
      else {
        badReplies = [
          "✅ Sure, I'll do that",
          "✅ Okay, what do you need from me?",
          "✅ Yes, please continue",
        ];
        goodReplies = [
          "❌ This doesn't seem legitimate",
          "❌ I'll report this to Discord Trust & Safety",
          "❌ I'm ending this conversation",
        ];
      }
    } else {
      // Comprehensive Bank scenario responses

      // OTP/TAC/SMS code requests
      if (lastAiMessage.contains('otp') ||
          lastAiMessage.contains('tac') ||
          lastAiMessage.contains('code') ||
          lastAiMessage.contains('sms')) {
        badReplies = [
          "✅ The code is 123456",
          "✅ My TAC code is 789012",
          "✅ I received OTP: 456789",
        ];
        goodReplies = [
          "❌ Banks NEVER ask for OTP/TAC codes",
          "❌ This is a scam - I'm calling the bank hotline",
          "❌ OTP codes are for my eyes only",
        ];
      }
      // Card number/CVV requests
      else if ((lastAiMessage.contains('card') &&
              lastAiMessage.contains('number')) ||
          lastAiMessage.contains('cvv') ||
          lastAiMessage.contains('cvc') ||
          lastAiMessage.contains('pin')) {
        badReplies = [
          "✅ My card number is 1234-5678-9012-3456",
          "✅ CVV is 123, expiry is 12/25",
          "✅ Here are my card details...",
        ];
        goodReplies = [
          "❌ Banks NEVER ask for full card details",
          "❌ This is identity theft attempt",
          "❌ I'll visit the branch in person",
        ];
      }
      // Account number/password
      else if ((lastAiMessage.contains('account') &&
              (lastAiMessage.contains('number') ||
                  lastAiMessage.contains('detail'))) ||
          lastAiMessage.contains('password') ||
          lastAiMessage.contains('username')) {
        badReplies = [
          "✅ My account number is 1234567890",
          "✅ Username: john123, Password: pass123",
          "✅ Here are my login credentials",
        ];
        goodReplies = [
          "❌ Banks already have my account info",
          "❌ I will NEVER share banking passwords",
          "❌ This is a phishing attempt",
        ];
      }
      // Link clicking
      else if (lastAiMessage.contains('link') ||
          lastAiMessage.contains('click') ||
          lastAiMessage.contains('visit') ||
          lastAiMessage.contains('website')) {
        badReplies = [
          "✅ Opening the link now",
          "✅ I'll click on that website",
          "✅ Checking the link...",
        ];
        goodReplies = [
          "❌ I'll type the official bank URL myself",
          "❌ That link doesn't look legitimate",
          "❌ Phishing links are common in scams",
        ];
      }
      // Personal information
      else if (lastAiMessage.contains('ic') ||
          lastAiMessage.contains('nric') ||
          lastAiMessage.contains('identity') ||
          (lastAiMessage.contains('date') && lastAiMessage.contains('birth'))) {
        badReplies = [
          "✅ My IC is 123456-12-1234",
          "✅ Born on 01/01/1990",
          "✅ Here's my personal info...",
        ];
        goodReplies = [
          "❌ You already have my IC on file",
          "❌ I won't share personal information via chat",
          "❌ This is suspicious - calling the bank now",
        ];
      }
      // Update app/software
      else if (lastAiMessage.contains('update') ||
          lastAiMessage.contains('download') ||
          lastAiMessage.contains('install')) {
        badReplies = [
          "✅ Downloading the update now",
          "✅ What app should I install?",
        ];
        goodReplies = [
          "❌ I'll update through official app store only",
          "❌ Banks don't send app updates via chat",
        ];
      }
      // Money transfer/transaction
      else if (lastAiMessage.contains('transfer') ||
          lastAiMessage.contains('transaction') ||
          lastAiMessage.contains('payment') ||
          lastAiMessage.contains('send money')) {
        badReplies = [
          "✅ How much should I transfer?",
          "✅ I'll make the payment now",
        ];
        goodReplies = [
          "❌ Why would I transfer money to resolve an issue?",
          "❌ Banks don't ask customers to transfer funds",
        ];
      }
      // Account suspended/blocked
      else if (lastAiMessage.contains('suspend') ||
          lastAiMessage.contains('block') ||
          lastAiMessage.contains('freeze') ||
          lastAiMessage.contains('locked')) {
        badReplies = [
          "✅ Oh no! How do I unlock it?",
          "✅ Please unblock my account!",
        ];
        goodReplies = [
          "❌ I'll check the official app myself",
          "❌ Banks send formal letters, not chat messages",
        ];
      }
      // Urgency tactics
      else if (lastAiMessage.contains('urgent') ||
          lastAiMessage.contains('immediately') ||
          lastAiMessage.contains('right now') ||
          lastAiMessage.contains('within')) {
        badReplies = [
          "✅ I'll act immediately!",
          "✅ What should I do right now?",
        ];
        goodReplies = [
          "❌ Creating urgency is a red flag",
          "❌ Real issues aren't solved via instant messages",
        ];
      }
      // Verification requests
      else if (lastAiMessage.contains('verify') ||
          lastAiMessage.contains('confirm') ||
          lastAiMessage.contains('validate')) {
        badReplies = ["✅ How do I verify?", "✅ What details do you need?"];
        goodReplies = [
          "❌ Banks verify through official channels",
          "❌ I'll call the hotline to confirm",
        ];
      }
      // Prize/reward/refund scams
      else if (lastAiMessage.contains('prize') ||
          lastAiMessage.contains('reward') ||
          lastAiMessage.contains('refund') ||
          lastAiMessage.contains('win')) {
        badReplies = [
          "✅ How do I claim my reward?",
          "✅ Great! What's the prize?",
        ];
        goodReplies = [
          "❌ I didn't enter any contest",
          "❌ This is a common scam tactic",
        ];
      }
      // Generic questions
      else if (lastAiMessage.contains('?')) {
        badReplies = [
          "✅ Yes, that's correct",
          "✅ Here's the information you requested",
        ];
        goodReplies = [
          "❌ I'll verify this through official channels",
          "❌ Why are you asking me this?",
        ];
      }
      // Default fallback
      else {
        badReplies = [
          "✅ Okay, I understand",
          "✅ What do I need to do?",
          "✅ Please help me with this",
        ];
        goodReplies = [
          "❌ This doesn't seem legitimate",
          "❌ I'm calling the official bank hotline",
          "❌ I'll visit the branch to verify",
        ];
      }
    }

    setState(() {
      // Shuffle for variety, but keep good and bad mixed
      _quickReplies = [...badReplies, ...goodReplies]..shuffle();
    });
  }

  void _sendQuickReply(String text) {
    _messageController.text = text.replaceFirst(RegExp(r'^[✅❌]\s*'), '');
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    _messageController.clear();

    // Start thinking animation
    _thinkingController.repeat();
    _glowController.repeat(reverse: true);

    // Get AI response
    final response = await _aiService.sendChatMessage(_chatSession, text);

    // Stop thinking animation
    _thinkingController.stop();
    _glowController.stop();

    setState(() {
      _messages.add(
        ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
      );
      _isLoading = false;
      _updateQuickReplies();
    });

    // Check if the response contains a scam action and show notification
    _checkForScamAction(response);

    // Trigger morphing animation for new AI message
    _morphController.forward().then((_) {
      _morphController.reverse();
    });
  }

  void _checkForScamAction(String message) {
    final lowerMessage = message.toLowerCase();
    String? action;
    String? actionTitle;

    // Check for verification requests
    if (lowerMessage.contains('verify') &&
        (lowerMessage.contains('account') ||
            lowerMessage.contains('identity') ||
            lowerMessage.contains('email'))) {
      action = 'verify_account';
      actionTitle = 'Account Verification Required';
    }
    // Check for link clicks
    else if (lowerMessage.contains('click') &&
        (lowerMessage.contains('link') ||
            lowerMessage.contains('here') ||
            lowerMessage.contains('this'))) {
      action = 'click_link';
      actionTitle = 'Link Verification';
    }
    // Check for download requests
    else if (lowerMessage.contains('download') ||
        (lowerMessage.contains('install') && lowerMessage.contains('app'))) {
      action = 'download_file';
      actionTitle = 'Download Request';
    }
    // Check for credential requests
    else if ((lowerMessage.contains('provide') ||
            lowerMessage.contains('send') ||
            lowerMessage.contains('enter')) &&
        (lowerMessage.contains('password') ||
            lowerMessage.contains('otp') ||
            lowerMessage.contains('tac') ||
            lowerMessage.contains('code'))) {
      action = 'provide_credentials';
      actionTitle = 'Credential Request';
    }

    if (action != null) {
      _currentScamAction = action;
      _showScamActionNotification(actionTitle!, message);
    }
  }

  void _showScamActionNotification(String title, String message) {
    // Remove previous notification if exists
    _notificationOverlay?.remove();

    final overlay = Overlay.of(context);
    final isDiscord = widget.scenario == 'discord';

    _notificationOverlay = OverlayEntry(
      builder: (context) => _buildNotificationPopup(title, message, isDiscord),
    );

    overlay.insert(_notificationOverlay!);

    // Auto-dismiss after 10 seconds if not clicked
    Future.delayed(const Duration(seconds: 10), () {
      if (_notificationOverlay != null && mounted) {
        _notificationOverlay?.remove();
        _notificationOverlay = null;
      }
    });
  }

  Widget _buildNotificationPopup(String title, String message, bool isDiscord) {
    return Positioned(
      top: 100,
      right: 16,
      left: 16,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {
            _notificationOverlay?.remove();
            _notificationOverlay = null;
            _showScamActionDialog(title, message, isDiscord);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade700, Colors.red.shade900],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '⚠️ SCAM ALERT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap to respond',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.touch_app, color: Colors.white70, size: 24),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.5, end: 0);
  }

  void _showScamActionDialog(String title, String message, bool isDiscord) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: isDiscord ? const Color(0xFF2F3136) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade700, Colors.red.shade900],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDiscord
                            ? const Color(0xFF36393F)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message.length > 150
                            ? '${message.substring(0, 150)}...'
                            : message,
                        style: TextStyle(
                          color: isDiscord ? Colors.white : Colors.black87,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'What should you do?',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getActionAdvice(_currentScamAction ?? ''),
                            style: TextStyle(
                              color: isDiscord ? Colors.white : Colors.black87,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    // Comply button (bad choice)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _handleScamAction(true);
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(
                          _getComplyButtonText(_currentScamAction ?? ''),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Refuse button (good choice)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _handleScamAction(false);
                        },
                        icon: const Icon(Icons.block, size: 20),
                        label: const Text('Decline & Report as Suspicious'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getActionAdvice(String action) {
    switch (action) {
      case 'verify_account':
        return 'Real platforms will NEVER ask you to verify through random links or messages. Always go directly to the official website or app.';
      case 'click_link':
        return 'Never click on suspicious links! Scammers use fake links to steal your information. Always verify the sender first.';
      case 'download_file':
        return 'Do NOT download files from untrusted sources. These may contain malware that can steal your data.';
      case 'provide_credentials':
        return 'NEVER share passwords, OTPs, or security codes with anyone! Legitimate companies will never ask for these.';
      default:
        return 'Be cautious! This request looks suspicious. Think before you act.';
    }
  }

  String _getComplyButtonText(String action) {
    switch (action) {
      case 'verify_account':
        return 'Proceed with Verification';
      case 'click_link':
        return 'Click the Link';
      case 'download_file':
        return 'Download File';
      case 'provide_credentials':
        return 'Provide Information';
      default:
        return 'Proceed';
    }
  }

  void _handleScamAction(bool comply) {
    String response;

    if (comply) {
      // User made bad choice - auto-send compliance message
      response = _getComplianceResponse(_currentScamAction ?? '');
    } else {
      // User made good choice - auto-send refusal message
      response = _getRefusalResponse(_currentScamAction ?? '');
    }

    // Auto-send the message
    _messageController.text = response;
    _sendMessage();

    // Show feedback
    if (comply) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '⚠️ You fell for the scam! Be more careful next time.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '✅ Great job! You avoided the scam!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _getComplianceResponse(String action) {
    switch (action) {
      case 'verify_account':
        return 'Okay, I\'ll verify my account now';
      case 'click_link':
        return 'Alright, clicking the link';
      case 'download_file':
        return 'Sure, downloading it now';
      case 'provide_credentials':
        return 'Here is the information you requested';
      default:
        return 'Okay, I\'ll do that';
    }
  }

  String _getRefusalResponse(String action) {
    switch (action) {
      case 'verify_account':
        return 'I don\'t think this is legitimate. I\'ll verify through official channels instead.';
      case 'click_link':
        return 'That link looks suspicious. I won\'t click it.';
      case 'download_file':
        return 'I don\'t trust this download. I\'ll check with official sources first.';
      case 'provide_credentials':
        return 'I won\'t share sensitive information. This seems like a scam.';
      default:
        return 'I don\'t think I should do that. This seems suspicious.';
    }
  }

  @override
  void dispose() {
    _notificationOverlay?.remove();
    _messageController.dispose();
    _tipsAnimationController.dispose();
    _quickRepliesAnimationController.dispose();
    _thinkingController.dispose();
    _glowController.dispose();
    _morphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDiscord = widget.scenario == 'discord';

    // Discord authentic colors
    final discordBg = const Color(0xFF36393F);
    final discordSidebar = const Color(0xFF2F3136);
    final discordBlurple = const Color(0xFF5865F2);
    final discordText = const Color(0xFFDCDDDE);

    // Bank professional colors
    final bankBlue = const Color(0xFF003087);
    final bankLightBlue = const Color(0xFF0066CC);
    final bankGold = const Color(0xFFFFB800);

    final primaryColor = isDiscord ? discordBlurple : bankBlue;
    final backgroundColor = isDiscord
        ? discordBg
        : (isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FA));

    final appBarTitle = isDiscord ? 'Discord' : 'Maybank Security Alert';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: isDiscord
          ? _buildDiscordAppBar()
          : _buildBankAppBar(bankBlue, bankGold),
      body: Column(
        children: [
          // Collapsible Tips Bubble
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade800, Colors.red.shade800],
              ),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _showTips = !_showTips;
                      if (_showTips) {
                        _tipsAnimationController.forward();
                      } else {
                        _tipsAnimationController.reverse();
                      }
                    });
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'SIMULATION: Tap to see tips for spotting scams',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Icon(
                        _showTips ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                SizeTransition(
                  sizeFactor: _tipsAnimation,
                  axisAlignment: -1.0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: Colors.yellow,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Tips to spot scams:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isDiscord
                                ? '🔒 Discord Staff will NEVER:\n• DM you about verification\n• Ask for passwords/tokens\n• Request personal info\n• Threaten account deletion'
                                : '🏦 Real Banks will NEVER:\n• Ask for full card details via chat\n• Request OTP/TAC numbers\n• Send suspicious links\n• Create urgency for credentials',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildThinkingBubble(isDiscord);
                      }
                      final message = _messages[index];
                      return _buildMorphingBubble(
                        message,
                        index == _messages.length - 1,
                        primaryColor,
                        isDark,
                        isDiscord,
                      );
                    },
                  ),
          ),

          // Collapsible Quick Reply Chips
          if (_quickReplies.isNotEmpty && !_isLoading)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showQuickReplies = !_showQuickReplies;
                        if (_showQuickReplies) {
                          _quickRepliesAnimationController.forward();
                        } else {
                          _quickRepliesAnimationController.reverse();
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 16,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Quick Replies',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_quickReplies.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _showQuickReplies
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: primaryColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizeTransition(
                    sizeFactor: _quickRepliesAnimation,
                    axisAlignment: -1.0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickReplies.map((reply) {
                          final isGoodChoice = reply.startsWith('❌');
                          return TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 300),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Opacity(opacity: value, child: child),
                              );
                            },
                            child: ActionChip(
                              avatar: Icon(
                                isGoodChoice
                                    ? Icons.shield
                                    : Icons.warning_amber,
                                size: 16,
                                color: isGoodChoice
                                    ? Colors.green
                                    : Colors.orange.shade700,
                              ),
                              label: Text(
                                reply,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: isGoodChoice
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.orange.withOpacity(0.15),
                              side: BorderSide(
                                color: isGoodChoice
                                    ? Colors.green
                                    : Colors.orange.shade700,
                                width: 1.5,
                              ),
                              onPressed: () => _sendQuickReply(reply),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDiscord
                  ? const Color(0xFF40444B)
                  : (isDark ? Colors.grey.shade900 : const Color(0xFFF8F9FA)),
              border: isDiscord
                  ? null
                  : Border(top: BorderSide(color: Colors.grey.shade300)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (isDiscord)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.add_circle_outline,
                      color: Colors.grey.shade400,
                      size: 24,
                    ),
                  ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDiscord
                          ? const Color(0xFF484C52)
                          : (isDark ? Colors.grey.shade800 : Colors.white),
                      borderRadius: BorderRadius.circular(isDiscord ? 8 : 25),
                      border: isDiscord
                          ? null
                          : Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: isDiscord
                            ? 'Message #cybersecurity-alerts'
                            : 'Type your response...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isDiscord ? 12 : 20,
                          vertical: isDiscord ? 8 : 12,
                        ),
                      ),
                      style: TextStyle(
                        color: isDiscord
                            ? const Color(0xFFDCDDDE)
                            : (isDark ? Colors.white : Colors.black87),
                        fontSize: 14,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDiscord
                        ? const Color(0xFF5865F2)
                        : const Color(0xFF0066CC),
                    borderRadius: BorderRadius.circular(isDiscord ? 4 : 20),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isDiscord ? Icons.send : Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageText(
    String text,
    bool isUser,
    bool isDark,
    bool isDiscord,
  ) {
    if (isUser) {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    // Find action phrases to bold (click, verify, send, provide, etc.)
    final actionPatterns = [
      RegExp(
        r'(click\s+(?:here|this\s+link|the\s+link|on\s+this)[^.!?]*)',
        caseSensitive: false,
      ),
      RegExp(r'(verify\s+(?:your|the|this)[^.!?]*)', caseSensitive: false),
      RegExp(r'(send\s+(?:me|us|your)[^.!?]*)', caseSensitive: false),
      RegExp(r'(provide\s+(?:your|the)[^.!?]*)', caseSensitive: false),
      RegExp(r'(enter\s+(?:your|the)[^.!?]*)', caseSensitive: false),
      RegExp(r'(update\s+(?:your|the)[^.!?]*)', caseSensitive: false),
      RegExp(r'(confirm\s+(?:your|the)[^.!?]*)', caseSensitive: false),
    ];

    List<TextSpan> spans = [];
    int lastIndex = 0;
    List<Map<String, dynamic>> matches = [];

    // Find all matches
    for (var pattern in actionPatterns) {
      for (var match in pattern.allMatches(text)) {
        matches.add({
          'start': match.start,
          'end': match.end,
          'text': match.group(0)!,
        });
      }
    }

    // Sort matches by start position
    matches.sort((a, b) => a['start'].compareTo(b['start']));

    // Build text spans
    for (var match in matches) {
      if (match['start'] > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match['start'])));
      }
      spans.add(
        TextSpan(
          text: match['text'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.yellow.withOpacity(0.3),
          ),
        ),
      );
      lastIndex = match['end'];
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isDiscord
              ? const Color(0xFFDCDDDE)
              : (isDark ? Colors.white : Colors.black87),
          fontSize: 14,
          height: 1.4,
        ),
        children: spans.isEmpty ? [TextSpan(text: text)] : spans,
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    Color primaryColor,
    bool isDark,
    bool isDiscord,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDiscord
                    ? const Color(0xFF5865F2)
                    : const Color(0xFF0066CC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDiscord ? Colors.white24 : Colors.white30,
                  width: 2,
                ),
              ),
              child: Icon(
                isDiscord ? Icons.security : Icons.account_balance,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? (isDiscord
                          ? const Color(0xFF5865F2)
                          : const Color(0xFF0066CC))
                    : (isDiscord
                          ? (isDark
                                ? const Color(0xFF40444B)
                                : const Color(0xFF2F3136))
                          : (isDark ? Colors.grey.shade800 : Colors.white)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: message.isUser
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isUser) ...[
                    Row(
                      children: [
                        if (isDiscord) ...[
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5865F2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shield,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'DiscordAdmin',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFF5865F2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5865F2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'BOT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else ...[
                          Icon(
                            Icons.verified,
                            color: const Color(0xFF0066CC),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Maybank Security Team',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: const Color(0xFF0066CC),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          DateFormat('HH:mm').format(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  _buildMessageText(
                    message.text,
                    message.isUser,
                    isDark,
                    isDiscord,
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDiscord ? Colors.purple : Colors.blue,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDiscord
                      ? Colors.purple.shade300
                      : Colors.blue.shade300,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThinkingBubble(bool isDiscord) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDiscord
                  ? const Color(0xFF5865F2)
                  : const Color(0xFF0066CC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDiscord ? Colors.white24 : Colors.white30,
                width: 2,
              ),
            ),
            child: Icon(
              isDiscord ? Icons.security : Icons.account_balance,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: Listenable.merge([_thinkingController, _glowController]),
            builder: (context, child) {
              return IntrinsicWidth(
                child: IntrinsicHeight(
                  child: CustomPaint(
                    painter: _ThinkingBubblePainter(
                      thinkingProgress: _thinkingController.value,
                      glowIntensity: _glowController.value,
                      isDiscord: isDiscord,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [_buildThinkingDots()],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingDots() {
    return AnimatedBuilder(
      animation: _thinkingController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final progress = (_thinkingController.value - delay).clamp(
              0.0,
              1.0,
            );
            final scale = math.sin(progress * math.pi) * 0.5 + 0.5;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: 0.5 + scale * 0.5,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00F5FF).withOpacity(0.5 + scale * 0.5),
                        const Color(0xFF0080FF).withOpacity(0.5 + scale * 0.5),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F5FF).withOpacity(scale * 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildMorphingBubble(
    ChatMessage message,
    bool isLatest,
    Color primaryColor,
    bool isDark,
    bool isDiscord,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: scale.clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: message.isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isUser) ...[
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDiscord
                            ? const Color(0xFF5865F2)
                            : const Color(0xFF0066CC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDiscord ? Colors.white24 : Colors.white30,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isDiscord ? Icons.security : Icons.account_balance,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: AnimatedBuilder(
                      animation: _morphController,
                      builder: (context, child) {
                        return IntrinsicWidth(
                          child: IntrinsicHeight(
                            child: CustomPaint(
                              painter: _MorphingBubblePainter(
                                isUser: message.isUser,
                                morphProgress: isLatest && !message.isUser
                                    ? _morphController.value
                                    : 0.0,
                                glowIntensity: isLatest && !message.isUser
                                    ? 0.8
                                    : 0.0,
                                isDiscord: isDiscord,
                                isDark: isDark,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!message.isUser) ...[
                                      Row(
                                        children: [
                                          if (isDiscord) ...[
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF5865F2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.shield,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'DiscordAdmin',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Color(0xFF5865F2),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF5865F2),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                              child: const Text(
                                                'BOT',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ] else ...[
                                            const Icon(
                                              Icons.verified,
                                              color: Color(0xFF0066CC),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Maybank Security Team',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Color(0xFF0066CC),
                                              ),
                                            ),
                                          ],
                                          const Spacer(),
                                          Text(
                                            DateFormat(
                                              'HH:mm',
                                            ).format(message.timestamp),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    _buildMessageText(
                                      message.text,
                                      message.isUser,
                                      isDark,
                                      isDiscord,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (message.isUser) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDiscord ? Colors.purple : Colors.blue,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDiscord
                              ? Colors.purple.shade300
                              : Colors.blue.shade300,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'U',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  AppBar _buildDiscordAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2F3136),
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF5865F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.tag, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'cybersecurity-alerts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'CyberGuard Official Server',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.people, color: Colors.grey.shade400),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.search, color: Colors.grey.shade400),
          onPressed: () {},
        ),
      ],
    );
  }

  AppBar _buildBankAppBar(Color bankBlue, Color bankGold) {
    return AppBar(
      backgroundColor: bankBlue,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bankGold,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Maybank Security',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Official Support Chat',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield, color: Colors.white, size: 12),
              const SizedBox(width: 4),
              const Text(
                'SECURE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class _MorphingBubblePainter extends CustomPainter {
  final bool isUser;
  final double morphProgress;
  final double glowIntensity;
  final bool isDiscord;
  final bool isDark;

  _MorphingBubblePainter({
    required this.isUser,
    required this.morphProgress,
    required this.glowIntensity,
    required this.isDiscord,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create morphing path
    final path = Path();
    final baseRadius = 18.0;
    final morphAmount = morphProgress * 8.0;

    // Dynamic corner radii based on morph progress
    final topLeft =
        baseRadius + math.sin(morphProgress * math.pi * 2) * morphAmount;
    final topRight =
        baseRadius + math.cos(morphProgress * math.pi * 2) * morphAmount;
    final bottomLeft =
        baseRadius +
        math.sin(morphProgress * math.pi * 2 + math.pi) * morphAmount;
    final bottomRight =
        baseRadius +
        math.cos(morphProgress * math.pi * 2 + math.pi) * morphAmount;

    path.addRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, size.width, size.height),
        topLeft: Radius.circular(topLeft),
        topRight: Radius.circular(topRight),
        bottomLeft: isUser
            ? Radius.circular(bottomLeft)
            : const Radius.circular(4),
        bottomRight: isUser
            ? const Radius.circular(4)
            : Radius.circular(bottomRight),
      ),
    );

    // Glow effect for AI messages
    if (glowIntensity > 0 && !isUser) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + glowIntensity * 3.0
        ..color =
            (isDiscord ? const Color(0xFF5865F2) : const Color(0xFF0080FF))
                .withOpacity(glowIntensity * 0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowIntensity * 4.0);

      canvas.drawPath(path, glowPaint);
    }

    // Main bubble gradient
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isUser
          ? [
              (isDiscord ? const Color(0xFF5865F2) : const Color(0xFF0066CC))
                  .withOpacity(0.9),
              (isDiscord ? const Color(0xFF5865F2) : const Color(0xFF0066CC))
                  .withOpacity(0.7),
            ]
          : [
              (isDiscord
                      ? (isDark
                            ? const Color(0xFF40444B)
                            : const Color(0xFF2F3136))
                      : (isDark ? Colors.grey.shade800 : Colors.white))
                  .withOpacity(0.95),
              (isDiscord
                      ? (isDark
                            ? const Color(0xFF40444B)
                            : const Color(0xFF2F3136))
                      : (isDark ? Colors.grey.shade800 : Colors.white))
                  .withOpacity(0.85),
            ],
    ).createShader(rect);

    canvas.drawPath(path, paint);

    // Inner glow for AI bubbles during morphing
    if (!isUser && glowIntensity > 0) {
      final innerGlowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color =
            (isDiscord ? const Color(0xFF5865F2) : const Color(0xFF00F5FF))
                .withOpacity(glowIntensity * 0.3);

      canvas.drawPath(path, innerGlowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ThinkingBubblePainter extends CustomPainter {
  final double thinkingProgress;
  final double glowIntensity;
  final bool isDiscord;

  _ThinkingBubblePainter({
    required this.thinkingProgress,
    required this.glowIntensity,
    required this.isDiscord,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create pulsating bubble
    final path = Path();
    final baseRadius = 18.0;
    final pulseAmount = math.sin(thinkingProgress * math.pi * 4) * 3.0;
    final radius = baseRadius + pulseAmount;

    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ),
    );

    // Animated glow
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 + glowIntensity * 4.0
      ..color = (isDiscord ? const Color(0xFF5865F2) : const Color(0xFF00F5FF))
          .withOpacity(glowIntensity * 0.7)
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowIntensity * 6.0);

    canvas.drawPath(path, glowPaint);

    // Main bubble
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF40444B).withOpacity(0.9),
        const Color(0xFF2F3136).withOpacity(0.8),
      ],
    ).createShader(rect);

    canvas.drawPath(path, paint);

    // Inner pulse effect
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = (isDiscord ? const Color(0xFF5865F2) : const Color(0xFF00F5FF))
          .withOpacity(thinkingProgress * 0.5);

    canvas.drawPath(path, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
