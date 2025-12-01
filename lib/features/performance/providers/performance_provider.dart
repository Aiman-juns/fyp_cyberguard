import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/supabase_config.dart';
import '../../../auth/providers/auth_provider.dart';

/// Achievement Model
class Achievement {
  final String id;
  final String badgeType; // 'first_steps', 'quick_learner', 'expert', etc.
  final String title;
  final String description;
  final IconType iconType;
  final DateTime? earnedAt;

  Achievement({
    required this.id,
    required this.badgeType,
    required this.title,
    required this.description,
    required this.iconType,
    this.earnedAt,
  });

  bool get isUnlocked => earnedAt != null;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      badgeType: json['badge_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconType: IconType.values.firstWhere(
        (e) => e.toString() == 'IconType.${json['icon_type']}',
        orElse: () => IconType.star,
      ),
      earnedAt: json['earned_at'] != null
          ? DateTime.parse(json['earned_at'] as String)
          : null,
    );
  }
}

enum IconType { trophy, flash, verified, star, shield, rocket }

/// Performance Stats Model
class PerformanceStats {
  final int totalScore;
  final int level;
  final int totalAttempts;
  final int correctAnswers;
  final double accuracyPercentage;
  final Map<String, ModuleStats> moduleStats;
  final List<Achievement> achievements;
  final DateTime? lastAttemptDate;

  PerformanceStats({
    required this.totalScore,
    required this.level,
    required this.totalAttempts,
    required this.correctAnswers,
    required this.accuracyPercentage,
    required this.moduleStats,
    required this.achievements,
    this.lastAttemptDate,
  });
}

/// Module-specific stats
class ModuleStats {
  final String moduleName; // 'phishing', 'password', 'attack'
  final int attempts;
  final int correct;
  final int totalScore;
  final double accuracy;
  final double completionPercentage;
  final int highestDifficultyCompleted;

  ModuleStats({
    required this.moduleName,
    required this.attempts,
    required this.correct,
    required this.totalScore,
    required this.accuracy,
    required this.completionPercentage,
    required this.highestDifficultyCompleted,
  });
}

/// Performance Provider - Fetch user performance stats
final performanceProvider = FutureProvider<PerformanceStats>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) throw Exception('User not authenticated');

  return fetchUserPerformanceStats(currentUser.id);
});

/// Achievements Provider - Fetch user achievements
final userAchievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) throw Exception('User not authenticated');

  return fetchUserAchievements(currentUser.id);
});

/// Module stats provider - Get stats for specific module
final moduleStatsProvider = FutureProvider.family<ModuleStats, String>((
  ref,
  moduleType,
) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) throw Exception('User not authenticated');

  return calculateModuleStats(currentUser.id, moduleType);
});

/// Fetch comprehensive performance stats
Future<PerformanceStats> fetchUserPerformanceStats(String userId) async {
  try {
    // Get user data
    final userResponse = await SupabaseConfig.client
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    final totalScore = (userResponse['total_score'] ?? 0) as int;
    final level = (userResponse['level'] ?? 1) as int;

    // Get all user progress
    final progressResponse = await SupabaseConfig.client
        .from('user_progress')
        .select()
        .eq('user_id', userId)
        .order('attempt_date', ascending: false);

    final progressList = List<Map<String, dynamic>>.from(progressResponse);
    final totalAttempts = progressList.length;
    final correctAnswers = progressList
        .where((p) => p['is_correct'] == true)
        .length;
    final accuracyPercentage = totalAttempts > 0
        ? (correctAnswers / totalAttempts * 100)
        : 0.0;
    final lastAttemptDate = progressList.isNotEmpty
        ? DateTime.parse(progressList.first['attempt_date'] as String)
        : null;

    // Calculate module stats
    final moduleStats = <String, ModuleStats>{};
    for (final module in ['phishing', 'password', 'attack']) {
      moduleStats[module] = await calculateModuleStats(userId, module);
    }

    // Get user achievements
    final achievements = await fetchUserAchievements(userId);

    return PerformanceStats(
      totalScore: totalScore,
      level: level,
      totalAttempts: totalAttempts,
      correctAnswers: correctAnswers,
      accuracyPercentage: accuracyPercentage,
      moduleStats: moduleStats,
      achievements: achievements,
      lastAttemptDate: lastAttemptDate,
    );
  } catch (e) {
    throw Exception('Failed to fetch performance stats: $e');
  }
}

/// Calculate stats for a specific module
Future<ModuleStats> calculateModuleStats(
  String userId,
  String moduleType,
) async {
  try {
    // Get all questions for the module
    final questionsResponse = await SupabaseConfig.client
        .from('questions')
        .select()
        .eq('module_type', moduleType);

    final allQuestions = List<Map<String, dynamic>>.from(questionsResponse);

    // Get all user progress for this user
    final progressResponse = await SupabaseConfig.client
        .from('user_progress')
        .select()
        .eq('user_id', userId);

    final allProgress = List<Map<String, dynamic>>.from(progressResponse);

    // Filter to just this module's attempts
    final questionIds = allQuestions.map((q) => q['id'] as String).toSet();
    final moduleProgress = allProgress
        .where((p) => questionIds.contains(p['question_id']))
        .toList();

    // Calculate stats
    final attempts = moduleProgress.length;
    final correct = moduleProgress.where((p) => p['is_correct'] == true).length;
    final totalScore = moduleProgress.fold<int>(
      0,
      (sum, p) => sum + (p['score_awarded'] as int? ?? 0),
    );
    final accuracy = attempts > 0 ? (correct / attempts * 100) : 0.0;

    // Calculate completion percentage
    final questionsAttempted = moduleProgress
        .map((p) => p['question_id'])
        .toSet()
        .length;
    final completionPercentage = allQuestions.isNotEmpty
        ? (questionsAttempted / allQuestions.length * 100)
        : 0.0;

    // Get highest difficulty completed
    int highestDifficulty = 0;
    if (moduleProgress.isNotEmpty) {
      highestDifficulty = moduleProgress
          .where((p) => p['is_correct'] == true)
          .fold<int>(0, (max, p) {
            final difficulty = p['questions']?['difficulty'] as int? ?? 0;
            return difficulty > max ? difficulty : max;
          });
    }

    return ModuleStats(
      moduleName: moduleType,
      attempts: attempts,
      correct: correct,
      totalScore: totalScore,
      accuracy: accuracy,
      completionPercentage: completionPercentage,
      highestDifficultyCompleted: highestDifficulty,
    );
  } catch (e) {
    // Return empty stats if module has no data
    return ModuleStats(
      moduleName: moduleType,
      attempts: 0,
      correct: 0,
      totalScore: 0,
      accuracy: 0.0,
      completionPercentage: 0.0,
      highestDifficultyCompleted: 0,
    );
  }
}

/// Fetch user achievements
Future<List<Achievement>> fetchUserAchievements(String userId) async {
  try {
    // Define all possible achievements
    final allAchievements = [
      Achievement(
        id: 'first_steps',
        badgeType: 'first_steps',
        title: 'First Steps',
        description: 'Complete your first quiz',
        iconType: IconType.trophy,
      ),
      Achievement(
        id: 'quick_learner',
        badgeType: 'quick_learner',
        title: 'Quick Learner',
        description: '10 correct answers',
        iconType: IconType.flash,
      ),
      Achievement(
        id: 'expert',
        badgeType: 'expert',
        title: 'Security Expert',
        description: 'Complete all modules',
        iconType: IconType.verified,
      ),
      Achievement(
        id: 'perfect_score',
        badgeType: 'perfect_score',
        title: 'Perfect Score',
        description: '100% accuracy in a module',
        iconType: IconType.star,
      ),
      Achievement(
        id: 'defender',
        badgeType: 'defender',
        title: 'Defender',
        description: 'Reach level 5+',
        iconType: IconType.shield,
      ),
      Achievement(
        id: 'speedrunner',
        badgeType: 'speedrunner',
        title: 'Speedrunner',
        description: 'Answer 5 questions in 1 minute',
        iconType: IconType.rocket,
      ),
    ];

    // Fetch user progress to check achievements
    final progressResponse = await SupabaseConfig.client
        .from('user_progress')
        .select()
        .eq('user_id', userId);

    final progress = List<Map<String, dynamic>>.from(progressResponse);

    // Get user data for level
    final userResponse = await SupabaseConfig.client
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    final userLevel = (userResponse['level'] ?? 1) as int;

    // Check each achievement
    final unlockedAchievements = <Achievement>[];

    for (final achievement in allAchievements) {
      bool isUnlocked = false;
      DateTime? earnedDate;

      switch (achievement.badgeType) {
        case 'first_steps':
          if (progress.isNotEmpty) {
            isUnlocked = true;
            earnedDate = DateTime.parse(
              progress.first['attempt_date'] as String,
            );
          }
          break;

        case 'quick_learner':
          final correctCount = progress
              .where((p) => p['is_correct'] == true)
              .length;
          if (correctCount >= 10) {
            isUnlocked = true;
            // Find when 10th correct answer was reached
            int count = 0;
            for (final p in progress) {
              if (p['is_correct'] == true) {
                count++;
                if (count == 10) {
                  earnedDate = DateTime.parse(p['attempt_date'] as String);
                  break;
                }
              }
            }
          }
          break;

        case 'expert':
          // Check if user completed all 3 modules
          final modules = progress.map((p) => p['module_type']).toSet().length;
          if (modules >= 3) {
            isUnlocked = true;
            earnedDate = DateTime.parse(
              progress.first['attempt_date'] as String,
            );
          }
          break;

        case 'perfect_score':
          // Check for 100% accuracy in any module
          for (final module in ['phishing', 'password', 'attack']) {
            final moduleProgress = progress
                .where((p) => p['module_type'] == module)
                .toList();
            if (moduleProgress.isNotEmpty) {
              final accuracy =
                  moduleProgress.where((p) => p['is_correct'] == true).length /
                  moduleProgress.length;
              if (accuracy == 1.0) {
                isUnlocked = true;
                earnedDate = DateTime.parse(
                  moduleProgress.first['attempt_date'] as String,
                );
                break;
              }
            }
          }
          break;

        case 'defender':
          if (userLevel >= 5) {
            isUnlocked = true;
          }
          break;

        case 'speedrunner':
          // Check if 5 questions answered within 1 minute
          if (progress.length >= 5) {
            for (int i = 4; i < progress.length; i++) {
              final startTime = DateTime.parse(
                progress[i]['attempt_date'] as String,
              );
              final endTime = DateTime.parse(
                progress[i - 4]['attempt_date'] as String,
              );
              if (endTime.difference(startTime).inSeconds <= 60) {
                isUnlocked = true;
                earnedDate = startTime;
                break;
              }
            }
          }
          break;
      }

      if (isUnlocked) {
        unlockedAchievements.add(
          Achievement(
            id: achievement.id,
            badgeType: achievement.badgeType,
            title: achievement.title,
            description: achievement.description,
            iconType: achievement.iconType,
            earnedAt: earnedDate,
          ),
        );
      }
    }

    // Return all achievements with unlocked status
    return allAchievements.map((achievement) {
      final unlocked = unlockedAchievements.firstWhere(
        (a) => a.badgeType == achievement.badgeType,
        orElse: () => achievement,
      );
      return unlocked;
    }).toList();
  } catch (e) {
    // Return empty achievements list on error
    return [];
  }
}
