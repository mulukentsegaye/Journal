-- ==============================================================================
-- Fix RLS Error (Code: 42501 USING expression) for Table "reflections"
-- Run this script in your Supabase Dashboard -> SQL Editor
-- ==============================================================================

-- 1. Ensure Row Level Security is active
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
