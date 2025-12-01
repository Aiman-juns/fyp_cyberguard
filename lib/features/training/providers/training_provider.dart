import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../config/supabase_config.dart';

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

/// Record user progress
Future<void> recordProgress(UserProgress progress) async {
  try {
    debugPrint(
      'Recording progress for user ${progress.userId}, question ${progress.questionId}',
    );
    final data = progress.toJson();
    debugPrint('Progress data: $data');
    await SupabaseConfig.client.from('user_progress').insert(data);
    debugPrint('Progress recorded successfully');
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
    final Map<int, int> totalByDifficulty = {1: 0, 2: 0, 3: 0};
    final Map<int, int> correctByDifficulty = {1: 0, 2: 0, 3: 0};

    for (final q in questions) {
      totalByDifficulty[q.difficulty] =
          (totalByDifficulty[q.difficulty] ?? 0) + 1;
    }

    // Fetch user progress for this module
    final userProgress = await fetchUserProgressByModule(userId, moduleType);

    // Count correct answers by difficulty
    for (final progress in userProgress) {
      final question = questions.firstWhere((q) => q.id == progress.questionId);
      if (progress.isCorrect) {
        correctByDifficulty[question.difficulty] =
            (correctByDifficulty[question.difficulty] ?? 0) + 1;
      }
    }

    // Calculate percentages
    final Map<int, double> progressMap = {};
    for (int level = 1; level <= 3; level++) {
      final total = totalByDifficulty[level] ?? 0;
      final correct = correctByDifficulty[level] ?? 0;
      progressMap[level] = total == 0 ? 0.0 : correct / total;
    }

    return progressMap;
  } catch (e) {
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
