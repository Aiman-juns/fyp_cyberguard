import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/supabase_config.dart';
import '../../training/providers/training_provider.dart';

/// Admin provider for managing questions and users
class AdminProvider extends StateNotifier<AsyncValue<void>> {
  AdminProvider() : super(const AsyncValue.data(null));

  /// Create a new question
  Future<Question> createQuestion({
    required String moduleType,
    required int difficulty,
    required String content,
    required String correctAnswer,
    required String explanation,
    String? mediaUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await SupabaseConfig.client
          .from('questions')
          .insert({
            'module_type': moduleType,
            'difficulty': difficulty,
            'content': content,
            'correct_answer': correctAnswer,
            'explanation': explanation,
            'media_url': mediaUrl,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final question = Question.fromJson(response);
      state = const AsyncValue.data(null);
      return question;
    } catch (e) {
      final error = Exception('Failed to create question: $e');
      state = AsyncValue.error(error, StackTrace.current);
      rethrow;
    }
  }

  /// Update an existing question
  Future<Question> updateQuestion({
    required String questionId,
    String? moduleType,
    int? difficulty,
    String? content,
    String? correctAnswer,
    String? explanation,
    String? mediaUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updates = <String, dynamic>{};
      if (moduleType != null) updates['module_type'] = moduleType;
      if (difficulty != null) updates['difficulty'] = difficulty;
      if (content != null) updates['content'] = content;
      if (correctAnswer != null) updates['correct_answer'] = correctAnswer;
      if (explanation != null) updates['explanation'] = explanation;
      if (mediaUrl != null) updates['media_url'] = mediaUrl;

      final response = await SupabaseConfig.client
          .from('questions')
          .update(updates)
          .eq('id', questionId)
          .select()
          .single();

      final question = Question.fromJson(response);
      state = const AsyncValue.data(null);
      return question;
    } catch (e) {
      final error = Exception('Failed to update question: $e');
      state = AsyncValue.error(error, StackTrace.current);
      rethrow;
    }
  }

  /// Delete a question
  Future<void> deleteQuestion(String questionId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseConfig.client
          .from('questions')
          .delete()
          .eq('id', questionId);
      state = const AsyncValue.data(null);
    } catch (e) {
      final error = Exception('Failed to delete question: $e');
      state = AsyncValue.error(error, StackTrace.current);
      rethrow;
    }
  }

  /// Upload media file to Supabase storage
  Future<String> uploadMedia(
    String filePath,
    String fileName,
    String folder,
  ) async {
    state = const AsyncValue.loading();
    try {
      final path = '$folder/$fileName';

      // Note: This requires proper file handling implementation
      // For now, using a placeholder - in production, use File from dart:io
      // final file = File(filePath);
      // final bucket = SupabaseConfig.client.storage.from('questions-media');
      // await bucket.upload(path, file);

      // Placeholder implementation
      state = const AsyncValue.data(null);
      return 'https://example.com/media/$path';
    } catch (e) {
      final error = Exception('Failed to upload media: $e');
      state = AsyncValue.error(error, StackTrace.current);
      rethrow;
    }
  }

  /// Get all users with their stats
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await SupabaseConfig.client.from('users').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Get user progress statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final userResponse = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final progressResponse = await SupabaseConfig.client
          .from('user_progress')
          .select()
          .eq('user_id', userId);

      final progress = List<Map<String, dynamic>>.from(progressResponse);

      // Calculate stats
      int totalAttempts = progress.length;
      int correctAnswers = progress
          .where((p) => p['is_correct'] == true)
          .length;
      int totalScore = progress.fold<int>(
        0,
        (sum, p) => sum + (p['score_awarded'] as int? ?? 0),
      );

      return {
        'user': userResponse,
        'totalAttempts': totalAttempts,
        'correctAnswers': correctAnswers,
        'accuracy': totalAttempts > 0
            ? (correctAnswers / totalAttempts * 100).toStringAsFixed(2)
            : '0.00',
        'totalScore': totalScore,
        'progress': progress,
      };
    } catch (e) {
      throw Exception('Failed to fetch user stats: $e');
    }
  }
}

/// Riverpod providers
final adminProvider = StateNotifierProvider<AdminProvider, AsyncValue<void>>(
  (ref) => AdminProvider(),
);

/// Provider to get all questions for a module
final adminQuestionsProvider = FutureProvider.family<List<Question>, String>((
  ref,
  moduleType,
) async {
  return ref
      .watch(phishingQuestionsProvider)
      .when(
        data: (_) async {
          final response = await SupabaseConfig.client
              .from('questions')
              .select()
              .eq('module_type', moduleType)
              .order('difficulty', ascending: true);

          return (response as List<dynamic>)
              .map((json) => Question.fromJson(json as Map<String, dynamic>))
              .toList();
        },
        loading: () async => [],
        error: (error, stack) async => throw error,
      );
});

/// Provider to get all users
final allUsersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return ref.read(adminProvider.notifier).getAllUsers();
});

/// Provider to get specific user stats
final userStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  userId,
) async {
  return ref.read(adminProvider.notifier).getUserStats(userId);
});
