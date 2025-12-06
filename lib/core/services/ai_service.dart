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
        'And make sure .env is in .gitignore'
      );
    }

    _apiKey = apiKey;
    _model = GenerativeModel(
      model: 'models/gemini-1.5-flash',
      apiKey: _apiKey,
    );
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
        'await FlutterSecureStorage().write(key: "GG_AI_KEY", value: "your_key");'
      );
    }

    return AiService._internal(apiKey);
  }

  /// Internal constructor with explicit API key
  AiService._internal(String apiKey) {
    _apiKey = apiKey;
    _model = GenerativeModel(
      model: 'models/gemini-2.5-flash',
      apiKey: _apiKey,
    );
  }

  /// Lists available models and their supported methods
  /// Returns a map of model names to their supported methods
  Future<Map<String, List<String>>> listModels() async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = <String, List<String>>{};
        
        if (data['models'] != null) {
          for (var model in data['models']) {
            final name = model['name'] as String;
            final supportedMethods = (model['supportedGenerationMethods'] as List?)
                ?.map((e) => e.toString())
                .toList() ?? [];
            models[name] = supportedMethods;
          }
        }
        
        return models;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(
          'API Key Error (${response.statusCode}): Invalid or unauthorized API key.\n'
          'Please check your GG_AI_KEY is correct and has proper permissions.\n'
          'Get a new key at: https://aistudio.google.com/app/apikey'
        );
      } else if (response.statusCode == 429) {
        throw Exception(
          'Quota Error (429): API quota exceeded.\n'
          'You may have hit rate limits or daily quota.\n'
          'Wait a few minutes or upgrade your API plan.'
        );
      } else {
        throw Exception(
          'Failed to list models (${response.statusCode}): ${response.body}'
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
    } else if (errorStr.contains('401') || errorStr.contains('403') || 
               errorStr.contains('unauthorized') || errorStr.contains('forbidden')) {
      return 'API Key Error: Authentication failed.\n'
          'Solutions:\n'
          '- Verify your API key is correct in .env file\n'
          '- Generate a new key at: https://aistudio.google.com/app/apikey\n'
          '- Ensure the API key has proper permissions\n'
          'Original error: $error';
    } else if (errorStr.contains('not supported') || errorStr.contains('method')) {
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
  Future<SmishAnalysisResult> analyzeSmishing(String message) async {
    try {
      final prompt = '''
You are a cybersecurity expert analyzing SMS messages for phishing (smishing) attempts.

Analyze this SMS message and provide your assessment:

Message: "$message"

Please respond in the following JSON format:
{
  "isScam": true/false,
  "confidenceLevel": "High/Medium/Low",
  "verdict": "Brief verdict in 1-2 sentences",
  "redFlags": ["list", "of", "red", "flags", "found"],
  "sarcasticAdvice": "A sarcastic but educational comment about what makes this suspicious or why it's safe"
}

Be thorough but concise. If it's clearly a scam, be witty in your sarcastic advice. If it seems legitimate, still point out what makes it trustworthy.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null) {
        throw Exception('No response from AI model');
      }

      // Parse the JSON response
      return _parseResponse(response.text!);
    } catch (e) {
      final detailedError = await _getDetailedErrorMessage(e);
      throw Exception('Failed to analyze message: $detailedError');
    }
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
If the user catches your scam or refuses, admit it and congratulate them.
Start by sending them an urgent message about their account.
''';
    } else if (scenario == 'bank') {
      systemPrompt = '''
You are roleplaying as a scammer pretending to be from the user's bank.
Your goal is to trick them into sharing account details, clicking links, or providing verification codes.
Be professional but include subtle red flags (spelling errors, urgency, suspicious requests).
Keep responses SHORT (1-3 sentences).
If the user catches your scam or refuses, admit it and congratulate them.
Start by sending them an urgent message about suspicious activity.
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
  Future<String> sendChatMessage(ChatSession chat, String userMessage) async {
    try {
      final response = await chat.sendMessage(Content.text(userMessage));
      return response.text ?? 'No response from AI';
    } on GenerativeAIException catch (e) {
      return 'AI Error: ${e.message}';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Roasts a password with mean, sarcastic cybersecurity feedback
  /// Returns funny commentary on why the password is weak or strong
  Future<String> roastPassword(String password) async {
    try {
      final prompt = '''
You are a mean, sarcastic cybersecurity expert who roasts people's passwords.

Analyze this password: "$password"

Give SHORT, FUNNY feedback (2-3 sentences max) on why this password is weak or strong.
Be brutally honest and sarcastic, but educational.
If it's weak, mock it creatively.
If it's strong, give grudging respect with a joke.

Respond with JUST the roast text, no JSON, no formatting.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        return "Even the AI is speechless at this password choice. That's... impressive? 🤦";
      }

      return response.text!.trim();
    } on GenerativeAIException catch (e) {
      final detailedError = await _getDetailedErrorMessage(e);
      return "The AI couldn't roast your password: $detailedError";
    } catch (e) {
      final detailedError = await _getDetailedErrorMessage(e);
      return "Error roasting password: $detailedError";
    }
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
      
      final isScamMatch = RegExp(r'"isScam":\s*(true|false)', caseSensitive: false)
          .firstMatch(jsonStr);
      final isScam = isScamMatch?.group(1)?.toLowerCase() == 'true';

      final confidenceMatch = RegExp(r'"confidenceLevel":\s*"([^"]+)"')
          .firstMatch(jsonStr);
      final confidence = confidenceMatch?.group(1) ?? 'Medium';

      final verdictMatch = RegExp(r'"verdict":\s*"([^"]+)"', dotAll: true)
          .firstMatch(jsonStr);
      final verdict = verdictMatch?.group(1) ?? 'Analysis completed';

      // Extract red flags array
      final redFlagsMatch = RegExp(r'"redFlags":\s*\[(.*?)\]', dotAll: true)
          .firstMatch(jsonStr);
      final redFlagsStr = redFlagsMatch?.group(1) ?? '';
      final redFlags = RegExp(r'"([^"]+)"')
          .allMatches(redFlagsStr)
          .map((m) => m.group(1)!)
          .toList();

      final adviceMatch = RegExp(r'"sarcasticAdvice":\s*"([^"]+)"', dotAll: true)
          .firstMatch(jsonStr);
      final advice = adviceMatch?.group(1) ?? 
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
        sarcasticAdvice: 'The AI got confused. Maybe try rephrasing the message?',
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
