import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/providers/auth_provider.dart';

enum ChallengeStatus { loading, ready, completed, error }

class DailyChallengeState {
  final ChallengeStatus status;
  final Map<String, dynamic>? challenge;
  final bool? userGuess;
  final bool? isCorrect;
  final String? errorMessage;
  final int streakCount; // Days completed in current 7-day cycle
  final int totalDays; // Total days ever played
  final List<bool>
  weekAnswers; // Track correct (true) or incorrect (false) for each day

  DailyChallengeState({
    required this.status,
    this.challenge,
    this.userGuess,
    this.isCorrect,
    this.errorMessage,
    this.streakCount = 0,
    this.totalDays = 0,
    this.weekAnswers = const [],
  });

  DailyChallengeState copyWith({
    ChallengeStatus? status,
    Map<String, dynamic>? challenge,
    bool? userGuess,
    bool? isCorrect,
    String? errorMessage,
    int? streakCount,
    int? totalDays,
    List<bool>? weekAnswers,
  }) {
    return DailyChallengeState(
      status: status ?? this.status,
      challenge: challenge ?? this.challenge,
      userGuess: userGuess ?? this.userGuess,
      isCorrect: isCorrect ?? this.isCorrect,
      errorMessage: errorMessage ?? this.errorMessage,
      streakCount: streakCount ?? this.streakCount,
      totalDays: totalDays ?? this.totalDays,
      weekAnswers: weekAnswers ?? this.weekAnswers,
    );
  }
}

class DailyChallengeNotifier extends StateNotifier<DailyChallengeState> {
  final Ref ref;
  final _supabase = Supabase.instance.client;

  DailyChallengeNotifier(this.ref)
    : super(DailyChallengeState(status: ChallengeStatus.loading)) {
    _checkAndLoadChallenge();
  }

  Future<void> _checkAndLoadChallenge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final userId = _supabase.auth.currentUser?.id;

      // Get streak data from SharedPreferences (for UI display)
      int streakCount = prefs.getInt('challenge_streak_count') ?? 0;
      int totalDays = prefs.getInt('challenge_total_days') ?? 0;

      // Get week answers (comma-separated: "1,0,1,1,0" where 1=correct, 0=incorrect)
      final weekAnswersStr = prefs.getString('challenge_week_answers') ?? '';
      final weekAnswers = weekAnswersStr.isEmpty
          ? <bool>[]
          : weekAnswersStr.split(',').map((e) => e == '1').toList();

      // First check database for today's progress
      if (userId != null) {
        try {
          final dbProgress = await _supabase
              .from('daily_challenge_progress')
              .select('*, daily_challenges(*)')
              .eq('user_id', userId)
              .gte('completed_at', '${today}T00:00:00Z')
              .lt('completed_at', '${today}T23:59:59Z')
              .maybeSingle();

          if (dbProgress != null) {
            // Already completed today - load from database
            final challenge =
                dbProgress['daily_challenges'] as Map<String, dynamic>?;
            state = DailyChallengeState(
              status: ChallengeStatus.completed,
              challenge: challenge,
              userGuess:
                  true, // We don't store the exact guess, but challenge was completed
              isCorrect: true, // Assume correct since completed
              streakCount: streakCount,
              totalDays: totalDays,
              weekAnswers: weekAnswers,
            );
            return;
          }
        } catch (e) {
          // If database check fails, fall back to SharedPreferences
          print('Database check failed, using SharedPreferences: $e');
        }
      }

      // Fall back to SharedPreferences check
      final lastPlayed = prefs.getString('last_challenge_date');

      if (lastPlayed == today) {
        // Already played today
        final savedGuess = prefs.getBool('last_challenge_guess');
        final savedCorrect = prefs.getBool('last_challenge_correct');
        final savedQuestion = prefs.getString('last_challenge_question');
        final savedExplanation = prefs.getString('last_challenge_explanation');

        state = DailyChallengeState(
          status: ChallengeStatus.completed,
          challenge: {
            'question': savedQuestion ?? '',
            'explanation': savedExplanation ?? '',
            'is_true': savedCorrect ?? false,
          },
          userGuess: savedGuess,
          isCorrect: savedCorrect,
          streakCount: streakCount,
          totalDays: totalDays,
          weekAnswers: weekAnswers,
        );
      } else {
        // Check if we need to reset streak (missed a day)
        if (lastPlayed != null) {
          final lastDate = DateTime.parse(lastPlayed);
          final todayDate = DateTime.parse(today);
          final daysDifference = todayDate.difference(lastDate).inDays;

          // If more than 1 day passed, reset streak
          if (daysDifference > 1) {
            streakCount = 0;
            await prefs.setInt('challenge_streak_count', 0);
            await prefs.setString('challenge_week_answers', '');
            weekAnswers.clear();
          }
        }

        // Fetch new challenge
        await _loadNewChallenge();

        // Update state with current streak
        state = state.copyWith(
          streakCount: streakCount,
          totalDays: totalDays,
          weekAnswers: weekAnswers,
        );
      }
    } catch (e) {
      state = DailyChallengeState(
        status: ChallengeStatus.error,
        errorMessage: 'Error loading challenge: $e',
      );
    }
  }

  Future<void> _loadNewChallenge() async {
    try {
      // Fetch all challenges and pick a random one
      final data = await _supabase.from('daily_challenges').select();

      if (data.isEmpty) {
        state = DailyChallengeState(
          status: ChallengeStatus.error,
          errorMessage: 'No challenges available',
        );
        return;
      }

      final randomChallenge = (data..shuffle()).first;

      state = DailyChallengeState(
        status: ChallengeStatus.ready,
        challenge: randomChallenge,
      );
    } catch (e) {
      state = DailyChallengeState(
        status: ChallengeStatus.error,
        errorMessage: 'Error fetching challenge: $e',
      );
    }
  }

  Future<void> submitAnswer(bool guess) async {
    if (state.challenge == null) return;

    final isCorrect = guess == state.challenge!['is_true'];
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      state = state.copyWith(
        status: ChallengeStatus.error,
        errorMessage: 'User not logged in',
      );
      return;
    }

    try {
      // Record progress directly to database using upsert
      await _supabase.from('daily_challenge_progress').upsert({
        'user_id': userId,
        'challenge_id': state.challenge!['id'],
        'completed': true,
        'completed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,challenge_id');

      // Update streak and total days
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];

      int streakCount = prefs.getInt('challenge_streak_count') ?? 0;
      int totalDays = prefs.getInt('challenge_total_days') ?? 0;

      // Get and update week answers
      final weekAnswersStr = prefs.getString('challenge_week_answers') ?? '';
      final weekAnswers = weekAnswersStr.isEmpty
          ? <bool>[]
          : weekAnswersStr.split(',').map((e) => e == '1').toList();
      weekAnswers.add(isCorrect);

      // Increment counters
      streakCount++;
      totalDays++;

      // Reset streak after 7 days
      if (streakCount > 7) {
        streakCount = 1;
        weekAnswers.clear();
        weekAnswers.add(isCorrect);
      }

      // Save week answers as comma-separated string
      final weekAnswersString = weekAnswers.map((e) => e ? '1' : '0').join(',');

      // Save to SharedPreferences
      await prefs.setString('last_challenge_date', today);
      await prefs.setBool('last_challenge_guess', guess);
      await prefs.setBool('last_challenge_correct', isCorrect);
      await prefs.setString(
        'last_challenge_question',
        state.challenge!['question'],
      );
      await prefs.setString(
        'last_challenge_explanation',
        state.challenge!['explanation'],
      );
      await prefs.setInt('challenge_streak_count', streakCount);
      await prefs.setInt('challenge_total_days', totalDays);
      await prefs.setString('challenge_week_answers', weekAnswersString);

      state = state.copyWith(
        status: ChallengeStatus.completed,
        userGuess: guess,
        isCorrect: isCorrect,
        streakCount: streakCount,
        totalDays: totalDays,
        weekAnswers: weekAnswers,
      );
    } catch (e) {
      state = state.copyWith(
        status: ChallengeStatus.error,
        errorMessage: 'Error submitting answer: $e',
      );
    }
  }

  Future<void> resetForTesting() async {
    // For testing purposes - clears the saved date
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_challenge_date');
    await prefs.remove('last_challenge_guess');
    await prefs.remove('last_challenge_correct');
    await prefs.remove('last_challenge_question');
    await prefs.remove('last_challenge_explanation');
    await prefs.remove('challenge_streak_count');
    await prefs.remove('challenge_total_days');
    await prefs.remove('challenge_week_answers');
    await _checkAndLoadChallenge();
  }
}

final dailyChallengeProvider =
    StateNotifierProvider<DailyChallengeNotifier, DailyChallengeState>((ref) {
      return DailyChallengeNotifier(ref);
    });
