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
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Migration helper if table already exists
ALTER TABLE public.reflections ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.reflections ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS Policies (Users can only access and modify their own private reflections)
DROP POLICY IF EXISTS "Users can view own reflections" ON public.reflections;
DROP POLICY IF EXISTS "Users can insert own reflections" ON public.reflections;
DROP POLICY IF EXISTS "Users can update own reflections" ON public.reflections;
DROP POLICY IF EXISTS "Users can delete own reflections" ON public.reflections;
DROP POLICY IF EXISTS "Users can manage own reflections" ON public.reflections;

CREATE POLICY "Users can manage own reflections"
    ON public.reflections
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 5. Performance Indexes
CREATE INDEX IF NOT EXISTS idx_reflections_user_date 
    ON public.reflections(user_id, date DESC);

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
