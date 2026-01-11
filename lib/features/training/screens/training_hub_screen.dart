import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/supabase_config.dart';
import '../../home/widgets/daily_challenge_card.dart';
import '../providers/training_provider.dart';
import 'phishing_screen.dart';
import 'password_dojo_screen.dart';
import 'cyber_attack_screen.dart';
import 'scam_simulator_screen.dart';
import 'infection_simulator_screen.dart';
import '../../support/screens/emergency_support_screen.dart';

class TrainingHubScreen extends ConsumerWidget {
  const TrainingHubScreen({Key? key}) : super(key: key);

  void _showLevelSelectionDialog(
    BuildContext context,
    String moduleName,
    Widget Function(int difficulty) screenBuilder,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => LevelSelectionDialog(
        moduleName: moduleName,
        onLevelSelected: (difficulty) {
          Navigator.pop(context); // Close dialog
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => screenBuilder(difficulty)),
          );
        },
      ),
    );
  }

  int _calculateCompleted(WidgetRef ref, String userId) {
    int completed = 0;

    final phishingAsync = ref.watch(
      moduleProgressProvider((userId: userId, moduleType: 'phishing')),
    );
    final passwordAsync = ref.watch(
      moduleProgressProvider((userId: userId, moduleType: 'password')),
    );
    final attackAsync = ref.watch(
      moduleProgressProvider((userId: userId, moduleType: 'attack')),
    );

    phishingAsync.whenData((map) {
      completed += map.values.where((p) => p == 1.0).length;
    });
    passwordAsync.whenData((map) {
      completed += map.values.where((p) => p == 1.0).length;
    });
    attackAsync.whenData((map) {
      completed += map.values.where((p) => p == 1.0).length;
    });

    return completed;
  }

  int _calculateInProgress(WidgetRef ref, String userId) {
    int inProgress = 0;

    final phishingAsync = ref.watch(
      moduleProgressProvider((userId: userId, moduleType: 'phishing')),
    );
    final passwordAsync = ref.watch(
      moduleProgressProvider((userId: userId, moduleType: 'password')),
    );
    final attackAsync = ref.watch(
      moduleProgressProvider((userId: userId, moduleType: 'attack')),
    );

    phishingAsync.whenData((map) {
      inProgress += map.values.where((p) => p > 0 && p < 1.0).length;
    });
    passwordAsync.whenData((map) {
      inProgress += map.values.where((p) => p > 0 && p < 1.0).length;
    });
    attackAsync.whenData((map) {
      inProgress += map.values.where((p) => p > 0 && p < 1.0).length;
    });

    return inProgress;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = SupabaseConfig.client.auth.currentUser?.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header Card with Quick Stats
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Training Hub',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Master cybersecurity skills',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Quick Stats
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              userId != null
                                  ? '${_calculateCompleted(ref, userId)}'
                                  : '0',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.pending_actions,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              userId != null
                                  ? '${_calculateInProgress(ref, userId)}'
                                  : '0',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'In Progress',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '850',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'XP Points',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),

          // Daily Cyber Challenge
          const DailyChallengeCard(),
          const SizedBox(height: 28.0),

          // Training Modules Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Training Modules',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          _ModuleCard(
            title: 'Phishing Detection',
            moduleColor: const Color(0xFF3B82F6),
            userId: userId,
            description: 'Learn to identify phishing emails and websites',
            icon: Icons.mail_outline,
            onTap: () => _showLevelSelectionDialog(
              context,
              'Phishing Detection',
              (difficulty) => PhishingScreen(difficulty: difficulty),
              ref,
            ),
          ),
          const SizedBox(height: 12.0),
          _ModuleCard(
            title: 'Password Dojo',
            description: 'Create and test strong passwords',
            icon: Icons.lock,
            moduleColor: const Color(0xFF8B5CF6),
            userId: userId,
            onTap: () => _showLevelSelectionDialog(
              context,
              'Password Dojo',
              (difficulty) => PasswordDojoLoaderScreen(difficulty: difficulty),
              ref,
            ),
          ),
          const SizedBox(height: 12.0),
          _ModuleCard(
            title: 'Cyber Attack Recognition',
            description: 'Recognize and identify cyber threat scenarios',
            icon: Icons.shield,
            moduleColor: const Color(0xFFEF4444),
            userId: userId,
            onTap: () => _showLevelSelectionDialog(
              context,
              'Cyber Attack Recognition',
              (difficulty) => CyberAttackScreen(difficulty: difficulty),
              ref,
            ),
          ),
          const SizedBox(height: 28.0),

          // Recent Activity Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history,
                      color: Color(0xFF8B5CF6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  if (userId != null) {
                    _showAllActivityDialog(context, ref, userId);
                  }
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          if (userId != null)
            _RecentActivityWidget(userId: userId)
          else
            Center(
              child: Text(
                'Please log in to see your activity',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}

void _showAllActivityDialog(
  BuildContext context,
  WidgetRef ref,
  String userId,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'All Recent Activity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: Consumer(
                  builder: (context, ref, child) {
                    final recentActivityAsync = ref.watch(
                      recentActivityProvider(userId),
                    );

                    return recentActivityAsync.when(
                      data: (activities) {
                        if (activities.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: Text(
                                'No activity yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        }

                        // Group activities by module
                        final Map<String, List<UserProgress>>
                        groupedActivities = {};
                        for (var activity in activities) {
                          final moduleType =
                              activity.question?.moduleType ?? 'unknown';
                          if (!groupedActivities.containsKey(moduleType)) {
                            groupedActivities[moduleType] = [];
                          }
                          groupedActivities[moduleType]!.add(activity);
                        }

                        return ListView(
                          padding: const EdgeInsets.all(20),
                          children: groupedActivities.entries.map((entry) {
                            final moduleType = entry.key;
                            final moduleActivities = entry.value;
                            final moduleName = _getModuleNameHelper(moduleType);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Module Header
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 12,
                                    top: 8,
                                  ),
                                  child: Text(
                                    moduleName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                // Activities for this module
                                ...moduleActivities.map((activity) {
                                  final question = activity.question;
                                  if (question == null)
                                    return const SizedBox.shrink();

                                  final isCorrect = activity.isCorrect;
                                  final formattedDate = _formatDateHelper(
                                    activity.attemptDate,
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        // Show question review dialog - need to pass ref
                                        _showQuestionReviewDialogHelper(
                                          context,
                                          activity,
                                          question,
                                          isCorrect,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF1E293B)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isCorrect
                                                ? Colors.green.withOpacity(0.3)
                                                : Colors.red.withOpacity(0.3),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isCorrect
                                                  ? Colors.green.withOpacity(
                                                      0.1,
                                                    )
                                                  : Colors.red.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isCorrect
                                                      ? Colors.green
                                                            .withOpacity(0.1)
                                                      : Colors.red.withOpacity(
                                                          0.1,
                                                        ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  isCorrect
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color: isCorrect
                                                      ? Colors.green
                                                      : Colors.red,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Level ${question.difficulty}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      formattedDate,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            Theme.of(
                                                                  context,
                                                                ).brightness ==
                                                                Brightness.dark
                                                            ? Colors
                                                                  .grey
                                                                  .shade400
                                                            : Colors
                                                                  .grey
                                                                  .shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF9333EA,
                                                  ).withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '+${activity.scoreAwarded}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF9333EA),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 8),
                              ],
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Text(
                            'Error loading activities',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _getModuleNameHelper(String moduleType) {
  switch (moduleType) {
    case 'phishing':
      return '📧 Phishing Email Detection';
    case 'password':
      return '🔒 Password Security';
    case 'attack':
      return '⚠️ Cyber Attack Recognition';
    default:
      return '📚 Training Module';
  }
}

String _formatDateHelper(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final dateOnly = DateTime(date.year, date.month, date.day);

  if (dateOnly == today) {
    return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  } else if (dateOnly == yesterday) {
    return 'Yesterday';
  } else {
    return '${date.month}/${date.day}/${date.year}';
  }
}

void _showQuestionReviewDialogHelper(
  BuildContext context,
  UserProgress activity,
  Question question,
  bool isCorrect,
) {
  // Parse the question content if it's JSON
  String questionText = question.content;
  List<String>? options;
  Map<String, String>? emailData;

  try {
    // Check if content looks like JSON
    if (question.content.trim().startsWith('{')) {
      final contentData = _parseJsonContentHelper(question.content);

      if (contentData != null) {
        if (contentData['type'] == 'email') {
          // This is an email format
          emailData = {
            'senderName': contentData['senderName'] as String,
            'senderEmail': contentData['senderEmail'] as String,
            'subject': contentData['subject'] as String,
            'body': contentData['body'] as String,
          };
          questionText = 'Is this email safe or a phishing attempt?';
        } else if (contentData['type'] == 'question' &&
            contentData['description'] != null) {
          // This is the old question format
          questionText = contentData['description'] as String;
          if (contentData['options'] != null &&
              contentData['options'] is List) {
            options = List<String>.from(contentData['options'] as List);
          }
        }
      }
    }
  } catch (e) {
    // If parsing fails, use original content
    questionText = question.content;
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCorrect
                        ? [Colors.green.shade400, Colors.green.shade600]
                        : [Colors.red.shade400, Colors.red.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCorrect ? 'Correct Answer' : 'Incorrect Answer',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Level ${question.difficulty} • ${_getModuleNameHelper(question.moduleType)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question
                      const Text(
                        'Question',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        questionText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Show email preview if this is phishing email detection
                      if (emailData != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // From field
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'From: ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          emailData['senderName']!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '<${emailData['senderEmail']!}>',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              // Subject field
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Subject: ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      emailData['subject']!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              // Body
                              Text(
                                emailData['body']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Show options if available
                      if (options != null && options.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Options',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...options.asMap().entries.map((entry) {
                          final index = entry.key;
                          final option = entry.value;
                          final isCorrectOption =
                              option == question.correctAnswer;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCorrectOption
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isCorrectOption
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.2),
                                width: isCorrectOption ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isCorrectOption
                                        ? Colors.green
                                        : Colors.grey.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(
                                        65 + index,
                                      ), // A, B, C, D
                                      style: TextStyle(
                                        color: isCorrectOption
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isCorrectOption
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isCorrectOption
                                          ? Colors.green.shade700
                                          : Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                                if (isCorrectOption)
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      const SizedBox(height: 20),
                      // Correct Answer (only show if no options or for clarity)
                      if (options == null || options.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Correct Answer',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      question.correctAnswer,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (options == null || options.isEmpty)
                        const SizedBox(height: 16),
                      // Explanation
                      const Text(
                        'Explanation',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question.explanation,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Score info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9333EA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFF9333EA),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'You earned ${activity.scoreAwarded} points',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9333EA),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDateHelper(activity.attemptDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Map<String, dynamic>? _parseJsonContentHelper(String content) {
  try {
    // Try to parse JSON content for phishing emails
    final RegExp senderNamePattern = RegExp(r'"senderName"\s*:\s*"([^"]*)"');
    final RegExp senderEmailPattern = RegExp(r'"senderEmail"\s*:\s*"([^"]*)"');
    final RegExp subjectPattern = RegExp(r'"subject"\s*:\s*"([^"]*)"');
    final RegExp bodyPattern = RegExp(r'"body"\s*:\s*"([^"]*)"');

    final senderNameMatch = senderNamePattern.firstMatch(content);
    final senderEmailMatch = senderEmailPattern.firstMatch(content);
    final subjectMatch = subjectPattern.firstMatch(content);
    final bodyMatch = bodyPattern.firstMatch(content);

    // Check if this is a phishing email format
    if (senderNameMatch != null ||
        senderEmailMatch != null ||
        subjectMatch != null ||
        bodyMatch != null) {
      final senderName = senderNameMatch?.group(1) ?? '';
      final senderEmail = senderEmailMatch?.group(1) ?? '';
      final subject = subjectMatch?.group(1) ?? '';
      final body =
          bodyMatch
              ?.group(1)
              ?.replaceAll(r'\n\n', '\n\n')
              .replaceAll(r'\n', '\n') ??
          '';

      return {
        'type': 'email',
        'senderName': senderName,
        'senderEmail': senderEmail,
        'subject': subject,
        'body': body,
      };
    }

    // Try old format with description and options
    final RegExp descPattern = RegExp(r'"description":"([^"]*)"');
    final RegExp optionsPattern = RegExp(r'"options":\[([^\]]*)\]');

    final descMatch = descPattern.firstMatch(content);
    final optionsMatch = optionsPattern.firstMatch(content);

    if (descMatch != null) {
      final description = descMatch.group(1);
      final List<String> options = [];

      if (optionsMatch != null) {
        final optionsStr = optionsMatch.group(1);
        if (optionsStr != null) {
          // Extract options from the string
          final optionItems = optionsStr.split('","');
          for (var item in optionItems) {
            final cleanItem = item.replaceAll('"', '').trim();
            if (cleanItem.isNotEmpty) {
              options.add(cleanItem);
            }
          }
        }
      }

      return {
        'type': 'question',
        'description': description,
        'options': options,
      };
    }
  } catch (e) {
    return null;
  }
  return null;
}

class _ModuleCard extends ConsumerWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color moduleColor;
  final String? userId;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.moduleColor,
    this.userId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get module type from title
    String moduleType = '';
    if (title.contains('Phishing')) moduleType = 'phishing';
    if (title.contains('Password')) moduleType = 'password';
    if (title.contains('Attack')) moduleType = 'attack';

    // Get progress data
    double completedLevels = 0;
    double progress = 0.0;
    if (userId != null && moduleType.isNotEmpty) {
      final progressAsync = ref.watch(
        moduleProgressProvider((userId: userId!, moduleType: moduleType)),
      );
      progressAsync.whenData((progressMap) {
        completedLevels = progressMap.values
            .where((p) => p == 1.0)
            .length
            .toDouble();
        progress = progressMap.values.fold(0.0, (sum, p) => sum + p) / 3.0;
      });
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: moduleColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: moduleColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [moduleColor, moduleColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: moduleColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                        if (completedLevels > 0) ...[
                          const SizedBox(height: 6),
                          Text(
                            '${completedLevels.toInt()}/3 levels',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: moduleColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Arrow Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: moduleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: moduleColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            // Progress bar
            if (progress > 0 && progress < 1.0)
              Container(
                height: 8,
                margin: const EdgeInsets.only(left: 18, right: 18, bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [moduleColor, moduleColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Tool Card Widget (simpler design)
class _ToolCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _ToolCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF10B981), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF64748B),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// AI Simulation Card Widget
class _AISimulationCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final String? badge;

  const _AISimulationCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    badge != null ? Icons.stars : Icons.psychology,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    badge ?? 'AI Powered',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for selecting difficulty level before starting a training module
class LevelSelectionDialog extends ConsumerWidget {
  final String moduleName;
  final Function(int difficulty) onLevelSelected;

  const LevelSelectionDialog({
    Key? key,
    required this.moduleName,
    required this.onLevelSelected,
  }) : super(key: key);

  String _getModuleType(String moduleName) {
    if (moduleName.contains('Phishing')) return 'phishing';
    if (moduleName.contains('Password')) return 'password';
    if (moduleName.contains('Attack') || moduleName.contains('Threat')) return 'attack';
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    final moduleType = _getModuleType(moduleName);

    return AlertDialog(
      title: const Text('Select Difficulty Level'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose the difficulty level for $moduleName',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (userId != null && moduleType.isNotEmpty)
              _LevelListWithProgress(
                userId: userId,
                moduleType: moduleType,
                onLevelSelected: onLevelSelected,
              )
            else
              _DefaultLevelList(onLevelSelected: onLevelSelected),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Default level list without progress tracking
class _DefaultLevelList extends StatelessWidget {
  final Function(int) onLevelSelected;

  const _DefaultLevelList({required this.onLevelSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final level = index + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getLevelColor(level),
              child: Text(
                '$level',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text('Level $level'),
            subtitle: Text(_getLevelDescription(level)),
            trailing: const Icon(Icons.arrow_forward),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
              ),
            ),
            onTap: () => onLevelSelected(level),
          ),
        );
      }),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getLevelDescription(int level) {
    switch (level) {
      case 1:
        return 'Beginner - Easy questions';
      case 2:
        return 'Intermediate - Moderate difficulty';
      case 3:
        return 'Advanced - Challenging scenarios';
      default:
        return '';
    }
  }
}

/// Widget to display level list with progress
class _LevelListWithProgress extends ConsumerWidget {
  final String userId;
  final String moduleType;
  final Function(int) onLevelSelected;

  const _LevelListWithProgress({
    required this.userId,
    required this.moduleType,
    required this.onLevelSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<int, double>>(
      // Fetch fresh progress directly from Supabase each time
      future: _fetchProgressDirectly(userId, moduleType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getLevelColor(index + 1),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text('Level ${index + 1}'),
                  trailing: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }),
          );
        }

        final progressMap = snapshot.data ?? {1: 0.0, 2: 0.0, 3: 0.0};

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final level = index + 1;
            final progress = progressMap[level] ?? 0.0;
            return _buildLevelTile(context, level, progress, onLevelSelected);
          }),
        );
      },
    );
  }

  // Fetch progress directly from Supabase
  Future<Map<int, double>> _fetchProgressDirectly(
    String userId,
    String moduleType,
  ) async {
    try {
      debugPrint('Fetching fresh progress for $moduleType...');

      // Get all questions for this module
      final questionsResponse = await SupabaseConfig.client
          .from('questions')
          .select('id, difficulty')
          .eq('module_type', moduleType);

      final questions = questionsResponse as List<dynamic>;

      // Group question IDs by difficulty
      final Map<int, Set<String>> questionIdsByDifficulty = {
        1: {},
        2: {},
        3: {},
      };
      for (final q in questions) {
        final difficulty = q['difficulty'] as int;
        final id = q['id'] as String;
        questionIdsByDifficulty[difficulty]?.add(id);
      }

      // Get user's correct answers
      final questionIds = questions.map((q) => q['id'] as String).toList();

      if (questionIds.isEmpty) {
        return {1: 0.0, 2: 0.0, 3: 0.0};
      }

      final progressResponse = await SupabaseConfig.client
          .from('user_progress')
          .select('question_id')
          .eq('user_id', userId)
          .eq('is_correct', true)
          .inFilter('question_id', questionIds);

      final userProgress = progressResponse as List<dynamic>;

      // Track unique completed questions per difficulty
      final Map<int, Set<String>> completedByDifficulty = {1: {}, 2: {}, 3: {}};

      for (final progress in userProgress) {
        final questionId = progress['question_id'] as String;
        // Find which difficulty this question belongs to
        for (final q in questions) {
          if (q['id'] == questionId) {
            final difficulty = q['difficulty'] as int;
            completedByDifficulty[difficulty]?.add(questionId);
            break;
          }
        }
      }

      // Calculate progress percentages
      final Map<int, double> progressMap = {};
      for (int level = 1; level <= 3; level++) {
        final total = questionIdsByDifficulty[level]?.length ?? 0;
        final completed = completedByDifficulty[level]?.length ?? 0;
        progressMap[level] = total == 0 ? 0.0 : completed / total;

        debugPrint(
          '$moduleType Level $level: $completed/$total = ${progressMap[level]}',
        );
      }

      return progressMap;
    } catch (e) {
      debugPrint('Error fetching progress: $e');
      return {1: 0.0, 2: 0.0, 3: 0.0};
    }
  }

  Widget _buildLevelTile(
    BuildContext context,
    int level,
    double? progress,
    Function(int) onTap,
  ) {
    final isComplete = progress == 1.0;
    final hasProgress = progress != null && progress > 0 && progress < 1.0;
    final levelColor = _getLevelColor(level);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => onTap(level),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isComplete
                ? levelColor.withOpacity(0.1)
                : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: levelColor.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: levelColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [levelColor, levelColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level $level',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getLevelDescription(level),
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isComplete)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                  )
                else if (hasProgress)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: levelColor,
                      ),
                    ),
                  )
                else
                  Icon(Icons.arrow_forward, color: levelColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getLevelDescription(int level) {
    switch (level) {
      case 1:
        return 'Beginner - Easy questions';
      case 2:
        return 'Intermediate - Moderate difficulty';
      case 3:
        return 'Advanced - Challenging scenarios';
      default:
        return '';
    }
  }
}

/// Widget to display recent activity feed
class _RecentActivityWidget extends ConsumerWidget {
  final String userId;

  const _RecentActivityWidget({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(recentActivityProvider(userId));

    return activityAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Failed to load activity: $error',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.red),
          ),
        ),
      ),
      data: (activities) {
        if (activities.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No activity yet.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            final question = activity.question;
            final moduleType = question?.moduleType ?? 'Unknown';
            final moduleName = _getModuleName(moduleType);
            final formattedDate = _formatDate(activity.attemptDate);
            final isCorrect = activity.isCorrect;

            return InkWell(
              onTap: () {
                if (question != null) {
                  _showQuestionReviewDialog(
                    context,
                    activity,
                    question,
                    isCorrect,
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isCorrect
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              moduleName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Level ${question?.difficulty ?? '?'} • $formattedDate',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          isCorrect ? Icons.check : Icons.close,
                          color: isCorrect ? Colors.green : Colors.red,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getModuleName(String moduleType) {
    switch (moduleType) {
      case 'phishing':
        return '📧 Phishing Email Detection';
      case 'password':
        return '🔒 Password Security';
      case 'attack':
        return '⚠️ Cyber Attack Recognition';
      default:
        return '📚 Training Module';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  Map<String, dynamic>? _parseJsonContent(String content) {
    try {
      // Try to parse JSON content for phishing emails
      // Format: {"senderName":"...","senderEmail":"...","subject":"...","body":"..."}
      final RegExp senderNamePattern = RegExp(r'"senderName"\s*:\s*"([^"]*)"');
      final RegExp senderEmailPattern = RegExp(
        r'"senderEmail"\s*:\s*"([^"]*)"',
      );
      final RegExp subjectPattern = RegExp(r'"subject"\s*:\s*"([^"]*)"');
      final RegExp bodyPattern = RegExp(r'"body"\s*:\s*"([^"]*)"');

      final senderNameMatch = senderNamePattern.firstMatch(content);
      final senderEmailMatch = senderEmailPattern.firstMatch(content);
      final subjectMatch = subjectPattern.firstMatch(content);
      final bodyMatch = bodyPattern.firstMatch(content);

      // Check if this is a phishing email format
      if (senderNameMatch != null ||
          senderEmailMatch != null ||
          subjectMatch != null ||
          bodyMatch != null) {
        final senderName = senderNameMatch?.group(1) ?? '';
        final senderEmail = senderEmailMatch?.group(1) ?? '';
        final subject = subjectMatch?.group(1) ?? '';
        final body =
            bodyMatch
                ?.group(1)
                ?.replaceAll(r'\n\n', '\n\n')
                .replaceAll(r'\n', '\n') ??
            '';

        return {
          'type': 'email',
          'senderName': senderName,
          'senderEmail': senderEmail,
          'subject': subject,
          'body': body,
        };
      }

      // Try old format with description and options
      final RegExp descPattern = RegExp(r'"description":"([^"]*)"');
      final RegExp optionsPattern = RegExp(r'"options":\[([^\]]*)\]');

      final descMatch = descPattern.firstMatch(content);
      final optionsMatch = optionsPattern.firstMatch(content);

      if (descMatch != null) {
        final description = descMatch.group(1);
        final List<String> options = [];

        if (optionsMatch != null) {
          final optionsStr = optionsMatch.group(1);
          if (optionsStr != null) {
            // Extract options from the string
            final optionItems = optionsStr.split('","');
            for (var item in optionItems) {
              final cleanItem = item.replaceAll('"', '').trim();
              if (cleanItem.isNotEmpty) {
                options.add(cleanItem);
              }
            }
          }
        }

        return {
          'type': 'question',
          'description': description,
          'options': options,
        };
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  void _showQuestionReviewDialog(
    BuildContext context,
    UserProgress activity,
    Question question,
    bool isCorrect,
  ) {
    // Parse the question content if it's JSON
    String questionText = question.content;
    List<String>? options;
    Map<String, String>? emailData;

    try {
      // Check if content looks like JSON
      if (question.content.trim().startsWith('{')) {
        final contentData = _parseJsonContent(question.content);

        if (contentData != null) {
          if (contentData['type'] == 'email') {
            // This is an email format
            emailData = {
              'senderName': contentData['senderName'] as String,
              'senderEmail': contentData['senderEmail'] as String,
              'subject': contentData['subject'] as String,
              'body': contentData['body'] as String,
            };
            questionText = 'Is this email safe or a phishing attempt?';
          } else if (contentData['type'] == 'question' &&
              contentData['description'] != null) {
            // This is the old question format
            questionText = contentData['description'] as String;
            if (contentData['options'] != null &&
                contentData['options'] is List) {
              options = List<String>.from(contentData['options'] as List);
            }
          }
        }
      }
    } catch (e) {
      // If parsing fails, use original content
      questionText = question.content;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCorrect
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [Colors.red.shade400, Colors.red.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCorrect ? 'Correct Answer' : 'Incorrect Answer',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Level ${question.difficulty} • ${_getModuleName(question.moduleType)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question
                        const Text(
                          'Question',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          questionText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Show email preview if this is phishing email detection
                        if (emailData != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // From field
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'From: ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            emailData['senderName']!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '<${emailData['senderEmail']!}>',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                // Subject field
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Subject: ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        emailData['subject']!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                // Body
                                Text(
                                  emailData['body']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Show options if available
                        if (options != null && options.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Options',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...options.asMap().entries.map((entry) {
                            final index = entry.key;
                            final option = entry.value;
                            final isCorrectOption =
                                option == question.correctAnswer;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCorrectOption
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCorrectOption
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.2),
                                  width: isCorrectOption ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isCorrectOption
                                          ? Colors.green
                                          : Colors.grey.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(
                                          65 + index,
                                        ), // A, B, C, D
                                        style: TextStyle(
                                          color: isCorrectOption
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isCorrectOption
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isCorrectOption
                                            ? Colors.green.shade700
                                            : Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                  if (isCorrectOption)
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                        const SizedBox(height: 20),
                        // Correct Answer (only show if no options or for clarity)
                        if (options == null || options.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Correct Answer',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        question.correctAnswer,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (options == null || options.isEmpty)
                          const SizedBox(height: 16),
                        // Explanation
                        const Text(
                          'Explanation',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.explanation,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Score info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9333EA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFF9333EA),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'You earned ${activity.scoreAwarded} points',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF9333EA),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatDate(activity.attemptDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Featured Infection Simulator Card - Prominent showcase card
class _FeaturedSimulatorCard extends StatelessWidget {
  final VoidCallback onTap;

  const _FeaturedSimulatorCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFDC2626), // Red-600
              Color(0xFFEF4444), // Red-500
              Color(0xFFF97316), // Orange-500
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'NEW EXPERIENCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.95),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bug_report, color: Colors.white, size: 28),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Malware Infection Simulator',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Experience what happens when you click malicious links. Feel the panic. Learn the lesson.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.95),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FeatureBadge(
                            icon: Icons.screen_rotation,
                            label: 'Immersive',
                          ),
                          _FeatureBadge(icon: Icons.vibration, label: 'Haptic'),
                          _FeatureBadge(
                            icon: Icons.psychology_outlined,
                            label: 'Educational',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
        ],
      ),
    );
  }
}
