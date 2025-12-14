import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/performance_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../../../core/services/avatar_service.dart';

class PerformanceScreen extends ConsumerStatefulWidget {
  const PerformanceScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends ConsumerState<PerformanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF3B82F6),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF3B82F6),
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: 'Performance'),
              Tab(text: 'Leaderboard'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PerformanceTab(),
              _LeaderboardTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _PerformanceTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceAsyncValue = ref.watch(performanceProvider);

    return performanceAsyncValue.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Current Level and Total Score
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Level',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Level ${stats.level}',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Score',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          '${stats.totalScore} pts',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            // Accuracy and Attempts
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade600,
                          Colors.orange.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.track_changes,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Accuracy',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '${stats.accuracyPercentage.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade600,
                          Colors.purple.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.format_list_numbered,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Attempts',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '${stats.totalAttempts}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            Text(
              'Module Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16.0),
            // Module Progress Cards
            _ModuleProgressCard(
              title: 'Phishing Detection',
              stats: stats.moduleStats['phishing'],
              color: Colors.blue,
            ),
            const SizedBox(height: 12.0),
            _ModuleProgressCard(
              title: 'Password Dojo',
              stats: stats.moduleStats['password'],
              color: Colors.green,
            ),
            const SizedBox(height: 12.0),
            _ModuleProgressCard(
              title: 'Cyber Attack Analyst',
              stats: stats.moduleStats['attack'],
              color: Colors.orange,
            ),
            const SizedBox(height: 24.0),
            Text(
              'Medals & Achievements',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16.0),
            _AchievementsView(stats: stats),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading performance: $error'),
          ],
        ),
      ),
    );
  }
}

class _ModuleProgressCard extends StatelessWidget {
  final String title;
  final ModuleStats? stats;
  final Color color;

  const _ModuleProgressCard({
    required this.title,
    required this.stats,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final stats = this.stats;
    if (stats == null) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade700
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
              const SizedBox(height: 12.0),
              Text(
                'No attempts yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.school, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${stats.correct}/${stats.attempts}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: LinearProgressIndicator(
                value: stats.completionPercentage / 100,
                minHeight: 8.0,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 12.0),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completion',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      '${stats.completionPercentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accuracy',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      '${stats.accuracy.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      '${stats.totalScore}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementsView extends ConsumerWidget {
  final PerformanceStats stats;

  const _AchievementsView({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...stats.achievements.map((achievement) {
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: _AchievementCard(achievement: achievement),
            );
          }),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  IconData _getIconData(IconType type) {
    return switch (type) {
      IconType.trophy => Icons.emoji_events,
      IconType.flash => Icons.flash_on,
      IconType.verified => Icons.verified,
      IconType.star => Icons.star,
      IconType.shield => Icons.shield,
      IconType.rocket => Icons.rocket_launch,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: achievement.isUnlocked
            ? (isDark
                  ? Colors.amber.shade900.withOpacity(0.3)
                  : Colors.amber.shade50)
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.isUnlocked
              ? (isDark ? Colors.amber.shade700 : Colors.amber.shade300)
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          width: 2,
        ),
        boxShadow: achievement.isUnlocked
            ? [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: achievement.isUnlocked
                    ? LinearGradient(
                        colors: [Colors.amber.shade400, Colors.amber.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: achievement.isUnlocked ? null : Colors.grey.shade300,
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: Colors.transparent,
                child: Icon(
                  _getIconData(achievement.iconType),
                  color: achievement.isUnlocked ? Colors.white : Colors.grey,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              achievement.title,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4.0),
            SizedBox(
              width: 80,
              child: Text(
                achievement.description,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (achievement.isUnlocked) ...[
              const SizedBox(height: 8.0),
              Text(
                'Unlocked',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.amber,
                  fontSize: 9,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Leaderboard Tab
class _LeaderboardTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return leaderboardAsync.when(
      data: (leaderboard) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(leaderboardProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // User Rank Card (if not in top 3)
              if (leaderboard.currentUser != null &&
                  leaderboard.currentUser!.rank > 3)
                _UserRankCard(
                  user: leaderboard.currentUser!,
                  percentageBetter: leaderboard.percentageBetter,
                ),
              if (leaderboard.currentUser != null &&
                  leaderboard.currentUser!.rank > 3)
                const SizedBox(height: 24),
              // Podium Section
              _PodiumSection(topUsers: leaderboard.topUsers.take(3).toList()),
              const SizedBox(height: 24),
              // Rankings List (4th place onwards)
              if (leaderboard.topUsers.length > 3)
                _RankingsList(
                  users: leaderboard.topUsers.skip(3).toList(),
                  currentUserId: leaderboard.currentUser?.id,
                ),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading leaderboard: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(leaderboardProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// User Rank Card Widget
class _UserRankCard extends StatelessWidget {
  final LeaderboardUser user;
  final double percentageBetter;

  const _UserRankCard({
    required this.user,
    required this.percentageBetter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFFB923C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#${user.rank}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You are doing better than',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${percentageBetter.toStringAsFixed(0)}% of other players!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Podium Section Widget
class _PodiumSection extends StatelessWidget {
  final List<LeaderboardUser> topUsers;

  const _PodiumSection({required this.topUsers});

  @override
  Widget build(BuildContext context) {
    // Ensure we have at least 3 users (pad with nulls if needed)
    final first = topUsers.length > 0 ? topUsers[0] : null;
    final second = topUsers.length > 1 ? topUsers[1] : null;
    final third = topUsers.length > 2 ? topUsers[2] : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7E22CE).withOpacity(0.3),
            const Color(0xFF3B82F6).withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Top row with 1st place
          if (first != null) _buildFirstPlace(first),
          const SizedBox(height: 16),
          // Bottom row with 2nd and 3rd
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (second != null)
                Expanded(child: _buildSecondPlace(second))
              else
                const Expanded(child: SizedBox()),
              const SizedBox(width: 12),
              if (third != null)
                Expanded(child: _buildThirdPlace(third))
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFirstPlace(LeaderboardUser user) {
    final avatar = AvatarService.getAvatarById(user.avatarId);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: avatar.color,
                child: Icon(avatar.icon, size: 40, color: Colors.white),
              ),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF59E0B),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                user.username,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${user.totalScore} DP',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: const Center(
            child: Text(
              '1',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondPlace(LeaderboardUser user) {
    final avatar = AvatarService.getAvatarById(user.avatarId);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF94A3B8).withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: avatar.color,
                child: Icon(avatar.icon, size: 32, color: Colors.white),
              ),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF94A3B8),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          user.username,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          '${user.totalScore} DP',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: const Center(
            child: Text(
              '2',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThirdPlace(LeaderboardUser user) {
    final avatar = AvatarService.getAvatarById(user.avatarId);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: avatar.color,
                child: Icon(avatar.icon, size: 32, color: Colors.white),
              ),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEA580C),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          user.username,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          '${user.totalScore} DP',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: const Center(
            child: Text(
              '3',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Rankings List Widget
class _RankingsList extends StatelessWidget {
  final List<LeaderboardUser> users;
  final String? currentUserId;

  const _RankingsList({
    required this.users,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = users[index];
          final isCurrentUser = user.id == currentUserId;
          final avatar = AvatarService.getAvatarById(user.avatarId);

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? const Color(0xFF9333EA).withOpacity(0.1)
                  : index % 2 == 0
                      ? const Color(0xFFF8FAFC)
                      : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: isCurrentUser
                  ? Border.all(
                      color: const Color(0xFF9333EA),
                      width: 2,
                    )
                  : null,
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                // Rank number
                SizedBox(
                  width: 32,
                  child: Text(
                    '${user.rank}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isCurrentUser ? FontWeight.bold : FontWeight.w600,
                      color: isCurrentUser
                          ? const Color(0xFF9333EA)
                          : const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 12),
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: avatar.color,
                  child: Icon(avatar.icon, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                // Username
                Expanded(
                  child: Text(
                    user.username,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isCurrentUser ? FontWeight.bold : FontWeight.w500,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Score
                Text(
                  '${user.totalScore} DP',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCurrentUser
                        ? const Color(0xFF9333EA)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Models are imported from performance_provider.dart at the top
