import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/local_notification_service.dart';

enum ChallengeStatus { loading, ready, completed, error }

class DailyChallengeState {
  final ChallengeStatus status;
  final Map<String, dynamic>? challenge;
  final bool? userGuess;
  final bool? isCorrect;
  final String? errorMessage;
  final int streakCount; // Total consecutive days completed (never resets unless missed)
  final int totalDays; // Total days ever played
  final List<bool>
      weekAnswers; // Track correct (true) or incorrect (false) for each day in current 7-day cycle

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

// Service class for daily challenge operations
class DailyChallengeService {
  static final _supabase = Supabase.instance.client;

  /// Load daily challenge - DATABASE FIRST approach with streak table
  static Future<DailyChallengeState> loadDailyChallenge() async {
    try {
      // 🧪 TESTING MODE: Set to false for production (24 hours)
      const bool testingMode = false;
      const int testingSeconds = 86400; // 24 hours = 86400 seconds
      
      debugPrint('🎯 DAILY CHALLENGE: Loading challenge...');
      if (testingMode) {
        debugPrint('🧪 TESTING MODE: Using ${testingSeconds ~/ 3600}-hour reset');
      }
      
final today = DateTime.now().toIso8601String().split('T')[0];
      final userId = _supabase.auth.currentUser?.id;

      debugPrint('🎯 DAILY CHALLENGE: Today = $today, User ID = $userId');

      if (userId == null) {
        debugPrint('❌ DAILY CHALLENGE: User not logged in');
        return DailyChallengeState(
          status: ChallengeStatus.error,
          errorMessage: 'User not logged in',
        );
      }

      // PRIORITY 1: Load streak data from database
      int streakCount = 0;
      int totalDays = 0;
      List<bool> weekAnswers = [];
      DateTime? lastCompletedDate;

      try {
        debugPrint('🎯 DAILY CHALLENGE: Loading streak from database...');
        final streakData = await _supabase
            .from('daily_challenge_streak')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (streakData != null) {
          streakCount = streakData['current_streak'] ?? 0;
          totalDays = streakData['total_days'] ?? 0;
          final weekAnswersStr = streakData['week_answers'] ?? '';
          
          // Fix type conversion: explicitly create List<bool>
          weekAnswers = weekAnswersStr.isEmpty
              ? []
              : List<bool>.from(weekAnswersStr.split(',').map((e) => e == '1'));
          
          if (streakData['last_completed_date'] != null) {
            lastCompletedDate = DateTime.parse(streakData['last_completed_date']);
          }

          debugPrint('✅ DAILY CHALLENGE: Streak from DB: $streakCount/7, Total: $totalDays');
        } else {
          debugPrint('ℹ️ DAILY CHALLENGE: No streak data in DB yet');
        }
      } catch (e) {
        debugPrint('⚠️ DAILY CHALLENGE: Error loading streak from DB: $e');
        // Fall back to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        streakCount = prefs.getInt('challenge_streak_count') ?? 0;
        totalDays = prefs.getInt('challenge_total_days') ?? 0;
        final weekAnswersStr = prefs.getString('challenge_week_answers') ?? '';
        
        // Fix type conversion: explicitly create List<bool>
        weekAnswers = weekAnswersStr.isEmpty
            ? []
            : List<bool>.from(weekAnswersStr.split(',').map((e) => e == '1'));
        
        debugPrint('💾 DAILY CHALLENGE: Loaded streak from SharedPreferences fallback');
      }

      // Check if already completed today (or within test window)
    try {
      debugPrint('🎯 DAILY CHALLENGE: Checking if completed today...');
      
      dynamic dbProgress;
      if (testingMode) {
        // In testing mode, check if completed within last 10 seconds
        final cutoffTime = DateTime.now().subtract(Duration(seconds: testingSeconds));
        final results = await _supabase
            .from('daily_challenge_progress')
            .select('*, daily_challenges(*)')
            .eq('user_id', userId)
            .gte('completed_at', cutoffTime.toIso8601String())
            .order('completed_at', ascending: false)
            .limit(1);
        
        dbProgress = results.isNotEmpty ? results.first : null;
        
        if (dbProgress != null) {
          debugPrint('🧪 TESTING: Challenge completed within last $testingSeconds seconds');
        }
      } else {
        // Normal mode: check if completed today (get most recent)
        final results = await _supabase
            .from('daily_challenge_progress')
            .select('*, daily_challenges(*)')
            .eq('user_id', userId)
            .gte('completed_at', '${today}T00:00:00Z')
            .lt('completed_at', '${today}T23:59:59Z')
            .order('completed_at', ascending: false)
            .limit(1);
        
        dbProgress = results.isNotEmpty ? results.first : null;
      }

      if (dbProgress != null) {
          debugPrint('✅ DAILY CHALLENGE: Found in database - already completed today');
          debugPrint('📊 DAILY CHALLENGE: Returning with streak=$streakCount/7, weekAnswers=${weekAnswers.length}');
          final challenge =
              dbProgress['daily_challenges'] as Map<String, dynamic>?;
          final isCorrect = dbProgress['is_correct'] ?? false;
          
          return DailyChallengeState(
            status: ChallengeStatus.completed,
            challenge: challenge,
            userGuess: true,
            isCorrect: isCorrect,
            streakCount: streakCount,
            totalDays: totalDays,
            weekAnswers: weekAnswers,
          );
        }
      } catch (e) {
        debugPrint('❌ DAILY CHALLENGE: Error checking completion: $e');
      }

      // Check if streak needs to be reset (missed a day/period)
      // 🧪 TESTING MODE: Skip this check - testing window is too short for meaningful streak tracking
      if (!testingMode && lastCompletedDate != null) {
        // Normal mode: reset if more than 1 day passed
        final todayDate = DateTime.parse(today);
        final daysDifference = todayDate.difference(lastCompletedDate).inDays;
        final hoursSinceCompletion = DateTime.now().difference(lastCompletedDate).inHours;

        // Send streak warning if it's been 20+ hours and still same day (haven't completed today)
        if (hoursSinceCompletion >= 20 && daysDifference == 0 && streakCount > 0) {
          debugPrint('⚠️ DAILY CHALLENGE: 20+ hours since completion, sending streak warning');
          LocalNotificationService.showStreakWarning(streakCount);
        }

        if (daysDifference > 1) {
          debugPrint('⚠️ DAILY CHALLENGE: Missed days, resetting streak');
          streakCount = 0;
          weekAnswers = [];
          
          // Update database
          try {
            await _supabase.from('daily_challenge_streak').upsert({
              'user_id': userId,
              'current_streak': 0,
              'week_answers': '',
              'last_completed_date': null,
            }, onConflict: 'user_id');
          } catch (e) {
            debugPrint('⚠️ Could not reset streak in DB: $e');
          }
        }
      }

      // Fetch new challenge for today
      debugPrint('🎯 DAILY CHALLENGE: Loading new challenge...');
      final newState = await _loadNewChallenge(streakCount, totalDays, weekAnswers);
      return newState;
    } catch (e) {
      debugPrint('❌ DAILY CHALLENGE ERROR: $e');
      return DailyChallengeState(
        status: ChallengeStatus.error,
        errorMessage: 'Error loading challenge: $e',
      );
    }
  }

  static Future<DailyChallengeState> _loadNewChallenge(
    int streakCount,
    int totalDays,
    List<bool> weekAnswers,
  ) async {
    try {
      debugPrint('🎯 DAILY CHALLENGE: Fetching new challenge from database...');
      // Fetch all challenges and pick a random one
      final data = await _supabase.from('daily_challenges').select();

      if (data.isEmpty) {
        debugPrint('❌ DAILY CHALLENGE: No challenges available in database');
        return DailyChallengeState(
          status: ChallengeStatus.error,
          errorMessage: 'No challenges available',
        );
      }

      final randomChallenge = (data..shuffle()).first;
      debugPrint('✅ DAILY CHALLENGE: Loaded new challenge: ${randomChallenge['question']}');

      return DailyChallengeState(
        status: ChallengeStatus.ready,
        challenge: randomChallenge,
        streakCount: streakCount,
        totalDays: totalDays,
        weekAnswers: weekAnswers,
      );
    } catch (e) {
      debugPrint('❌ DAILY CHALLENGE: Error fetching challenge: $e');
      return DailyChallengeState(
        status: ChallengeStatus.error,
        errorMessage: 'Error fetching challenge: $e',
      );
    }
  }

  /// Submit answer and update progress - DATABASE FIRST approach
  static Future<DailyChallengeState> submitAnswer(
    DailyChallengeState currentState,
    bool guess,
  ) async {
    if (currentState.challenge == null) return currentState;

    final isCorrect = guess == currentState.challenge!['is_true'];
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      debugPrint('❌ DAILY CHALLENGE: User not logged in');
      return currentState.copyWith(
        status: ChallengeStatus.error,
        errorMessage: 'User not logged in',
      );
    }

    try {
      debugPrint('🎯 DAILY CHALLENGE: Submitting answer (guess=$guess, correct=$isCorrect)');
      
      // PRIORITY 1: Save challenge completion to database
      // First, delete any existing entries for this user and challenge to avoid duplicates
      await _supabase
          .from('daily_challenge_progress')
          .delete()
          .eq('user_id', userId)
          .eq('challenge_id', currentState.challenge!['id']);
      
      // Then insert the new completion record
      await _supabase.from('daily_challenge_progress').insert({
        'user_id': userId,
        'challenge_id': currentState.challenge!['id'],
        'completed': true,
        'is_correct': isCorrect,
        'completed_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ DAILY CHALLENGE: Saved completion to database');

      // Calculate new streak values
      int streakCount = currentState.streakCount + 1;
      int totalDays = currentState.totalDays + 1;
      List<bool> weekAnswers = List.from(currentState.weekAnswers);
      weekAnswers.add(isCorrect);

      // Reset week cycle after 7 days (but streak continues)
      if (weekAnswers.length > 7) {
        weekAnswers = [isCorrect]; // Start new week cycle
        // streakCount continues counting (8, 9, 10...)
      }

      final weekAnswersString = weekAnswers.map((e) => e ? '1' : '0').join(',');
      final today = DateTime.now().toIso8601String();

      // PRIORITY 2: Save streak to database  
      try {
        await _supabase.from('daily_challenge_streak').upsert({
          'user_id': userId,
          'current_streak': streakCount,
          'total_days': totalDays,
          'week_answers': weekAnswersString,
          'last_completed_date': today,
        }, onConflict: 'user_id');

        debugPrint('✅ DAILY CHALLENGE: Saved streak to database (streak=$streakCount/7)');
      } catch (e) {
        debugPrint('⚠️ DAILY CHALLENGE: Failed to save streak to DB: $e');
        // Continue - will save to SharedPreferences as fallback
      }

      // PRIORITY 3: Backup to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final todayDate = DateTime.now().toIso8601String().split('T')[0];
        
        await prefs.setString('last_challenge_date', todayDate);
        await prefs.setBool('last_challenge_guess', guess);
        await prefs.setBool('last_challenge_correct', isCorrect);
        await prefs.setString(
          'last_challenge_question',
          currentState.challenge!['question'],
        );
        await prefs.setString(
          'last_challenge_explanation',
          currentState.challenge!['explanation'],
        );
        await prefs.setInt('challenge_streak_count', streakCount);
        await prefs.setInt('challenge_total_days', totalDays);
        await prefs.setString('challenge_week_answers', weekAnswersString);

        debugPrint('💾 DAILY CHALLENGE: Backed up to SharedPreferences');
      } catch (e) {
        debugPrint('⚠️ DAILY CHALLENGE: SharedPreferences backup failed: $e');
        // Not critical - database is the source of truth
      }

      return currentState.copyWith(
        status: ChallengeStatus.completed,
        userGuess: guess,
        isCorrect: isCorrect,
        streakCount: streakCount,
        totalDays: totalDays,
        weekAnswers: weekAnswers,
      );
    } catch (e) {
      debugPrint('❌ DAILY CHALLENGE SUBMIT ERROR: $e');
      return currentState.copyWith(
        status: ChallengeStatus.error,
        errorMessage: 'Error submitting answer: $e',
      );
    }
  }

  static Future<void> resetForTesting() async {
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
    debugPrint('🧪 DAILY CHALLENGE: Test reset complete');
  }
}

// StateNotifier for daily challenge - handles auth changes
class DailyChallengeNotifier extends StateNotifier<AsyncValue<DailyChallengeState>> {
  String? _currentUserId;
  
  DailyChallengeNotifier() : super(const AsyncValue.loading()) {
    _setupAuthListener();
    _loadChallenge();
  }

  /// Listen for auth state changes and reload challenge when user changes
  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final newUserId = data.session?.user.id;
      
      debugPrint('🔄 DAILY CHALLENGE AUTH: Old user: $_currentUserId, New user: $newUserId');
      
      // If user changed (login/logout/switch), reload challenge
      if (newUserId != _currentUserId) {
        _currentUserId = newUserId;
        debugPrint('🔄 DAILY CHALLENGE: User changed, reloading challenge...');
        state = const AsyncValue.loading();
        _loadChallenge();
      }
    });
  }

  /// Load challenge from database
  Future<void> _loadChallenge() async {
    try {
      final challengeState = await DailyChallengeService.loadDailyChallenge();
      state = AsyncValue.data(challengeState);
    } catch (e, stack) {
      debugPrint('❌ DAILY CHALLENGE: Error loading: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Reload challenge manually
  Future<void> reload() async {
    state = const AsyncValue.loading();
    await _loadChallenge();
  }
}

// Provider for daily challenge - automatically reloads on user auth changes
final dailyChallengeProvider = StateNotifierProvider<DailyChallengeNotifier, AsyncValue<DailyChallengeState>>((ref) {
  return DailyChallengeNotifier();
});
