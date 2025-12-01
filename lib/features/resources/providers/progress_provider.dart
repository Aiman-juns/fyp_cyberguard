import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  ProgressNotifier() : super({});

  void markAsComplete(String resourceId) {
    final current = state[resourceId] ?? ResourceProgress(resourceId: resourceId);
    state = {
      ...state,
      resourceId: current.copyWith(
        isCompleted: true,
        completedLessons: current.totalLessons, // Set to 100%
      ),
    };
  }

  void updateProgress(String resourceId, int completed, int total) {
    state = {
      ...state,
      resourceId: ResourceProgress(
        resourceId: resourceId,
        completedLessons: completed,
        totalLessons: total,
      ),
    };
  }

  void updateWatchTime(String resourceId, int minutes) {
    final current = state[resourceId] ?? ResourceProgress(resourceId: resourceId);
    state = {
      ...state,
      resourceId: current.copyWith(minutesWatched: minutes),
    };
  }

  void addWatchTime(String resourceId, Duration watched) {
    final current = state[resourceId] ?? ResourceProgress(resourceId: resourceId);
    final newMinutes = current.minutesWatched + watched.inMinutes;
    state = {
      ...state,
      resourceId: current.copyWith(minutesWatched: newMinutes),
    };
  }

  ResourceProgress getProgress(String resourceId) {
    return state[resourceId] ??
        ResourceProgress(resourceId: resourceId, totalLessons: 245);
  }
}

final progressProvider =
    StateNotifierProvider<ProgressNotifier, Map<String, ResourceProgress>>((ref) {
  return ProgressNotifier();
});

final resourceProgressProvider =
    Provider.family<ResourceProgress, String>((ref, resourceId) {
  final allProgress = ref.watch(progressProvider);
  return allProgress[resourceId] ??
      ResourceProgress(resourceId: resourceId, totalLessons: 245);
});

