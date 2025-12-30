# Admin Media Upload Feature Setup Guide

## Overview
The admin question management now supports **direct file uploads** for images and MP4 videos in the Attack module, in addition to URL input.

## Features Added
- ✅ Upload image files (JPG, PNG, GIF, etc.)
- ✅ Upload MP4 video files
- ✅ Automatic upload to Supabase Storage
- ✅ Option to use URL instead of file upload
- ✅ Upload progress indicator
- ✅ File validation and error handling

## Supabase Storage Setup

### Step 1: Create Storage Bucket
1. Go to your Supabase Dashboard
2. Navigate to **Storage** in the left sidebar
3. Click **New Bucket**
4. Create a bucket with the following settings:
   - **Name**: `question-media`
   - **Public**: ✅ Enabled (so media can be accessed publicly)
   - **File size limit**: 50MB (recommended for videos)
   - **Allowed MIME types**: 
     - Images: `image/*`
     - Videos: `video/mp4`, `video/webm`

### Step 2: Set Up Storage Policies
You need to run **ALL THREE** SQL policies below in Supabase.

**Where to run the SQL:**
1. Go to Supabase Dashboard
2. Click **SQL Editor** in the left sidebar (or use the Storage Policies section)
3. Click **"+ New query"**
4. Copy and paste each policy below (one at a time)
5. Click **"Run"** or press Ctrl+Enter

---

#### Policy 1: Public Read Access (Required)
Copy and run this SQL:

```sql
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'question-media' );
```

---

#### Policy 2: Authenticated Upload (Required)
Copy and run this SQL:

```sql
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'question-media' AND
  auth.role() = 'authenticated'
);
```

---

#### Policy 3: Authenticated Delete (Optional but Recommended)
Copy and run this SQL:

```sql
CREATE POLICY "Authenticated users can delete"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'question-media' AND
  auth.role() = 'authenticated'
);
```

---

**Alternative Method (Using Storage UI):**
1. Go to **Storage** → `question-media` bucket → **Policies** tab
2. Click **"New Policy"** → **"For full customization"**
3. Paste each SQL above
4. Click **"Review"** → **"Save policy"**

**✅ Success Check:** After running all 3, you should see 3 policies listed under your bucket's Policies tab.

## How to Use (Admin Guide)

### Adding Questions with Media

1. **Navigate to Admin Dashboard** → Question Management → Select "Attack" module
2. **Click "Add Question"**
3. **Fill in question details**:
   - Description
   - Answer options (A, B, C, D)
   - Select correct answer

4. **Add Media** (for Image or MP4 Video):
   
   **Option 1: Upload File**
   - Select media type: "Image" or "MP4 Video"
   - Click **"Upload [Image/Video] File"** button
   - Select file from your computer
   - Wait for upload to complete (green checkmark appears)
   - The URL field will be automatically filled

   **Option 2: Enter URL**
   - Select media type
   - Enter the direct URL in the text field below "OR enter URL directly:"

5. **Complete the question**:
   - Add explanation
   - Set difficulty level
   - Click **Save**

### Supported File Types
- **Images**: JPG, PNG, GIF, WebP, BMP
- **Videos**: MP4, WebM (MP4 recommended for best compatibility)

### File Size Recommendations
- **Images**: Up to 5MB
- **Videos**: Up to 50MB (keep videos short for better performance)

## Technical Details

### File Upload Process
1. User selects file through file picker
2. File is validated for type and size
3. File is uploaded to Supabase Storage bucket `question-media`
4. Files are stored in folders:
   - `images/` for image files
   - `videos/` for video files
5. Public URL is generated and stored in the question

### File Naming Convention
Files are renamed on upload:
```
{moduleType}_{timestamp}.{extension}
```
Example: `attack_1735574400000.mp4`

## Package Dependencies
The following package was added to support file uploads:
- `file_picker: ^8.0.0+1`

To install, run:
```bash
flutter pub get
```

## Troubleshooting

### Upload Failed Error
- **Cause**: Storage bucket doesn't exist or policies are not set
- **Solution**: Follow setup steps above to create bucket and policies

### File Too Large Error
- **Cause**: File exceeds bucket size limit
- **Solution**: Compress video/image or adjust bucket size limit in Supabase

### Permission Denied
- **Cause**: User is not authenticated or policies are missing
- **Solution**: Ensure admin is logged in and storage policies are created

## Notes
- YouTube videos still use URL input (no upload needed)
- Uploaded files are stored permanently until manually deleted
- Consider implementing cleanup for unused media files
- Video files should be compressed for optimal performance
