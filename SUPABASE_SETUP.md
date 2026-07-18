# RavenVote - Supabase Setup Guide

Run the following SQL script in your **Supabase SQL Editor** to initialize the database for RavenVote.

```sql
-- =====================================================
-- 1. CLEAN RESET
-- =====================================================

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO anon;
GRANT ALL ON SCHEMA public TO authenticated;
GRANT ALL ON SCHEMA public TO service_role;

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
  photo_url TEXT,
  enabled_permissions TEXT[] DEFAULT '{"/admin"}',
  is_deleted BOOLEAN DEFAULT false,
  last_seen TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- STUDENTS (Eligible Voters)
CREATE TABLE public.students (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  index_number TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  level TEXT NOT NULL,
  class_name TEXT,
  phone_number TEXT,
  academic_school TEXT,
  program TEXT,
  otp TEXT, -- Used for MFA verification
  has_voted BOOLEAN DEFAULT false,
  voted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- POSITIONS (e.g., President, Secretary)
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
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- VOTES (Audit Log)
CREATE TABLE public.votes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID REFERENCES public.students(id),
  candidate_id UUID REFERENCES public.candidates(id),
  position_id UUID REFERENCES public.positions(id),
  timestamp TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =====================================================
-- 3. SECURITY & REALTIME
-- =====================================================

-- Disable RLS for initial development
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.students DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.positions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidates DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.votes DISABLE ROW LEVEL SECURITY;

GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE 
  public.students, 
  public.candidates, 
  public.votes,
  public.positions;

-- =====================================================
-- 4. INITIAL DATA (Optional)
-- =====================================================

-- Insert a test student
-- INSERT INTO public.students (index_number, full_name, level, otp) 
-- VALUES ('20001234', 'Emmanuel Kwesi Arthur', '400', '12345');
```
