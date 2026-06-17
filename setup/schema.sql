-- ─────────────────────────────────────────────────────────────────────
-- FRPL — Supabase Schema  (matches app column names exactly)
-- Run in: Supabase Dashboard → SQL Editor → New query → Run
-- ─────────────────────────────────────────────────────────────────────

-- ── User profiles ────────────────────────────────────────────────────
create table public.profiles (
  id         uuid references auth.users on delete cascade primary key,
  created_at timestamptz default now() not null
);

-- ── Custom category tabs ──────────────────────────────────────────────
-- The 3 default tabs (Owned / To Try / Favourite Notes) are hardcoded
-- in the app; only user-created tabs are stored here.
create table public.categories (
  id         uuid default gen_random_uuid() primary key,
  user_id    uuid references public.profiles on delete cascade not null,
  name       text not null,
  sort_order smallint default 0,
  created_at timestamptz default now() not null
);

-- ── Lists ─────────────────────────────────────────────────────────────
create table public.lists (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references public.profiles on delete cascade not null,
  section_id  text not null,   -- 'owned' | 'totry' | 'favnotes' | custom category UUID
  parent_id   uuid references public.lists on delete cascade,
  name        text not null,
  cover_start text not null default '#8E73C0',
  cover_end   text not null default '#C9B8E6',
  sort_order  smallint default 0,
  created_at  timestamptz default now() not null
);

-- ── List entries ──────────────────────────────────────────────────────
create table public.list_entries (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references public.profiles on delete cascade not null,
  list_id     uuid references public.lists on delete cascade not null,
  perfume_id  text not null,
  tag         text check (tag in ('toget', 'travel')),
  position    smallint default 0,
  created_at  timestamptz default now() not null,
  unique (list_id, perfume_id)
);

-- ── Personal notes per perfume ────────────────────────────────────────
create table public.user_perfume_notes (
  user_id     uuid references public.profiles on delete cascade not null,
  perfume_id  text not null,
  note        text,
  reminds_of  text,
  price_paid  text,
  price_target text,
  updated_at  timestamptz default now() not null,
  primary key (user_id, perfume_id)
);

-- ── Manually added perfumes ───────────────────────────────────────────
create table public.custom_perfumes (
  id         text primary key,
  user_id    uuid references public.profiles on delete cascade not null,
  name       text not null,
  brand      text,
  year       smallint,
  created_at timestamptz default now() not null
);

-- ── Row Level Security ────────────────────────────────────────────────
alter table public.profiles         enable row level security;
alter table public.categories       enable row level security;
alter table public.lists            enable row level security;
alter table public.list_entries     enable row level security;
alter table public.user_perfume_notes enable row level security;
alter table public.custom_perfumes  enable row level security;

create policy "own_profile"       on public.profiles           for all using (auth.uid() = id);
create policy "own_categories"    on public.categories         for all using (auth.uid() = user_id);
create policy "own_lists"         on public.lists              for all using (auth.uid() = user_id);
create policy "own_entries"       on public.list_entries       for all using (auth.uid() = user_id);
create policy "own_notes"         on public.user_perfume_notes for all using (auth.uid() = user_id);
create policy "own_custom"        on public.custom_perfumes    for all using (auth.uid() = user_id);

-- ── Auto-create profile on sign-up ───────────────────────────────────
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id) values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
