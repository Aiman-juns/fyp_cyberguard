import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
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
    // Get all user progress
    final progressResponse = await SupabaseConfig.client
        .from('user_progress')
        .select()
        .eq('user_id', userId)
        .order('attempt_date', ascending: false);

    final progressList = List<Map<String, dynamic>>.from(progressResponse);
    
    // Calculate total score from all progress records (same as profile page)
    int totalScore = 0;
    for (var progress in progressList) {
      totalScore += (progress['score_awarded'] as num?)?.toInt() ?? 0;
    }
    
    // Calculate level from total score (same as profile page)
    final level = _calculateLevelFromXP(totalScore);

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
    // Define all 10 achievements - NEW SYSTEM
    final allAchievements = [
      // TIER 1: BEGINNER
      Achievement(
        id: 'first_steps',
        badgeType: 'first_steps',
        title: 'First Steps',
        description: 'Complete 1 training question',
        iconType: IconType.trophy,
      ),
      Achievement(
        id: 'getting_started',
        badgeType: 'getting_started',
        title: 'Getting Started',
        description: 'Answer 5 questions correctly',
        iconType: IconType.flash,
      ),
      Achievement(
        id: 'module_explorer',
        badgeType: 'module_explorer',
        title: 'Module Explorer',
        description: 'Try 2 different training modules',
        iconType: IconType.star,
      ),
      
      // TIER 2: INTERMEDIATE
      Achievement(
        id: 'hot_streak',
        badgeType: 'hot_streak',
        title: 'Hot Streak',
        description: 'Answer 3 questions correctly in a row',
        iconType: IconType.rocket,
      ),
      Achievement(
        id: 'triple_threat',
        badgeType: 'triple_threat',
        title: 'Triple Threat',
        description: 'Complete at least 1 question in all 3 modules',
        iconType: IconType.verified,
      ),
      Achievement(
        id: 'cyber_defender',
        badgeType: 'cyber_defender',
        title: 'Cyber Defender',
        description: 'Reach Level 3',
        iconType: IconType.shield,
      ),
      
      // TIER 3: ADVANCED
      Achievement(
        id: 'knowledge_seeker',
        badgeType: 'knowledge_seeker',
        title: 'Knowledge Seeker',
        description: 'Answer 30 questions correctly',
        iconType: IconType.star,
      ),
      Achievement(
        id: 'security_expert',
        badgeType: 'security_expert',
        title: 'Security Expert',
        description: 'Complete 10 questions in each module',
        iconType: IconType.verified,
      ),
      Achievement(
        id: 'daily_warrior',
        badgeType: 'daily_warrior',
        title: 'Daily Warrior',
        description: 'Complete 10 daily challenges',
        iconType: IconType.flash,
      ),
      
      // VIDEO ACHIEVEMENTS
      Achievement(
        id: 'video_beginner',
        badgeType: 'video_beginner',
        title: 'Video Beginner',
        description: 'Watch your first resource video',
        iconType: IconType.star,
      ),
      Achievement(
        id: 'video_master',
        badgeType: 'video_master',
        title: 'Video Master',
        description: 'Complete all resource videos',
        iconType: IconType.verified,
      ),
      
      // TIER 4: MASTERY
      Achievement(
        id: 'cyberguard_champion',
        badgeType: 'cyberguard_champion',
        title: 'CyberGuard Champion',
        description: 'Reach Level 5',
        iconType: IconType.trophy,
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
    
    // Get daily challenge progress
    final dailyChallengeResponse = await SupabaseConfig.client
        .from('daily_challenge_progress')
        .select()
        .eq('user_id', userId)
        .eq('completed', true);
    
    final dailyChallengeCount = dailyChallengeResponse.length;
    
    // Get video progress for video achievements
    final videoProgressResponse = await SupabaseConfig.client
        .from('video_progress')
        .select()
        .eq('user_id', userId);
    
    final completedVideos = videoProgressResponse
        .where((v) => v['completed'] == true)
        .length;
    
    // Get total videos count from resources table
    final totalVideosResponse = await SupabaseConfig.client
        .from('resources')
        .select('id')
        .not('media_url', 'is', null);
    
    final totalVideos = totalVideosResponse.length;

    // Check each achievement
    final unlockedAchievements = <Achievement>[];

    for (final achievement in allAchievements) {
      bool isUnlocked = false;
      DateTime? earnedDate;

      switch (achievement.badgeType) {
        case 'first_steps':
          // Complete 1 question
          if (progress.isNotEmpty) {
            isUnlocked = true;
            earnedDate = DateTime.parse(progress.first['attempt_date'] as String);
          }
          break;

        case 'getting_started':
          // 5 correct answers
          final correctCount = progress.where((p) => p['is_correct'] == true).length;
          if (correctCount >= 5) {
            isUnlocked = true;
            // Find 5th correct answer date
            int count = 0;
            for (final p in progress) {
              if (p['is_correct'] == true) {
                count++;
                if (count == 5) {
                  earnedDate = DateTime.parse(p['attempt_date'] as String);
                  break;
                }
              }
            }
          }
          break;

        case 'module_explorer':
          // Try 2 different modules
          final modules = progress.map((p) => p['module_type']).toSet().length;
          if (modules >= 2) {
            isUnlocked = true;
            earnedDate = DateTime.parse(progress.first['attempt_date'] as String);
          }
          break;

        case 'hot_streak':
          // 3 correct in a row
          int streak = 0;
          int maxStreak = 0;
          for (final p in progress) {
            if (p['is_correct'] == true) {
              streak++;
              if (streak > maxStreak) {
                maxStreak = streak;
                if (maxStreak >= 3 && !isUnlocked) {
                  isUnlocked = true;
                  earnedDate = DateTime.parse(p['attempt_date'] as String);
                }
              }
            } else {
              streak = 0;
            }
          }
          break;

        case 'triple_threat':
          // All 3 modules
          final modules = progress.map((p) => p['module_type']).toSet().length;
          if (modules >= 3) {
            isUnlocked = true;
            earnedDate = DateTime.parse(progress.first['attempt_date'] as String);
          }
          break;

        case 'cyber_defender':
          // Level 3
          if (userLevel >= 3) {
            isUnlocked = true;
          }
          break;

        case 'knowledge_seeker':
          // 30 correct answers
          final correctCount = progress.where((p) => p['is_correct'] == true).length;
          if (correctCount >= 30) {
            isUnlocked = true;
            // Find 30th correct answer
            int count = 0;
            for (final p in progress) {
              if (p['is_correct'] == true) {
                count++;
                if (count == 30) {
                  earnedDate = DateTime.parse(p['attempt_date'] as String);
                  break;
                }
              }
            }
          }
          break;

        case 'security_expert':
          // 10 questions in each module
          final phishingCount = progress.where((p) => p['module_type'] == 'phishing').length;
          final passwordCount = progress.where((p) => p['module_type'] == 'password').length;
          final attackCount = progress.where((p) => p['module_type'] == 'attack').length;
          
          if (phishingCount >= 10 && passwordCount >= 10 && attackCount >= 10) {
            isUnlocked = true;
            earnedDate = DateTime.parse(progress.first['attempt_date'] as String);
          }
          break;

        case 'daily_warrior':
          // 10 daily challenges
          if (dailyChallengeCount >= 10) {
            isUnlocked = true;
          }
          break;

        case 'video_beginner':
          // Watch first video
          if (completedVideos >= 1) {
            isUnlocked = true;
          }
          break;

        case 'video_master':
          // Complete all videos
          if (totalVideos > 0 && completedVideos >= totalVideos) {
            isUnlocked = true;
          }
          break;

        case 'cyberguard_champion':
          // Level 5
          if (userLevel >= 5) {
            isUnlocked = true;
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
    debugPrint('❌ Error fetching achievements: $e');
    // Return empty achievements list on error
    return [];
  }
}

/// Calculate level from total XP (same formula as profile page)
int _calculateLevelFromXP(int xp) {
  int level = 1;
  while (_getXPRequiredForLevel(level + 1) <= xp) {
    level++;
  }
  return level;
}

/// Get XP required for a specific level
int _getXPRequiredForLevel(int level) {
  if (level == 1) return 0;
  return (level - 1) * 100 + ((level - 2) * (level - 1) ~/ 2) * 50;
}
