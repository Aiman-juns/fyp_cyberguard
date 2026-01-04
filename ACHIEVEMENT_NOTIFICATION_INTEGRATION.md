// Example of how to integrate Achievement Notifications
// 
// This file shows how to trigger achievement unlocked notifications
// with celebration effects throughout your app.

/*

1. IMPORT THE SERVICE
   ==================
   
   import 'package:cats_flutter/core/services/achievement_notification_service.dart';
   import 'package:cats_flutter/features/performance/providers/performance_provider.dart';

2. CHECK FOR NEW ACHIEVEMENTS
   ==========================
   
   After completing an action (quiz, video watch, etc.), check if new achievements were unlocked:
   
   Future<void> checkAndNotifyAchievements(BuildContext context, WidgetRef ref) async {
     final userId = SupabaseConfig.client.auth.currentUser?.id;
     if (userId == null) return;
     
     // Get current achievements
     final currentAchievements = await fetchUserAchievements(userId);
     
     // Compare with previous achievements to find newly unlocked ones
     // You can store the previous state in SharedPreferences or a provider
     final newAchievements = currentAchievements.where(
       (achievement) => achievement.isUnlocked && !wasPreviouslyUnlocked(achievement.id)
     ).toList();
     
     // Show notification for each new achievement
     for (final achievement in newAchievements) {
       if (context.mounted) {
         AchievementNotificationService.showAchievementUnlocked(context, achievement);
         // Add a delay between multiple achievements
         await Future.delayed(const Duration(milliseconds: 500));
       }
     }
   }

3. TRIGGER ON QUIZ COMPLETION
   ===========================
   
   In your quiz completion handler:
   
   void _onQuizCompleted() async {
     // Save quiz results first
     await _saveQuizResults();
     
     // Then check for achievements
     if (mounted) {
       await checkAndNotifyAchievements(context, ref);
     }
     
     // Navigate to results page
     context.go('/results');
   }

4. TRIGGER ON VIDEO COMPLETION
   ============================
   
   When a video is marked as complete:
   
   Future<void> _markVideoComplete() async {
     await videoProgressProvider.markCompleted(resourceId);
     
     // Check for "Diligent Student" achievement (5 videos watched)
     if (mounted) {
       await checkAndNotifyAchievements(context, ref);
     }
   }

5. TRIGGER ON LEVEL UP
   ====================
   
   When user levels up:
   
   void _onLevelUp(int newLevel) async {
     // Update user level
     await updateUserLevel(newLevel);
     
     // Check for level-based achievements (Defender at level 5, Master Guardian at level 10)
     if (mounted) {
       await checkAndNotifyAchievements(context, ref);
     }
   }

6. MANUAL TRIGGER (FOR TESTING)
   =============================
   
   To manually show an achievement notification:
   
   ElevatedButton(
     onPressed: () {
       final testAchievement = Achievement(
         id: 'test',
         badgeType: 'test',
         title: 'Test Achievement',
         description: 'This is a test!',
         iconType: IconType.trophy,
         isUnlocked: true,
       );
       
       AchievementNotificationService.showAchievementUnlocked(
         context,
         testAchievement,
       );
     },
     child: Text('Show Achievement'),
   ),

7. TRACKING PREVIOUS ACHIEVEMENTS
   ==============================
   
   Use SharedPreferences to track which achievements were previously shown:
   
   import 'package:shared_preferences/shared_preferences.dart';
   
   Future<bool> wasPreviouslyUnlocked(String achievementId) async {
     final prefs = await SharedPreferences.getInstance();
     return prefs.getBool('achievement_$achievementId') ?? false;
   }
   
   Future<void> markAchievementAsShown(String achievementId) async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.setBool('achievement_$achievementId', true);
   }

8. ACHIEVEMENTS LIST
   =================
   
   Current achievements available:
   
   - First Steps: Complete your first quiz
   - Quick Learner: 10 correct answers
   - Security Expert: Complete all modules
   - Perfect Score: 100% accuracy in a module
   - Defender: Reach level 5+
   - Speedrunner: Answer 5 questions in 1 minute
   - Diligent Student: Watch 5 training videos (NEW)
   - Knowledge Seeker: Complete 50 questions (NEW)
   - Master Guardian: Reach level 10 (NEW)

*/
