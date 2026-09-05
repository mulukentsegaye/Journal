-- ==============================================================================
-- Daily Reflection - Supabase Database Schema
-- ==============================================================================

-- 1. Enable UUID Extension (standard in Supabase)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Create Reflections Table
CREATE TABLE IF NOT EXISTS public.reflections (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE DEFAULT auth.uid(),
    date TIMESTAMPTZ NOT NULL,
    mood TEXT NOT NULL DEFAULT 'Calm',
    mood_emoji TEXT NOT NULL DEFAULT '🌿',
    answers JSONB NOT NULL DEFAULT '{}'::jsonb,
    freeform_title TEXT,
    freeform_note TEXT,
    photo_url TEXT,
    is_bookmarked BOOLEAN NOT NULL DEFAULT FALSE,
    type TEXT NOT NULL DEFAULT 'guided',
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Migration helpers if table already exists
ALTER TABLE public.reflections ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE public.reflections ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.reflections ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.reflections ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS Policies (Users can only access and modify their own private reflections)
DROP POLICY IF EXISTS "Users can view own reflections" ON public.reflections;
DROP POLICY IF EXISTS "Users can insert own reflections" ON public.reflections;
DROP POLICY IF EXISTS "Users can update own reflections" ON public.reflections;
DROP POLICY IF EXISTS "Users can delete own reflections" ON public.reflections;
DROP POLICY IF EXISTS "Users can manage own reflections" ON public.reflections;
DROP POLICY IF EXISTS "Users can select own reflections" ON public.reflections;

-- SELECT policy: Users can only read their own rows
CREATE POLICY "Users can select own reflections"
    ON public.reflections
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- INSERT policy: Must satisfy WITH CHECK
CREATE POLICY "Users can insert own reflections"
    ON public.reflections
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- UPDATE policy: BOTH USING and WITH CHECK are required for PostgREST upsert
CREATE POLICY "Users can update own reflections"
    ON public.reflections
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- DELETE policy: Must satisfy USING
CREATE POLICY "Users can delete own reflections"
    ON public.reflections
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- 5. Performance Indexes
CREATE INDEX IF NOT EXISTS idx_reflections_user_date 
    ON public.reflections(user_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_reflections_user_active_date 
    ON public.reflections(user_id, is_deleted, date DESC);

CREATE INDEX IF NOT EXISTS idx_reflections_user_bookmarked 
    ON public.reflections(user_id, is_bookmarked) 
    WHERE is_bookmarked = TRUE;

-- 6. Updated At Trigger Function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_updated_at ON public.reflections;
CREATE TRIGGER trigger_set_updated_at
    BEFORE UPDATE ON public.reflections
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ==============================================================================
-- 7. Supabase Storage Bucket Setup for Attached Moment Photos
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('reflection_photos', 'reflection_photos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Storage RLS Policies (User-isolated storage: user_id/filename)
DROP POLICY IF EXISTS "Authenticated users can upload photos" ON storage.objects;
CREATE POLICY "Authenticated users can upload photos"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'reflection_photos' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

DROP POLICY IF EXISTS "Authenticated users can update photos" ON storage.objects;
CREATE POLICY "Authenticated users can update photos"
    ON storage.objects FOR UPDATE TO authenticated
    USING (
        bucket_id = 'reflection_photos' AND
        (storage.foldername(name))[1] = auth.uid()::text
    )
    WITH CHECK (
        bucket_id = 'reflection_photos' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

DROP POLICY IF EXISTS "Public can view reflection photos" ON storage.objects;
CREATE POLICY "Public can view reflection photos"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'reflection_photos');

DROP POLICY IF EXISTS "Authenticated users can delete photos" ON storage.objects;
CREATE POLICY "Authenticated users can delete photos"
    ON storage.objects FOR DELETE TO authenticated
    USING (
        bucket_id = 'reflection_photos' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

-- ==============================================================================
-- Optional: AI Semantic Search with pgvector (Ready for future activation)
-- ==============================================================================
-- To enable semantic search:
-- 1. In Supabase Dashboard -> Database -> Extensions -> Enable "vector"
-- 2. Uncomment and run the following:
--
-- CREATE EXTENSION IF NOT EXISTS vector;
-- ALTER TABLE public.reflections ADD COLUMN IF NOT EXISTS embedding vector(1536);
-- CREATE INDEX IF NOT EXISTS idx_reflections_embedding ON public.reflections 
-- USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
--
-- CREATE OR REPLACE FUNCTION match_reflections (
--   query_embedding vector(1536),
--   match_threshold float,
--   match_count int
-- )
-- RETURNS TABLE (
--   id text,
--   freeform_title text,
--   freeform_note text,
--   mood text,
--   date timestamptz,
--   similarity float
-- )
-- LANGUAGE plpgsql
-- AS $$
-- BEGIN
--   RETURN QUERY
--   SELECT
--     reflections.id,
--     reflections.freeform_title,
--     reflections.freeform_note,
--     reflections.mood,
--     reflections.date,
--     1 - (reflections.embedding <=> query_embedding) AS similarity
--   FROM reflections
--   WHERE reflections.user_id = auth.uid()
--     AND 1 - (reflections.embedding <=> query_embedding) > match_threshold
--   ORDER BY similarity DESC
--   LIMIT match_count;
-- END;
-- $$;
