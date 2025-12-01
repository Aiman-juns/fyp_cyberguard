# 🔧 Supabase Database Setup Guide

## Step 1: Create a Supabase Account & Project

### 1.1 Go to Supabase Website
- Open your browser and go to: **https://app.supabase.com**
- Click **"Sign Up"** (or login if you already have an account)

### 1.2 Create New Project
- Click **"+ New Project"**
- Fill in the form:
  - **Project Name:** `cyberguard` (or your choice)
  - **Database Password:** Create a strong password (save this!)
  - **Region:** Select your region (e.g., Southeast Asia if available, or closest to Malaysia)
- Click **"Create new project"**
- **Wait 3-5 minutes** for the project to be created

---

## Step 2: Get Your Credentials

### 2.1 Find Your Project URL & Anon Key
Once your project is created:
1. Go to **Settings** (⚙️ icon) in the left sidebar
2. Click **"API"** 
3. You'll see:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **Project API Keys** section with **`anon public`** key

**Copy these values** - you'll need them next!

### 2.2 Update Your Flutter App
Open `lib/config/supabase_config.dart` and replace:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

With your actual values. Example:
```dart
static const String supabaseUrl = 'https://abcdefgh.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

---

## Step 3: Set Up the Database Schema

### 3.1 Open SQL Editor
1. In your Supabase project dashboard, go to **SQL Editor** (left sidebar)
2. Click **"New Query"**

### 3.2 Copy & Paste SQL Schema
1. Open the file `SUPABASE_SCHEMA.sql` from your project
2. Copy **ALL** the content
3. Paste it into the Supabase SQL Editor query box
4. Click **"Execute"** (⏯️ button)

**Wait for it to complete** - you should see a success message!

### 3.3 Verify Tables Were Created
After running the SQL:
1. Go to **Table Editor** (left sidebar)
2. You should see these tables:
   - `users` ✅
   - `resources` ✅
   - `questions` ✅
   - `user_progress` ✅
   - `news` ✅

Click on each table to verify it has the correct columns.

---

## Step 4: Configure Authentication

### 4.1 Enable Email/Password Auth
1. Go to **Authentication** in the left sidebar
2. Click **"Providers"** tab
3. Make sure **"Email"** is toggled **ON** ✅
4. Keep the default settings

### 4.2 Set Email Templates (Optional)
- You can customize welcome emails in **Email Templates** if you want
- Default templates work fine for now

---

## Step 5: Create Storage Bucket (for Phase 6)

### 5.1 Create Bucket for Media
1. Go to **Storage** (left sidebar)
2. Click **"Create a new bucket"**
3. Name it: `media`
4. **Make it public** (toggle ON)
5. Click **"Create bucket"**

This will be used in Phase 6 for uploading images/videos.

---

## Step 6: Test the Connection

### 6.1 Get Dependencies
Open terminal in your project folder:
```bash
cd "c:\flutter project\cats_project\cats_flutter"
flutter pub get
```

### 6.2 Run the App
```bash
flutter run
```

### 6.3 Test Registration
1. Go to Register screen
2. Create a test account:
   - **Name:** Test User
   - **Email:** test@example.com
   - **Password:** TestPass123!
   - **Confirm:** TestPass123!
3. Check terms & click **"Create Account"**

### 6.4 Verify in Supabase
1. Go to **Table Editor** in Supabase
2. Click **"users"** table
3. You should see your new user with:
   - ✅ email: `test@example.com`
   - ✅ full_name: `Test User`
   - ✅ role: `user`
   - ✅ avatar_url: (auto-generated)
   - ✅ total_score: `0`
   - ✅ level: `1`

**Success!** 🎉 Your database is connected!

---

## Database Structure Explanation

### 5 Main Tables

#### 1. **users** - Stores user profiles
```
id (UUID)           - Unique identifier
email (Text)        - User email
full_name (Text)    - User's full name
role (Text)         - 'user' or 'admin'
avatar_url (Text)   - Auto-generated avatar
total_score (Int)   - All-time score
level (Int)         - Current level
```

#### 2. **resources** - Learning materials
```
id (UUID)           - Unique identifier
title (Text)        - Article title
category (Text)     - Category (Phishing, Security, etc.)
content (Text)      - Markdown content
media_url (Text)    - Link to images/videos
created_at          - Creation timestamp
```

#### 3. **questions** - Training questions
```
id (UUID)           - Unique identifier
module_type (Text)  - 'phishing', 'password', or 'attack'
difficulty (Int)    - 1-5 scale
content (Text)      - Question text
correct_answer      - The correct answer
explanation         - Why this answer is correct
media_url (Text)    - Question image/video
```

#### 4. **user_progress** - Tracks learning progress
```
id (UUID)           - Unique identifier
user_id (UUID)      - Links to users table
question_id (UUID)  - Links to questions table
is_correct (Bool)   - Did user answer correctly?
score_awarded (Int) - Points earned
attempt_date        - When was this attempted?
```

#### 5. **news** - Cybersecurity news
```
id (UUID)           - Unique identifier
title (Text)        - News headline
body (Text)         - Full news article
source_url (Text)   - Link to source
image_url (Text)    - News image
created_at          - Publication date
```

---

## Security Features

The database has **Row-Level Security (RLS)** policies:

### What This Means:
- ✅ Users can **only see their own data**
- ✅ Admins can **see all data**
- ✅ **Public can read** resources and news
- ✅ **Only admins can create/edit** questions

### These are Already Configured!
You don't need to do anything - the SQL schema already set them up.

---

## Troubleshooting

### Issue: "No tables appear in Table Editor"
**Solution:** 
1. Refresh the browser (F5)
2. Go back to Supabase dashboard
3. Check if there are any error messages in SQL Editor

### Issue: "User not being saved after registration"
**Solution:**
1. Check if `supabase_config.dart` has correct URL and Key
2. Verify internet connection
3. Check browser console for errors (F12)

### Issue: "Connection refused" error
**Solution:**
1. Double-check your Supabase URL (should be `https://xxxxx.supabase.co`)
2. Make sure you copied the full Anon Key (very long string)
3. Clear app cache: `flutter clean` then `flutter pub get`

### Issue: SQL script gives error
**Solution:**
1. Make sure you're using the complete `SUPABASE_SCHEMA.sql` file
2. Run it all at once (don't break it into parts)
3. Check Supabase SQL Editor for specific error message

---

## Quick Reference

### Your Credentials Template
```
Project URL:   https://________________.supabase.co
Anon Key:      eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

(Save these securely!)
```

### Database Connection String
```
postgres://postgres:[PASSWORD]@db.[PROJECT_ID].supabase.co:5432/postgres
```

### Useful Supabase Links
- **Dashboard:** https://app.supabase.com
- **Documentation:** https://supabase.com/docs
- **API Reference:** https://supabase.com/docs/reference/javascript/introduction

---

## What's Next?

After setting up Supabase:
1. ✅ Verify all tables are created
2. ✅ Test user registration
3. ✅ Update Flutter app with credentials
4. ✅ Run `flutter pub get`
5. ✅ Test login/register screens
6. ✅ Ready for Phase 2!

---

## Important Security Notes

⚠️ **Keep your Anon Key Private!**
- Don't share it publicly
- Don't commit it to GitHub (use environment variables in production)
- In production, use `.env` files or GitHub Secrets

⚠️ **Database Password**
- Save the password you created (you'll need it for direct database access)
- Don't share it with others

⚠️ **RLS Policies**
- Already configured in the SQL schema
- They protect user data automatically
- Trust them - they work!

---

## Next Steps

1. **Complete this setup guide ✅**
2. **Verify all tables in Supabase Table Editor**
3. **Update lib/config/supabase_config.dart with credentials**
4. **Run Flutter app and test registration**
5. **Ready for Phase 2: Shell & Navigation**

---

**Database Setup Guide Complete!**  
**Your CyberGuard app is now connected to Supabase!** 🚀
