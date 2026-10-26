-- ==============================================================================
-- ADD USER_ACTIVE_BORDER TO COURSE_FEEDBACK
-- Project: FOODIE Mobile App
-- Feature: Saran & Kesan Mata Kuliah (Public Border Showcase)
-- Target: Supabase PostgreSQL
-- ==============================================================================

-- 1. Tambahkan kolom user_active_border di tabel course_feedback jika belum ada
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'course_feedback' 
          AND column_name = 'user_active_border'
    ) THEN
        ALTER TABLE public.course_feedback ADD COLUMN user_active_border TEXT;
    END IF;
END $$;

-- 2. Index untuk performa query ulasan
CREATE INDEX IF NOT EXISTS idx_course_feedback_user_active_border 
ON public.course_feedback(user_active_border) 
WHERE user_active_border IS NOT NULL;

-- 3. Sinkronisasi active_border_id dari tabel profiles ke data ulasan yang sudah ada
UPDATE public.course_feedback cf
SET user_active_border = p.active_border_id
FROM public.profiles p
WHERE cf.user_id = p.id::text
  AND p.active_border_id IS NOT NULL
  AND (cf.user_active_border IS NULL OR cf.user_active_border = '');
