import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../config/supabase_config.dart';
import '../providers/training_provider.dart';

class CyberAttackScreen extends ConsumerStatefulWidget {
  final int difficulty;

  const CyberAttackScreen({Key? key, required this.difficulty})
    : super(key: key);

  @override
  ConsumerState<CyberAttackScreen> createState() => _CyberAttackScreenState();
}

class _CyberAttackScreenState extends ConsumerState<CyberAttackScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  bool _isCorrect = false;
  String _selectedAnswer = '';
  int _attemptCount = 0;

  // Video controllers
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  void _initializeMediaController(Question question) {
    // Parse attack data to get media type and URL
    Map<String, dynamic> attackData = {};
    if (question.content.isNotEmpty) {
      try {
        attackData = jsonDecode(question.content) as Map<String, dynamic>;
      } catch (e) {
        // Use defaults if parsing fails
      }
    }

    final mediaType = attackData['mediaType'] ?? 'none';
    final mediaUrl = question.mediaUrl;

    // Clean up existing controllers
    _videoController?.dispose();
    _chewieController?.dispose();
    _youtubeController?.dispose();

    if (mediaType == 'youtube' && mediaUrl != null && mediaUrl.isNotEmpty) {
      // Extract YouTube video ID
      String videoId = mediaUrl;
      if (mediaUrl.contains('youtube.com')) {
        final uri = Uri.parse(mediaUrl);
        videoId = uri.queryParameters['v'] ?? mediaUrl;
      } else if (mediaUrl.contains('youtu.be')) {
        videoId = mediaUrl.split('/').last;
      }

      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
      );
    } else if (mediaType == 'video' &&
        mediaUrl != null &&
        mediaUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl));
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
      );
    }
  }

  void _handleAnswer(String answer) {
    if (_isAnswered) return;

    final questionsAsync = ref.read(attackQuestionsProvider);

    questionsAsync.whenData((questions) {
      if (questions.isEmpty || _currentIndex >= questions.length) return;

      final question = questions[_currentIndex];
      final correct = question.correctAnswer == answer;

      setState(() {
        _isAnswered = true;
        _isCorrect = correct;
        _selectedAnswer = answer;
        _attemptCount++;

        if (correct) {
          // Score based on difficulty and attempts
          int points = ((6 - question.difficulty) * 10) ~/ _attemptCount;
          _score += points;
        }
      });

      // Record progress to database
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId != null) {
        final scoreAwarded = correct
            ? ((6 - question.difficulty) * 10) ~/ _attemptCount
            : 0;
        final progress = UserProgress(
          id: 'temp',
          userId: userId,
          questionId: question.id,
          isCorrect: correct,
          scoreAwarded: scoreAwarded,
          attemptDate: DateTime.now(),
        );
        recordProgress(progress).catchError((e) {
          debugPrint('Failed to record progress: $e');
        });
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _isAnswered = false;
      _selectedAnswer = '';
      _currentIndex++;
      _attemptCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(
      attackQuestionsByDifficultyProvider(widget.difficulty),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Cyber Attack Analyst - Level ${widget.difficulty}'),
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
                  attackQuestionsByDifficultyProvider(widget.difficulty),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(
              child: Text('No cyber attack questions available yet'),
            );
          }

          if (_currentIndex >= questions.length) {
            return _buildCompletionScreen(questions.length, context);
          }

          final question = questions[_currentIndex];

          // Parse attack data
          Map<String, dynamic> attackData = {};
          try {
            attackData = jsonDecode(question.content) as Map<String, dynamic>;
          } catch (e) {
            // Use defaults
          }

          final description = attackData['description'] ?? '';
          final options =
              (attackData['options'] as List<dynamic>?)?.cast<String>() ?? [];
          final mediaType = attackData['mediaType'] ?? 'none';

          // Initialize media controller
          if (_youtubeController == null &&
              _videoController == null &&
              mediaType != 'none') {
            _initializeMediaController(question);
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Scenario ${_currentIndex + 1}/${questions.length}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  // Difficulty indicator
                  Row(
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < question.difficulty
                                ? Colors.deepOrange
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Scenario content card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Media display based on type
                          if (mediaType == 'youtube' &&
                              _youtubeController != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: YoutubePlayer(
                                    controller: _youtubeController!,
                                    showVideoProgressIndicator: true,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            )
                          else if (mediaType == 'video' &&
                              _chewieController != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Chewie(
                                      controller: _chewieController!,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            )
                          else if (mediaType == 'image' &&
                              question.mediaUrl != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    question.mediaUrl!,
                                    width: double.infinity,
                                    height: 250,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            width: double.infinity,
                                            height: 250,
                                            color: Colors.grey.shade200,
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: double.infinity,
                                        height: 250,
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.image_not_supported,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          // Scenario description
                          Text(
                            'Scenario:',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description.isNotEmpty
                                ? description
                                : 'Analyze this cyberattack scenario.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Question prompt
                  Text(
                    'What type of attack is this?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Answer options
                  if (options.isNotEmpty)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: options.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final answer = options[index];
                        final isSelected = _selectedAnswer == answer;
                        final isCorrectAnswer =
                            question.correctAnswer == answer;
                        final showResult =
                            _isAnswered && (isSelected || isCorrectAnswer);
                        final resultIsCorrect = isCorrectAnswer;

                        return GestureDetector(
                          onTap: _isAnswered
                              ? null
                              : () => _handleAnswer(answer),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: showResult
                                  ? resultIsCorrect
                                        ? Colors.green.shade50
                                        : Colors.red.shade50
                                  : Colors.grey.shade50,
                              border: Border.all(
                                color: showResult
                                    ? resultIsCorrect
                                          ? Colors.green
                                          : Colors.red
                                    : Colors.grey.shade300,
                                width: showResult ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    answer,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: showResult
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: showResult
                                              ? resultIsCorrect
                                                    ? Colors.green
                                                    : Colors.red
                                              : null,
                                        ),
                                  ),
                                ),
                                if (showResult)
                                  Icon(
                                    resultIsCorrect
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: resultIsCorrect
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Center(
                      child: Text(
                        'No options available for this question',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Feedback and explanation
                  if (_isAnswered)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isCorrect
                            ? Colors.blue.shade50
                            : Colors.orange.shade50,
                        border: Border.all(
                          color: _isCorrect ? Colors.blue : Colors.orange,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isCorrect ? '✓ Correct!' : '✗ Incorrect',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isCorrect ? Colors.blue : Colors.orange,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Correct Answer: ${question.correctAnswer}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Next button
                  if (_isAnswered)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextQuestion,
                        child: Text(
                          _currentIndex + 1 >= questions.length
                              ? 'View Results'
                              : 'Next Scenario',
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompletionScreen(int totalQuestions, BuildContext context) {
    final maxScore = totalQuestions * 50;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield, size: 80, color: Colors.deepOrange),
          const SizedBox(height: 24),
          Text(
            'Analysis Complete!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
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
                    color: Colors.deepOrange,
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
                _selectedAnswer = '';
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
