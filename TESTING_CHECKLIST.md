# Progress Persistence - Testing Checklist

## ✅ Test 1: Video Progress Persistence (Single User)

**Goal:** Verify video progress saves and persists after app restart.

### Steps:

1. **Register/Login as Test User A**
   - Email: `testa@example.com`
   - Password: `test123`

2. **Mark Video #1 as Complete**
   - Navigate to: Resources → Click any video
   - Click "Mark as Complete" button
   - **Check Console:** Should see:
     ```
     ✅ VIDEO PROGRESS: Database saved! Response: [...]
     ✅ MARKING COMPLETE: 1
     ```

3. **Go Back to Resources List**
   - **Expected:** Video #1 shows checkmark ✅
   - **Check Console:** Should see:
     ```
     ✅ PROGRESS LOAD: Loaded 1 resources from DB: [1]
     ```

4. **Restart Flutter App**
   - Stop: `Ctrl+C`
   - Run: `flutter run -d chrome`
   - Login as Test User A again

5. **Verify Progress Persisted**
   - Navigate to Resources
   - **Expected:** Video #1 still shows checkmark ✅
   - **Check Console:** Should see:
     ```
     ✅ PROGRESS LOAD: Loaded 1 resources from DB: [1]
     ```

**✅ PASS if:** Video #1 remains complete after restart  
**❌ FAIL if:** Video #1 resets to 0%

---

## ✅ Test 2: Multi-User Isolation (No Cross-Contamination)

**Goal:** Verify each user has their own separate progress.

### Steps:

1. **Login as Test User A**
   - Should already have Video #1 complete from Test 1
   - **Verify:** Resources shows Video #1 with checkmark ✅

2. **Mark Video #2 and #3 as Complete**
   - Complete 2 more videos
   - **Check Console:** Should see database saves for each

3. **Check Resources List**
   - **Expected:** 3 videos show checkmarks (Videos 1, 2, 3)
   - **Check Console:**
     ```
     ✅ PROGRESS LOAD: Loaded 3 resources from DB: [1, 2, 3]
     ```

4. **Logout**
   - Navigate to Profile → Logout
   - **Check Console:** Should see:
     ```
     🔄 AUTH STATE CHANGE: Old user: [user_a_id], New user: null
     🔄 USER CHANGED: Reloading progress...
     ```

5. **Register Test User B**
   - Email: `testb@example.com`
   - Password: `test123`
   - **Check Console:** Should see:
     ```
     🔄 AUTH STATE CHANGE: Old user: null, New user: [user_b_id]
     🔄 USER CHANGED: Reloading progress...
     ✅ PROGRESS LOAD: Loaded 0 resources from DB: []
     ```

6. **Verify User B Has No Progress**
   - Navigate to Resources
   - **Expected:** All videos show 0% progress (NO checkmarks) ✅
   - **NOT Expected:** Should NOT see User A's 3 completed videos

7. **Mark Video #1 for User B**
   - Complete Video #1 for User B
   - **Check Console:** Should see database save

8. **Logout User B, Login User A Again**
   - Logout User B
   - Login as User A (`testa@example.com`)
   - **Check Console:**
     ```
     🔄 AUTH STATE CHANGE: Old user: [user_b_id], New user: [user_a_id]
     🔄 USER CHANGED: Reloading progress...
     ✅ PROGRESS LOAD: Loaded 3 resources from DB: [1, 2, 3]
     ```

9. **Verify User A Still Has 3 Videos**
   - Navigate to Resources
   - **Expected:** Still shows 3 videos complete ✅

**✅ PASS if:** 
- User A has 3 videos complete
- User B has only 1 video complete
- No cross-contamination

**❌ FAIL if:**
- User B sees User A's progress
- User A loses their progress

---

## ✅ Test 3: Daily Challenge Persistence

**Goal:** Verify daily challenge completion and streak persist.

### Steps:

1. **Login as Test User A**

2. **Complete Today's Daily Challenge**
   - Navigate to: Training Hub
   - Click "Daily Challenge"
   - Answer the question (True/False)
   - **Check Console:**
     ```
     ✅ DAILY CHALLENGE: Saved completion to database
     ✅ DAILY CHALLENGE: Saved streak to database (streak=1/7)
     ```

3. **Check Streak Shows**
   - **Expected:** Shows "Day 1/7" in the UI
   - Streak count should be 1

4. **Restart Flutter App**
   - Stop and restart app
   - Login as User A

5. **Verify Challenge Shows as Completed**
   - Navigate to Training Hub
   - **Check Console:**
     ```
     🎯 DAILY CHALLENGE: Loading streak from database...
     ✅ DAILY CHALLENGE: Streak from DB: 1/7, Total: 1
     ✅ DAILY CHALLENGE: Found in database - already completed today
     ```
   - **Expected:** Shows "Already completed" message
   - Streak should still show 1/7

**✅ PASS if:** Daily challenge completion and streak persist  
**❌ FAIL if:** Streak resets to 0 or shows as incomplete

---

## ✅ Test 4: Database Verification

**Goal:** Verify data is actually in Supabase database.

### Steps:

1. **Go to Supabase Dashboard**
   - Navigate to: Table Editor → `video_progress`

2. **Check User A's Data**
   - Filter by User A's `user_id`
   - **Expected:** See 3 rows (for Videos 1, 2, 3)
   - All should have `completed = true`
   - All should have `watch_percentage = 100`

3. **Check User B's Data**
   - Filter by User B's `user_id`
   - **Expected:** See 1 row (for Video 1)
   - Should have `completed = true`

4. **Verify No Shared Data**
   - Each `user_id` should only see their own rows
   - No duplicate `resource_id` within same `user_id`

**✅ PASS if:** Database shows correct isolated data per user  
**❌ FAIL if:** Data is missing or mixed between users

---

## ✅ Test 5: Auto-Focus Registration Flow

**Goal:** Verify the improved registration UX.

### Steps:

1. **Logout All Users**

2. **Go to Register Page**

3. **Test Keyboard Navigation**
   - Type name in "Full Name" field
   - **Press Enter** → Should jump to Email field ✅
   - Type email
   - **Press Enter** → Should jump to Password field ✅
   - Type password
   - **Press Enter** → Should submit registration ✅

4. **Verify Goes Directly to Dashboard**
   - After registration completes
   - **Expected:** Lands on Dashboard/Home page
   - **NOT Expected:** Should NOT see splash screen

**✅ PASS if:** Smooth keyboard navigation and direct dashboard  
**❌ FAIL if:** Enter keys don't work or splash screen appears

---

## 🔍 Console Log Quick Reference

### ✅ Good Logs (Success):

```
✅ VIDEO PROGRESS: Database saved!
✅ PROGRESS LOAD: Loaded X resources from DB: [...]
✅ DAILY CHALLENGE: Saved streak to database
🔄 AUTH STATE CHANGE: Old user: [...], New user: [...]
🔄 USER CHANGED: Reloading progress...
```

### ❌ Bad Logs (Issues):

```
❌ VIDEO PROGRESS DATABASE ERROR: ...
❌ LOAD PROGRESS DATABASE ERROR: ...
❌ Error loading progress from database: ...
```

### ⚠️ Warning Logs (Non-critical):

```
⚠️ PROGRESS LOAD: User not logged in
ℹ️ DAILY CHALLENGE: No streak data in DB yet
```

---

## 📋 Final Checklist

Before deploying, verify ALL tests pass:

- [ ] Test 1: Single user progress persists after restart
- [ ] Test 2: Multi-user isolation (no cross-contamination)
- [ ] Test 3: Daily challenge and streak persist
- [ ] Test 4: Database shows correct data
- [ ] Test 5: Registration auto-focus works
- [ ] Console shows success logs (✅)
- [ ] No error logs in console (❌)

---

## 🚀 Quick Smoke Test (5 Minutes)

If you're in a hurry, do this minimal test:

1. **Register User 1** → Mark Video #1 complete
2. **Restart app** → Login User 1 → Video #1 still complete? ✅
3. **Logout** → **Register User 2** → All videos 0%? ✅
4. **If both pass** → System is working! 🎉

---

## 🐛 Troubleshooting

### Issue: Progress resets after restart

**Check:**
- Did you run the SQL script in Supabase?
- Verify table exists: `video_progress`
- Check console for database errors

### Issue: New user sees old user's progress

**Check:**
- Console logs for "AUTH STATE CHANGE"
- Console logs for "USER CHANGED: Reloading progress..."
- If missing → auth listener not working

### Issue: Database shows no data

**Check:**
- Look for "DATABASE ERROR" in console
- Verify Supabase connection
- Check RLS policies are enabled

---

## ✨ Success Criteria

**All tests must pass without:**
- ❌ Any error messages in console
- ❌ Progress resetting unexpectedly
- ❌ Cross-user data contamination
- ❌ Database connection failures

**You should see:**
- ✅ Consistent green checkmarks (✅) in console
- ✅ Progress persists across app restarts
- ✅ Each user has isolated progress
- ✅ Smooth UX with no delays

---

**Good luck testing! 🚀**
