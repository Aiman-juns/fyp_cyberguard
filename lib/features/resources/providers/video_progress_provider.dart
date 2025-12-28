import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/supabase_config.dart';
import '../models/video_progress_model.dart';

class VideoProgressNotifier
    extends StateNotifier<AsyncValue<VideoProgressModel?>> {
  // Use SupabaseConfig.client consistently with rest of app
  SupabaseClient get _supabase => SupabaseConfig.client;

  VideoProgressNotifier() : super(const AsyncValue.data(null));

  /// Update video progress
  Future<void> updateProgress({
    required String resourceId,
    required double watchPercentage,
    required int watchDurationSeconds,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('❌ VIDEO PROGRESS: User not logged in!');
      // Still save to SharedPreferences even if not logged in
      await _saveToLocalStorage(
        resourceId,
        watchPercentage,
        watchDurationSeconds,
      );
      return;
    }

    debugPrint('📹 VIDEO PROGRESS: Saving progress for resource: $resourceId');
    debugPrint('📹 VIDEO PROGRESS: User ID: $userId');
    debugPrint('📹 VIDEO PROGRESS: Watch %: $watchPercentage');

    final isCompleted = watchPercentage >= 90;

    // ALWAYS save to SharedPreferences first (local backup)
    await _saveToLocalStorage(
      resourceId,
      watchPercentage,
      watchDurationSeconds,
    );

    try {
      state = const AsyncValue.loading();

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

      // Try database save
      final response = await _supabase
          .from('video_progress')
          .upsert(data, onConflict: 'user_id,resource_id')
          .select();

      debugPrint('✅ VIDEO PROGRESS: Database saved! Response: $response');

      // Update state with saved progress
      final progress = VideoProgressModel(
        id: '',
        resourceId: resourceId,
        userId: userId,
        watchPercentage: watchPercentage,
        watchDurationSeconds: watchDurationSeconds,
        completed: isCompleted,
      );
      state = AsyncValue.data(progress);
    } catch (e) {
      debugPrint('❌ VIDEO PROGRESS DATABASE ERROR: $e');
      // Don't fail - we still have local storage
      // Update state from local storage instead
      await _loadFromLocalStorage(resourceId);
    }
  }

  /// Save progress to SharedPreferences (local backup)
  Future<void> _saveToLocalStorage(
    String resourceId,
    double watchPercentage,
    int watchDurationSeconds,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(
        'video_progress_${resourceId}_percentage',
        watchPercentage,
      );
      await prefs.setInt(
        'video_progress_${resourceId}_duration',
        watchDurationSeconds,
      );
      await prefs.setBool(
        'video_progress_${resourceId}_completed',
        watchPercentage >= 90,
      );
      debugPrint(
        '💾 LOCAL STORAGE: Saved progress for $resourceId: $watchPercentage%',
      );
    } catch (e) {
      debugPrint('❌ LOCAL STORAGE ERROR: $e');
    }
  }

  /// Load progress from SharedPreferences
  Future<void> _loadFromLocalStorage(String resourceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final percentage =
          prefs.getDouble('video_progress_${resourceId}_percentage') ?? 0.0;
      final duration =
          prefs.getInt('video_progress_${resourceId}_duration') ?? 0;
      final completed =
          prefs.getBool('video_progress_${resourceId}_completed') ?? false;

      if (percentage > 0) {
        debugPrint(
          '💾 LOCAL STORAGE: Loaded progress for $resourceId: $percentage%',
        );
        final progress = VideoProgressModel(
          id: 'local',
          resourceId: resourceId,
          userId: _supabase.auth.currentUser?.id ?? '',
          watchPercentage: percentage,
          watchDurationSeconds: duration,
          completed: completed,
        );
        state = AsyncValue.data(progress);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      debugPrint('❌ LOCAL STORAGE LOAD ERROR: $e');
      state = const AsyncValue.data(null);
    }
  }

  /// Get video progress for a specific resource
  Future<void> getProgress(String resourceId) async {
    final userId = _supabase.auth.currentUser?.id;

    // Try database first if logged in
    if (userId != null) {
      try {
        state = const AsyncValue.loading();

        debugPrint(
          '📹 GET PROGRESS: Fetching for resource: $resourceId, user: $userId',
        );

        final response = await _supabase
            .from('video_progress')
            .select()
            .eq('user_id', userId)
            .eq('resource_id', resourceId)
            .maybeSingle();

        debugPrint('📹 GET PROGRESS: Database response: $response');

        if (response != null) {
          final progress = VideoProgressModel.fromJson(response);
          debugPrint(
            '✅ GET PROGRESS: Found in DB: ${progress.watchPercentage}%',
          );
          state = AsyncValue.data(progress);
          return;
        }
      } catch (e) {
        debugPrint('❌ GET PROGRESS DATABASE ERROR: $e');
        // Fall through to local storage
      }
    }

    // Fallback to local storage
    debugPrint('📹 GET PROGRESS: Trying local storage for $resourceId');
    await _loadFromLocalStorage(resourceId);
  }

  /// Get all completed videos for user
  Future<List<VideoProgressModel>> getCompletedVideos() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('video_progress')
          .select('*, resources(*)')
          .eq('user_id', userId)
          .eq('completed', true)
          .order('updated_at', ascending: false);

      return response
          .map<VideoProgressModel>((json) => VideoProgressModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load completed videos: $e');
    }
  }

  /// Mark video as completed (90%+ watched)
  Future<void> markCompleted(String resourceId) async {
    // Immediately update state to show 100% (optimistic update)
    final userId = _supabase.auth.currentUser?.id ?? '';
    state = AsyncValue.data(
      VideoProgressModel(
        id: 'pending',
        resourceId: resourceId,
        userId: userId,
        watchPercentage: 100.0,
        watchDurationSeconds: 0,
        completed: true,
      ),
    );

    // Then save to database and local storage
    await updateProgress(
      resourceId: resourceId,
      watchPercentage: 100.0,
      watchDurationSeconds: 0,
    );
  }
}

// Provider for video progress
final videoProgressProvider =
    StateNotifierProvider.family<
      VideoProgressNotifier,
      AsyncValue<VideoProgressModel?>,
      String
    >((ref, resourceId) {
      final notifier = VideoProgressNotifier();
      notifier.getProgress(resourceId);
      return notifier;
    });

// Provider for completed videos list
final completedVideosProvider = FutureProvider<List<VideoProgressModel>>((
  ref,
) async {
  final notifier = VideoProgressNotifier();
  return notifier.getCompletedVideos();
});
