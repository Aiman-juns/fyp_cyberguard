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
  ProgressNotifier() : super({}) {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
      (key) => key.startsWith('resource_') && key.endsWith('_completed'),
    );
    final Map<String, ResourceProgress> loaded = {};

    for (final key in keys) {
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
    }

    if (loaded.isNotEmpty) {
      state = loaded;
    }
  }

  Future<void> _saveProgress(
    String resourceId,
    ResourceProgress progress,
  ) async {
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
  }

  void markAsComplete(String resourceId) {
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
