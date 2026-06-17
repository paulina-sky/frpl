-- ============================================================
-- FRPL — Supabase Schema  
-- Paste into: Supabase Dashboard → SQL Editor → New query → Run
-- ============================================================

-- ── Profiles ────────────────────────────────────────────────
create table if not exists public.profiles (
  id            uuid primary key references auth.users on delete cascade,
  email         text,
  display_name  text,
  created_at    timestamptz default now()
);
alter table public.profiles enable row level security;
create policy "own profile" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

-- Auto-create profile on sign-up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email, split_part(new.email, '@', 1))
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ── Custom categories (tabs beyond the 3 built-ins) ─────────
create table if not exists public.categories (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references auth.users on delete cascade not null,
  name        text not null,
  sort_order  int default 0,
  created_at  timestamptz default now()
);
alter table public.categories enable row level security;
create policy "own categories" on public.categories
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ── Lists ───────────────────────────────────────────────────
create table if not exists public.lists (
  id           uuid default gen_random_uuid() primary key,
  user_id      uuid references auth.users on delete cascade not null,
  name         text not null,
  section_id   text not null,   -- 'owned' | 'totry' | 'favnotes' | <category uuid>
  parent_id    uuid references public.lists(id) on delete cascade,
  cover_start  text default '#8E73C0',
  cover_end    text default '#C9B8E6',
  sort_order   int default 0,
  created_at   timestamptz default now()
);
alter table public.lists enable row level security;
create policy "own lists" on public.lists
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ── List entries ────────────────────────────────────────────
create table if not exists public.list_entries (
  id          uuid default gen_random_uuid() primary key,
  list_id     uuid references public.lists(id) on delete cascade not null,
  user_id     uuid references auth.users on delete cascade not null,
  perfume_id  text not null,    -- numeric string from catalogue, or custom perfume UUID
  tag         text check (tag in ('toget', 'travel')),
  position    int default 0,
  added_at    timestamptz default now(),
  unique (list_id, perfume_id)
);
alter table public.list_entries enable row level security;
create policy "own list entries" on public.list_entries
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ── Manually added perfumes (not in the catalogue) ──────────
create table if not exists public.custom_perfumes (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references auth.users on delete cascade not null,
  name        text not null,
  brand       text,
  year        int,
  created_at  timestamptz default now()
);
alter table public.custom_perfumes enable row level security;
create policy "own custom perfumes" on public.custom_perfumes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ── Per-user perfume annotations ────────────────────────────
create table if not exists public.user_perfume_notes (
  id            uuid default gen_random_uuid() primary key,
  user_id       uuid references auth.users on delete cascade not null,
  perfume_id    text not null,
  note          text,
  reminds_of    text,
  price_paid    text,
  price_target  text,
  updated_at    timestamptz default now(),
  unique (user_id, perfume_id)
);
alter table public.user_perfume_notes enable row level security;
create policy "own perfume notes" on public.user_perfume_notes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
