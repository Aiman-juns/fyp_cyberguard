import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/supabase_config.dart';

class ResourceProgress {
  final String resourceId;
  final bool isCompleted;
  final int completedLessons;
  final int totalLessons;
  final int minutesWatched; // Track watch time in minutes

  ResourceProgress({
    required this.resourceId,
    this.isCompleted = false,
    this.completedLessons = 0,
    this.totalLessons = 245, // Default total lessons
    this.minutesWatched = 0,
  });

  double get progressPercentage {
    if (totalLessons == 0) return 0.0;
    return (completedLessons / totalLessons) * 100;
  }

  ResourceProgress copyWith({
    bool? isCompleted,
    int? completedLessons,
    int? totalLessons,
    int? minutesWatched,
  }) {
    return ResourceProgress(
      resourceId: resourceId,
      isCompleted: isCompleted ?? this.isCompleted,
      completedLessons: completedLessons ?? this.completedLessons,
      totalLessons: totalLessons ?? this.totalLessons,
      minutesWatched: minutesWatched ?? this.minutesWatched,
    );
  }
}

class ProgressNotifier extends StateNotifier<Map<String, ResourceProgress>> {
  bool _isLoaded = false;
  String? _currentUserId;

  ProgressNotifier() : super({}) {
    _loadProgress();
    _setupAuthListener();
  }

  bool get isLoaded => _isLoaded;

  /// Listen for auth state changes and reload progress when user changes
  void _setupAuthListener() {
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      final newUserId = data.session?.user.id;
      
      debugPrint('🔄 AUTH STATE CHANGE: Old user: $_currentUserId, New user: $newUserId');
      
      // If user changed (login/logout/switch), reload progress
      if (newUserId != _currentUserId) {
        _currentUserId = newUserId;
        debugPrint('🔄 USER CHANGED: Reloading progress...');
        _isLoaded = false;
        state = {}; // Clear cache immediately
        _loadProgress();
      }
    });
  }


  Future<void> _loadProgress() async {
    debugPrint(
      '🔄 PROGRESS LOAD: Loading progress from database ONLY...',
    );
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      
      if (userId == null) {
        debugPrint('⚠️ PROGRESS LOAD: User not logged in');
        state = {};
        _isLoaded = true;
        return;
      }

      debugPrint('🔄 PROGRESS LOAD: Loading from video_progress table for user: $userId');
      
      final response = await SupabaseConfig.client
          .from('video_progress')
          .select()
          .eq('user_id', userId);

      final Map<String, ResourceProgress> loaded = {};

      for (final item in response as List<dynamic>) {
        final resourceId = item['resource_id'] as String;
        final percentage = (item['watch_percentage'] as num).toDouble();
        final completed = item['completed'] as bool;
        final duration = item['watch_duration_seconds'] as int;

        loaded[resourceId] = ResourceProgress(
          resourceId: resourceId,
          isCompleted: completed,
          completedLessons: completed ? 245 : (percentage * 2.45).round(),
          minutesWatched: (duration / 60).round(),
        );
      }

      debugPrint(
        '✅ PROGRESS LOAD: Loaded ${loaded.length} resources from DB: ${loaded.keys.toList()}',
      );
      state = loaded;
      _isLoaded = true;
    } catch (e) {
      debugPrint('❌ Error loading progress from database: $e');
      state = {}; // Clear state on error - no fallback
      _isLoaded = true;
    }
  }


  /// Force reload progress (call this when user logs in)
  Future<void> reload() async {
    debugPrint('🔄 PROGRESS: Force reloading progress...');
    _isLoaded = false;
    state = {}; // Clear current state
    await _loadProgress();
  }

  /// Clear all progress (call this on logout)
  void clear() {
    debugPrint('🧹 PROGRESS: Clearing progress state...');
    state = {};
    _isLoaded = false;
  }


  Future<void> _saveProgress(
    String resourceId,
    ResourceProgress progress,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        'resource_${resourceId}_completed',
        progress.isCompleted,
      );
      await prefs.setInt(
        'resource_${resourceId}_lessons',
        progress.completedLessons,
      );
      await prefs.setInt(
        'resource_${resourceId}_minutes',
        progress.minutesWatched,
      );

      // Also save in video_progress format for cross-compatibility
      await prefs.setDouble(
        'video_progress_${resourceId}_percentage',
        progress.isCompleted ? 100.0 : progress.progressPercentage,
      );
      await prefs.setBool(
        'video_progress_${resourceId}_completed',
        progress.isCompleted,
      );

      debugPrint(
        '💾 Saved progress for $resourceId: completed=${progress.isCompleted}, lessons=${progress.completedLessons}',
      );
    } catch (e) {
      debugPrint('❌ Error saving progress: $e');
    }
  }

  void markAsComplete(String resourceId) {
    debugPrint('✅ MARKING COMPLETE: $resourceId');
    final current =
        state[resourceId] ?? ResourceProgress(resourceId: resourceId);
    final updated = current.copyWith(
      isCompleted: true,
      completedLessons: current.totalLessons,
    );
    state = {...state, resourceId: updated};
    _saveProgress(resourceId, updated);
  }

  void updateProgress(String resourceId, int completed, int total) {
    final updated = ResourceProgress(
      resourceId: resourceId,
      completedLessons: completed,
      totalLessons: total,
    );
    state = {...state, resourceId: updated};
    _saveProgress(resourceId, updated);
  }

  void updateWatchTime(String resourceId, int minutes) {
    final current =
        state[resourceId] ?? ResourceProgress(resourceId: resourceId);
    final updated = current.copyWith(minutesWatched: minutes);
    state = {...state, resourceId: updated};
    _saveProgress(resourceId, updated);
  }

  void addWatchTime(String resourceId, Duration watched) {
    final current =
        state[resourceId] ?? ResourceProgress(resourceId: resourceId);
    final newMinutes = current.minutesWatched + watched.inMinutes;
    final updated = current.copyWith(minutesWatched: newMinutes);
    state = {...state, resourceId: updated};
    _saveProgress(resourceId, updated);
  }

  ResourceProgress getProgress(String resourceId) {
    return state[resourceId] ??
        ResourceProgress(resourceId: resourceId, totalLessons: 245);
  }
}

final progressProvider =
    StateNotifierProvider<ProgressNotifier, Map<String, ResourceProgress>>((
      ref,
    ) {
      return ProgressNotifier();
    });

final resourceProgressProvider = Provider.family<ResourceProgress, String>((
  ref,
  resourceId,
) {
  final allProgress = ref.watch(progressProvider);
  return allProgress[resourceId] ??
      ResourceProgress(resourceId: resourceId, totalLessons: 245);
});
