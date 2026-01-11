import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Android initialization settings
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      debugPrint('✅ NOTIFICATIONS: Initialized successfully');
    } catch (e) {
      debugPrint('❌ NOTIFICATIONS: Initialization failed: $e');
    }
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    try {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      debugPrint('✅ NOTIFICATIONS: Permission result = $result');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ NOTIFICATIONS: Permission request failed: $e');
      return false;
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint(
      '🔔 NOTIFICATION TAPPED: ${response.payload}',
    );
    // TODO: Handle navigation based on payload
  }

  /// Show achievement unlocked notification
  static Future<void> showAchievementUnlocked(
    String achievementTitle,
    String achievementDescription,
  ) async {
    try {
      await _notifications.show(
        1, // Notification ID
        '🏆 Achievement Unlocked!',
        achievementTitle,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'achievements',
            'Achievements',
            channelDescription: 'Notifications for earned achievements',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              achievementDescription,
              contentTitle: '🏆 Achievement Unlocked!',
              summaryText: 'CyberGuard',
            ),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            subtitle: achievementTitle,
          ),
        ),
        payload: 'achievement',
      );
      debugPrint('🔔 NOTIFICATION: Achievement sent - $achievementTitle');
    } catch (e) {
      debugPrint('❌ NOTIFICATION ERROR: $e');
    }
  }

  /// Schedule daily challenge notification
  static Future<void> scheduleDailyChallenge({int hour = 9}) async {
    try {
      await _notifications.zonedSchedule(
        2, // Notification ID
        '🎯 Daily Challenge Ready!',
        'Test your cybersecurity knowledge with today\'s challenge',
        _nextInstanceOfTime(hour, 0),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_challenge',
            'Daily Challenge',
            channelDescription: 'Daily challenge reminder',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_challenge',
      );
      debugPrint('🔔 NOTIFICATION: Daily challenge scheduled for $hour:00');
    } catch (e) {
      debugPrint('❌ NOTIFICATION ERROR: $e');
    }
  }

  /// Send streak warning notification
  static Future<void> showStreakWarning(int currentStreak) async {
    try {
      await _notifications.show(
        3, // Notification ID
        '🔥 Streak Alert!',
        'Don\'t lose your $currentStreak-day streak! Complete today\'s challenge',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'streak_warning',
            'Streak Warnings',
            channelDescription: 'Warnings about losing your streak',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              'You have a few hours left to keep your $currentStreak-day streak alive. Don\'t break the chain!',
              contentTitle: '🔥 Streak Alert!',
              summaryText: 'CyberGuard',
            ),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'streak_warning',
      );
      debugPrint('🔔 NOTIFICATION: Streak warning sent - $currentStreak days');
    } catch (e) {
      debugPrint('❌ NOTIFICATION ERROR: $e');
    }
  }

  /// Show milestone reached notification
  static Future<void> showMilestoneReached(
    String milestone,
    String description,
  ) async {
    try {
      await _notifications.show(
        4, // Notification ID
        '🎉 Milestone Reached!',
        milestone,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'milestones',
            'Milestones',
            channelDescription: 'Notifications for reaching milestones',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              description,
              contentTitle: '🎉 Milestone Reached!',
              summaryText: 'CyberGuard',
            ),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            subtitle: milestone,
          ),
        ),
        payload: 'milestone',
      );
      debugPrint('🔔 NOTIFICATION: Milestone sent - $milestone');
    } catch (e) {
      debugPrint('❌ NOTIFICATION ERROR: $e');
    }
  }

  /// Schedule comeback reminder (3 days from now)
  static Future<void> scheduleComebackReminder() async {
    try {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(
        const Duration(days: 3),
      );

      await _notifications.zonedSchedule(
        5, // Notification ID
        '👋 We Miss You!',
        'Your cybersecurity training is waiting. Come back and continue your progress!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'comeback',
            'Comeback Reminders',
            channelDescription: 'Reminders to come back to the app',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'comeback',
      );
      debugPrint('🔔 NOTIFICATION: Comeback reminder scheduled for 3 days');
    } catch (e) {
      debugPrint('❌ NOTIFICATION ERROR: $e');
    }
  }

  /// Cancel comeback reminder (when user returns)
  static Future<void> cancelComebackReminder() async {
    try {
      await _notifications.cancel(5);
      debugPrint('🔔 NOTIFICATION: Comeback reminder cancelled');
    } catch (e) {
      debugPrint('❌ NOTIFICATION ERROR: $e');
    }
  }

  /// Show module completion notification
  static Future<void> showModuleCompleted(String moduleName) async {
    try {
      await _notifications.show(
        6, // Notification ID
        '🎊 Module Complete!',
        '$moduleName mastered!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'module_completion',
            'Module Completion',
            channelDescription: 'Notifications for completing modules',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              'Congratulations! You\'ve successfully completed all challenges in $moduleName',
              contentTitle: '🎊 Module Complete!',
              summaryText: 'CyberGuard',
            ),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            subtitle: '$moduleName mastered!',
          ),
        ),
        payload: 'module_completion',
      );
      debugPrint('🔔 NOTIFICATION: Module completion sent - $moduleName');
    } catch (e) {
      debugPrint('❌ NOTIFICATION ERROR: $e');
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
      debugPrint('🔔 NOTIFICATION: All notifications cancelled');
    } catch (e) {
      debugPrint('❌ NOTIFICATION ERROR: $e');
    }
  }

  /// Helper method to get next instance of a specific time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
