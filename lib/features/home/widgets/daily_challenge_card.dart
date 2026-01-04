import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/daily_challenge_provider.dart';

// Provider to track collapse/expand state
final challengeExpandedProvider = StateProvider<bool>((ref) => true);

class DailyChallengeCard extends ConsumerWidget {
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeState = ref.watch(dailyChallengeProvider);
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '🔥',
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
                    ref.read(challengeExpandedProvider.notifier).state = !isExpanded;
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
      ),
    );
  }

  Widget _buildProgressIndicator(DailyChallengeState state) {
    final streakCount = state.streakCount;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316).withOpacity(0.1),
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
              'Week Progress: $streakCount/7',
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
                onPressed: () {
                  ref.read(dailyChallengeProvider.notifier).submitAnswer(true);
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
                onPressed: () {
                  ref.read(dailyChallengeProvider.notifier).submitAnswer(false);
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
        const SizedBox(height: 12),
        Center(
          child: Text(
            '✨ Come back tomorrow for a new challenge!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
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
