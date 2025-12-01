import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/supabase_config.dart';

/// News Model
class News {
  final String id;
  final String title;
  final String body;
  final String sourceUrl;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  News({
    required this.id,
    required this.title,
    required this.body,
    required this.sourceUrl,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      sourceUrl: json['source_url'] as String,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// Fetch all news from Supabase
Future<List<News>> fetchNews() async {
  try {
    final response = await SupabaseConfig.client
        .from('news')
        .select()
        .order('created_at', ascending: false);

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
