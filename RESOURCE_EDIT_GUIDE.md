# 📚 How to Edit Resources and Fix Video Issues

## 🎯 Where to Edit Resource Content

All resource data is located in:
```
lib/features/resources/providers/resources_provider.dart
```

---

## 📹 Adding/Editing Videos in Resources

### File Location
Open: `lib/features/resources/providers/resources_provider.dart`

### Current Resources Structure

Each resource has this structure:
```dart
Resource(
  id: '1',
  title: 'Resource Title',
  category: 'Category Name',
  content: 'Detailed text content',
  mediaUrl: 'https://www.youtube.com/watch?v=VIDEO_ID',  // ← VIDEO URL HERE
  description: 'Short description',
  learningObjectives: ['Objective 1', 'Objective 2'],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
),
```

---

## 🎬 Current Videos in System

### Resource 1: "What is Cyber Security?"
- **ID**: `1`
- **Video URL**: `https://www.youtube.com/watch?v=shQEXpUwaIY`
- **Status**: ✅ Has video
- **Line**: ~65

### Resource 2: "Types of Cyber Attack"
- **ID**: `2`
- **Video URL**: `null` (NO VIDEO)
- **Status**: ❌ Missing video
- **Line**: ~85
- **To Add**: Replace `mediaUrl: null,` with `mediaUrl: 'https://www.youtube.com/watch?v=YOUR_VIDEO_ID',`

### Resource 3: "How to Prevent It"
- **ID**: `3`
- **Video URL**: `null` (NO VIDEO)
- **Status**: ❌ Missing video
- **Line**: ~145
- **To Add**: Replace `mediaUrl: null,` with `mediaUrl: 'https://www.youtube.com/watch?v=YOUR_VIDEO_ID',`

---

## ✏️ How to Edit a Resource

### Step 1: Open the Provider File
```
lib/features/resources/providers/resources_provider.dart
```

### Step 2: Find the Resource
Search for the resource by ID or title

### Step 3: Update the Video URL
Change:
```dart
mediaUrl: null,
```

To:
```dart
mediaUrl: 'https://www.youtube.com/watch?v=YOUR_YOUTUBE_VIDEO_ID',
```

### Step 4: Save and Restart
- Save the file (Ctrl+S)
- Restart your Flutter app (full restart, not hot reload)

---

## 🐛 Troubleshooting: Why Videos Don't Show

### Issue 1: mediaUrl is null
**Solution**: Add a YouTube URL to the `mediaUrl` field

### Issue 2: Wrong URL Format
❌ Wrong:
```dart
mediaUrl: 'youtube.com/watch?v=abc123',
```

✅ Correct:
```dart
mediaUrl: 'https://www.youtube.com/watch?v=abc123',
```

### Issue 3: Video Shows Play Button But Won't Play
- Check that the video URL is correct
- Make sure the video is public (not private)
- Try the URL in your browser first

### Issue 4: Hot Reload Doesn't Show New Video
- Use full **Restart** instead of Hot Reload
- Videos need app rebuild to load

---

## 📝 Edit Examples

### Example 1: Add Video to "Types of Cyber Attack"
**Location**: Line ~90 in `resources_provider.dart`

**Before**:
```dart
Resource(
  id: '2',
  title: 'Types of Cyber Attack',
  category: 'Cyber Attacks',
  content: '''Learn about different types of cyber attacks...''',
  mediaUrl: null,  // ← NO VIDEO
  ...
)
```

**After**:
```dart
Resource(
  id: '2',
  title: 'Types of Cyber Attack',
  category: 'Cyber Attacks',
  content: '''Learn about different types of cyber attacks...''',
  mediaUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',  // ← ADDED VIDEO
  ...
)
```

---

## 🔍 Video Display Flow

```
resources_provider.dart (mediaUrl)
         ↓
resourcesProvider (Riverpod)
         ↓
resources_screen.dart (displays list)
         ↓
resource_detail_screen.dart (plays video)
         ↓
youtube_player_flutter (shows YouTube player)
```

---

## 🎥 Getting YouTube Video IDs

From URL: `https://www.youtube.com/watch?v=**dQw4w9WgXcQ**`

The ID is: `dQw4w9WgXcQ`

Use in code as:
```dart
mediaUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
```

---

## ✅ Quick Checklist

- [ ] Open `resources_provider.dart`
- [ ] Find the resource with `mediaUrl: null`
- [ ] Add YouTube URL in format: `https://www.youtube.com/watch?v=VIDEO_ID`
- [ ] Save file
- [ ] Restart Flutter app (full restart)
- [ ] Open Resources screen
- [ ] Tap on resource
- [ ] Video should appear in player

---

## 💡 Need More Videos?

You can add more resources by duplicating the Resource block:

```dart
Resource(
  id: '4',
  title: 'New Resource',
  category: 'Category',
  content: 'Content here',
  mediaUrl: 'https://www.youtube.com/watch?v=VIDEO_ID',
  description: 'Description',
  learningObjectives: ['Objective 1', 'Objective 2'],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
),
```

Then add it to the `_localResources` list at the top.

---

**Questions?** Check the resource_detail_screen.dart to see how videos are displayed!
