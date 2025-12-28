import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  ProgressNotifier() : super({}) {
    _loadProgress();
  }

  bool get isLoaded => _isLoaded;

  Future<void> _loadProgress() async {
    debugPrint(
      '🔄 PROGRESS LOAD: Starting to load progress from SharedPreferences...',
    );
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load from both old format (resource_) and new format (video_progress_)
      final allKeys = prefs.getKeys();
      debugPrint('🔄 PROGRESS LOAD: Found ${allKeys.length} total keys');
      debugPrint('🔄 PROGRESS LOAD: Keys = $allKeys');

      final Map<String, ResourceProgress> loaded = {};

      // Load old format: resource_{id}_completed
      final oldFormatKeys = allKeys.where(
        (key) => key.startsWith('resource_') && key.endsWith('_completed'),
      );

      for (final key in oldFormatKeys) {
        final resourceId = key
            .replaceFirst('resource_', '')
            .replaceFirst('_completed', '');
        final isCompleted = prefs.getBool(key) ?? false;
        final completedLessons =
            prefs.getInt('resource_${resourceId}_lessons') ?? 0;
        final minutesWatched =
            prefs.getInt('resource_${resourceId}_minutes') ?? 0;

        loaded[resourceId] = ResourceProgress(
          resourceId: resourceId,
          isCompleted: isCompleted,
          completedLessons: completedLessons,
          minutesWatched: minutesWatched,
        );
        debugPrint(
          '📦 Loaded resource progress: $resourceId, completed=$isCompleted',
        );
      }

      // Also load new format: video_progress_{id}_completed
      final newFormatKeys = allKeys.where(
        (key) =>
            key.startsWith('video_progress_') && key.endsWith('_completed'),
      );

      for (final key in newFormatKeys) {
        final resourceId = key
            .replaceFirst('video_progress_', '')
            .replaceFirst('_completed', '');

        // Only add if not already loaded from old format
        if (!loaded.containsKey(resourceId)) {
          final isCompleted = prefs.getBool(key) ?? false;
          final percentage =
              prefs.getDouble('video_progress_${resourceId}_percentage') ?? 0.0;

          if (isCompleted || percentage > 0) {
            loaded[resourceId] = ResourceProgress(
              resourceId: resourceId,
              isCompleted: isCompleted,
              completedLessons: isCompleted ? 245 : (percentage * 2.45).round(),
              minutesWatched:
                  prefs.getInt('video_progress_${resourceId}_duration') ?? 0,
            );
            debugPrint(
              '📦 Loaded video progress: $resourceId, completed=$isCompleted, percentage=$percentage',
            );
          }
        }
      }

      debugPrint(
        '✅ PROGRESS LOAD: Loaded ${loaded.length} resources: ${loaded.keys.toList()}',
      );
      state = loaded;
      _isLoaded = true;
    } catch (e) {
      debugPrint('❌ Error loading progress: $e');
      _isLoaded = true; // Mark as loaded even on error
    }
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
