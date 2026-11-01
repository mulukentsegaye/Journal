-- ==============================================================================
-- Fix RLS Error (Code: 42501 USING expression) for Table "reflections"
-- Run this script in your Supabase Dashboard -> SQL Editor
-- ==============================================================================

-- 1. Ensure all required columns exist in public.reflections (Fixes PGRST204)
ALTER TABLE public.reflections ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE public.reflections ADD COLUMN IF NOT EXISTS is_bookmarked BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.reflections ADD COLUMN IF NOT EXISTS type TEXT NOT NULL DEFAULT 'guided';
ALTER TABLE public.reflections ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.reflections ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE public.reflections ADD COLUMN IF NOT EXISTS freeform_title TEXT;
ALTER TABLE public.reflections ADD COLUMN IF NOT EXISTS freeform_note TEXT;
ALTER TABLE public.reflections ADD COLUMN IF NOT EXISTS answers JSONB NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE public.reflections ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE public.reflections ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE public.reflections ADD COLUMN IF NOT EXISTS tags TEXT[] NOT NULL DEFAULT '{}';

-- 2. Ensure Row Level Security is active
ALTER TABLE public.reflections ENABLE ROW LEVEL SECURITY;

-- 2. Drop all legacy/conflicting policies on public.reflections
DROP POLICY IF EXISTS "Users can view own reflections" ON public.reflections;
DROP POLICY IF EXISTS "Users can insert own reflections" ON public.reflections;
DROP POLICY IF EXISTS "Users can update own reflections" ON public.reflections;
DROP POLICY IF EXISTS "Users can delete own reflections" ON public.reflections;
DROP POLICY IF EXISTS "Users can manage own reflections" ON public.reflections;
DROP POLICY IF EXISTS "Users can select own reflections" ON public.reflections;
DROP POLICY IF EXISTS "Allow select for authenticated users" ON public.reflections;
DROP POLICY IF EXISTS "Allow all for authenticated users" ON public.reflections;

-- 3. Re-create explicit, unambiguous RLS policies for public.reflections

-- Policy 1: SELECT (Read access)
CREATE POLICY "Users can select own reflections"
    ON public.reflections
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Policy 2: INSERT (Creation access)
CREATE POLICY "Users can insert own reflections"
    ON public.reflections
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Policy 3: UPDATE (Modification & Upsert access)
-- NOTE: PostgreSQL requires BOTH USING and WITH CHECK clauses for UPSERT operations.
CREATE POLICY "Users can update own reflections"
    ON public.reflections
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy 4: DELETE (Removal access)
CREATE POLICY "Users can delete own reflections"
    ON public.reflections
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- 4. Fix storage.objects policies for reflection_photos
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

-- 6. Check Email Exists Helper (pre-checks before sending confirmation emails)
CREATE OR REPLACE FUNCTION public.check_email_exists(email_to_check TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM auth.users 
        WHERE LOWER(email) = LOWER(TRIM(email_to_check))
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_email_exists(TEXT) TO anon, authenticated;

-- 7. Reload Supabase PostgREST schema cache so new columns and RPCs are recognized immediately
NOTIFY pgrst, 'reload schema';

