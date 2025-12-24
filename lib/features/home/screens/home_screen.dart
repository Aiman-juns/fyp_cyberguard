import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../core/services/avatar_service.dart';
import '../../../config/supabase_config.dart';
import '../../support/screens/emergency_support_screen.dart';
import '../../resources/providers/resources_provider.dart';
import '../../resources/providers/progress_provider.dart';
import '../../training/providers/training_provider.dart';
import '../../../shared/widgets/security_fab.dart';

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
                        // User Avatar
                        Container(
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
                        const SizedBox(width: 12),
                        // Greeting
                        Expanded(
                          child: Text(
                            'Hello, ${user.fullName.split(' ')[0]} 👋',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Search Icon (inactive)
                        IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            // No action
                          },
                        ),
                        // Settings Icon
                        IconButton(
                          icon: Icon(Icons.settings),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
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
                          // Watermark Icon
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: Icon(
                              Icons.shield_outlined,
                              size: 120,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          // Decorative circles
                          Positioned(
                            right: 40,
                            top: 10,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                          // Text Content
                          Positioned(
                            left: 24,
                            top: 0,
                            bottom: 0,
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
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Quick Stats Cards
                  Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildQuickStatCard(
                                context,
                                icon: Icons.local_fire_department,
                                value: '7',
                                label: 'Day Streak',
                                color: Color(0xFFFF6B35),
                                iconColor: Color(0xFFFF6B35),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickStatCard(
                                context,
                                icon: Icons.emoji_events,
                                value: '12',
                                label: 'Badges',
                                color: Color(0xFFFBBF24),
                                iconColor: Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickStatCard(
                                context,
                                icon: Icons.access_time,
                                value: '4.5h',
                                label: 'Learning',
                                color: Color(0xFF10B981),
                                iconColor: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fade(duration: 500.ms, delay: 100.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Daily Security Tip
                  Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
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
                                    Text(
                                      'Today\'s Security Tip',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Always use unique passwords for each account',
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
                      )
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
                            color: Color(0xFF1E293B),
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
                            color: Color(0xFF1E293B),
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
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.08,
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
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Learning materials',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
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
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.08,
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
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Practice modules',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
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
      floatingActionButton: const SecurityFAB(),
    );
  }

  static Widget _buildQuickStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
