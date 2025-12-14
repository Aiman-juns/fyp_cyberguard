import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/supabase_config.dart';
import '../services/news_service.dart';

/// News Model (Updated)
class News {
  final String id;
  final String title;
  final String summary;
  final String source;
  final String url;
  final DateTime publishedAt;
  final String category;
  final String? imageUrl;

  News({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.url,
    required this.publishedAt,
    required this.category,
    this.imageUrl,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      source: json['source'] as String,
      url: json['url'] as String,
      publishedAt: DateTime.parse(json['published_at'] as String),
      category: json['category'] as String? ?? 'General',
      imageUrl: json['image_url'] as String?,
    );
  }
}

/// Fetch all news from Supabase (cached)
Future<List<News>> fetchNews() async {
  try {
    final response = await SupabaseConfig.client
        .from('news')
        .select()
        .order('published_at', ascending: false)
        .limit(50);

    return (response as List<dynamic>)
        .map((json) => News.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    throw Exception('Failed to fetch news: $e');
  }
}

/// Fetch single news by ID
Future<News> fetchNewsById(String id) async {
  try {
    final response = await SupabaseConfig.client
        .from('news')
        .select()
        .eq('id', id)
        .single();

    return News.fromJson(response as Map<String, dynamic>);
  } catch (e) {
    throw Exception('Failed to fetch news: $e');
  }
}

/// Riverpod provider for news list
final newsProvider = FutureProvider<List<News>>((ref) async {
  return fetchNews();
});

/// Riverpod provider for single news
final newsItemProvider = FutureProvider.family<News, String>((ref, id) async {
  return fetchNewsById(id);
});

/// Provider to refresh news from external APIs
final refreshNewsProvider = FutureProvider<void>((ref) async {
  await NewsService.fetchAndCacheNews();
  // Invalidate news provider to refetch from Supabase
  ref.invalidate(newsProvider);
});
