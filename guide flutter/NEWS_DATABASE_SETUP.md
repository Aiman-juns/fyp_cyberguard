# News Feature Database Schema Update

## Required Supabase Table Structure

Run this SQL in your Supabase SQL Editor to update the `news` table:

```sql
-- Update the news table structure
ALTER TABLE public.news
  ADD COLUMN IF NOT EXISTS summary TEXT,
  ADD COLUMN IF NOT EXISTS source TEXT,
  ADD COLUMN IF NOT EXISTS url TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS published_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'General';

-- Migrate existing data (if you have old data)
UPDATE public.news
SET 
  summary = body,
  url = source_url
WHERE summary IS NULL;

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_news_published_at ON public.news(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_news_category ON public.news(category);
CREATE INDEX IF NOT EXISTS idx_news_url ON public.news(url);

-- Update RLS policies (if needed)
-- Make sure authenticated users can read news
DROP POLICY IF EXISTS "Allow authenticated users to read news" ON public.news;
CREATE POLICY "Allow authenticated users to read news"
  ON public.news FOR SELECT
  TO authenticated
  USING (true);

-- Optional: Allow service role to insert/update for caching
DROP POLICY IF EXISTS "Allow service role to manage news" ON public.news;
CREATE POLICY "Allow service role to manage news"
  ON public.news FOR ALL
  TO service_role
  USING (true);
```

## Testing the Setup

After running the SQL:

1. Get your NewsData.io API key from https://newsdata.io
2. Add the key to `.env` file:
   ```
   NEWSDATA_API_KEY=your_actual_api_key
   ```
3. Run the app and tap the refresh button in the News screen
4. The app will fetch real-time news and cache it in Supabase

## How It Works

1. **First Load**: App reads cached news from Supabase (ordered by published_at)
2. **Refresh**: Taps refresh → Calls NewsData.io API → Falls back to GDELT if needed → Caches results
3. **Categories**: Articles are auto-categorized based on keywords:
   - **Scam**: phishing, scam, fraud
   - **Ransomware**: ransomware, malware, virus
   - **Data Breach**: breach, leak, hack, stolen
   - **Cyber Attack**: attack, ddos, threat, exploit
   - **General**: Everything else

## API Limits

- **NewsData.io Free Tier**: 200 requests/day
- **GDELT**: Unlimited (fallback source)
- **Recommendation**: Use refresh sparingly or implement rate limiting
