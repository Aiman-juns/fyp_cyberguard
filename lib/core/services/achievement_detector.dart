import 'package:flutter/foundation.dart';
import '../../features/performance/providers/performance_provider.dart';

/// Simple service to detect newly unlocked achievements by comparing states
class AchievementDetector {
  /// Compare two achievement lists and return newly unlocked ones
  static List<Achievement> detectNewAchievements({
    required List<Achievement> previousAchievements,
    required List<Achievement> currentAchievements,
  }) {
    final newlyUnlocked = <Achievement>[];
    
    debugPrint('🔍 ACHIEVEMENT DETECTOR: Comparing achievements...');
    debugPrint('  Previous: ${previousAchievements.where((a) => a.isUnlocked).length} unlocked');
    debugPrint('  Current: ${currentAchievements.where((a) => a.isUnlocked).length} unlocked');
    
    for (final current in currentAchievements) {
      // Find the same achievement in previous state
      final previous = previousAchievements.firstWhere(
        (a) => a.id == current.id,
        orElse: () => Achievement(
          id: current.id,
          badgeType: current.badgeType,
          title: current.title,
          description: current.description,
          iconType: current.iconType,
        ),
      );
      
      // Log each achievement's state
      debugPrint('  📌 ${current.title}: was=${previous.isUnlocked}, now=${current.isUnlocked}');
      
      // If it wasn't unlocked before but is now, it's new!
      if (!previous.isUnlocked && current.isUnlocked) {
        debugPrint('  🎉 NEW UNLOCK: ${current.title}');
        newlyUnlocked.add(current);
      }
    }
    
    debugPrint('  ✅ Found ${newlyUnlocked.length} new achievements');
    return newlyUnlocked;
  }
}
