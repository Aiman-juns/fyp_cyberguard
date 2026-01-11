import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/supabase_config.dart';
import '../providers/training_provider.dart';
import '../../performance/providers/performance_provider.dart';
import '../../profile/providers/profile_analytics_provider.dart';
import '../../../core/widgets/achievement_dialog.dart';
import '../../../core/services/achievement_detector.dart';

class PhishingScreen extends ConsumerStatefulWidget {
  final int difficulty;

  const PhishingScreen({Key? key, required this.difficulty}) : super(key: key);

  @override
  ConsumerState<PhishingScreen> createState() => _PhishingScreenState();
}

class _PhishingScreenState extends ConsumerState<PhishingScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  bool _isCorrect = false;
  String _feedbackMessage = '';

  void _handleSwipe({required bool isPhishing}) {
    if (_isAnswered) return;

    // Get questions from the provider's current value
    final questionsAsync = ref.read(
      phishingQuestionsByDifficultyProvider(widget.difficulty),
    );

    questionsAsync.when(
      data: (questions) {
        if (questions.isEmpty || _currentIndex >= questions.length) return;

        final question = questions[_currentIndex];
        final correct =
            question.correctAnswer.toLowerCase() ==
            (isPhishing ? 'phishing' : 'safe');

        setState(() {
          _isAnswered = true;
          _isCorrect = correct;
          _feedbackMessage = correct
              ? '✓ Correct! That is ${isPhishing ? 'PHISHING' : 'SAFE'}.'
              : '✗ Incorrect! It is actually ${question.correctAnswer}.';

          if (correct) {
            _score +=
                (6 - question.difficulty) *
                10; // More points for harder difficulty
          }
        });

        // Record progress to database
        final userId = SupabaseConfig.client.auth.currentUser?.id;
        if (userId != null) {
          // Wrap in async IIFE to capture achievements before recording
          (() async {
            final achievementsBefore = await ref.read(
              userAchievementsProvider.future,
            );

            final progress = UserProgress(
              id: 'temp',
              userId: userId,
              questionId: question.id,
              isCorrect: correct,
              scoreAwarded: correct ? (6 - question.difficulty) * 10 : 0,
              attemptDate: DateTime.now(),
            );

            await recordProgress(progress);

            // Refresh providers
            ref.refresh(performanceProvider);
            ref.refresh(profileAnalyticsProvider);
            ref.refresh(
              phishingQuestionsByDifficultyProvider(widget.difficulty),
            );

            // CRITICAL: Invalidate achievements to force fresh fetch
            ref.invalidate(userAchievementsProvider);

            // CRITICAL: Invalidate recent activity to show in UI
            ref.invalidate(recentActivityProvider);

            try {
              // Get achievements AFTER refresh
              final achievementsAfter = await ref.read(
                userAchievementsProvider.future,
              );

              // Detect new unlocks
              final newAchievements = AchievementDetector.detectNewAchievements(
                previousAchievements: achievementsBefore,
                currentAchievements: achievementsAfter,
              );

              // Show dialog for each
              if (newAchievements.isNotEmpty && mounted) {
                for (final achievement in newAchievements) {
                  await AchievementDialog.show(context, achievement);
                }
              }
            } catch (e) {
              debugPrint('❌ Achievement error: $e');
            }

            debugPrint('✅ Providers refreshed - UI should update immediately');
          })(); // Close and invoke the async IIFE
        }

        // Move to next question after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isAnswered = false;
              _currentIndex++;
            });
          }
        });
      },
      loading: () {},
      error: (error, stack) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(
      phishingQuestionsByDifficultyProvider(widget.difficulty),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Phishing Detection - Level ${widget.difficulty}'),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Score: $_score',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading questions: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(
                  phishingQuestionsByDifficultyProvider(widget.difficulty),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(
              child: Text('No phishing questions available yet'),
            );
          }

          if (_currentIndex >= questions.length) {
            return _buildCompletionScreen(questions.length, context);
          }

          final question = questions[_currentIndex];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  Text(
                    'Question ${_currentIndex + 1}/${questions.length}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  // Difficulty indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < question.difficulty
                                ? Colors.orange
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Email simulation card
                  GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity! > 0) {
                        // Swiped right - mark as phishing
                        _handleSwipe(isPhishing: true);
                      } else if (details.primaryVelocity! < 0) {
                        // Swiped left - mark as safe
                        _handleSwipe(isPhishing: false);
                      }
                    },
                    child: EmailSimulationCard(question: question),
                  ),
                  const SizedBox(height: 32),
                  // Feedback
                  if (_isAnswered)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isCorrect
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        border: Border.all(
                          color: _isCorrect ? Colors.green : Colors.red,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _feedbackMessage,
                            style: TextStyle(
                              color: _isCorrect ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            question.explanation,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        Text(
                          'Swipe to answer:',
                          style: Theme.of(
                            context,
                          ).textTheme.labelMedium?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  const SizedBox(height: 16),
                  // Answer buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isAnswered
                            ? null
                            : () => _handleSwipe(isPhishing: true),
                        icon: const Icon(Icons.warning),
                        label: const Text('Phishing'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          disabledBackgroundColor: Colors.red.shade200,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isAnswered
                            ? null
                            : () => _handleSwipe(isPhishing: false),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Safe'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          disabledBackgroundColor: Colors.green.shade200,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildCompletionScreen(int totalQuestions, BuildContext context) {
    // Get actual max score based on difficulty level
    final questionsAsync = ref.read(
      phishingQuestionsByDifficultyProvider(widget.difficulty),
    );

    int maxScore = 0;
    questionsAsync.whenData((questions) {
      if (questions.isNotEmpty) {
        // Calculate max score based on actual question difficulties
        maxScore = questions.fold(
          0,
          (sum, q) => sum + ((6 - q.difficulty) * 10),
        );
      }
    });

    // Fallback if questions not loaded
    if (maxScore == 0) {
      maxScore = totalQuestions * ((6 - widget.difficulty) * 10);
    }

    final percentage = maxScore > 0 ? (_score / maxScore) * 100 : 0;

    // Performance rating based on score
    String performanceTitle;
    String performanceMessage;
    IconData performanceIcon;
    Color performanceColor;

    if (percentage >= 90) {
      performanceTitle = 'Excellent Work!';
      performanceMessage = 'You\'re a phishing detection expert! 🎯';
      performanceIcon = Icons.emoji_events;
      performanceColor = Colors.amber;
    } else if (percentage >= 75) {
      performanceTitle = 'Great Job!';
      performanceMessage = 'You\'re getting really good at spotting threats!';
      performanceIcon = Icons.check_circle;
      performanceColor = Colors.green;
    } else if (percentage >= 60) {
      performanceTitle = 'Good Effort!';
      performanceMessage = 'Keep practicing to sharpen your skills!';
      performanceIcon = Icons.thumbs_up_down;
      performanceColor = Colors.blue;
    } else {
      performanceTitle = 'Keep Learning!';
      performanceMessage = 'Practice makes perfect. Try again!';
      performanceIcon = Icons.school;
      performanceColor = Colors.orange;
    }

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated trophy/icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: performanceColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: performanceColor, width: 3),
                ),
                child: Icon(performanceIcon, size: 80, color: performanceColor),
              ),
              const SizedBox(height: 24),
              Text(
                'Training Complete!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                performanceTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: performanceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                performanceMessage,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Score Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Score',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$_score / $maxScore',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Statistics breakdown
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Text(
                      'Performance Stats',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          context,
                          Icons.quiz,
                          'Questions',
                          totalQuestions.toString(),
                          Colors.blue,
                        ),
                        _buildStatItem(
                          context,
                          Icons.check_circle,
                          'Correct',
                          '${(_score / 50).floor()}',
                          Colors.green,
                        ),
                        _buildStatItem(
                          context,
                          Icons.trending_up,
                          'Accuracy',
                          '${percentage.toStringAsFixed(0)}%',
                          Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentIndex = 0;
                        _score = 0;
                        _isAnswered = false;
                      });
                    },
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Training Hub'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget that displays a realistic email simulation card
class EmailSimulationCard extends StatelessWidget {
  final Question question;

  const EmailSimulationCard({Key? key, required this.question})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Try to parse content as JSON
    Map<String, dynamic>? emailData;
    bool isJsonFormat = false;

    try {
      if (question.content.isNotEmpty) {
        emailData = jsonDecode(question.content) as Map<String, dynamic>;
        // Check if it has the expected email structure
        if (emailData.containsKey('senderName') ||
            emailData.containsKey('senderEmail') ||
            emailData.containsKey('subject') ||
            emailData.containsKey('body')) {
          isJsonFormat = true;
        }
      }
    } catch (e) {
      // Not JSON format, will use fallback display
      isJsonFormat = false;
    }

    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isJsonFormat && emailData != null) ...[
                // Email Header with Gradient Background
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      // CircleAvatar with gradient background
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: Text(
                          (emailData['senderName'] as String? ?? '?').isNotEmpty
                              ? (emailData['senderName'] as String)[0]
                                    .toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Sender name and email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emailData['senderName'] as String? ??
                                  'Unknown Sender',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              emailData['senderEmail'] as String? ?? '',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Timestamp
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Now',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.star_border,
                            color: Colors.white.withOpacity(0.7),
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Subject Line with background
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subject',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        emailData['subject'] as String? ?? 'No Subject',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Colors.black87,
                            ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                  indent: 16,
                  endIndent: 16,
                ),
                // Email Body with padding
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emailData['body'] as String? ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                      // Media URL image if present
                      if (question.mediaUrl != null) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            question.mediaUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                // Fallback: Display raw content (legacy format)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (question.mediaUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            question.mediaUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        question.content,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
