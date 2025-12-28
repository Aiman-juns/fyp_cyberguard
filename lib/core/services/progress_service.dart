import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressService {
  static final _supabase = Supabase.instance.client;

  /// Record video watching progress - saves directly to database
  static Future<void> updateVideoProgress({
    required String resourceId,
    required double watchPercentage,
    required int watchDurationSeconds,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final isCompleted = watchPercentage >= 90;

    // Use upsert to insert or update existing progress
    await _supabase.from('video_progress').upsert({
      'user_id': userId,
      'resource_id': resourceId,
      'watch_percentage': watchPercentage,
      'watch_duration_seconds': watchDurationSeconds,
      'completed': isCompleted,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,resource_id');
  }

  /// Get video progress for a resource
  static Future<Map<String, dynamic>?> getVideoProgress(
    String resourceId,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('video_progress')
        .select()
        .eq('user_id', userId)
        .eq('resource_id', resourceId)
        .maybeSingle();

    return response;
  }

  /// Get all completed videos for user
  static Future<List<Map<String, dynamic>>> getCompletedVideos() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('video_progress')
        .select()
        .eq('user_id', userId)
        .eq('completed', true)
        .order('updated_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Record daily challenge completion - saves directly to database
  static Future<void> recordDailyChallengeProgress({
    required String challengeId,
    required bool userAnswer,
    required bool isCorrect,
    int scoreAwarded = 0,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // Use upsert to handle replay on same day
    await _supabase.from('daily_challenge_progress').upsert({
      'user_id': userId,
      'challenge_id': challengeId,
      'completed': true,
      'completed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,challenge_id');
  }

  /// Get daily challenge progress for today
  static Future<Map<String, dynamic>?> getTodaysChallengeProgress() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final today = DateTime.now().toIso8601String().split('T')[0];

    final response = await _supabase
        .from('daily_challenge_progress')
        .select('*, daily_challenges(*)')
        .eq('user_id', userId)
        .gte('completed_at', '${today}T00:00:00Z')
        .lt('completed_at', '${today}T23:59:59Z')
        .maybeSingle();

    return response;
  }

  /// Get user's overall progress statistics
  static Future<Map<String, dynamic>> getUserProgressStats() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // Get video progress stats
    final videoStats = await _supabase
        .from('video_progress')
        .select('completed')
        .eq('user_id', userId);

    final totalVideos = videoStats.length;
    final completedVideos = videoStats
        .where((v) => v['completed'] == true)
        .length;

    // Get daily challenge stats
    final challengeStats = await _supabase
        .from('daily_challenge_progress')
        .select('completed')
        .eq('user_id', userId);

    final totalChallenges = challengeStats.length;

    return {
      'video_progress': {
        'total': totalVideos,
        'completed': completedVideos,
        'completion_rate': totalVideos > 0
            ? (completedVideos / totalVideos * 100).round()
            : 0,
      },
      'daily_challenges': {'total': totalChallenges},
    };
  }
}
