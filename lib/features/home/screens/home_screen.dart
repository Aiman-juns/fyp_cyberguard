import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../core/services/avatar_service.dart';
import '../../../config/supabase_config.dart';
import '../../resources/providers/resources_provider.dart';
import '../../resources/providers/progress_provider.dart';
import '../../training/providers/training_provider.dart';
import '../providers/daily_challenge_provider.dart';
import '../../performance/providers/performance_provider.dart';
import 'global_search_screen.dart';
import 'dart:math' as math;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: authState.when(
          data: (user) {
            if (user == null) {
              return Center(child: Text('Please log in'));
            }

            final avatar = AvatarService.getAvatarById(user.avatarId);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // User Avatar - Click to open drawer
                        GestureDetector(
                          onTap: () {
                            Scaffold.of(context).openDrawer();
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: avatar.color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: avatar.color.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              avatar.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Greeting
                        Expanded(
                          child: Text(
                            'Hello, ${user.fullName.split(' ')[0]} 👋',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        // Search Icon - Open Global Search
                        IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const GlobalSearchScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Hero Banner with Gradient
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF3B82F6).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Decorative circles
                          Positioned(
                            right: 100,
                            top: -20,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 20,
                            bottom: -30,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                          ),
                          // Text Content
                          Positioned(
                            left: 24,
                            top: 0,
                            bottom: 0,
                            right: 120,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Secure Your Digital Life',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Learn to protect yourself online',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.95),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Shield Icon on the right
                          Positioned(
                            right: 16,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Image.asset(
                                'assets/images/icons/shield.png',
                                width: 100,
                                height: 100,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to icon if image not found
                                  print('Shield image error: $error');
                                  return Icon(
                                    Icons.shield,
                                    size: 80,
                                    color: Colors.white.withOpacity(0.9),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Quick Stats Cards - Dynamic Data
                  Consumer(
                    builder: (context, ref, child) {
                      // Get streak from daily challenge
                      final dailyChallengeAsync = ref.watch(dailyChallengeProvider);
                      final streakCount = dailyChallengeAsync.when(
                        data: (state) => state.streakCount,
                        loading: () => 0,
                        error: (_, __) => 0,
                      );

                      // Get achievements count from performanceProvider
                      final performanceAsync = ref.watch(performanceProvider);
                      final badgeCount = performanceAsync.when(
                        data: (stats) => stats.achievements.where((a) => a.isUnlocked).length,
                        loading: () => 0,
                        error: (_, __) => 0,
                      );

                      // Calculate training modules completed (≥80% completion)
                      int completedModules = 0;
                      final userId = SupabaseConfig.client.auth.currentUser?.id;

                      if (userId != null) {
                        // Check phishing module
                        final phishingStats = ref.watch(
                          moduleStatsProvider('phishing'),
                        );
                        phishingStats.whenData((stats) {
                          if (stats.completionPercentage >= 80) {
                            completedModules++;
                          }
                        });

                        // Check password module
                        final passwordStats = ref.watch(
                          moduleStatsProvider('password'),
                        );
                        passwordStats.whenData((stats) {
                          if (stats.completionPercentage >= 80) {
                            completedModules++;
                          }
                        });

                        // Check attack module
                        final attackStats = ref.watch(
                          moduleStatsProvider('attack'),
                        );
                        attackStats.whenData((stats) {
                          if (stats.completionPercentage >= 80) {
                            completedModules++;
                          }
                        });
                      }

                      return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildQuickStatCard(
                                    context,
                                    icon: Icons.local_fire_department,
                                    value: streakCount.toString(),
                                    label: 'Day Streak',
                                    color: Color(0xFFFF6B35),
                                    iconColor: Color(0xFFFF6B35),
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickStatCard(
                                    context,
                                    icon: Icons.emoji_events,
                                    value: badgeCount.toString(),
                                    label: 'Badges',
                                    color: Color(0xFFFBBF24),
                                    iconColor: Color(0xFFF59E0B),
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickStatCard(
                                    context,
                                    icon: Icons.check_circle_outline,
                                    value: completedModules.toString(),
                                    label: 'Module',
                                    color: Color(0xFF10B981),
                                    iconColor: Color(0xFF059669),
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fade(duration: 500.ms, delay: 100.ms)
                          .slideY(begin: 0.1, end: 0);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Daily Security Tip - Interactive
                  const _SecurityTipCard()
                      .animate()
                      .fade(duration: 500.ms, delay: 200.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 32),

                  // Learning Progress Section with View All
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Learning Progress',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/resources'),
                          child: Text(
                            'View All',
                            style: TextStyle(
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Learning Progress Card
                  Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final resourcesAsync = ref.watch(resourcesProvider);

                            return resourcesAsync.when(
                              data: (resources) {
                                // Calculate progress from local storage
                                int totalCourses = 0;
                                int completedCourses = 0;
                                double totalProgress = 0.0;

                                // Count resource progress
                                for (var resource in resources) {
                                  // For "Types of Cyber Attack", count individual attack types
                                  if (resource.title ==
                                          'Types of Cyber Attack' &&
                                      resource.attackTypes != null &&
                                      resource.attackTypes!.isNotEmpty) {
                                    for (var attackType
                                        in resource.attackTypes!) {
                                      final attackProgressId =
                                          '${resource.id}_${attackType.id}';
                                      final attackProgress = ref.watch(
                                        resourceProgressProvider(
                                          attackProgressId,
                                        ),
                                      );
                                      totalCourses++;
                                      if (attackProgress.isCompleted) {
                                        completedCourses++;
                                        totalProgress += 100.0;
                                      } else if (attackProgress.minutesWatched >
                                          0) {
                                        totalProgress += 50.0;
                                      }
                                    }
                                  } else {
                                    // Regular resource
                                    totalCourses++;
                                    final progress = ref.watch(
                                      resourceProgressProvider(resource.id),
                                    );
                                    if (progress.isCompleted) {
                                      completedCourses++;
                                      totalProgress += 100.0;
                                    } else if (progress.minutesWatched > 0) {
                                      totalProgress +=
                                          progress.progressPercentage;
                                    }
                                  }
                                }

                                // Add training module progress (3 modules)
                                final userId =
                                    SupabaseConfig.client.auth.currentUser?.id;
                                if (userId != null) {
                                  // Phishing module
                                  final phishingProgress = ref.watch(
                                    phishingProgressProvider(userId),
                                  );
                                  totalCourses++;
                                  phishingProgress.whenData((progress) {
                                    final correctAnswers = progress
                                        .where((p) => p.isCorrect)
                                        .length;
                                    if (correctAnswers > 0) {
                                      completedCourses++;
                                      totalProgress +=
                                          (correctAnswers / 10 * 100).clamp(
                                            0,
                                            100,
                                          );
                                    }
                                  });

                                  // Password module
                                  final passwordProgress = ref.watch(
                                    passwordProgressProvider(userId),
                                  );
                                  totalCourses++;
                                  passwordProgress.whenData((progress) {
                                    final correctAnswers = progress
                                        .where((p) => p.isCorrect)
                                        .length;
                                    if (correctAnswers > 0) {
                                      completedCourses++;
                                      totalProgress +=
                                          (correctAnswers / 10 * 100).clamp(
                                            0,
                                            100,
                                          );
                                    }
                                  });

                                  // Attack module
                                  final attackProgress = ref.watch(
                                    attackProgressProvider(userId),
                                  );
                                  totalCourses++;
                                  attackProgress.whenData((progress) {
                                    final correctAnswers = progress
                                        .where((p) => p.isCorrect)
                                        .length;
                                    if (correctAnswers > 0) {
                                      completedCourses++;
                                      totalProgress +=
                                          (correctAnswers / 10 * 100).clamp(
                                            0,
                                            100,
                                          );
                                    }
                                  });
                                }

                                final percentage = totalCourses > 0
                                    ? (totalProgress / totalCourses)
                                    : 0.0;

                                return Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Overall Progress',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '${percentage.toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            FractionallySizedBox(
                                              widthFactor: percentage / 100,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Color(0xFF3B82F6),
                                                      Color(0xFF2563EB),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFF3B82F6,
                                                      ).withOpacity(0.4),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$completedCourses of $totalCourses courses completed',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loading: () => Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (error, stack) => Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text('Error loading progress'),
                              ),
                            );
                          },
                        ),
                      )
                      .animate()
                      .fade(duration: 500.ms)
                      .slideY(begin: 0.1, end: 0)
                      .animate(delay: 100.ms),

                  const SizedBox(height: 32),

                  // Dashboard Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/training'),
                          child: Text(
                            'View All',
                            style: TextStyle(
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Two Large Cards: Training Hub and Resources
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        // Card 1: Resources (moved first)
                        Expanded(
                          child:
                              GestureDetector(
                                    onTap: () {
                                      context.push('/resources');
                                    },
                                    child: Container(
                                      height: 140,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.grey.shade800
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              isDark ? 0.3 : 0.08,
                                            ),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Color(
                                                0xFF3B82F6,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Icon(
                                              Icons.auto_stories,
                                              size: 48,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Resources',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Learning materials',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.grey.shade400
                                                  : Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fade(duration: 500.ms)
                                  .slideY(begin: 0.1, end: 0)
                                  .animate(delay: 200.ms),
                        ),
                        const SizedBox(width: 16),
                        // Card 2: Training Hub (moved second)
                        Expanded(
                          child:
                              GestureDetector(
                                    onTap: () {
                                      context.push('/training');
                                    },
                                    child: Container(
                                      height: 140,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.grey.shade800
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              isDark ? 0.3 : 0.08,
                                            ),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Color(
                                                0xFF10B981,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Icon(
                                              Icons.model_training,
                                              size: 32,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Training Hub',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Practice modules',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.grey.shade400
                                                  : Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fade(duration: 500.ms)
                                  .slideY(begin: 0.1, end: 0)
                                  .animate(delay: 300.ms),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
          loading: () => Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  static Widget _buildQuickStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// Interactive Security Tip Card Widget
class _SecurityTipCard extends StatefulWidget {
  const _SecurityTipCard();

  @override
  State<_SecurityTipCard> createState() => _SecurityTipCardState();
}

class _SecurityTipCardState extends State<_SecurityTipCard> {
  int _currentTipIndex = 0;

  final List<String> _securityTips = [
    'Always use unique passwords for each account',
    'Enable two-factor authentication whenever possible',
    'Never click on suspicious links in emails or messages',
    'Keep your software and apps up to date',
    'Use a password manager to store your passwords securely',
    'Be cautious when using public Wi-Fi networks',
    'Regularly backup your important data',
    'Check the URL before entering sensitive information',
    'Don\'t share personal information on social media',
    'Use strong passwords with letters, numbers, and symbols',
    'Be wary of phishing emails pretending to be from trusted sources',
    'Lock your devices when not in use',
    'Use encryption for sensitive files and communications',
    'Review app permissions before installing',
    'Don\'t use the same security questions across multiple sites',
  ];

  void _showNextTip() {
    setState(() {
      _currentTipIndex = (_currentTipIndex + 1) % _securityTips.length;
    });
  }

  @override
  void initState() {
    super.initState();
    // Show random tip on first load
    _currentTipIndex = math.Random().nextInt(_securityTips.length);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: _showNextTip,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey<int>(_currentTipIndex),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFFEF3C7),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFFFBBF24).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    color: Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Today\'s Security Tip',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.touch_app,
                            size: 16,
                            color: Color(0xFF92400E).withOpacity(0.6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _securityTips[_currentTipIndex],
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF78350F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
