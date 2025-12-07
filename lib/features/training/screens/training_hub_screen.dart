import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/supabase_config.dart';
import '../providers/training_provider.dart';
import 'phishing_screen.dart';
import 'password_dojo_screen.dart';
import 'cyber_attack_screen.dart';
import 'scam_simulator_screen.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = SupabaseConfig.client.auth.currentUser?.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade700, Colors.purple.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose a difficulty level before starting',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),
          _ModuleCard(
            title: 'Phishing Detection',
            description: 'Learn to identify phishing emails and websites',
            icon: Icons.mail_outline,
            color: Colors.blue,
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
            color: Colors.green,
            onTap: () => _showLevelSelectionDialog(
              context,
              'Password Dojo',
              (difficulty) => PasswordDojoLoaderScreen(difficulty: difficulty),
              ref,
            ),
          ),
          const SizedBox(height: 12.0),
          _ModuleCard(
            title: 'Cyber Attack Analyst',
            description: 'Analyze and identify cyber attack scenarios',
            icon: Icons.shield,
            color: Colors.orange,
            onTap: () => _showLevelSelectionDialog(
              context,
              'Cyber Attack Analyst',
              (difficulty) => CyberAttackScreen(difficulty: difficulty),
              ref,
            ),
          ),
          const SizedBox(height: 32.0),

          // Simulation Games Section
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Simulation Games (AI)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          _ModuleCard(
            title: 'Hacker Chat: Discord Scam',
            description: 'Interactive chat simulation - Can you spot the scammer?',
            icon: Icons.chat_bubble_outline,
            color: Color(0xFF5865F2),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScamSimulatorScreen(scenario: 'discord'),
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          _ModuleCard(
            title: 'Hacker Chat: Bank Phishing',
            description: 'Can you identify a fake bank representative?',
            icon: Icons.account_balance,
            color: Color(0xFF0066CC),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScamSimulatorScreen(scenario: 'bank'),
              ),
            ),
          ),
          const SizedBox(height: 32.0),

          // Recent Activity Section
          Text(
            'Recent Activity',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12.0),
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

class _ModuleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 30),
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
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_forward, color: color, size: 20),
              ),
            ],
          ),
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
    if (moduleName.contains('Attack')) return 'attack';
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
    final progressAsync = ref.watch(
      moduleProgressProvider((userId: userId, moduleType: moduleType)),
    );

    return progressAsync.when(
      loading: () => Column(
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
      ),
      error: (error, stack) => Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          final level = index + 1;
          return _buildLevelTile(context, level, null, onLevelSelected);
        }),
      ),
      data: (progressMap) {
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

            return Container(
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
}
