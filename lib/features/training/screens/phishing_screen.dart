import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/supabase_config.dart';
import '../providers/training_provider.dart';

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
          final progress = UserProgress(
            id: 'temp',
            userId: userId,
            questionId: question.id,
            isCorrect: correct,
            scoreAwarded: correct ? (6 - question.difficulty) * 10 : 0,
            attemptDate: DateTime.now(),
          );
          recordProgress(progress).catchError((e) {
            debugPrint('Failed to record progress: $e');
          });
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

  Widget _buildCompletionScreen(int totalQuestions, BuildContext context) {
    final maxScore = totalQuestions * 50; // Max 50 points per question

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            'Training Complete!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Text(
                  'Your Score',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_score / $maxScore',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${((_score / maxScore) * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
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
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Training Hub'),
          ),
        ],
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
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isJsonFormat && emailData != null) ...[
                // Email Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      // CircleAvatar with first letter
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue.shade600,
                        child: Text(
                          (emailData['senderName'] as String? ?? '?').isNotEmpty
                              ? (emailData['senderName'] as String)[0]
                                    .toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                                    fontSize: 15,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              emailData['senderEmail'] as String? ?? '',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Timestamp (mock)
                      Text(
                        'Now',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider
                Divider(height: 1, color: Colors.grey.shade200),
                // Subject Line
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    emailData['subject'] as String? ?? 'No Subject',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Email Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emailData['body'] as String? ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      // Media URL image if present
                      if (question.mediaUrl != null) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            question.mediaUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                color: Colors.grey.shade200,
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
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            question.mediaUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey.shade200,
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
