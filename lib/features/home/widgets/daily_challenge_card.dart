import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/daily_challenge_provider.dart';
import '../../performance/providers/performance_provider.dart';
import '../../profile/providers/profile_analytics_provider.dart';

// Provider to track collapse/expand state
final challengeExpandedProvider = StateProvider<bool>((ref) => true);

class DailyChallengeCard extends ConsumerStatefulWidget {
  const DailyChallengeCard({super.key});

  @override
  ConsumerState<DailyChallengeCard> createState() => _DailyChallengeCardState();
}

class _DailyChallengeCardState extends ConsumerState<DailyChallengeCard> {
  @override
  Widget build(BuildContext context) {
    final challengeAsync = ref.watch(dailyChallengeProvider);
    final isExpanded = ref.watch(challengeExpandedProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: const Color(0xFFF97316),
            width: 6,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: challengeAsync.when(
          data: (challengeState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '🏆',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Daily Cyber Challenge',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (challengeState.status == ChallengeStatus.completed &&
                      challengeState.isCorrect == true)
                    const Text(
                      '+50 pts',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF97316),
                      ),
                    ),
                  const SizedBox(width: 4),
                  // Collapse/Expand button
                  IconButton(
                    onPressed: () {
                      ref.read(challengeExpandedProvider.notifier).state =
                          !isExpanded;
                    },
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Color(0xFF64748B),
                      size: 24,
                    ),
                    tooltip: isExpanded ? 'Collapse' : 'Expand',
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress Indicator (X/7 days)
              _buildProgressIndicator(challengeState),
              if (isExpanded) ...[
                const SizedBox(height: 16),
                _buildContent(context, ref, challengeState),
              ],
            ],
          ),
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '🏆',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Daily Cyber Challenge',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(color: Color(0xFFF97316)),
              ),
            ],
          ),
          error: (error, stack) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '🏆',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Daily Cyber Challenge',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading challenge: $error',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(DailyChallengeState state) {
    final streakCount = state.streakCount;
    final weekProgress = state.weekAnswers.length; // Current progress in 7-day cycle
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316).withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today,
            size: 14,
            color: Color(0xFFF97316),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Week: $weekProgress/7',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          ...List.generate(7, (index) {
            final isCompleted = index < state.weekAnswers.length;
            final wasCorrect = isCompleted ? state.weekAnswers[index] : false;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted 
                      ? (wasCorrect ? Colors.greenAccent : Colors.redAccent)
                      : Colors.white.withOpacity(0.3),
                  boxShadow: isCompleted
                      ? [
                          BoxShadow(
                            color: (wasCorrect ? Colors.greenAccent : Colors.redAccent).withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    DailyChallengeState state,
  ) {
    switch (state.status) {
      case ChallengeStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );

      case ChallengeStatus.ready:
        return _buildReadyState(context, ref, state);

      case ChallengeStatus.completed:
        return _buildCompletedState(state);

      case ChallengeStatus.error:
        return _buildErrorState(state);
    }
  }

  Widget _buildReadyState(
    BuildContext context,
    WidgetRef ref,
    DailyChallengeState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            state.challenge!['question'],
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1E293B),
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final challengeAsync = ref.read(dailyChallengeProvider);
                  await challengeAsync.when(
                    data: (currentState) async {
                      await DailyChallengeService.submitAnswer(currentState, true);
                      ref.read(dailyChallengeProvider.notifier).reload();
                      // Refresh providers for immediate UI updates
                      ref.refresh(performanceProvider);
                      ref.refresh(profileAnalyticsProvider);
                      debugPrint('✅ Challenge complete - providers refreshed');
                    },
                    loading: () {},
                    error: (_, __) {},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'TRUE',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final challengeAsync = ref.read(dailyChallengeProvider);
                  await challengeAsync.when(
                    data: (currentState) async {
                      await DailyChallengeService.submitAnswer(currentState, false);
                      ref.read(dailyChallengeProvider.notifier).reload();
                      // Refresh providers for immediate UI updates
                      ref.refresh(performanceProvider);
                      ref.refresh(profileAnalyticsProvider);
                      debugPrint('✅ Challenge complete - providers refreshed');
                    },
                    loading: () {},
                    error: (_, __) {},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'FALSE',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedState(DailyChallengeState state) {
    final isCorrect = state.isCorrect ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCorrect ? 'Correct! 🎉' : 'Incorrect 😔',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                state.challenge!['question'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFCBD5E1)),
              const SizedBox(height: 8),
              const Text(
                'Explanation:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.challenge!['explanation'],
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Countdown Timer
        _CountdownTimer(startTime: DateTime.now()),
      ],
    );
  }

  Widget _buildErrorState(DailyChallengeState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.errorMessage ?? 'An error occurred',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Countdown Timer Widget - Shows time until next challenge (midnight)
class _CountdownTimer extends StatefulWidget {
  final DateTime startTime;
  
  const _CountdownTimer({required this.startTime});

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  late Duration _timeUntilMidnight;
  late Stream<void> _timer;
  
  // 🧪 TESTING MODE: Match the provider settings
  static const bool testingMode = false;
  static const int testingSeconds = 86400; // 24 hours for production

  @override
  void initState() {
    super.initState();
    _updateTimeUntilMidnight();
    // Update every second
    _timer = Stream.periodic(const Duration(seconds: 1));
    _timer.listen((_) {
      if (mounted) {
        setState(() {
          _updateTimeUntilMidnight();
        });
      }
    });
  }

  void _updateTimeUntilMidnight() {
    if (testingMode) {
      // In testing mode: countdown from start time + 10 seconds
      final now = DateTime.now();
      final nextChallengeTime = widget.startTime.add(Duration(seconds: testingSeconds));
      final remaining = nextChallengeTime.difference(now);
      
      // If time has passed, show 0
      if (remaining.isNegative) {
        _timeUntilMidnight = Duration.zero;
      } else {
        _timeUntilMidnight = remaining;
      }
    } else {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      _timeUntilMidnight = tomorrow.difference(now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = _timeUntilMidnight.inHours;
    final minutes = _timeUntilMidnight.inMinutes.remainder(60);
    final seconds = _timeUntilMidnight.inSeconds.remainder(60);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF97316).withOpacity(0.1),
            const Color(0xFFF97316).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF97316).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timer_outlined,
                color: Color(0xFFF97316),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Next challenge in:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeUnit(hours.toString().padLeft(2, '0'), 'Hours'),
              const SizedBox(width: 8),
              const Text(
                ':',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF97316),
                ),
              ),
              const SizedBox(width: 8),
              _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'Minutes'),
              const SizedBox(width: 8),
              const Text(
                ':',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF97316),
                ),
              ),
              const SizedBox(width: 8),
              _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'Seconds'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF97316),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF97316).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
