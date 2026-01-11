import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Migration Service - One-time migration from SharedPreferences to Supabase
/// This service runs automatically on app startup to migrate existing progress data
class MigrationService {
  static final _supabase = Supabase.instance.client;
  static const _migrationKey = 'migration_v1_completed';

  /// Check if migration is needed and execute if necessary
  static Future<void> migrate() async {
    debugPrint('🔄 MIGRATION: Checking if migration is needed...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final migrationCompleted = prefs.getBool(_migrationKey) ?? false;

      if (migrationCompleted) {
        debugPrint('✅ MIGRATION: Already completed, skipping');
        return;
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ MIGRATION: User not logged in, will try again later');
        return;
      }

      debugPrint('🚀 MIGRATION: Starting migration for user: $userId');

      // Migrate video progress
      await _migrateVideoProgress(prefs, userId);

      // Migrate daily challenge progress
      await _migrateDailyChallengeProgress(prefs, userId);

      // Mark migration as complete
      await prefs.setBool(_migrationKey, true);
      
      // IMPORTANT: Clear SharedPreferences to prevent cross-user data sharing
      debugPrint('🧹 MIGRATION: Clearing SharedPreferences after successful migration...');
      await _clearSharedPreferencesData(prefs);
      
      debugPrint('✅ MIGRATION: Complete!');
    } catch (e) {
      debugPrint('❌ MIGRATION ERROR: $e');
      // Don't throw - allow app to continue even if migration fails
    }
  }

  /// Clear all progress-related SharedPreferences data after migration
  static Future<void> _clearSharedPreferencesData(SharedPreferences prefs) async {
    try {
      final allKeys = prefs.getKeys();
      
      // Remove all video progress keys
      final progressKeys = allKeys.where(
        (key) => key.startsWith('video_progress_') || 
                 key.startsWith('resource_') ||
                 key.startsWith('challenge_') ||
                 key.startsWith('last_challenge_'),
      ).toList();
      
      for (final key in progressKeys) {
        await prefs.remove(key);
      }
      
      debugPrint('🧹 MIGRATION: Cleared ${progressKeys.length} SharedPreferences keys');
    } catch (e) {
      debugPrint('⚠️ MIGRATION: Error clearing SharedPreferences: $e');
    }
  }

  /// Migrate video progress from SharedPreferences to Supabase
  static Future<void> _migrateVideoProgress(
    SharedPreferences prefs,
    String userId,
  ) async {
    debugPrint('📹 MIGRATION: Migrating video progress...');

    try {
      final allKeys = prefs.getKeys();
      int migratedCount = 0;

      // Find all video_progress keys
      final progressKeys = allKeys.where(
        (key) =>
            key.startsWith('video_progress_') && key.endsWith('_percentage'),
      );

      for (final key in progressKeys) {
        final resourceId = key
            .replaceFirst('video_progress_', '')
            .replaceFirst('_percentage', '');

        final percentage = prefs.getDouble(key) ?? 0.0;
        final completed =
            prefs.getBool('video_progress_${resourceId}_completed') ?? false;
        final duration =
            prefs.getInt('video_progress_${resourceId}_duration') ?? 0;

        // Only migrate if there's actual progress
        if (percentage > 0 || completed) {
          try {
            await _supabase.from('video_progress').upsert({
              'user_id': userId,
              'resource_id': resourceId,
              'watch_percentage': percentage,
              'watch_duration_seconds': duration,
              'completed': completed,
            }, onConflict: 'user_id,resource_id');

            migratedCount++;
            debugPrint(
              '  ✓ Migrated: $resourceId (${percentage.toStringAsFixed(1)}%)',
            );
          } catch (e) {
            debugPrint('  ✗ Failed to migrate $resourceId: $e');
          }
        }
      }

      debugPrint('📹 MIGRATION: Migrated $migratedCount video progress records');
    } catch (e) {
      debugPrint('❌ MIGRATION: Video progress migration error: $e');
    }
  }

  /// Migrate daily challenge streak from SharedPreferences to Supabase
  static Future<void> _migrateDailyChallengeProgress(
    SharedPreferences prefs,
    String userId,
  ) async {
    debugPrint('🎯 MIGRATION: Migrating daily challenge streak...');

    try {
      final streakCount = prefs.getInt('challenge_streak_count') ?? 0;
      final totalDays = prefs.getInt('challenge_total_days') ?? 0;
      final weekAnswersStr = prefs.getString('challenge_week_answers') ?? '';
      final lastPlayedStr = prefs.getString('last_challenge_date');

      // Only migrate if there's actual streak data
      if (streakCount > 0 || totalDays > 0) {
        final lastCompletedDate =
            lastPlayedStr != null ? DateTime.parse(lastPlayedStr) : null;

        await _supabase.from('daily_challenge_streak').upsert({
          'user_id': userId,
          'current_streak': streakCount,
          'total_days': totalDays,
          'week_answers': weekAnswersStr,
          'last_completed_date': lastCompletedDate?.toIso8601String(),
        }, onConflict: 'user_id');

        debugPrint(
          '  ✓ Migrated streak: $streakCount/7 days, total: $totalDays',
        );
      }

      debugPrint('🎯 MIGRATION: Daily challenge migration complete');
    } catch (e) {
      debugPrint('❌ MIGRATION: Daily challenge migration error: $e');
    }
  }

  /// Force clear migration flag (for testing purposes only)
  static Future<void> resetMigration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationKey);
    debugPrint('🧪 MIGRATION: Reset flag cleared');
  }
}
