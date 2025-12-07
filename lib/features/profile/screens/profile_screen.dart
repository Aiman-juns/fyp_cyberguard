import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../core/services/avatar_service.dart';
import '../../../config/supabase_config.dart';
import '../../performance/providers/performance_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  Future<void> _updateAvatar(BuildContext context, WidgetRef ref, String newAvatarId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      // Update in Supabase
      await SupabaseConfig.client
          .from('users')
          .update({'avatar_id': newAvatarId})
          .eq('id', userId);

      // Refresh auth state by invalidating the provider
      ref.invalidate(authProvider);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update avatar: $e')),
        );
      }
    }
  }

  void _showAvatarPicker(BuildContext context, WidgetRef ref, String currentAvatarId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose Your Avatar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: AvatarService.getAllAvatars().length,
                itemBuilder: (context, index) {
                  final avatar = AvatarService.getAllAvatars()[index];
                  final isSelected = avatar.id == currentAvatarId;

                  return GestureDetector(
                    onTap: () => _updateAvatar(context, ref, avatar.id),
                    child: Container(
                      decoration: BoxDecoration(
                        color: avatar.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? avatar.color : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            avatar.icon,
                            size: 48,
                            color: avatar.color,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            avatar.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: avatar.color,
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: avatar.color,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return authState.when(
      data: (user) {
        if (user == null) {
          return Center(
            child: Text('Please log in to view your profile'),
          );
        }

        final avatar = AvatarService.getAvatarById(user.avatarId);
        final performanceAsync = ref.watch(performanceProvider);
        final achievementsAsync = ref.watch(userAchievementsProvider);

        return SingleChildScrollView(
          child: Column(
            children: [
              // Header with Avatar - Blue Gradient Background
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2196F3),  // Material Blue
                      const Color(0xFF1976D2),  // Darker Blue
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Name and Quote
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.quote,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Avatar with Edit button
                      Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: avatar.color,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                avatar.icon,
                                size: 56,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _showAvatarPicker(context, ref, user.avatarId),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: performanceAsync.when(
                  data: (stats) {
                    return Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Attempts',
                            value: stats.totalAttempts.toString(),
                            icon: Icons.play_circle_outline,
                            color: Colors.blue,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Accuracy',
                            value: '${stats.accuracyPercentage.toStringAsFixed(0)}%',
                            icon: Icons.trending_up,
                            color: Colors.green,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Total Score',
                            value: stats.totalScore.toString(),
                            icon: Icons.star,
                            color: Colors.orange,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading stats: $e'),
                ),
              ),

              const SizedBox(height: 24),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Trophy Case Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Trophy Case',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    achievementsAsync.when(
                      data: (achievements) {
                        if (achievements.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.emoji_events_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No badges yet!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Complete training modules to earn your first badge',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: achievements.length,
                          itemBuilder: (context, index) {
                            final achievement = achievements[index];
                            return _BadgeCard(
                              title: achievement.title,
                              icon: _getAchievementIcon(achievement.badgeType),
                              color: _getAchievementColor(achievement.badgeType),
                              earnedAt: achievement.earnedAt ?? DateTime.now(),
                              isDark: isDark,
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error loading badges: $e'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  IconData _getAchievementIcon(String type) {
    switch (type) {
      case 'perfect_score':
        return Icons.stars;
      case 'speed_demon':
        return Icons.flash_on;
      case 'first_module':
        return Icons.school;
      case 'streak_master':
        return Icons.local_fire_department;
      default:
        return Icons.emoji_events;
    }
  }

  Color _getAchievementColor(String type) {
    switch (type) {
      case 'perfect_score':
        return Colors.amber;
      case 'speed_demon':
        return Colors.orange;
      case 'first_module':
        return Colors.blue;
      case 'streak_master':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final DateTime earnedAt;
  final bool isDark;

  const _BadgeCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.earnedAt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
