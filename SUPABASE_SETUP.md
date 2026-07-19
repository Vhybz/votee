
-- =====================================================
-- 1. CLEAN RESET (Caution: Deletes all data)
-- =====================================================

-- Drop existing schema if needed
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

-- Standard permissions
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO anon;
GRANT ALL ON SCHEMA public TO authenticated;
GRANT ALL ON SCHEMA public TO service_role;

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 2. CORE TABLES
-- =====================================================

-- ADMIN USERS
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT NOT NULL,
  surname TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL DEFAULT 'admin', -- superAdmin, admin, electionOfficial
  status TEXT NOT NULL DEFAULT 'pending', -- pending, approved, suspended
  rank TEXT,
  photo_url TEXT,
  enabled_permissions TEXT[] DEFAULT '{"/admin"}',
  is_deleted BOOLEAN DEFAULT false,
  last_seen TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- STUDENTS / VOTERS
CREATE TABLE public.students (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  index_number TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  level TEXT NOT NULL,
  class_name TEXT,
  phone_number TEXT,
  academic_school TEXT,
  program TEXT,
  otp TEXT DEFAULT '12345', -- Default test OTP
  has_voted BOOLEAN DEFAULT false,
  voted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- POSITIONS
CREATE TABLE public.positions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  max_selections INT DEFAULT 1,
  "order" INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- CANDIDATES
CREATE TABLE public.candidates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name TEXT NOT NULL,
  position_id UUID REFERENCES public.positions(id) ON DELETE CASCADE,
  slogan TEXT,
  image_url TEXT,
  vote_count INT DEFAULT 0,
  rejection_count INT DEFAULT 0, -- Track 'NO' votes
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- VOTES (Audit Log)
CREATE TABLE public.votes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID REFERENCES public.students(id) ON DELETE CASCADE,
  candidate_id UUID REFERENCES public.candidates(id) ON DELETE CASCADE,
  position_id UUID REFERENCES public.positions(id) ON DELETE CASCADE,
  timestamp TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ANOMALIES (Fraud Detection Alerts)
CREATE TABLE public.anomalies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  details TEXT NOT NULL,
  severity TEXT NOT NULL DEFAULT 'low', -- high, medium, low
  ip_address TEXT, -- Optional: tracking IP of the anomaly
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- BLACKLISTED IPS
CREATE TABLE public.blacklisted_ips (
  ip TEXT PRIMARY KEY,
  reason TEXT,
  blacklisted_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ELECTION SETTINGS
CREATE TABLE public.settings (
  id TEXT PRIMARY KEY DEFAULT 'current_election',
  election_title TEXT NOT NULL DEFAULT 'RavenVote by TechRaven LTD',
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Initialize settings
INSERT INTO public.settings (id, election_title) 
VALUES ('current_election', 'RavenVote by TechRaven LTD')
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 3. AUTOMATION & TRIGGERS
-- =====================================================

-- Function: Auto-create Profile & First Admin Auto-Approval
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  user_count INT;
BEGIN
  SELECT count(*) INTO user_count FROM public.users;
  
  INSERT INTO public.users (id, first_name, surname, email, role, status, rank)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', 'New'),
    COALESCE(NEW.raw_user_meta_data->>'surname', 'User'),
    NEW.email,
    CASE WHEN user_count = 0 THEN 'superAdmin' ELSE 'admin' END,
    CASE WHEN user_count = 0 THEN 'approved' ELSE 'pending' END,
    NEW.raw_user_meta_data->>'rank'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for profile creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function: Handle Vote Logic (Atomic Update)
CREATE OR REPLACE FUNCTION public.increment_vote_count()
RETURNS TRIGGER AS $$
BEGIN
  -- 1. Increase candidate total or rejection total
  IF NEW.candidate_id IS NOT NULL THEN
    UPDATE public.candidates
    SET vote_count = vote_count + 1
    WHERE id = NEW.candidate_id;
  ELSE
    -- For 'NO' votes, we'll store position_id in votes table with NULL candidate_id
    -- This assumes we update the app to send NULL for candidate_id on NO votes.
    -- Alternatively, we can use a special flag.
    NULL; 
  END IF;
  
  -- 2. Prevent student from voting again
  UPDATE public.students
  SET has_voted = true, voted_at = now()
  WHERE id = NEW.student_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for voting
CREATE TRIGGER on_vote_cast
  AFTER INSERT ON public.votes
  FOR EACH ROW EXECUTE FUNCTION public.increment_vote_count();

-- Function: Protect Root Admin
CREATE OR REPLACE FUNCTION public.protect_root_admin()
RETURNS TRIGGER AS $$
DECLARE
  root_id UUID;
BEGIN
  -- Find the oldest user ID
  SELECT id INTO root_id FROM public.users ORDER BY created_at ASC LIMIT 1;
  
  -- If deleting the root user, abort
  IF TG_OP = 'DELETE' AND OLD.id = root_id THEN
    RAISE EXCEPTION 'The Root SuperAdmin (Founder) cannot be deleted.';
  END IF;
  
  -- If updating the role of the root user to anything else, abort
  IF TG_OP = 'UPDATE' AND OLD.id = root_id AND NEW.role != 'superAdmin' THEN
    RAISE EXCEPTION 'The Root SuperAdmin (Founder) must remain a superAdmin.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for root protection
CREATE TRIGGER on_user_modify_protect
  BEFORE UPDATE OR DELETE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.protect_root_admin();

-- =====================================================
-- 3.5 PRODUCTION CONSTRAINTS (Crucial for Security)
-- =====================================================

-- Prevent duplicate voting at the database level (The ultimate safety valve)
ALTER TABLE public.votes 
DROP CONSTRAINT IF EXISTS unique_student_pos_vote;

ALTER TABLE public.votes 
ADD CONSTRAINT unique_student_pos_vote UNIQUE (student_id, position_id);

-- Ensure phone numbers are stored consistently
ALTER TABLE public.students
ADD CONSTRAINT phone_format CHECK (phone_number ~ '^[0-9]+$');

-- =====================================================
-- 4. PERFORMANCE INDEXES
-- =====================================================

CREATE INDEX idx_students_index ON public.students(index_number);
CREATE INDEX idx_candidates_position ON public.candidates(position_id);
CREATE INDEX idx_votes_candidate ON public.votes(candidate_id);

-- =====================================================
-- 5. STORAGE SETUP (Buckets & Policies)
-- =====================================================

-- Note: Use Dashboard to ensure lowercase bucket IDs.
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true), ('candidates', 'candidates', true), ('backups', 'backups', false)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

-- Enable public access (View)
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id IN ('avatars', 'candidates'));

-- Allow authenticated users to Upload/Update/Delete
DROP POLICY IF EXISTS "Admin CRUD" ON storage.objects;
CREATE POLICY "Admin CRUD" ON storage.objects 
FOR ALL 
USING (auth.role() = 'authenticated') 
WITH CHECK (auth.role() = 'authenticated');

-- Explicit Private Access for Backups
DROP POLICY IF EXISTS "Backups Private" ON storage.objects;
CREATE POLICY "Backups Private" ON storage.objects 
FOR ALL 
TO service_role 
USING (bucket_id = 'backups');

-- =====================================================
-- 6. SECURITY & REALTIME
-- =====================================================

-- Disable RLS for development to ensure connectivity
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.students DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.positions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidates DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.votes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.anomalies DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.blacklisted_ips DISABLE ROW LEVEL SECURITY;

-- Reset Realtime Publication
DROP PUBLICATION IF EXISTS supabase_realtime;
CREATE PUBLICATION supabase_realtime FOR TABLE 
  public.users,
  public.students, 
  public.candidates, 
  public.votes,
  public.positions,
  public.anomalies,
  public.settings,
  public.blacklisted_ips;

-- =====================================================
-- 7. EXPLICIT GRANTS
-- =====================================================

GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, anon, authenticated, service_role;

