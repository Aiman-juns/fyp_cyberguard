# 🧪 Notification System - Quick Testing Guide

## Prerequisites
- Physical Android/iOS device (notifications don't work well on emulators)
- App installed and permissions granted
- Signed in as a user

---

## Test 1: Achievement Notification 🏆

**What it tests:** Push notification when achievement is unlocked

**Steps:**
1. Sign in to the app
2. Go to Training Hub
3. Complete your **first quiz** (any module, any difficulty)
4. After submitting answers, you should see:
   - ✅ In-app confetti overlay with achievement card
   - ✅ Push notification: "Achievement Unlocked! 🏆"

**Expected Result:**
```
Title: Achievement Unlocked! 🏆
Body: First Steps - Complete your first quiz
```

**Debug Logs to Check:**
```
🏆 ACHIEVEMENT: Unlocking First Steps
🔔 NOTIFICATION SENT: Achievement Unlocked
```

---

## Test 2: Daily Challenge Notification 📅

**What it tests:** Scheduled notification at 9 AM daily

**Steps (Quick Test):**
1. Open [lib/main.dart](lib/main.dart)
2. Find line: `await LocalNotificationService.scheduleDailyChallenge(hour: 9);`
3. Change to current time + 2 minutes: `hour: XX, minute: YY`
4. Hot restart app (press 'R' in terminal)
5. Close app completely
6. Wait 2 minutes

**Expected Result:**
```
Title: New Daily Challenge Available! 🎯
Body: Test your cybersecurity knowledge and keep your streak alive!
```

**⚠️ IMPORTANT:** Change back to `hour: 9` after testing!

---

## Test 3: Streak Warning Notification ⚠️

**What it tests:** Warning when streak is at risk (20+ hours since last completion)

**Steps:**
1. Complete today's daily challenge
2. **Option A (Manual DB Test):**
   - Open Supabase dashboard
   - Go to `daily_challenge_streak` table
   - Find your user record
   - Change `last_completed_date` to yesterday at this time
   - Save changes
3. **Option B (Wait 20 Hours):** Just wait 20 hours 😅
4. Open the app
5. Notification should appear immediately

**Expected Result:**
```
Title: Don't Break Your Streak! ⚠️
Body: You have a X-day streak. Complete today's challenge to keep it going!
```

**Debug Logs to Check:**
```
⚠️ DAILY CHALLENGE: 20+ hours since completion, sending streak warning
🔔 NOTIFICATION SENT: Streak Warning
```

---

## Test 4: Milestone Notification 🎯

**What it tests:** Notification when reaching milestones

**Milestones Available:**
- Level 2, 3, 4, 5, 6, 7, 8, 9, 10 (level up)
- 10 questions completed
- 50 questions completed
- 100 questions completed
- 500 questions completed

**Steps:**
1. Check your current stats in Performance tab
2. Complete questions in any training module
3. Keep completing until you:
   - Level up (check performance screen for current level)
   - OR reach 10/50/100/500 total questions

**Expected Result:**
```
Title: Milestone Reached! 🎯
Body: You've reached: Level X
      or
Body: You've reached: 10 Questions Completed
```

**Debug Logs to Check:**
```
🎉 MILESTONE: User leveled up to 5!
🔔 NOTIFICATION SENT: Milestone - Level 5
```

---

## Test 5: Module Completion Notification 🎓

**What it tests:** Notification when 100% completing a module

**Steps:**
1. Pick a module (Phishing Detection, Password Security, or Threat Recognition)
2. Go to that module in Training Hub
3. Complete **ALL questions in ALL 3 difficulty levels**:
   - Level 1 (Easy): Complete all questions
   - Level 2 (Medium): Complete all questions  
   - Level 3 (Hard): Complete all questions
4. After completing the last question → Notification appears

**Expected Result:**
```
Title: Module Completed! 🎓
Body: Congratulations! You've mastered Phishing Detection!
      (or Password Security / Threat Recognition)
```

**Debug Logs to Check:**
```
🎉 MODULE COMPLETE: phishing - All difficulties completed!
🔔 NOTIFICATION SENT: Module Completed - Phishing Detection
```

**Tip:** Use admin dashboard to check question count per module/difficulty

---

## Test 6: Comeback Reminder Notification 💙

**What it tests:** Scheduled notification 3 days after app closes

**Steps (Quick Test - Requires Code Change):**
1. Open [lib/core/services/local_notification_service.dart](lib/core/services/local_notification_service.dart)
2. Find `scheduleComebackReminder()` function
3. Change `DateTime.now().add(Duration(days: 3))` to `DateTime.now().add(Duration(minutes: 2))`
4. Hot restart app
5. Close app completely (press home button)
6. Wait 2 minutes

**Expected Result:**
```
Title: We Miss You! 💙
Body: Continue your cybersecurity journey. New challenges are waiting!
```

**⚠️ IMPORTANT:** Change back to `Duration(days: 3)` after testing!

**Debug Logs to Check:**
```
📱 APP LIFECYCLE: Going to background, scheduling comeback reminder
✅ NOTIFICATION SCHEDULED: Comeback reminder
```

---

## Quick Checklist for All Tests

- [ ] Test 1: Achievement Unlocked ✅
- [ ] Test 2: Daily Challenge (9 AM) ✅
- [ ] Test 3: Streak Warning ✅
- [ ] Test 4: Milestone Reached ✅
- [ ] Test 5: Module Completion ✅
- [ ] Test 6: Comeback Reminder ✅

---

## Troubleshooting

### Notifications Not Appearing?

**Check 1: Permissions**
```
Settings → Apps → CyberGuard → Notifications
Make sure "Notifications" is enabled
```

**Check 2: Battery Optimization (Android)**
```
Settings → Battery → Battery Optimization
Find CyberGuard → Set to "Don't optimize"
```

**Check 3: Do Not Disturb**
```
Make sure phone is not in Do Not Disturb mode
```

**Check 4: Debug Logs**
```
Run app from VS Code/Android Studio
Check debug console for notification logs:
  - Look for "🔔 NOTIFICATION SENT:"
  - Look for "✅ NOTIFICATION SCHEDULED:"
  - Look for any "❌" error messages
```

**Check 5: Flutter Clean**
```bash
flutter clean
flutter pub get
flutter run
```

---

## Debug Commands

### Check Notification Permission Status
Add this to any screen's build method:
```dart
LocalNotificationService.requestPermissions().then((granted) {
  print('Notification permission: $granted');
});
```

### Manual Notification Test
Add this button to any screen:
```dart
ElevatedButton(
  onPressed: () {
    LocalNotificationService.showAchievementUnlocked(
      'Test Achievement',
      'Testing notification system',
    );
  },
  child: Text('Test Notification'),
)
```

---

## Platform-Specific Notes

### Android
- Notifications show in notification shade
- Can set importance level (affects sound/vibration)
- Supports notification channels
- Badge icon appears on app launcher

### iOS
- Notifications show in Notification Center
- Requires explicit user permission
- Badge number on app icon
- Supports rich notifications with images

---

## Expected Behavior Summary

| Notification Type | Trigger | Frequency | Priority |
|------------------|---------|-----------|----------|
| Achievement | On achievement unlock | Variable | Medium |
| Daily Challenge | 9 AM daily | Once/day | High |
| Streak Warning | 20+ hours no completion | Once/day | Medium |
| Milestone | On milestone | Variable | Low |
| Module Completion | 100% module done | Max 3 total | Low |
| Comeback | App inactive 3 days | Once/absence | Low |

---

## Next Steps After Testing

1. ✅ Verify all 6 notification types work
2. ✅ Check notifications appear when app is closed
3. ✅ Confirm notifications are not spammy
4. ⏳ Optional: Adjust notification time/frequency
5. ⏳ Optional: Add notification settings screen
6. ⏳ Optional: Track notification analytics

---

*Testing Status: Ready*
*Last Updated: Implementation Complete*
