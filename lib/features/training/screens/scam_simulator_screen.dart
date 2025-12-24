import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/services/ai_service.dart';
import 'package:flutter/gestures.dart';

class ScamSimulatorScreen extends StatefulWidget {
  final String scenario;

  const ScamSimulatorScreen({Key? key, required this.scenario})
      : super(key: key);

  @override
  State<ScamSimulatorScreen> createState() => _ScamSimulatorScreenState();
}

class _ScamSimulatorScreenState extends State<ScamSimulatorScreen> {
  final AiService _aiService = AiService();
  late ChatSession _chatSession;
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  List<String> _quickReplies = [];

  @override
  void initState() {
    super.initState();
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
      _messages.add(ChatMessage(
        text: openingMessage,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = false;
      _updateQuickReplies();
    });
  }

  void _updateQuickReplies() {
    final isDiscord = widget.scenario == 'discord';
    setState(() {
      _quickReplies = isDiscord
          ? [
              "✅ Okay, I'll verify my account",
              "✅ Sure, what information do you need?",
              "❌ This seems suspicious. I'll contact Discord support directly.",
            ]
          : [
              "✅ I'll update my information right away",
              "✅ Yes, please send me the verification link",
              "❌ I'll call my bank's official number to verify this.",
            ];
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
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();

    // Get AI response
    final response = await _aiService.sendChatMessage(_chatSession, text);

    setState(() {
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = false;
      _updateQuickReplies();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDiscord = widget.scenario == 'discord';

    // Theme colors based on scenario
    final primaryColor = isDiscord
        ? const Color(0xFF5865F2) // Discord blue
        : const Color(0xFF0066CC); // Bank blue
    
    final backgroundColor = isDark
        ? (isDiscord ? const Color(0xFF36393F) : const Color(0xFF1A1A2E))
        : (isDiscord ? const Color(0xFF36393F) : Colors.white);

    final appBarTitle = isDiscord
        ? '💬 Discord Moderator'
        : '🏦 Bank Security Alert';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(appBarTitle),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Warning banner with hints
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.orange.shade800,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SIMULATION: This is a fake scam. Try to spot the red flags!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💡 Tips to spot scams:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDiscord
                            ? '• Check for urgency & pressure\n• Real mods don\'t DM first\n• Never share passwords\n• Verify links carefully'
                            : '• Banks never ask for full details\n• Check for spelling errors\n• No urgency for credentials\n• Verify via official channels',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(
                        message,
                        primaryColor,
                        isDark,
                        isDiscord,
                      );
                    },
                  ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Typing...',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Quick Reply Chips
          if (_quickReplies.isNotEmpty && !_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        size: 14,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Quick Replies:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _quickReplies.map((reply) {
                      final isGoodChoice = reply.startsWith('❌');
                      return ActionChip(
                        avatar: Icon(
                          isGoodChoice ? Icons.shield : Icons.warning_amber,
                          size: 16,
                          color: isGoodChoice ? Colors.green : Colors.orange.shade700,
                        ),
                        label: Text(
                          reply,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: isGoodChoice
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        side: BorderSide(
                          color: isGoodChoice ? Colors.green : Colors.orange.shade700,
                          width: 1,
                        ),
                        onPressed: () => _sendQuickReply(reply),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: isDiscord
                          ? 'Message @Moderator'
                          : 'Type your response...',
                      filled: true,
                      fillColor: isDark ? Colors.grey.shade800 : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
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

  Widget _buildMessageText(String text, bool isUser, bool isDark) {
    if (isUser) {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      );
    }

    // Find action phrases to bold (click, verify, send, provide, etc.)
    final actionPatterns = [
      RegExp(r'(click\s+(?:here|this\s+link|the\s+link|on\s+this)[^.!?]*)',
          caseSensitive: false),
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
        spans.add(TextSpan(
          text: text.substring(lastIndex, match['start']),
        ));
      }
      spans.add(TextSpan(
        text: match['text'],
        style: TextStyle(
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.yellow.withOpacity(0.3),
        ),
      ));
      lastIndex = match['end'];
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
      ));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 14,
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
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: primaryColor,
              radius: 16,
              child: Icon(
                isDiscord ? Icons.shield : Icons.account_balance,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser
                    ? primaryColor
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isUser)
                    Text(
                      isDiscord ? 'Discord Moderator' : 'Bank Security',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: primaryColor,
                      ),
                    ),
                  _buildMessageText(
                    message.text,
                    message.isUser,
                    isDark,
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey.shade600,
              radius: 16,
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
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
