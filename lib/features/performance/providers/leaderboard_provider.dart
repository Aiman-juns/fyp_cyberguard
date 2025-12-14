import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/supabase_config.dart';
import '../../../auth/providers/auth_provider.dart';

/// Leaderboard User Model
class LeaderboardUser {
  final String id;
  final String username;
  final String avatarId;
  final int totalScore;
  final int level;
  final int rank;

  LeaderboardUser({
    required this.id,
    required this.username,
    required this.avatarId,
    required this.totalScore,
    required this.level,
    required this.rank,
  });

  factory LeaderboardUser.fromJson(Map<String, dynamic> json, int rank) {
    return LeaderboardUser(
      id: json['id'] as String,
      username: json['full_name'] as String? ?? 'User',
      avatarId: json['avatar_id'] as String? ?? 'shield',
      totalScore: json['total_score'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      rank: rank,
    );
  }
}

/// Leaderboard Data Model
class LeaderboardData {
  final List<LeaderboardUser> topUsers;
  final LeaderboardUser? currentUser;
  final int totalUsers;
  final double percentageBetter; // Percentage of users current user is better than

  LeaderboardData({
    required this.topUsers,
    this.currentUser,
    required this.totalUsers,
    required this.percentageBetter,
  });
}

/// Leaderboard Provider - Fetch all-time leaderboard
final leaderboardProvider = FutureProvider<LeaderboardData>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) throw Exception('User not authenticated');

  try {
    // Fetch all users sorted by total_score descending
    final response = await SupabaseConfig.client
        .from('users')
        .select('id, full_name, avatar_id, total_score, level')
        .order('total_score', ascending: false)
        .limit(100); // Get top 100 users

    if (response == null) {
      throw Exception('Failed to fetch leaderboard data');
    }

    final List<dynamic> usersData = response as List<dynamic>;
    final totalUsers = usersData.length;

    // Create leaderboard users with ranks
    final List<LeaderboardUser> allUsers = [];
    for (int i = 0; i < usersData.length; i++) {
      allUsers.add(
        LeaderboardUser.fromJson(
          usersData[i] as Map<String, dynamic>,
          i + 1,
        ),
      );
    }

    // Find current user in the list
    LeaderboardUser? currentUserData;
    int currentUserRank = -1;
    
    for (int i = 0; i < allUsers.length; i++) {
      if (allUsers[i].id == currentUser.id) {
        currentUserData = allUsers[i];
        currentUserRank = i + 1;
        break;
      }
    }

    // If current user not in top 100, fetch their specific data
    if (currentUserData == null) {
      final userResponse = await SupabaseConfig.client
          .from('users')
          .select('id, full_name, avatar_id, total_score, level')
          .eq('id', currentUser.id)
          .single();

      if (userResponse != null) {
        // Count how many users have higher score
        final higherScoreCount = await SupabaseConfig.client
            .from('users')
            .select('id')
            .gt('total_score', userResponse['total_score'] ?? 0);

        currentUserRank = (higherScoreCount as List).length + 1;
        
        currentUserData = LeaderboardUser.fromJson(
          userResponse as Map<String, dynamic>,
          currentUserRank,
        );
      }
    }

    // Calculate percentage better than others
    double percentageBetter = 0.0;
    if (currentUserRank > 0 && totalUsers > 1) {
      percentageBetter = ((totalUsers - currentUserRank) / (totalUsers - 1)) * 100;
    }

    return LeaderboardData(
      topUsers: allUsers,
      currentUser: currentUserData,
      totalUsers: totalUsers,
      percentageBetter: percentageBetter,
    );
  } catch (e) {
    print('Error fetching leaderboard: $e');
    rethrow;
  }
});
