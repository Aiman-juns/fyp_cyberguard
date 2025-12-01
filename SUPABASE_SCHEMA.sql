-- CyberGuard - Supabase PostgreSQL Schema
-- Execute these SQL statements in the Supabase SQL Editor

-- ============================================================================
-- EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- ENUMS
-- ============================================================================

CREATE TYPE user_role AS ENUM ('user', 'admin');

CREATE TYPE module_type AS ENUM ('phishing', 'password', 'attack');

-- ============================================================================
-- TABLES
-- ============================================================================

-- 1. USERS TABLE
CREATE TABLE public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role user_role NOT NULL DEFAULT 'user',
    avatar_url TEXT,
    total_score INTEGER NOT NULL DEFAULT 0,
    level INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT TIMEZONE('utc'::text, NOW()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 2. RESOURCES TABLE
CREATE TABLE public.resources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    content TEXT NOT NULL,
    media_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT TIMEZONE('utc'::text, NOW()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 3. QUESTIONS TABLE
CREATE TABLE public.questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_type module_type NOT NULL,
    difficulty INTEGER NOT NULL DEFAULT 1 CHECK (difficulty >= 1 AND difficulty <= 5),
    content TEXT NOT NULL,
    correct_answer TEXT NOT NULL,
    explanation TEXT NOT NULL,
    media_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT TIMEZONE('utc'::text, NOW()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 4. USER_PROGRESS TABLE
CREATE TABLE public.user_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    is_correct BOOLEAN NOT NULL,
    score_awarded INTEGER NOT NULL DEFAULT 0,
    attempt_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT TIMEZONE('utc'::text, NOW()),
    UNIQUE(user_id, question_id)
);

-- 5. NEWS TABLE
CREATE TABLE public.news (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    source_url TEXT,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT TIMEZONE('utc'::text, NOW()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT TIMEZONE('utc'::text, NOW())
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Performance indexes
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_role ON public.users(role);
CREATE INDEX idx_resources_category ON public.resources(category);
CREATE INDEX idx_questions_module_type ON public.questions(module_type);
CREATE INDEX idx_questions_difficulty ON public.questions(difficulty);
CREATE INDEX idx_user_progress_user_id ON public.user_progress(user_id);
CREATE INDEX idx_user_progress_question_id ON public.user_progress(question_id);
CREATE INDEX idx_news_created_at ON public.news(created_at DESC);

-- ============================================================================
-- TRIGGERS (for updated_at)
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for users
CREATE TRIGGER users_updated_at_trigger
BEFORE UPDATE ON public.users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger for resources
CREATE TRIGGER resources_updated_at_trigger
BEFORE UPDATE ON public.resources
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger for questions
CREATE TRIGGER questions_updated_at_trigger
BEFORE UPDATE ON public.questions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger for news
CREATE TRIGGER news_updated_at_trigger
BEFORE UPDATE ON public.news
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.news ENABLE ROW LEVEL SECURITY;

-- USERS TABLE POLICIES
-- Users can read their own profile, admins can read all
CREATE POLICY "Users can read own profile" ON public.users
    FOR SELECT USING (auth.uid() = id OR auth.jwt() ->> 'role' = 'admin');

-- Admins can update user roles and data
CREATE POLICY "Admins can update any user" ON public.users
    FOR UPDATE USING (auth.jwt() ->> 'role' = 'admin');

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- RESOURCES TABLE POLICIES
-- Everyone can read resources
CREATE POLICY "Anyone can read resources" ON public.resources
    FOR SELECT USING (true);

-- Admins can insert resources
CREATE POLICY "Admins can insert resources" ON public.resources
    FOR INSERT WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- Admins can update resources
CREATE POLICY "Admins can update resources" ON public.resources
    FOR UPDATE USING (auth.jwt() ->> 'role' = 'admin');

-- Admins can delete resources
CREATE POLICY "Admins can delete resources" ON public.resources
    FOR DELETE USING (auth.jwt() ->> 'role' = 'admin');

-- QUESTIONS TABLE POLICIES
-- Everyone can read questions
CREATE POLICY "Anyone can read questions" ON public.questions
    FOR SELECT USING (true);

-- Admins can insert questions
CREATE POLICY "Admins can insert questions" ON public.questions
    FOR INSERT WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- Admins can update questions
CREATE POLICY "Admins can update questions" ON public.questions
    FOR UPDATE USING (auth.jwt() ->> 'role' = 'admin');

-- Admins can delete questions
CREATE POLICY "Admins can delete questions" ON public.questions
    FOR DELETE USING (auth.jwt() ->> 'role' = 'admin');

-- USER_PROGRESS TABLE POLICIES
-- Users can read/insert/update their own progress
CREATE POLICY "Users can read own progress" ON public.user_progress
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress" ON public.user_progress
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress" ON public.user_progress
    FOR UPDATE USING (auth.uid() = user_id);

-- Admins can read all progress
CREATE POLICY "Admins can read all progress" ON public.user_progress
    FOR SELECT USING (auth.jwt() ->> 'role' = 'admin');

-- NEWS TABLE POLICIES
-- Everyone can read news
CREATE POLICY "Anyone can read news" ON public.news
    FOR SELECT USING (true);

-- Admins can insert news
CREATE POLICY "Admins can insert news" ON public.news
    FOR INSERT WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- Admins can update news
CREATE POLICY "Admins can update news" ON public.news
    FOR UPDATE USING (auth.jwt() ->> 'role' = 'admin');

-- Admins can delete news
CREATE POLICY "Admins can delete news" ON public.news
    FOR DELETE USING (auth.jwt() ->> 'role' = 'admin');

-- ============================================================================
-- STORAGE BUCKETS
-- ============================================================================

-- Create storage bucket for media uploads (images, videos)
-- Note: Execute this in Supabase Dashboard > Storage > New Bucket
-- Bucket Name: media
-- Public (turned ON for direct URL access)

-- ============================================================================
-- SAMPLE DATA (OPTIONAL - for testing)
-- ============================================================================

-- Sample Resources
INSERT INTO public.resources (title, category, content, media_url)
VALUES
    ('Phishing Basics', 'Phishing', 'Learn how to identify phishing emails...', NULL),
    ('Password Best Practices', 'Security', 'Creating strong and unique passwords...', NULL),
    ('Malware Protection', 'Malware', 'Protect your device from malware attacks...', NULL);

-- Sample Questions - Phishing Module
INSERT INTO public.questions (module_type, difficulty, content, correct_answer, explanation, media_url)
VALUES
    ('phishing', 1, 'Which of these is a sign of a phishing email?', 'Suspicious sender domain', 'Phishing emails often come from domains that look similar to legitimate ones.', NULL),
    ('phishing', 2, 'What should you do if you receive a suspicious email?', 'Report it to your IT department', 'Always report suspicious emails to your IT department or email provider.', NULL);

-- Sample Questions - Password Module
INSERT INTO public.questions (module_type, difficulty, content, correct_answer, explanation, media_url)
VALUES
    ('password', 1, 'How long should a strong password be?', 'At least 12 characters', 'Strong passwords should be at least 12 characters long with mixed case, numbers, and symbols.', NULL),
    ('password', 2, 'What should you avoid in passwords?', 'Using personal information', 'Avoid using names, birthdays, or other personal information that can be guessed.', NULL);

-- Sample Questions - Cyber Attack Analyst Module
INSERT INTO public.questions (module_type, difficulty, content, correct_answer, explanation, media_url)
VALUES
    ('attack', 1, 'What is a DDoS attack?', 'Overwhelming a server with traffic', 'A DDoS (Distributed Denial of Service) attack floods a server with requests to make it unavailable.', NULL),
    ('attack', 2, 'How can you protect against SQL injection?', 'Use parameterized queries', 'Parameterized queries or prepared statements prevent SQL injection attacks.', NULL);

-- Sample News
INSERT INTO public.news (title, body, source_url, image_url)
VALUES
    ('New Phishing Campaign Targets Malaysian Banks', 'A new phishing campaign has been identified...', 'https://example.com/news1', NULL),
    ('Cybersecurity Awareness Week 2025', 'Join us for cybersecurity awareness activities...', 'https://example.com/news2', NULL);

-- ============================================================================
-- HELPFUL QUERIES FOR FLUTTER APP
-- ============================================================================

-- Get user by ID with progress stats
-- SELECT u.*, COUNT(up.id) as total_questions_answered
-- FROM public.users u
-- LEFT JOIN public.user_progress up ON u.id = up.user_id
-- WHERE u.id = {user_id}
-- GROUP BY u.id;

-- Get user progress by module
-- SELECT module_type, COUNT(*) as total, SUM(CASE WHEN is_correct THEN 1 ELSE 0 END) as correct
-- FROM public.questions q
-- LEFT JOIN public.user_progress up ON q.id = up.question_id
-- WHERE up.user_id = {user_id}
-- GROUP BY module_type;

-- Get latest news (limit 10)
-- SELECT * FROM public.news ORDER BY created_at DESC LIMIT 10;

-- Get questions by module and difficulty
-- SELECT * FROM public.questions
-- WHERE module_type = {module_type}
-- AND difficulty <= {max_difficulty}
-- ORDER BY difficulty ASC;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
