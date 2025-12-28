import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/breach_model.dart';

class BreachService {
  static const String _baseUrl = 'https://api.xposedornot.com/v1';

  // Toggle this to use mock data for demos
  static const bool _useMockData = false;

  /// Check if an email has been involved in any data breaches
  /// Returns an empty list if no breaches found
  /// Returns a list of BreachModel if breaches are found
  Future<List<BreachModel>> checkEmail(String email) async {
    // Validate email format
    if (!_isValidEmail(email)) {
      throw Exception('Invalid email format');
    }

    // Use mock data if enabled
    if (_useMockData) {
      return _getMockBreaches(email);
    }

    try {
      final url = Uri.parse('$_baseUrl/check-email/$email');

      print('Checking breach for: $email');

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Status 404 or "Not found" means no breaches
      if (response.statusCode == 404) {
        return [];
      }

      // Check for "Error": "Not found" in body
      if (response.body.contains('"Error"') &&
          response.body.contains('Not found')) {
        return [];
      }

      // Status 200 with breaches data
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Check if Breaches key exists
        if (data.containsKey('Breaches')) {
          final breachesData = data['Breaches'];

          // The API returns breaches as a list of lists: [["Name1", ...], ["Name2", ...]]
          if (breachesData is List && breachesData.isNotEmpty) {
            List<BreachModel> breaches = [];

            for (var breach in breachesData) {
              if (breach is List && breach.isNotEmpty) {
                // First element is the breach name
                final breachName = breach[0] as String;
                breaches.add(BreachModel.fromName(breachName));
              }
            }

            return breaches;
          }
        }

        // If no breaches found in response
        return [];
      }

      // Handle other status codes
      if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      }

      throw Exception('Failed to check email: ${response.statusCode}');
    } catch (e) {
      print('Error checking breach: $e');

      // Return friendly error message
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please check your connection.');
      }

      rethrow;
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Mock data for testing/demos
  Future<List<BreachModel>> _getMockBreaches(String email) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Return mock breaches for demo
    if (email.contains('test')) {
      return [
        BreachModel(
          name: 'LinkedIn Data Breach 2021',
          description:
              'Professional data including email, name, and job information may be exposed.',
          riskLevel: 'high',
        ),
        BreachModel(
          name: 'Adobe Systems Breach 2013',
          description:
              'Account credentials and personal information likely compromised.',
          riskLevel: 'high',
        ),
        BreachModel(
          name: 'Dropbox Breach 2012',
          description:
              'Cloud storage credentials and potentially stored files exposed.',
          riskLevel: 'medium',
        ),
      ];
    }

    // Return empty list for other emails
    return [];
  }
}
