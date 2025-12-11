# 🎥 YouTube Video Troubleshooting Guide

## Current Issue: Videos Not Playing

You've added YouTube URLs to the resources, but they're not showing up in the app.

---

## ✅ What You've Done
✓ Added YouTube URLs to `resources_provider.dart`:
- Resource 2: "Types of Cyber Attack" → Added video URL
- Resource 3: "How to Prevent It" → Added video URL
- Sub-resources (Clickjacking, Phishing, etc.) → Added video URLs

---

## 🔍 Why Videos Might Not Be Showing

### 1. **Hot Reload Issue** (MOST COMMON)
Videos are bundled at startup. Hot reload doesn't pick up new data.

**Solution:**
```bash
# STOP the app completely
# Then run:
flutter run
```

### 2. **Video Player Not Initialized**
The video controller might not be initializing properly.

**Check in:** `lib/features/resources/screens/resource_detail_screen.dart`
- Look for `_initializeVideoPlayer()` method
- Verify it detects YouTube URLs correctly

### 3. **YouTube URL Format Issues**
Make sure URLs are in exact format:

❌ **WRONG:**
```dart
'youtube.com/watch?v=abc123'
'youtu.be/abc123'
'https://youtu.be/abc123'
```

✅ **CORRECT:**
```dart
'https://www.youtube.com/watch?v=abc123'
```

### 4. **Video ID Extraction Failed**
The app uses `YoutubePlayer.convertUrlToId()` to extract the video ID.

**Check:** Make sure your URL contains the exact video ID:
- URL: `https://www.youtube.com/watch?v=shQEXpUwaIY`
- Video ID: `shQEXpUwaIY`

---

## 📋 Step-by-Step Troubleshooting

### Step 1: Verify URLs in Provider
Open: `lib/features/resources/providers/resources_provider.dart`

Check these resources have valid URLs:

**Resource 2:**
```dart
Resource(
  id: '2',
  title: 'Types of Cyber Attack',
  mediaUrl: 'https://www.youtube.com/watch?v=...',  // ← CHECK THIS
  ...
)
```

**Resource 3:**
```dart
Resource(
  id: '3',
  title: 'How to Prevent It',
  mediaUrl: 'https://www.youtube.com/watch?v=...',  // ← CHECK THIS
  ...
)
```

### Step 2: Verify Attack Types Have URLs
```dart
attackTypes: [
  CyberAttackType(
    id: '1',
    title: 'Clickjacking',
    mediaUrl: 'https://www.youtube.com/watch?v=...',  // ← CHECK THIS
  ),
  ...
]
```

### Step 3: Restart App (Full Restart)
```bash
# In terminal:
flutter clean
flutter pub get
flutter run
```

### Step 4: Test the App
1. Open app
2. Tap "Resources" from home screen
3. Tap on a resource
4. Scroll down to "About" tab
5. Scroll down to media section
6. You should see a YouTube player

---

## 🎯 Expected Behavior

### When Video is Present:
1. Resource detail opens
2. User sees media player at top
3. Player shows YouTube video thumbnail
4. Play button appears
5. Clicking play loads YouTube video

### When Video is NULL:
1. Resource detail opens
2. No media player shown
3. Goes straight to description

---

## 📱 Test Resources

These resources SHOULD have videos:

1. **Resource 1** ✅ "What is Cyber Security?"
   - URL: `https://www.youtube.com/watch?v=shQEXpUwaIY`
   - Status: Working

2. **Resource 2** "Types of Cyber Attack"
   - URL: Should be in provider
   - Status: Check if showing

3. **Resource 3** "How to Prevent It"
   - URL: Should be in provider
   - Status: Check if showing

4. **Attack Types** (Clickjacking, Phishing, etc.)
   - URLs: Should be in each CyberAttackType
   - Status: Check if showing

---

## 🔧 Common Fixes

### Fix 1: Verify YouTube URLs
```dart
// BEFORE (Wrong format)
mediaUrl: 'youtu.be/abc123',

// AFTER (Correct format)
mediaUrl: 'https://www.youtube.com/watch?v=abc123',
```

### Fix 2: Full Restart
```bash
flutter clean
flutter pub get
flutter run
```

### Fix 3: Check Network
Make sure your device/emulator has internet connection for YouTube videos.

---

## 🐛 Debug: Print Video URL

Add debugging to see what's happening:

In `resource_detail_screen.dart`, find `_initializeVideoPlayer()`:

```dart
Future<void> _initializeVideoPlayer(String? videoPath) async {
  if (videoPath == null || videoPath.isEmpty) {
    print('DEBUG: Video path is NULL or empty');  // ← ADD THIS
    return;
  }

  final cleanPath = videoPath.trim();
  print('DEBUG: Video path = $cleanPath');  // ← ADD THIS

  if (cleanPath.contains('youtube.com') || cleanPath.contains('youtu.be')) {
    print('DEBUG: Detected YouTube URL');  // ← ADD THIS
    final videoId = YoutubePlayer.convertUrlToId(cleanPath);
    print('DEBUG: Extracted video ID = $videoId');  // ← ADD THIS
    ...
  }
}
```

Then check the console when opening a resource with video.

---

## ✨ If Still Not Working

Check these files in order:

1. **resources_provider.dart** - URLs are set correctly
2. **resource_detail_screen.dart** - Video initialization logic
3. **resource_detail_screen.dart** - Video display widget
4. **pubspec.yaml** - youtube_player_flutter is installed

---

## 📞 Summary

- ✅ URLs added to provider
- ⚠️ Need FULL RESTART (not hot reload)
- ✅ URL format must be: `https://www.youtube.com/watch?v=ID`
- ✅ Check if videos appear in detail screen
- ✅ Check console for debug messages

Try these steps and let me know which video isn't working!
