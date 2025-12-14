import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../config/supabase_config.dart';

class NewsService {
  static const String newsDataApiUrl = 'https://newsdata.io/api/1/news';
  
  /// Fetch and cache cybersecurity news
  static Future<void> fetchAndCacheNews() async {
    try {
      List<Map<String, dynamic>> articles = [];

      // Try NewsData.io API first
      final newsDataKey = dotenv.env['NEWSDATA_API_KEY'] ?? '';
      if (newsDataKey.isNotEmpty) {
        articles = await _fetchFromNewsData(newsDataKey);
      }

      // Fallback to GDELT if no results
      if (articles.isEmpty) {
        articles = await _fetchFromGDELT();
      }

      // Insert/update in Supabase
      if (articles.isNotEmpty) {
        await _cacheInSupabase(articles);
      }
    } catch (e) {
      print('Error fetching news: $e');
      throw Exception('Failed to fetch news: $e');
    }
  }

  /// Fetch from NewsData.io API
  static Future<List<Map<String, dynamic>>> _fetchFromNewsData(
      String apiKey) async {
    try {
      // Search for cybersecurity news in Malaysia
      final url = Uri.parse(
        '$newsDataApiUrl?apikey=$apiKey&country=my&q=cyber OR scam OR ransomware OR phishing&language=en',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>?;

        if (results != null && results.isNotEmpty) {
          return results.map((article) {
            return {
              'title': article['title'] ?? 'No Title',
              'summary':
                  article['description'] ?? article['content'] ?? 'No description available',
              'source': article['source_id'] ?? 'Unknown Source',
              'url': article['link'] ?? '',
              'published_at': article['pubDate'] ?? DateTime.now().toIso8601String(),
              'category': _categorizeArticle(article['title'] ?? ''),
              'image_url': article['image_url'],
            };
          }).toList();
        }
      }
    } catch (e) {
      print('NewsData.io error: $e');
    }
    return [];
  }

  /// Fallback: Fetch from GDELT API
  static Future<List<Map<String, dynamic>>> _fetchFromGDELT() async {
    try {
      // GDELT API for cybersecurity news
      final url = Uri.parse(
        'https://api.gdeltproject.org/api/v2/doc/doc?query=(cybersecurity OR cyber%20attack OR scam OR ransomware OR phishing)%20sourcelang:eng&mode=artlist&maxrecords=20&format=json',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final articles = data['articles'] as List<dynamic>?;

        if (articles != null && articles.isNotEmpty) {
          return articles.map((article) {
            return {
              'title': article['title'] ?? 'No Title',
              'summary': article['seendate'] != null
                  ? 'Published: ${article['seendate']}'
                  : 'Cybersecurity news article',
              'source': article['domain'] ?? 'GDELT',
              'url': article['url'] ?? '',
              'published_at': article['seendate'] != null
                  ? _parseGDELTDate(article['seendate'])
                  : DateTime.now().toIso8601String(),
              'category': _categorizeArticle(article['title'] ?? ''),
              'image_url': article['socialimage'],
            };
          }).toList();
        }
      }
    } catch (e) {
      print('GDELT error: $e');
    }
    return [];
  }

  /// Parse GDELT date format (YYYYMMDDHHMMSS)
  static String _parseGDELTDate(String gdeltDate) {
    try {
      if (gdeltDate.length >= 8) {
        final year = gdeltDate.substring(0, 4);
        final month = gdeltDate.substring(4, 6);
        final day = gdeltDate.substring(6, 8);
        return '$year-$month-${day}T00:00:00Z';
      }
    } catch (e) {
      print('Date parse error: $e');
    }
    return DateTime.now().toIso8601String();
  }

  /// Auto-categorize article based on keywords
  static String _categorizeArticle(String title) {
    final titleLower = title.toLowerCase();

    if (titleLower.contains('scam') ||
        titleLower.contains('fraud') ||
        titleLower.contains('phishing')) {
      return 'Scam';
    } else if (titleLower.contains('ransomware') ||
        titleLower.contains('malware') ||
        titleLower.contains('virus')) {
      return 'Ransomware';
    } else if (titleLower.contains('data breach') ||
        titleLower.contains('leak') ||
        titleLower.contains('hack')) {
      return 'Data Breach';
    } else if (titleLower.contains('attack') || titleLower.contains('threat')) {
      return 'Cyber Attack';
    } else {
      return 'General';
    }
  }

  /// Cache articles in Supabase
  static Future<void> _cacheInSupabase(
      List<Map<String, dynamic>> articles) async {
    try {
      for (var article in articles) {
        // Check if article already exists (by URL)
        final existing = await SupabaseConfig.client
            .from('news')
            .select('id')
            .eq('url', article['url'])
            .maybeSingle();

        if (existing == null) {
          // Insert new article
          await SupabaseConfig.client.from('news').insert({
            'title': article['title'],
            'summary': article['summary'],
            'source': article['source'],
            'url': article['url'],
            'published_at': article['published_at'],
            'category': article['category'],
            'image_url': article['image_url'],
          });
        }
      }
    } catch (e) {
      print('Supabase cache error: $e');
      throw Exception('Failed to cache news: $e');
    }
  }
}
