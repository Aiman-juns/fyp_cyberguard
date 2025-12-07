# How to Add Local Video Files to Learning Resources

The app now uses local video files instead of YouTube links. Here's how to add videos:

## Step 1: Prepare Your Video Files

1. **Supported formats**: MP4, MOV, AVI, MKV
2. **Recommended**: MP4 format (most compatible)
3. **Place videos in your project**: 
   - Create a folder: `assets/videos/` in your project root
   - Or use any accessible folder on your device

## Step 2: Add Videos to Assets (Option 1 - Bundled)

If you want videos bundled with the app:

1. Create `assets/videos/` folder in project root
2. Copy your video files there
3. Update `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/videos/
    - assets/videos/phishing_intro.mp4
    - assets/videos/password_security.mp4
    # Add more video files here
```

4. Run: `flutter pub get`

## Step 3: Use External Storage (Option 2 - Not Bundled)

For larger videos or frequently updated content:

1. Place videos in device storage
2. Use absolute paths like:
   - Windows: `C:/Users/YourName/Videos/cyberguard/phishing_intro.mp4`
   - Android: `/storage/emulated/0/CyberGuard/Videos/phishing_intro.mp4`
   - iOS: Use app's Documents directory

## Step 4: Update Resource mediaUrl in Admin Panel

1. Go to Admin Dashboard → Learning Resources
2. Edit or create a resource
3. In the **Media URL** field, enter the video file path:
   - Bundled: `assets/videos/phishing_intro.mp4`
   - External: Full path like `C:/Users/YourName/Videos/video.mp4`

## Example Video Paths

### For Testing (Bundled Assets):
```
assets/videos/phishing_email_detection.mp4
assets/videos/password_security_basics.mp4
assets/videos/cyber_attack_prevention.mp4
```

### For Production (External Storage):
```
C:/CyberGuard/Videos/phishing_email_detection.mp4
/storage/emulated/0/CyberGuard/Videos/password_security.mp4
```

## Video Player Features

The new video player includes:
- ✅ Play/Pause button (center overlay)
- ✅ Progress bar with scrubbing
- ✅ -10s / +10s skip buttons
- ✅ Automatic progress tracking
- ✅ Note timestamps linked to video position
- ✅ Error messages if video not found

## Troubleshooting

### "Video file not found" error:
1. Check file path is correct (case-sensitive)
2. Verify file exists at the specified location
3. For bundled assets, ensure `pubspec.yaml` is updated
4. Run `flutter clean` then `flutter pub get`

### Video not playing:
1. Ensure video format is supported (MP4 recommended)
2. Check file is not corrupted
3. For large files, ensure device has enough storage

### Black screen with loading indicator:
1. Video is still loading (wait a few seconds)
2. Check video codec is supported (H.264 recommended)

## Recommended Video Specifications

- **Format**: MP4 (H.264 video, AAC audio)
- **Resolution**: 720p or 1080p
- **Aspect Ratio**: 16:9
- **Bitrate**: 1-5 Mbps
- **File Size**: Keep under 100MB for better performance

## Next Steps

1. Prepare your video files
2. Choose bundled or external storage approach
3. Update the `mediaUrl` field in your resources
4. Test the video playback in the app
