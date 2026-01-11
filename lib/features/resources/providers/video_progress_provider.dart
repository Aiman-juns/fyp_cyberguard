import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_config.dart';
import '../models/video_progress_model.dart';

// Helper functions for video progress
class VideoProgressService {
  static SupabaseClient get _supabase => SupabaseConfig.client;

  /// Update video progress - DATABASE FIRST, then SharedPreferences as backup
  static Future<void> updateProgress({
    required String resourceId,
    required double watchPercentage,
    required int watchDurationSeconds,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('❌ VIDEO PROGRESS: User not logged in!');
      return;
    }

    debugPrint('📹 VIDEO PROGRESS: Saving progress for resource: $resourceId');
    debugPrint('📹 VIDEO PROGRESS: User ID: $userId');
    debugPrint('📹 VIDEO PROGRESS: Watch %: $watchPercentage');

    final isCompleted = watchPercentage >= 90;

    try {
      final now = DateTime.now().toIso8601String();

      final data = {
        'user_id': userId,
        'resource_id': resourceId,
        'watch_percentage': watchPercentage,
        'watch_duration_seconds': watchDurationSeconds,
        'completed': isCompleted,
        'updated_at': now,
      };

      debugPrint('📹 VIDEO PROGRESS: Data to save: $data');

      // Save to Supabase database ONLY (no SharedPreferences backup)
      final response = await _supabase
          .from('video_progress')
          .upsert(data, onConflict: 'user_id,resource_id')
          .select();

      debugPrint('✅ VIDEO PROGRESS: Database saved! Response: $response');
    } catch (e) {
      debugPrint('❌ VIDEO PROGRESS DATABASE ERROR: $e');
      rethrow; // Throw error if database fails - no fallback
    }
  }

  /// Load progress from database ONLY (no SharedPreferences fallback)
  static Future<VideoProgressModel?> loadProgress(String resourceId) async {
    debugPrint('🔍 VIDEO PROGRESS: loadProgress called for: $resourceId');

    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      debugPrint('❌ LOAD PROGRESS: User not logged in!');
      return null;
    }

    try {
      debugPrint(
        '📹 LOAD PROGRESS: Fetching from DB for resource: $resourceId, user: $userId',
      );

      final response = await _supabase
          .from('video_progress')
          .select()
          .eq('user_id', userId)
          .eq('resource_id', resourceId)
          .maybeSingle();

      debugPrint('📹 LOAD PROGRESS: Database response: $response');

      if (response != null) {
        final progress = VideoProgressModel.fromJson(response);
        debugPrint(
          '✅ LOAD PROGRESS: Found in DB: ${progress.watchPercentage}%',
        );
        return progress;
      }

      debugPrint('📹 LOAD PROGRESS: No data found in database');
      return null;
    } catch (e) {
      debugPrint('❌ LOAD PROGRESS DATABASE ERROR: $e');
      rethrow; // Throw error - no fallback
    }
  }

  /// Get all completed videos for user
  static Future<List<VideoProgressModel>> getCompletedVideos() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('video_progress')
          .select('*, resources(*)')
          .eq('user_id', userId)
          .eq('completed', true)
          .order('updated_at', ascending: false);

      return (response as List<dynamic>)
          .map(
            (json) => VideoProgressModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching completed videos: $e');
      return [];
    }
  }
}

// Provider for video progress - loads from Supabase database first
// Removed autoDispose to maintain cache and prevent unnecessary reloads
final videoProgressProvider =
    FutureProvider.family<VideoProgressModel?, String>((ref, resourceId) async {
      debugPrint(
        '🔄 VIDEO PROGRESS PROVIDER: Loading for resource: $resourceId',
      );
      return VideoProgressService.loadProgress(resourceId);
    });

// Provider for completed videos list
final completedVideosProvider =
    FutureProvider.autoDispose<List<VideoProgressModel>>((ref) async {
      return VideoProgressService.getCompletedVideos();
    });
