import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  static const String _apiKey = 'AIzaSyDx1DPfa1E-krs0ABg2exdBeNys0BDf0ho';
  late final GenerativeModel _model;

  AiService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: _apiKey,
    );
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
      throw Exception('Failed to analyze message: $e');
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
      return 'AI Error: ${e.message ?? 'Unknown error'}';
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
      return "The AI couldn't roast your password because: ${e.message ?? 'Unknown error'}. Maybe it's too scared? 😅";
    } catch (e) {
      return "Something went wrong trying to roast your password. It's probably so bad it broke the AI. 💀";
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
      final msg = e.message ?? 'Unknown Generative AI error';
      return SmishAnalysisResult(
        isScam: false,
        confidenceLevel: 'Low',
        verdict: 'AI service error: $msg',
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
