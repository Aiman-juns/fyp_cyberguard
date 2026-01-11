import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/supabase_config.dart';
import '../../../auth/providers/auth_provider.dart';

// Models
class ProfileAnalytics {
  final int totalXP;
  final int currentLevel;
  final int xpForNextLevel;
  final DailyProgress dailyProgress;
  final WeeklyProgress weeklyProgress;
  final ModulePerformance? strongestModule;
  final ModulePerformance? weakestModule;
  final List<ActivityEntry> recentActivity;

  ProfileAnalytics({
    required this.totalXP,
    required this.currentLevel,
    required this.xpForNextLevel,
    required this.dailyProgress,
    required this.weeklyProgress,
    this.strongestModule,
    this.weakestModule,
    required this.recentActivity,
  });

  int get xpProgress => totalXP - _getXPForLevel(currentLevel);
  int get xpNeeded => xpForNextLevel - xpProgress;
  double get progressPercent => (xpProgress / xpForNextLevel * 100).clamp(0, 100);

  static int _getXPForLevel(int level) {
    if (level == 1) return 0;
    return (level - 1) * 100 + ((level - 2) * (level - 1) ~/ 2) * 50;
  }
}

class DailyProgress {
  final int questionsAnswered;
  final int dailyGoal;
  final int streak;

  DailyProgress({
    required this.questionsAnswered,
    required this.dailyGoal,
    required this.streak,
  });

  bool get isCompleted => questionsAnswered >= dailyGoal;
  double get progressPercent => (questionsAnswered / dailyGoal * 100).clamp(0, 100);
}

class WeeklyProgress {
  final int questionsAnswered;
  final int weeklyGoal;
  final int bonusXP;

  WeeklyProgress({
    required this.questionsAnswered,
    required this.weeklyGoal,
    required this.bonusXP,
  });

  bool get isCompleted => questionsAnswered >= weeklyGoal;
  double get progressPercent => (questionsAnswered / weeklyGoal * 100).clamp(0, 100);
}

class ModulePerformance {
  final String moduleName;
  final String moduleType;
  final int totalQuestions;
  final int correctAnswers;
  final double accuracy;

  ModulePerformance({
    required this.moduleName,
    required this.moduleType,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.accuracy,
  });
}

class ActivityEntry {
  final String moduleName;
  final String moduleType;
  final int score;
  final DateTime timestamp;
  final bool isCorrect;

  ActivityEntry({
    required this.moduleName,
    required this.moduleType,
    required this.score,
    required this.timestamp,
    required this.isCorrect,
  });
}

// Provider
final profileAnalyticsProvider = FutureProvider<ProfileAnalytics>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) throw Exception('User not authenticated');

  return fetchProfileAnalytics(currentUser.id);
});

// Fetch analytics data
Future<ProfileAnalytics> fetchProfileAnalytics(String userId) async {
  try {
    // 1. Calculate total XP
    final xpResult = await SupabaseConfig.client
        .from('user_progress')
        .select('score_awarded')
        .eq('user_id', userId);

    int totalXP = 0;
    for (var row in xpResult) {
      totalXP += (row['score_awarded'] as num?)?.toInt() ?? 0;
    }

    // 2. Calculate level
    int level = _calculateLevel(totalXP);
    int xpForNextLevel = _getXPRequiredForLevel(level + 1) - _getXPRequiredForLevel(level);

    // 3. Daily progress
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final dailyResult = await SupabaseConfig.client
        .from('user_progress')
        .select('id')
        .eq('user_id', userId)
        .gte('attempt_date', todayStart.toIso8601String())
        .lt('attempt_date', todayEnd.toIso8601String());

    int questionsToday = dailyResult.length;

    // Calculate streak (simplified - consecutive days)
    int streak = await _calculateStreak(userId);

    final dailyProgress = DailyProgress(
      questionsAnswered: questionsToday,
      dailyGoal: 5, // Default goal
      streak: streak,
    );

    // 4. Weekly progress
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    final weeklyResult = await SupabaseConfig.client
        .from('user_progress')
        .select('id')
        .eq('user_id', userId)
        .gte('attempt_date', weekStartDate.toIso8601String());

    int questionsThisWeek = weeklyResult.length;
    bool weeklyCompleted = questionsThisWeek >= 20;
    int bonusXP = weeklyCompleted ? 100 : 0;

    final weeklyProgress = WeeklyProgress(
      questionsAnswered: questionsThisWeek,
      weeklyGoal: 20,
      bonusXP: bonusXP,
    );

    // 5. Module performance
    final moduleStats = await _calculateModulePerformance(userId);
    
    ModulePerformance? strongest;
    ModulePerformance? weakest;
    
    if (moduleStats.isNotEmpty) {
      moduleStats.sort((a, b) => b.accuracy.compareTo(a.accuracy));
      strongest = moduleStats.first;
      weakest = moduleStats.length > 1 ? moduleStats.last : null;
    }

    // 6. Recent activity
    final activityData = await SupabaseConfig.client
        .from('user_progress')
        .select('*, questions(module_type, content)')
        .eq('user_id', userId)
        .order('attempt_date', ascending: false)
        .limit(7);

    final recentActivity = activityData.map((row) {
      final question = row['questions'] as Map<String, dynamic>?;
      final moduleType = question?['module_type'] ?? 'unknown';
      
      return ActivityEntry(
        moduleName: _getModuleName(moduleType),
        moduleType: moduleType,
        score: (row['score_awarded'] as num?)?.toInt() ?? 0,
        timestamp: DateTime.parse(row['attempt_date']),
        isCorrect: row['is_correct'] == true,
      );
    }).toList();

    return ProfileAnalytics(
      totalXP: totalXP,
      currentLevel: level,
      xpForNextLevel: xpForNextLevel,
      dailyProgress: dailyProgress,
      weeklyProgress: weeklyProgress,
      strongestModule: strongest,
      weakestModule: weakest,
      recentActivity: recentActivity,
    );
  } catch (e) {
    throw Exception('Failed to fetch profile analytics: $e');
  }
}

// Helper: Calculate level from XP
int _calculateLevel(int xp) {
  int level = 1;
  while (_getXPRequiredForLevel(level + 1) <= xp) {
    level++;
  }
  return level;
}

// Helper: Get XP required for a specific level
int _getXPRequiredForLevel(int level) {
  if (level == 1) return 0;
  // Level 2: 100 XP, Level 3: 250 XP, Level 4: 450 XP, etc.
  return (level - 1) * 100 + ((level - 2) * (level - 1) ~/ 2) * 50;
}

// Helper: Calculate consecutive day streak
Future<int> _calculateStreak(String userId) async {
  try {
    final recentDays = await SupabaseConfig.client
        .from('user_progress')
        .select('attempt_date')
        .eq('user_id', userId)
        .order('attempt_date', ascending: false)
        .limit(30);

    if (recentDays.isEmpty) return 0;

    final dates = recentDays
        .map((row) => DateTime.parse(row['attempt_date']))
        .map((dt) => DateTime(dt.year, dt.month, dt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 1;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Check if user trained today or yesterday
    if (!dates.first.isAtSameMomentAs(todayDate) &&
        !dates.first.isAtSameMomentAs(todayDate.subtract(const Duration(days: 1)))) {
      return 0;
    }

    for (int i = 1; i < dates.length; i++) {
      final difference = dates[i - 1].difference(dates[i]).inDays;
      if (difference == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  } catch (e) {
    return 0;
  }
}

// Helper: Calculate module performance
Future<List<ModulePerformance>> _calculateModulePerformance(String userId) async {
  try {
    final data = await SupabaseConfig.client
        .from('user_progress')
        .select('is_correct, questions(module_type)')
        .eq('user_id', userId);

    final Map<String, Map<String, int>> stats = {};

    for (var row in data) {
      final question = row['questions'] as Map<String, dynamic>?;
      final moduleType = question?['module_type'] ?? 'unknown';
      
      stats.putIfAbsent(moduleType, () => {'total': 0, 'correct': 0});
      stats[moduleType]!['total'] = stats[moduleType]!['total']! + 1;
      if (row['is_correct'] == true) {
        stats[moduleType]!['correct'] = stats[moduleType]!['correct']! + 1;
      }
    }

    return stats.entries.where((e) => e.value['total']! > 0).map((entry) {
      final total = entry.value['total']!;
      final correct = entry.value['correct']!;
      final accuracy = (correct / total * 100);

      return ModulePerformance(
        moduleName: _getModuleName(entry.key),
        moduleType: entry.key,
        totalQuestions: total,
        correctAnswers: correct,
        accuracy: accuracy,
      );
    }).toList();
  } catch (e) {
    return [];
  }
}

// Helper: Get user-friendly module name
String _getModuleName(String moduleType) {
  switch (moduleType) {
    case 'phishing':
      return 'Phishing Detection';
    case 'password':
      return 'Password Security';
    case 'attack':
      return 'Threat Recognition';
    default:
      return moduleType.toUpperCase();
  }
}
