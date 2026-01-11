import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../config/supabase_config.dart';
import '../../../core/services/local_notification_service.dart';

/// Question Models
class Question {
  final String id;
  final String moduleType; // 'phishing', 'password', 'attack'
  final int difficulty; // 1-3
  final String content;
  final String correctAnswer;
  final String explanation;
  final String? mediaUrl;
  final DateTime createdAt;

  Question({
    required this.id,
    required this.moduleType,
    required this.difficulty,
    required this.content,
    required this.correctAnswer,
    required this.explanation,
    this.mediaUrl,
    required this.createdAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      moduleType: json['module_type'] as String,
      difficulty: json['difficulty'] as int,
      content: json['content'] as String,
      correctAnswer: json['correct_answer'] as String,
      explanation: json['explanation'] as String,
      mediaUrl: json['media_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// User Progress Model
class UserProgress {
  final String id;
  final String userId;
  final String questionId;
  final bool isCorrect;
  final int scoreAwarded;
  final DateTime attemptDate;
  final Question? question;

  UserProgress({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.isCorrect,
    required this.scoreAwarded,
    required this.attemptDate,
    this.question,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    // Try to parse nested question object from Supabase join
    Question? parsedQuestion;
    try {
      final questionData = json['questions'] ?? json['question'];
      if (questionData != null && questionData is Map<String, dynamic>) {
        parsedQuestion = Question.fromJson(questionData);
      }
    } catch (e) {
      // Silently ignore if question parsing fails
    }

    return UserProgress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      questionId: json['question_id'] as String,
      isCorrect: json['is_correct'] as bool,
      scoreAwarded: json['score_awarded'] as int,
      attemptDate: DateTime.parse(json['attempt_date'] as String),
      question: parsedQuestion,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'question_id': questionId,
    'is_correct': isCorrect,
    'score_awarded': scoreAwarded,
    'attempt_date': attemptDate.toIso8601String(),
  };
}

/// Fetch questions by module type
Future<List<Question>> fetchQuestionsByModule(String moduleType) async {
  try {
    final response = await SupabaseConfig.client
        .from('questions')
        .select()
        .eq('module_type', moduleType)
        .order('difficulty', ascending: true);

    return (response as List<dynamic>)
        .map((json) => Question.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    throw Exception('Failed to fetch questions: $e');
  }
}

/// Fetch questions by module type and difficulty level
Future<List<Question>> fetchQuestionsByModuleAndDifficulty(
  String moduleType,
  int difficulty,
) async {
  try {
    final response = await SupabaseConfig.client
        .from('questions')
        .select()
        .eq('module_type', moduleType)
        .eq('difficulty', difficulty)
        .order('created_at', ascending: true);

    return (response as List<dynamic>)
        .map((json) => Question.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    throw Exception('Failed to fetch questions: $e');
  }
}

/// Calculate user level based on total score
/// Level thresholds:
/// Level 1: 0-99 points
/// Level 2: 100-249 points
/// Level 3: 250-499 points
/// Level 4: 500-999 points
/// Level 5: 1000-1999 points
/// Level 6: 2000-3999 points
/// Level 7: 4000-7999 points
/// Level 8: 8000-15999 points
/// Level 9: 16000-31999 points
/// Level 10: 32000+ points
int calculateLevel(int totalScore) {
  if (totalScore < 100) return 1;
  if (totalScore < 250) return 2;
  if (totalScore < 500) return 3;
  if (totalScore < 1000) return 4;
  if (totalScore < 2000) return 5;
  if (totalScore < 4000) return 6;
  if (totalScore < 8000) return 7;
  if (totalScore < 16000) return 8;
  if (totalScore < 32000) return 9;
  return 10; // Max level
}

/// Update user's total score and level in Supabase
Future<void> updateUserScoreAndLevel(String userId) async {
  try {
    // Get all user progress to calculate total score
    final progressResponse = await SupabaseConfig.client
        .from('user_progress')
        .select('score_awarded')
        .eq('user_id', userId);

    // Calculate total score from all attempts
    int totalScore = 0;
    int totalCorrectAnswers = 0;
    for (final record in progressResponse as List<dynamic>) {
      totalScore += (record['score_awarded'] as int? ?? 0);
      if ((record['score_awarded'] as int? ?? 0) > 0) {
        totalCorrectAnswers++;
      }
    }

    // Calculate level based on total score
    final level = calculateLevel(totalScore);
    
    // Get previous level to detect level-ups
    final userResponse = await SupabaseConfig.client
        .from('users')
        .select('level, total_score')
        .eq('id', userId)
        .maybeSingle();
    
    final previousLevel = userResponse?['level'] as int? ?? 0;
    final previousScore = userResponse?['total_score'] as int? ?? 0;

    // Update user's total_score and level in users table
    await SupabaseConfig.client
        .from('users')
        .update({
          'total_score': totalScore,
          'level': level,
        })
        .eq('id', userId);

    debugPrint('Updated user $userId: Score=$totalScore, Level=$level');
    
    // Check for milestone notifications
    // Check for level up
    if (previousLevel < level) {
      debugPrint('🎉 MILESTONE: User leveled up to $level!');
      // Notification disabled - using achievement dialogs instead
      // LocalNotificationService.showMilestoneReached('Level $level', 'Congratulations! You\'ve reached level $level!');
      debugPrint('🔔 NOTIFICATION: Milestone sent - Level $level');
    }
    
    // Milestone: Total questions (10, 50, 100, 500)
    final totalQuestions = progressResponse.length;
    
    if (totalQuestions == 10 && previousScore < 10) { // Check if it's the first time reaching this milestone
      debugPrint('🎉 MILESTONE: 10 questions completed!');
      // LocalNotificationService.showMilestoneReached('10 Questions Completed', 'Great start! Keep learning!');
    } else if (totalQuestions == 50 && previousScore < 50) {
      debugPrint('🎉 MILESTONE: 50 questions completed!');
      // LocalNotificationService.showMilestoneReached('50 Questions Completed', 'You\'re making excellent progress!');
    } else if (totalQuestions == 100 && previousScore < 100) {
      debugPrint('🎉 MILESTONE: 100 questions completed!');
      // LocalNotificationService.showMilestoneReached('100 Questions Completed', 'Amazing dedication! You\'re a cyber expert!');
    } else if (totalQuestions == 500 && previousScore < 500) {
      debugPrint('🎉 MILESTONE: 500 questions completed!');
      // LocalNotificationService.showMilestoneReached('500 Questions Mastered', 'Incredible achievement! You\'re a CyberGuard master!');
    }
    
  } catch (e) {
    debugPrint('Error updating user score and level: $e');
    throw Exception('Failed to update user stats: $e');
  }
}

/// Record user progress and automatically update score/level
Future<void> recordProgress(UserProgress progress) async {
  try {
    debugPrint(
      'Recording progress for user ${progress.userId}, question ${progress.questionId}',
    );
    final data = progress.toJson();
    debugPrint('Progress data: $data');
    
    // Insert progress record
    await SupabaseConfig.client.from('user_progress').upsert(
      data,
      onConflict: 'user_id,question_id',
    );
    debugPrint('✅ Progress recorded successfully via UPSERT');
    
    // Automatically update user's total score and level
    await updateUserScoreAndLevel(progress.userId);
    debugPrint('User score and level updated successfully');
  } catch (e) {
    debugPrint('Error recording progress: $e');
    throw Exception('Failed to record progress: $e');
  }
}

/// Fetch user progress for a module
Future<List<UserProgress>> fetchUserProgressByModule(
  String userId,
  String moduleType,
) async {
  try {
    final questions = await fetchQuestionsByModule(moduleType);
    final questionIds = questions.map((q) => q.id).toList();

    if (questionIds.isEmpty) return [];

    final response = await SupabaseConfig.client
        .from('user_progress')
        .select()
        .eq('user_id', userId)
        .inFilter('question_id', questionIds);

    return (response as List<dynamic>)
        .map((json) => UserProgress.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    throw Exception('Failed to fetch user progress: $e');
  }
}

/// Fetch recent activity for a user (last 5 attempts)
Future<List<UserProgress>> fetchRecentActivity(String userId) async {
  try {
    final response = await SupabaseConfig.client
        .from('user_progress')
        .select('*, questions(*)')
        .eq('user_id', userId)
        .order('attempt_date', ascending: false)
        .limit(5);

    return (response as List<dynamic>)
        .map((json) => UserProgress.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    throw Exception('Failed to fetch recent activity: $e');
  }
}

/// Calculate progress per difficulty level for a module
Future<Map<int, double>> calculateModuleProgress(
  String userId,
  String moduleType,
) async {
  try {
    // Fetch all questions for this module
    final questions = await fetchQuestionsByModule(moduleType);

    // Group questions by difficulty
    final Map<int, List<String>> questionIdsByDifficulty = {1: [], 2: [], 3: []};
    final Map<int, Set<String>> completedQuestionsByDifficulty = {1: {}, 2: {}, 3: {}};

    for (final q in questions) {
      questionIdsByDifficulty[q.difficulty]?.add(q.id);
    }

    // Fetch user progress for this module
    final userProgress = await fetchUserProgressByModule(userId, moduleType);

    // Track UNIQUE correct questions per difficulty
    for (final progress in userProgress) {
      if (progress.isCorrect) {
        // Find the question to get its difficulty
        final question = questions.firstWhere(
          (q) => q.id == progress.questionId,
          orElse: () => questions.first,
        );
        // Add to set (automatically handles duplicates)
        completedQuestionsByDifficulty[question.difficulty]?.add(progress.questionId);
      }
    }

    // Calculate percentages based on unique completions
    final Map<int, double> progressMap = {};
    bool isModuleComplete = true;
    
    for (int level = 1; level <= 3; level++) {
      final totalQuestions = questionIdsByDifficulty[level]?.length ?? 0;
      final completedQuestions = completedQuestionsByDifficulty[level]?.length ?? 0;
      progressMap[level] = totalQuestions == 0 ? 0.0 : completedQuestions / totalQuestions;
      
      debugPrint('Module: $moduleType, Difficulty: $level, Completed: $completedQuestions/$totalQuestions = ${progressMap[level]}');
      
      // Check if module level is now complete
      if ((progressMap[level] ?? 0) < 1.0) {
        isModuleComplete = false;
      }
    }
    
    // Check if module was just completed (all difficulties at 100%)
    if (isModuleComplete && questions.isNotEmpty) {
      debugPrint('🎉 MODULE COMPLETE: $moduleType - All difficulties completed!');
      // Send module completion notification
      final moduleNames = {
        'phishing': 'Phishing Detection',
        'password': 'Password Security',
        'attack': 'Threat Recognition',
      };
      // TODO: Add module completion notification if needed
      debugPrint('🎉 Module completed: ${moduleNames[moduleType]}');
    }

    return progressMap;
  } catch (e) {
    debugPrint('Failed to calculate module progress: $e');
    throw Exception('Failed to calculate module progress: $e');
  }
}


/// Riverpod Providers

/// Phishing module questions
final phishingQuestionsProvider = FutureProvider<List<Question>>((ref) async {
  return fetchQuestionsByModule('phishing');
});

/// Phishing module questions filtered by difficulty
final phishingQuestionsByDifficultyProvider =
    FutureProvider.family<List<Question>, int>((ref, difficulty) async {
      return fetchQuestionsByModuleAndDifficulty('phishing', difficulty);
    });

/// Password module questions
final passwordQuestionsProvider = FutureProvider<List<Question>>((ref) async {
  return fetchQuestionsByModule('password');
});

/// Password module questions filtered by difficulty
final passwordQuestionsByDifficultyProvider =
    FutureProvider.family<List<Question>, int>((ref, difficulty) async {
      return fetchQuestionsByModuleAndDifficulty('password', difficulty);
    });

/// Attack module questions
final attackQuestionsProvider = FutureProvider<List<Question>>((ref) async {
  return fetchQuestionsByModule('attack');
});

/// Attack module questions filtered by difficulty
final attackQuestionsByDifficultyProvider =
    FutureProvider.family<List<Question>, int>((ref, difficulty) async {
      return fetchQuestionsByModuleAndDifficulty('attack', difficulty);
    });

/// User progress for phishing module
final phishingProgressProvider =
    FutureProvider.family<List<UserProgress>, String>((ref, userId) async {
      return fetchUserProgressByModule(userId, 'phishing');
    });

/// User progress for password module
final passwordProgressProvider =
    FutureProvider.family<List<UserProgress>, String>((ref, userId) async {
      return fetchUserProgressByModule(userId, 'password');
    });

/// User progress for attack module
final attackProgressProvider =
    FutureProvider.family<List<UserProgress>, String>((ref, userId) async {
      return fetchUserProgressByModule(userId, 'attack');
    });

/// Recent activity feed for a user (last 5 attempts)
final recentActivityProvider =
    FutureProvider.family<List<UserProgress>, String>((ref, userId) async {
      return fetchRecentActivity(userId);
    });

/// Module progress tracking - percentage complete per difficulty level
final moduleProgressProvider =
    FutureProvider.family<
      Map<int, double>,
      ({String userId, String moduleType})
    >((ref, params) async {
      return calculateModuleProgress(params.userId, params.moduleType);
    });
