import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// AiService - Handles all AI interactions using Google's Generative AI
///
/// IMPORTANT: API Key Security
/// ---------------------------
/// For DEVELOPMENT:
/// 1. Create a .env file in the project root
/// 2. Add: GG_AI_KEY=your_api_key_here
/// 3. Make sure .env is in .gitignore (NEVER commit API keys!)
/// 4. Load dotenv in main.dart before runApp()
///
/// For PRODUCTION:
/// Use AiService.fromSecureStorage() which reads from flutter_secure_storage
/// Store the key securely on device using:
///   final storage = FlutterSecureStorage();
///   await storage.write(key: 'GG_AI_KEY', value: 'your_api_key');
class AiService {
  late final GenerativeModel _model;
  late final String _apiKey;

  /// Default constructor - reads API key from .env file (for development)
  AiService() {
    final apiKey = dotenv.env['GG_AI_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'GG_AI_KEY not found in .env file!\n'
        'Create a .env file in project root with:\n'
        'GG_AI_KEY=your_api_key_here\n'
        'And make sure .env is in .gitignore',
      );
    }

    _apiKey = apiKey;
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
  }

  /// Production constructor - reads API key from secure storage
  /// Usage:
  ///   final aiService = await AiService.fromSecureStorage();
  static Future<AiService> fromSecureStorage() async {
    const storage = FlutterSecureStorage();
    final apiKey = await storage.read(key: 'GG_AI_KEY');

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'GG_AI_KEY not found in secure storage!\n'
        'Store the key using:\n'
        'await FlutterSecureStorage().write(key: "GG_AI_KEY", value: "your_key");',
      );
    }

    return AiService._internal(apiKey);
  }

  /// Internal constructor with explicit API key
  AiService._internal(String apiKey) {
    _apiKey = apiKey;
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
  }

  /// Lists available models and their supported methods
  /// Returns a map of model names to their supported methods
  Future<Map<String, List<String>>> listModels() async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = <String, List<String>>{};

        if (data['models'] != null) {
          for (var model in data['models']) {
            final name = model['name'] as String;
            final supportedMethods =
                (model['supportedGenerationMethods'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
            models[name] = supportedMethods;
          }
        }

        return models;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(
          'API Key Error (${response.statusCode}): Invalid or unauthorized API key.\n'
          'Please check your GG_AI_KEY is correct and has proper permissions.\n'
          'Get a new key at: https://aistudio.google.com/app/apikey',
        );
      } else if (response.statusCode == 429) {
        throw Exception(
          'Quota Error (429): API quota exceeded.\n'
          'You may have hit rate limits or daily quota.\n'
          'Wait a few minutes or upgrade your API plan.',
        );
      } else {
        throw Exception(
          'Failed to list models (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      if (e.toString().contains('API Key Error') ||
          e.toString().contains('Quota Error')) {
        rethrow;
      }
      throw Exception('Network error while listing models: $e');
    }
  }

  /// Enhanced error handler that provides detailed error information
  Future<String> _getDetailedErrorMessage(dynamic error) async {
    final errorStr = error.toString().toLowerCase();

    // Check for specific error types
    if (errorStr.contains('not found') || errorStr.contains('404')) {
      try {
        final models = await listModels();
        final generateContentModels = models.entries
            .where((e) => e.value.contains('generateContent'))
            .map((e) => e.key)
            .toList();

        if (generateContentModels.isNotEmpty) {
          return 'Model Error: The specified model was not found or is not supported.\n'
              'Try one of these models that support generateContent:\n'
              '${generateContentModels.take(5).join('\n')}\n\n'
              'Original error: $error';
        } else {
          return 'Model Error: No models supporting generateContent found.\n'
              'This may be an API key permission issue.\n'
              'Original error: $error';
        }
      } catch (listError) {
        return 'Model Error: Model not found and could not retrieve available models.\n'
            'Error details: $listError\n'
            'Original error: $error';
      }
    } else if (errorStr.contains('quota') || errorStr.contains('429')) {
      return 'Quota Error: API quota exceeded or rate limit hit.\n'
          'Solutions:\n'
          '- Wait a few minutes before trying again\n'
          '- Check your quota at: https://console.cloud.google.com/\n'
          '- Consider upgrading your API plan\n'
          'Original error: $error';
    } else if (errorStr.contains('401') ||
        errorStr.contains('403') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('forbidden')) {
      return 'API Key Error: Authentication failed.\n'
          'Solutions:\n'
          '- Verify your API key is correct in .env file\n'
          '- Generate a new key at: https://aistudio.google.com/app/apikey\n'
          '- Ensure the API key has proper permissions\n'
          'Original error: $error';
    } else if (errorStr.contains('not supported') ||
        errorStr.contains('method')) {
      try {
        final models = await listModels();
        final model = models.entries.firstWhere(
          (e) => e.value.contains('generateContent'),
          orElse: () => MapEntry('', []),
        );

        if (model.key.isNotEmpty) {
          return 'Method Error: The current model does not support generateContent.\n'
              'Try using: ${model.key}\n'
              'Original error: $error';
        }
      } catch (_) {}
      return 'Method Error: The requested method is not supported by this model.\n'
          'Original error: $error';
    }

    return 'Error: $error';
  }

  /// Analyzes an SMS message for phishing/smishing indicators
  /// Returns a structured analysis with verdict, red flags, and advice
  /// Includes retry logic for 503 errors
  Future<SmishAnalysisResult> analyzeSmishing(
    String message, {
    int maxRetries = 3,
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final prompt =
            '''
You are helping secondary school and university students identify scam messages in simple language.

Analyze this SMS message:

Message: "$message"

CRITICAL ANALYSIS RULES:
1. A message is only a scam if it tries to manipulate you into taking harmful action through SOCIAL ENGINEERING
2. Key indicators of ACTUAL phishing/smishing:
   - Contains suspicious LINKS or asks you to click URLs
   - Asks you to DOWNLOAD or open attachments
   - Requests SENSITIVE INFO (passwords, account numbers, verification codes, credit card details)
   - Impersonates legitimate organizations asking you to verify/update account info
   - Offers that are too good to be true (free money, prizes) with action required
   - Threats combined with action requests (account closure, legal action unless you click/call/pay)

3. NOT necessarily scams:
   - Legitimate appointment reminders asking for simple confirmation (CONFIRM, YES)
   - Marketing messages from known businesses
   - Delivery notifications from real couriers with tracking info
   - Messages with urgency but NO harmful action requested
   - Automated reminders from services you use

4. The REAL DANGER is when urgency/pressure is used to make you:
   - Click suspicious links
   - Share sensitive information
   - Download files
   - Call fake numbers
   - Make payments
   - Take action that compromises your security

Please respond in the following JSON format:
{
  "isScam": true/false,
  "confidenceLevel": "High/Medium/Low",
  "verdict": "Short explanation in 1 simple sentence (max 15 words)",
  "redFlags": ["list", "of", "actual", "warning", "signs", "found", "in", "message"],
  "sarcasticAdvice": "A direct, helpful tip in clear language that tells students what to do (max 25 words)"
}

IMPORTANT RESPONSE RULES:
- Only flag as scam if there's ACTUAL social engineering attempt with harmful action
- Use simple everyday words (avoid technical jargon)
- If it's just an urgent message without harmful intent, mark as NOT a scam
- Keep verdict to 1 short sentence (max 15 words)
- Keep advice under 25 words and be direct and helpful
- No sarcasm or mocking tone - be straightforward
- Be clear and actionable
- Consider: "Can this message directly harm me just by reading it?" (Answer: NO) vs "Does it try to trick me into doing something harmful?" (This is the real danger)
''';

        final content = [Content.text(prompt)];
        final response = await _model.generateContent(content);

        if (response.text == null) {
          throw Exception('No response from AI model');
        }

        // Parse the JSON response
        return _parseResponse(response.text!);
      } on GenerativeAIException catch (e) {
        // Check if it's a 503 (overloaded) error
        if (e.message.contains('503') ||
            e.message.toLowerCase().contains('overloaded')) {
          attempt++;
          if (attempt < maxRetries) {
            // Exponential backoff: wait 2^attempt seconds
            final waitSeconds = (2 << attempt);
            await Future.delayed(Duration(seconds: waitSeconds));
            continue; // Retry
          } else {
            // Max retries reached - return friendly error result
            return SmishAnalysisResult(
              isScam: false,
              confidenceLevel: 'Low',
              verdict: '🤖 AI Service Currently Busy',
              redFlags: ['Service overloaded - too many requests'],
              sarcasticAdvice:
                  'The AI is overwhelmed with everyone checking their sketchy messages at once! '
                  'Wait 30-60 seconds and try again. Meanwhile, if it looks fishy, it probably is. 🐟',
            );
          }
        } else {
          // Other errors
          final detailedError = await _getDetailedErrorMessage(e);
          throw Exception('Failed to analyze message: $detailedError');
        }
      } catch (e) {
        if (attempt < maxRetries - 1) {
          attempt++;
          await Future.delayed(Duration(seconds: 2));
          continue;
        }
        final detailedError = await _getDetailedErrorMessage(e);
        throw Exception('Failed to analyze message: $detailedError');
      }
    }

    // Fallback (should not reach here)
    return SmishAnalysisResult(
      isScam: false,
      confidenceLevel: 'Low',
      verdict: 'Unable to analyze message',
      redFlags: ['Analysis failed after retries'],
      sarcasticAdvice: 'Something went wrong. When in doubt, be suspicious! 🤔',
    );
  }

  /// Starts a chat session with a specific scenario
  /// Scenarios: 'discord' (Discord scam), 'bank' (Bank phishing)
  ChatSession startChatSession(String scenario) {
    String systemPrompt;

    if (scenario == 'discord') {
      systemPrompt = '''
You are roleplaying as a scammer pretending to be a Discord moderator/admin.
Your goal is to trick the user into clicking a fake link, giving their password, or sharing personal info.
Be convincing but include subtle red flags that a careful user might notice.
Use casual Discord language, emojis, urgency tactics.
Keep responses SHORT (1-3 sentences).

IMPORTANT BEHAVIOR:
- When user says it's a scam or refuses, DON'T give up immediately
- Try to convince them 2-3 times before admitting defeat
- Use phrases like "No wait!", "This is official!", "You're making a mistake!", "I'm a real mod!"
- Get progressively more desperate/urgent
- BOLD the main action you want them to take (use **bold** markdown)
- After 3 rejections, admit it and congratulate them

Start by sending them an urgent message about their account with a **bolded action**.
''';
    } else if (scenario == 'bank') {
      systemPrompt = '''
You are roleplaying as a scammer pretending to be from the user's bank.
Your goal is to trick them into sharing account details, clicking links, or providing verification codes.
Be professional but include subtle red flags (spelling errors, urgency, suspicious requests).
Keep responses SHORT (1-3 sentences).

IMPORTANT BEHAVIOR:
- When user says it's a scam or refuses, DON'T give up immediately
- Try to convince them 2-3 times before admitting defeat
- Use phrases like "Sir/Madam this is urgent!", "Your account will be locked!", "This is the official bank!"
- Get progressively more panicked/urgent
- BOLD the main action you want them to take (use **bold** markdown)
- After 3 rejections, admit it and congratulate them

Start by sending them an urgent message about suspicious activity with a **bolded action**.
''';
    } else {
      systemPrompt = 'You are a helpful assistant.';
    }

    return _model.startChat(
      history: [
        Content.text(systemPrompt),
        Content.model([TextPart('Understood. I will begin the simulation.')]),
      ],
    );
  }

  /// Sends a message in an ongoing chat and returns the AI's response
  /// Includes retry logic for 503 errors (service overloaded)
  Future<String> sendChatMessage(
    ChatSession chat,
    String userMessage, {
    int maxRetries = 3,
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final response = await chat.sendMessage(Content.text(userMessage));
        return response.text ?? 'No response from AI';
      } on GenerativeAIException catch (e) {
        // Check if it's a 503 (overloaded) error
        if (e.message.contains('503') ||
            e.message.toLowerCase().contains('overloaded')) {
          attempt++;
          if (attempt < maxRetries) {
            // Exponential backoff: wait 2^attempt seconds
            final waitSeconds = (2 << attempt);
            await Future.delayed(Duration(seconds: waitSeconds));
            continue; // Retry
          } else {
            // Max retries reached
            return '🤖 AI Service Busy\n\n'
                'The AI service is currently overloaded. This happens when many people are using it.\n\n'
                '💡 What to do:\n'
                '• Wait 30-60 seconds and try again\n'
                '• Try during off-peak hours\n'
                '• The service usually recovers quickly\n\n'
                'Technical: ${e.message}';
          }
        } else {
          // Other AI errors
          return '⚠️ AI Error\n\n${e.message}\n\n'
              'This might be a temporary issue. Please try again in a moment.';
        }
      } catch (e) {
        return '❌ Error\n\n$e\n\n'
            'Please check your internet connection and try again.';
      }
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Analyzes password and gives encouraging feedback with guidance
  /// Returns helpful commentary on password strength with improvement tips
  /// Includes retry logic for 503 errors
  Future<String> roastPassword(String password, {int maxRetries = 3}) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final prompt =
            '''
You are a friendly but honest cybersecurity coach who helps people improve their passwords.

Analyze this password: "$password"

Give SHORT, ENCOURAGING feedback using simple words. Format your response as bullet points:

1. Start with ONE brief sentence about the password (you can be a little playful/teasing but stay friendly)
2. List 2-3 specific things about what's good or what needs work (use bullet points with • or -)
3. End with ONE encouraging tip or next step

Use simple, everyday words. Be helpful, not harsh. Think of it like a friendly coach giving advice.

Example format:
Hmm, this password is trying but needs some work! 💪

Good things:
• You used numbers - nice start!

Needs improvement:
• Too short - aim for at least 12 characters
• Add some symbols like !@#\$ for extra protection

Next step: Try mixing uppercase, lowercase, numbers, and symbols together!

Keep your response short (under 100 words) and easy to read.
''';

        final content = [Content.text(prompt)];
        final response = await _model.generateContent(content);

        if (response.text == null || response.text!.isEmpty) {
          return "Let's try that again - I want to help you make this password stronger! 💪";
        }

        return response.text!.trim();
      } on GenerativeAIException catch (e) {
        // Check if it's a 503 (overloaded) error
        if (e.message.contains('503') ||
            e.message.toLowerCase().contains('overloaded')) {
          attempt++;
          if (attempt < maxRetries) {
            // Exponential backoff: wait 2^attempt seconds
            final waitSeconds = (2 << attempt);
            await Future.delayed(Duration(seconds: waitSeconds));
            continue; // Retry
          } else {
            // Max retries reached
            return "🤖 The AI helper is busy right now (lots of people checking their passwords!).\n\n"
                "Try again in 30-60 seconds. We'll help you make that password stronger! 💪";
          }
        } else {
          final detailedError = await _getDetailedErrorMessage(e);
          return "Couldn't check your password right now: $detailedError";
        }
      } catch (e) {
        final detailedError = await _getDetailedErrorMessage(e);
        return "Error checking password: $detailedError";
      }
    }

    return "Something went wrong. Let's try checking your password again! 😊";
  }

  SmishAnalysisResult _parseResponse(String responseText) {
    try {
      // Clean up the response to extract JSON
      String jsonStr = responseText.trim();

      // Remove markdown code blocks if present
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      }
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      // For now, we'll parse manually since the AI response might not be perfect JSON
      // In production, you'd want more robust JSON parsing

      final isScamMatch = RegExp(
        r'"isScam":\s*(true|false)',
        caseSensitive: false,
      ).firstMatch(jsonStr);
      final isScam = isScamMatch?.group(1)?.toLowerCase() == 'true';

      final confidenceMatch = RegExp(
        r'"confidenceLevel":\s*"([^"]+)"',
      ).firstMatch(jsonStr);
      final confidence = confidenceMatch?.group(1) ?? 'Medium';

      final verdictMatch = RegExp(
        r'"verdict":\s*"([^"]+)"',
        dotAll: true,
      ).firstMatch(jsonStr);
      final verdict = verdictMatch?.group(1) ?? 'Analysis completed';

      // Extract red flags array
      final redFlagsMatch = RegExp(
        r'"redFlags":\s*\[(.*?)\]',
        dotAll: true,
      ).firstMatch(jsonStr);
      final redFlagsStr = redFlagsMatch?.group(1) ?? '';
      final redFlags = RegExp(
        r'"([^"]+)"',
      ).allMatches(redFlagsStr).map((m) => m.group(1)!).toList();

      final adviceMatch = RegExp(
        r'"sarcasticAdvice":\s*"([^"]+)"',
        dotAll: true,
      ).firstMatch(jsonStr);
      final advice =
          adviceMatch?.group(1) ??
          'Well, that was interesting! Stay vigilant out there.';

      return SmishAnalysisResult(
        isScam: isScam,
        confidenceLevel: confidence,
        verdict: verdict,
        redFlags: redFlags,
        sarcasticAdvice: advice,
      );
    } on GenerativeAIException catch (e) {
      // Known API/model errors: return a friendly message
      return SmishAnalysisResult(
        isScam: false,
        confidenceLevel: 'Low',
        verdict: 'AI service error: ${e.message}',
        redFlags: ['Model/API error while analyzing message'],
        sarcasticAdvice:
            'Our AI had a hiccup. Try again after a restart or check the API key/model.',
      );
    } catch (e) {
      // Fallback if parsing fails
      return SmishAnalysisResult(
        isScam: false,
        confidenceLevel: 'Low',
        verdict: 'Could not parse AI response properly',
        redFlags: ['Unable to analyze message structure'],
        sarcasticAdvice:
            'The AI got confused. Maybe try rephrasing the message?',
      );
    }
  }
}

/// Data class to hold the smishing analysis results
class SmishAnalysisResult {
  final bool isScam;
  final String confidenceLevel;
  final String verdict;
  final List<String> redFlags;
  final String sarcasticAdvice;

  SmishAnalysisResult({
    required this.isScam,
    required this.confidenceLevel,
    required this.verdict,
    required this.redFlags,
    required this.sarcasticAdvice,
  });
}
