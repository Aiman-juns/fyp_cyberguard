import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/supabase_config.dart';
import '../providers/training_provider.dart';
import '../../../core/services/ai_service.dart';
import '../../performance/providers/performance_provider.dart';
import '../../profile/providers/profile_analytics_provider.dart';
import '../../../core/widgets/achievement_dialog.dart';
import '../../../core/services/achievement_detector.dart';

class PasswordDojoScreen extends ConsumerStatefulWidget {
  final Question question;

  const PasswordDojoScreen({Key? key, required this.question})
    : super(key: key);

  @override
  ConsumerState<PasswordDojoScreen> createState() => _PasswordDojoScreenState();
}

class _PasswordDojoScreenState extends ConsumerState<PasswordDojoScreen> {
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _showValidationResult = false;
  List<ValidationResult> _validationResults = [];
  final AiService _aiService = AiService();

  // Parsed requirements
  late int minLength;
  late bool requireUppercase;
  late bool requireLowercase;
  late bool requireNumbers;
  late bool requireSpecial;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _parseRequirements();
  }

  void _parseRequirements() {
    try {
      final data = jsonDecode(widget.question.content) as Map<String, dynamic>;
      setState(() {
        minLength = data['minLength'] ?? 8;
        requireUppercase = data['uppercase'] ?? true;
        requireLowercase = data['lowercase'] ?? true;
        requireNumbers = data['numbers'] ?? true;
        requireSpecial = data['special'] ?? true;
      });
    } catch (e) {
      // Default values if parsing fails
      setState(() {
        minLength = 8;
        requireUppercase = true;
        requireLowercase = true;
        requireNumbers = true;
        requireSpecial = true;
      });
    }
  }

  void _verifyPassword() {
    final password = _passwordController.text;
    final results = <ValidationResult>[];

    // Check minimum length
    results.add(
      ValidationResult(
        requirement: 'At least $minLength characters',
        passed: password.length >= minLength,
      ),
    );

    // Check uppercase
    if (requireUppercase) {
      results.add(
        ValidationResult(
          requirement: 'Contains uppercase letters (A-Z)',
          passed: password.contains(RegExp(r'[A-Z]')),
        ),
      );
    }

    // Check lowercase
    if (requireLowercase) {
      results.add(
        ValidationResult(
          requirement: 'Contains lowercase letters (a-z)',
          passed: password.contains(RegExp(r'[a-z]')),
        ),
      );
    }

    // Check numbers
    if (requireNumbers) {
      results.add(
        ValidationResult(
          requirement: 'Contains numbers (0-9)',
          passed: password.contains(RegExp(r'[0-9]')),
        ),
      );
    }

    // Check special characters
    if (requireSpecial) {
      results.add(
        ValidationResult(
          requirement: 'Contains special characters (!@#\$%^&*...)',
          passed: password.contains(
            RegExp(r'[!@#\$%^&*()_+\-=\[\]{};:`<>?/\\|~.]'),
          ),
        ),
      );
    }

    setState(() {
      _validationResults = results;
      _showValidationResult = true;
    });

    // If all passed, show success dialog
    if (results.every((r) => r.passed)) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    // Record progress to database
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId != null) {
      final progress = UserProgress(
        id: 'temp',
        userId: userId,
        questionId: widget.question.id,
        isCorrect: true,
        scoreAwarded: (6 - widget.question.difficulty) * 10,
        attemptDate: DateTime.now(),
      );
      recordProgress(progress).then((_) async {
        // Get achievements BEFORE refreshing
        final achievementsBefore = await ref.read(userAchievementsProvider.future);
        
        // Refresh providers
        ref.refresh(performanceProvider);
        ref.refresh(profileAnalyticsProvider);
        
        // CRITICAL: Invalidate achievements to force fresh fetch
        ref.invalidate(userAchievementsProvider);
        
        // CRITICAL: Invalidate recent activity to show in UI
        ref.invalidate(recentActivityProvider);
        
        try {
          // Get achievements AFTER
          final achievementsAfter = await ref.read(userAchievementsProvider.future);
          
          // Detect new unlocks
          final newAchievements = AchievementDetector.detectNewAchievements(
            previousAchievements: achievementsBefore,
            currentAchievements: achievementsAfter,
          );
          
          // Show dialogs
          if (newAchievements.isNotEmpty && mounted) {
            for (final achievement in newAchievements) {
              await AchievementDialog.show(context, achievement);
            }
          }
        } catch (e) {
          debugPrint('❌ Achievement error: $e');
        }
        
        debugPrint('✅ Providers refreshed - UI should update immediately');
      }).catchError((e) {
        debugPrint('Failed to record progress: $e');
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Password meets all requirements!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Explanation: ${widget.question.explanation}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to training screen
            },
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _roastPassword() async {
    final password = _passwordController.text;

    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a password first!')));
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final roast = await _aiService.roastPassword(password);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show roast result
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(children: [Text('🔥 Password Roasted')]),
          content: Text(roast, style: const TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Requirement Simulator'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Create a password that matches these rules:',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Requirements list
              _buildRequirementsList(context),
              const SizedBox(height: 24),

              // Password input
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Enter Password',
                  hintText: 'Type a password',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
                  ),
                  prefixIcon: Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.lock, color: Colors.white, size: 20),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Validation results (if shown)
              if (_showValidationResult) ...[
                Text(
                  'Validation Results:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._validationResults.map((result) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildValidationItem(result, context),
                  );
                }),
                const SizedBox(height: 24),
              ],

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _verifyPassword,
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('Verify Password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Check My Password button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _roastPassword,
                  icon: const Text('💪', style: TextStyle(fontSize: 20)),
                  label: const Text('Check My Password (AI)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Back button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF4A90E2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(color: Color(0xFF4A90E2)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementsList(BuildContext context) {
    final requirements = <String>[];
    requirements.add('• At least $minLength characters');
    if (requireUppercase)
      requirements.add('• Contains uppercase letters (A-Z)');
    if (requireLowercase)
      requirements.add('• Contains lowercase letters (a-z)');
    if (requireNumbers) requirements.add('• Contains numbers (0-9)');
    if (requireSpecial)
      requirements.add('• Contains special characters (!@#\$%^&*...)');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: requirements
            .map(
              (req) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(req, style: Theme.of(context).textTheme.bodyMedium),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildValidationItem(ValidationResult result, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.passed ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(color: result.passed ? Colors.green : Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            result.passed ? Icons.check_circle : Icons.cancel,
            color: result.passed ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              result.requirement,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: result.passed ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ValidationResult {
  final String requirement;
  final bool passed;

  ValidationResult({required this.requirement, required this.passed});
}

/// Loader screen that fetches a password question and shows PasswordDojoScreen
class PasswordDojoLoaderScreen extends ConsumerWidget {
  final int difficulty;

  const PasswordDojoLoaderScreen({Key? key, required this.difficulty})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(passwordQuestionsProvider);

    return questionsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Password Dojo')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Password Dojo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
      data: (questions) {
        if (questions.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Password Dojo')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No password questions available'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
          );
        }

        // Filter questions by difficulty
        final difficultyQuestions = questions
            .where((q) => q.difficulty == difficulty)
            .toList();

        if (difficultyQuestions.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Password Dojo')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No questions found for this difficulty'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
          );
        }

        // Try to find an unanswered question
        // First, fetch user progress to see which questions are already answered
        final userId = SupabaseConfig.client.auth.currentUser?.id;
        
        return FutureBuilder<Question>(
          future: _getNextQuestion(userId, difficultyQuestions),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                appBar: AppBar(title: const Text('Password Dojo')),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            final selectedQuestion = snapshot.data ?? difficultyQuestions.first;
            return PasswordDojoScreen(question: selectedQuestion);
          },
        );
      },
    );
  }

  // Get the next unanswered question or a random one
  Future<Question> _getNextQuestion(String? userId, List<Question> questions) async {
    if (userId == null || questions.isEmpty) {
      return questions.first;
    }

    try {
      // Get question IDs that user has already answered correctly
      final questionIds = questions.map((q) => q.id).toList();
      final answeredResponse = await SupabaseConfig.client
          .from('user_progress')
          .select('question_id')
          .eq('user_id', userId)
          .eq('is_correct', true)
          .inFilter('question_id', questionIds);

      final answeredIds = (answeredResponse as List<dynamic>)
          .map((row) => row['question_id'] as String)
          .toSet();

      // Filter out answered questions
      final unansweredQuestions = questions
          .where((q) => !answeredIds.contains(q.id))
          .toList();

      // Return first unanswered question, or first question if all are answered
      return unansweredQuestions.isEmpty 
          ? questions.first 
          : unansweredQuestions.first;
    } catch (e) {
      debugPrint('Error fetching unanswered questions: $e');
      return questions.first;
    }
  }
}
