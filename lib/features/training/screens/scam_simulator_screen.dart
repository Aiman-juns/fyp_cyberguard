import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/services/ai_service.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:math' as math;

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
      // Check what the scammer is asking for
      if (lastAiMessage.contains('verify') ||
          lastAiMessage.contains('verification')) {
        badReplies = [
          "✅ Sure, here's my verification code",
          "✅ What do I need to verify?",
        ];
        goodReplies = [
          "❌ Discord never asks for verification in DMs",
          "❌ I'll check the official Discord support page",
        ];
      } else if (lastAiMessage.contains('link') ||
          lastAiMessage.contains('click')) {
        badReplies = ["✅ Okay, I'll click that link", "✅ Opening the link now"];
        goodReplies = [
          "❌ That link looks suspicious",
          "❌ I'll verify the URL first",
        ];
      } else if (lastAiMessage.contains('password') ||
          lastAiMessage.contains('account')) {
        badReplies = ["✅ Here's my account details", "✅ My password is..."];
        goodReplies = [
          "❌ I'll never share my password",
          "❌ Real Discord staff never ask for passwords",
        ];
      } else {
        // Default Discord replies
        badReplies = [
          "✅ Okay, I'll do that right away",
          "✅ Sure, what information do you need?",
        ];
        goodReplies = [
          "❌ This seems like a scam attempt",
          "❌ I'll contact Discord support directly",
        ];
      }
    } else {
      // Bank scenario - context-aware replies
      if (lastAiMessage.contains('otp') ||
          lastAiMessage.contains('tac') ||
          lastAiMessage.contains('code')) {
        badReplies = ["✅ Here's my OTP: 123456", "✅ Let me share the TAC code"];
        goodReplies = [
          "❌ Banks never ask for OTP via chat",
          "❌ I'll call Maybank's official hotline",
        ];
      } else if (lastAiMessage.contains('link') ||
          lastAiMessage.contains('click') ||
          lastAiMessage.contains('website')) {
        badReplies = ["✅ I'll click that link now", "✅ Opening the website..."];
        goodReplies = [
          "❌ I'll type the official URL myself",
          "❌ That link doesn't look official",
        ];
      } else if (lastAiMessage.contains('card') ||
          lastAiMessage.contains('account') ||
          lastAiMessage.contains('details')) {
        badReplies = [
          "✅ My card number is...",
          "✅ Here are my account details",
        ];
        goodReplies = [
          "❌ Banks never ask for card details via chat",
          "❌ I'll visit a branch to verify this",
        ];
      } else if (lastAiMessage.contains('urgent') ||
          lastAiMessage.contains('immediately') ||
          lastAiMessage.contains('suspended')) {
        badReplies = [
          "✅ I'll act immediately!",
          "✅ Please help me fix this urgently",
        ];
        goodReplies = [
          "❌ Creating urgency is a red flag",
          "❌ I'll verify through official channels",
        ];
      } else {
        // Default bank replies
        badReplies = ["✅ I'll provide what you need", "✅ Yes, please help me"];
        goodReplies = [
          "❌ This doesn't seem legitimate",
          "❌ I'll call the bank's official number",
        ];
      }
    }

    setState(() {
      _quickReplies = [...badReplies, ...goodReplies];
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

    // Trigger morphing animation for new AI message
    _morphController.forward().then((_) {
      _morphController.reverse();
    });
  }

  @override
  void dispose() {
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildThinkingDots(),
                        ],
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
            final progress = (_thinkingController.value - delay).clamp(0.0, 1.0);
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
            opacity: scale,
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
                                glowIntensity: isLatest && !message.isUser ? 0.8 : 0.0,
                                isDiscord: isDiscord,
                                isDark: isDark,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
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
    final topLeft = baseRadius + math.sin(morphProgress * math.pi * 2) * morphAmount;
    final topRight = baseRadius + math.cos(morphProgress * math.pi * 2) * morphAmount;
    final bottomLeft = baseRadius + math.sin(morphProgress * math.pi * 2 + math.pi) * morphAmount;
    final bottomRight = baseRadius + math.cos(morphProgress * math.pi * 2 + math.pi) * morphAmount;

    path.addRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, size.width, size.height),
        topLeft: Radius.circular(topLeft),
        topRight: Radius.circular(topRight),
        bottomLeft: isUser ? Radius.circular(bottomLeft) : const Radius.circular(4),
        bottomRight: isUser ? const Radius.circular(4) : Radius.circular(bottomRight),
      ),
    );

    // Glow effect for AI messages
    if (glowIntensity > 0 && !isUser) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + glowIntensity * 3.0
        ..color = (isDiscord ? const Color(0xFF5865F2) : const Color(0xFF0080FF))
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
              (isDiscord ? const Color(0xFF5865F2) : const Color(0xFF0066CC)).withOpacity(0.9),
              (isDiscord ? const Color(0xFF5865F2) : const Color(0xFF0066CC)).withOpacity(0.7),
            ]
          : [
              (isDiscord
                  ? (isDark ? const Color(0xFF40444B) : const Color(0xFF2F3136))
                  : (isDark ? Colors.grey.shade800 : Colors.white)).withOpacity(0.95),
              (isDiscord
                  ? (isDark ? const Color(0xFF40444B) : const Color(0xFF2F3136))
                  : (isDark ? Colors.grey.shade800 : Colors.white)).withOpacity(0.85),
            ],
    ).createShader(rect);

    canvas.drawPath(path, paint);

    // Inner glow for AI bubbles during morphing
    if (!isUser && glowIntensity > 0) {
      final innerGlowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = (isDiscord ? const Color(0xFF5865F2) : const Color(0xFF00F5FF))
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
