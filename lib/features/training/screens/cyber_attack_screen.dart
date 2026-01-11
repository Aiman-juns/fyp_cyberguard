import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../config/supabase_config.dart';
import '../providers/training_provider.dart';
import '../../performance/providers/performance_provider.dart';
import '../../profile/providers/profile_analytics_provider.dart';
import '../../../core/widgets/achievement_dialog.dart';
import '../../../core/services/achievement_detector.dart';

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

    final questionsAsync = ref.read(
      attackQuestionsByDifficultyProvider(widget.difficulty),
    );

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
        // Wrap in async IIFE to capture achievements before recording
        (() async {
          debugPrint(
            '🔍 STEP 1: Fetching achievements BEFORE recording progress...',
          );
          
          // CRITICAL FIX: Fetch fresh BEFORE state from database (not cached)
          final userId = SupabaseConfig.client.auth.currentUser?.id;
          if (userId == null) {
            debugPrint('❌ No user ID found');
            return;
          }
          
          // Get FRESH state directly from database
          final achievementsBefore = await fetchUserAchievements(userId);
          debugPrint(
            '  Before (FRESH): ${achievementsBefore.where((a) => a.isUnlocked).length} unlocked',
          );

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

          await recordProgress(progress);
          debugPrint('📝 Progress recorded successfully');

          // Refresh providers to trigger immediate UI rebuild
          debugPrint('🔍 STEP 2: Refreshing providers...');
          ref.refresh(performanceProvider);
          ref.refresh(profileAnalyticsProvider);
          ref.refresh(attackQuestionsByDifficultyProvider(widget.difficulty));

          // CRITICAL: Invalidate recent activity to show in UI
          ref.invalidate(recentActivityProvider);

          // Wait for database to settle
          await Future.delayed(const Duration(milliseconds: 800));

          debugPrint(
            '🔍 STEP 3: Fetching achievements AFTER refresh (FRESH FROM DB)...',
          );

          try {
            // FORCE FRESH FETCH: Get user ID and call provider function directly
            final checkUserId = SupabaseConfig.client.auth.currentUser?.id;
            if (checkUserId == null) {
              debugPrint('❌ No user ID found');
              return;
            }

            // Manually fetch fresh achievements from database
            final achievementsAfter = await fetchUserAchievements(checkUserId);
            debugPrint(
              '  After: ${achievementsAfter.where((a) => a.isUnlocked).length} unlocked',
            );
            debugPrint(
              '📋 Got ${achievementsAfter.length} achievements from provider',
            );

            // Detect new unlocks
            final newAchievements = AchievementDetector.detectNewAchievements(
              previousAchievements: achievementsBefore,
              currentAchievements: achievementsAfter,
            );

            debugPrint('🎯 Found ${newAchievements.length} NEW achievements!');

            // Show dialog for each new achievement
            if (newAchievements.isNotEmpty && mounted) {
              debugPrint('🎨 Showing dialogs...');
              for (final achievement in newAchievements) {
                debugPrint('  Showing dialog for: ${achievement.title}');
                await AchievementDialog.show(context, achievement);
              }
            } else {
              debugPrint('❌ No new achievements or not mounted');
            }
          } catch (e) {
            debugPrint('❌ Achievement check error: $e');
          }

          debugPrint('✅ All updates complete');
        })(); // Close and invoke the async IIFE
      }
    });
  }

  void _nextQuestion() {
    // Clean up video controllers before moving to next question
    _videoController?.dispose();
    _chewieController?.dispose();
    _youtubeController?.dispose();
    _videoController = null;
    _chewieController = null;
    _youtubeController = null;

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
        title: Text('Threat Recognition - Level ${widget.difficulty}'),
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

          // Initialize media controller for current question
          if (mediaType != 'none') {
            _initializeMediaController(question);
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scenario ${_currentIndex + 1}/${questions.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          'Difficulty: ${question.difficulty}/5',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Difficulty indicator bars
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: List.generate(
                      5,
                      (i) => Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(2),
                            color: i < question.difficulty
                                ? Colors.deepOrange
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Scenario content card with enhanced styling
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Media display based on type
                      if (mediaType == 'youtube' && _youtubeController != null)
                        YoutubePlayer(
                          controller: _youtubeController!,
                          showVideoProgressIndicator: true,
                          aspectRatio: 16 / 9,
                        )
                      else if (mediaType == 'video' &&
                          _chewieController != null)
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Chewie(controller: _chewieController!),
                        )
                      else if (mediaType == 'image' &&
                          question.mediaUrl != null)
                        Image.network(
                          question.mediaUrl!,
                          width: double.infinity,
                          height: 280,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: double.infinity,
                              height: 280,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.grey.shade200,
                                    Colors.grey.shade300,
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 280,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Image not available',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      // Spacing after media
                      const SizedBox(height: 24),
                      // Scenario description with enhanced styling
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.orange.shade50,
                                Colors.deepOrange.shade50,
                              ],
                            ),
                            border: Border.all(
                              color: Colors.orange.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.deepOrange,
                                      Colors.orange.shade700,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Scenario:',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: Text(
                                  description.isNotEmpty
                                      ? description
                                      : 'Analyze this cyberattack scenario.',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        height: 1.6,
                                        color: Colors.grey.shade800,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Answer options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
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
                                      : isSelected
                                      ? Colors.blue.shade50
                                      : Colors.white,
                                  border: Border.all(
                                    color: showResult
                                        ? resultIsCorrect
                                              ? Colors.green.shade400
                                              : Colors.red.shade400
                                        : isSelected
                                        ? Colors.blue.shade300
                                        : Colors.grey.shade300,
                                    width: showResult || isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    if (isSelected && !_isAnswered)
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    if (showResult)
                                      BoxShadow(
                                        color:
                                            (resultIsCorrect
                                                    ? Colors.green
                                                    : Colors.red)
                                                .withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    if (!showResult && !isSelected)
                                      Container(
                                        width: 20,
                                        height: 20,
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey.shade400,
                                            width: 2,
                                          ),
                                        ),
                                      )
                                    else if (!showResult && isSelected)
                                      Container(
                                        width: 20,
                                        height: 20,
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blue,
                                          border: Border.all(
                                            color: Colors.blue,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: Icon(
                                          resultIsCorrect
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color: resultIsCorrect
                                              ? Colors.green.shade600
                                              : Colors.red.shade600,
                                          size: 24,
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        answer,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: showResult
                                                  ? resultIsCorrect
                                                        ? Colors.green.shade700
                                                        : Colors.red.shade700
                                                  : Colors.grey.shade800,
                                            ),
                                      ),
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
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
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
                                  color: _isCorrect
                                      ? Colors.blue
                                      : Colors.orange,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Correct Answer: ${question.correctAnswer}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (question.explanation.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _isCorrect
                                          ? Colors.blue.shade200
                                          : Colors.orange.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.lightbulb_outline,
                                            size: 18,
                                            color: _isCorrect
                                                ? Colors.blue
                                                : Colors.orange,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Explanation:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _isCorrect
                                                  ? Colors.blue
                                                  : Colors.orange,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        question.explanation,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              height: 1.5,
                                              color: Colors.grey.shade800,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
              ],
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
      attackQuestionsByDifficultyProvider(widget.difficulty),
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
      performanceTitle = 'Outstanding!';
      performanceMessage = 'You\'re a cyber threat analyst! 🛡️';
      performanceIcon = Icons.military_tech;
      performanceColor = Colors.amber;
    } else if (percentage >= 75) {
      performanceTitle = 'Well Done!';
      performanceMessage = 'Your threat detection skills are impressive!';
      performanceIcon = Icons.verified_user;
      performanceColor = Colors.green;
    } else if (percentage >= 60) {
      performanceTitle = 'Good Progress!';
      performanceMessage = 'You\'re learning to identify threats!';
      performanceIcon = Icons.security;
      performanceColor = Colors.blue;
    } else {
      performanceTitle = 'Keep Training!';
      performanceMessage = 'More practice will boost your defense skills!';
      performanceIcon = Icons.shield;
      performanceColor = Colors.orange;
    }

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated shield/icon
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
                'Analysis Complete!',
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

              // Score Card - Matching Phishing Module (Blue Theme)
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
                      'Attack Analysis Stats',
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
                          Icons.bug_report,
                          'Scenarios',
                          totalQuestions.toString(),
                          Colors.deepOrange,
                        ),
                        _buildStatItem(
                          context,
                          Icons.block,
                          'Blocked',
                          '${(_score / 50).floor()}',
                          Colors.green,
                        ),
                        _buildStatItem(
                          context,
                          Icons.speed,
                          'Accuracy',
                          '${percentage.toStringAsFixed(0)}%',
                          Colors.blue,
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
                        _selectedAnswer = '';
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
