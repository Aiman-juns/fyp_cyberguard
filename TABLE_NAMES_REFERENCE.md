# Quick Reference - Table Names

## Video Progress
**Table Name:** `video_progress`

**Columns:**
- `id` - UUID (auto-generated)
- `user_id` - References auth.users
- `resource_id` - TEXT (e.g., "1", "2", "1_1" for attack types)
- `watch_percentage` - NUMERIC (0-100)
- `watch_duration_seconds` - INTEGER
- `completed` - BOOLEAN
- `created_at` - TIMESTAMPTZ
- `updated_at` - TIMESTAMPTZ

**Unique Constraint:** `(user_id, resource_id)` - prevents duplicates

---

## Daily Challenge Progress
**Table Name:** `daily_challenge_progress`

**Columns:**
- `id` - UUID (auto-generated)
- `user_id` - References auth.users
- `challenge_id` - References daily_challenges table
- `completed` - BOOLEAN
- `is_correct` - BOOLEAN
- `completed_at` - TIMESTAMPTZ
- `created_at` - TIMESTAMPTZ

**Unique Constraint:** `(user_id, challenge_id)` - one completion per challenge per user

---

## Daily Challenge Streak (NEW!)
**Table Name:** `daily_challenge_streak`

**Columns:**
- `id` - UUID (auto-generated)
- `user_id` - References auth.users
- `current_streak` - INTEGER (e.g., 3 means "Day 3/7")
- `total_days` - INTEGER (total challenges ever completed)
- `week_answers` - TEXT (e.g., "1,0,1,1" where 1=correct, 0=incorrect)
- `last_completed_date` - DATE
- `created_at` - TIMESTAMPTZ
- `updated_at` - TIMESTAMPTZ

**Unique Constraint:** `(user_id)` - one streak record per user

---

## Daily Challenges (Questions)
**Table Name:** `daily_challenges`

**Columns:**
- `id` - UUID (auto-generated)
- `question` - TEXT
- `is_true` - BOOLEAN (true/false answer)
- `explanation` - TEXT
- `created_at` - TIMESTAMPTZ
- `updated_at` - TIMESTAMPTZ

---

## Troubleshooting

### If progress still resets:

1. **Verify tables exist** - Run `VERIFY_TABLES.sql` in Supabase SQL Editor

2. **Check Flutter console logs** when marking complete:
   ```
   ✅ VIDEO PROGRESS: Database saved!  <- Should see this
   ❌ VIDEO PROGRESS DATABASE ERROR    <- If you see this, tables missing
   ```

3. **Check Flutter console logs** on app restart:
   ```
   ✅ LOAD PROGRESS: Found in DB: 100.0%  <- Should see this
   📹 LOAD PROGRESS: No data found        <- Tables exist but no data
   ❌ LOAD PROGRESS DATABASE ERROR         <- Tables don't exist
   ```

### Common Issues:

**Issue:** "relation does not exist"
- **Cause:** Tables not created yet
- **Fix:** Run `COMPLETE_PROGRESS_PERSISTENCE_FIX.sql` in Supabase

**Issue:** "permission denied" or "RLS policy violation"
- **Cause:** Row Level Security blocking access
- **Fix:** RLS policies should be created by the SQL script. Verify with `VERIFY_TABLES.sql`

**Issue:** Progress saves but doesn't load
- **Cause:** Provider cache issue or migration not running
- **Fix:** Check console for migration logs on app startup

---

## How to Verify Setup

### Step 1: Run SQL Script
```
Supabase Dashboard → SQL Editor → Paste COMPLETE_PROGRESS_PERSISTENCE_FIX.sql → Run
```

### Step 2: Verify Tables
```
Supabase Dashboard → SQL Editor → Paste VERIFY_TABLES.sql → Run
Should return 4 tables in step 1
```

### Step 3: Test in App
1. Mark video as complete
2. Check console: Should see `✅ VIDEO PROGRESS: Database saved!`
3. Terminate app (force close)
4. Restart app
5. Check console: Should see `✅ LOAD PROGRESS: Found in DB: 100.0%`
6. Video should still show as complete

---

## SQL Scripts in Your Project

1. **`COMPLETE_PROGRESS_PERSISTENCE_FIX.sql`** - Main setup script (RUN THIS FIRST)
2. **`VERIFY_TABLES.sql`** - Check if tables exist (RUN THIS TO DEBUG)
