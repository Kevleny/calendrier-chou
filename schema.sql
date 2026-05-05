-- ============================================================
-- CALENDRIER CHOU — Schéma Supabase
-- À coller dans : Supabase Dashboard > SQL Editor > New Query
-- ============================================================

-- 1. Table des profils utilisateurs
CREATE TABLE IF NOT EXISTS profiles (
  id    UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name  TEXT NOT NULL,
  city  TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '#e8a87c',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Table des événements
CREATE TABLE IF NOT EXISTS events (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title       TEXT NOT NULL,
  event_date  DATE NOT NULL,
  event_time  TIME,
  location    TEXT,
  created_by  UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- RLS (Row Level Security)
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE events   ENABLE ROW LEVEL SECURITY;

-- Profiles : lecture publique (authentifié), écriture own
CREATE POLICY "profiles_read"   ON profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "profiles_insert" ON profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

-- Events : lecture publique, CRUD own
CREATE POLICY "events_read"   ON events FOR SELECT TO authenticated USING (true);
CREATE POLICY "events_insert" ON events FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);
CREATE POLICY "events_update" ON events FOR UPDATE TO authenticated USING (auth.uid() = created_by);
CREATE POLICY "events_delete" ON events FOR DELETE TO authenticated USING (auth.uid() = created_by);

-- ============================================================
-- Trigger updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER events_updated_at
  BEFORE UPDATE ON events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- Realtime (obligatoire pour les notifications)
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE events;

-- ============================================================
-- MIGRATION : Nouveaux champs événements
-- À exécuter dans Supabase Dashboard > SQL Editor
-- ============================================================

ALTER TABLE events ADD COLUMN IF NOT EXISTS category    TEXT;
ALTER TABLE events ADD COLUMN IF NOT EXISTS notes       TEXT;
ALTER TABLE events ADD COLUMN IF NOT EXISTS end_time    TIME;
ALTER TABLE events ADD COLUMN IF NOT EXISTS is_irl      BOOLEAN DEFAULT false;

-- ============================================================
-- IMPORTANT : Dans Supabase Dashboard
-- > Authentication > Settings > Email
-- Désactiver "Enable email confirmations"
-- pour que les comptes soient actifs immédiatement.
-- ============================================================
