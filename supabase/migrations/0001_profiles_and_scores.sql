-- Block Fusion: player identity and score sync.
--
-- Two tables, deliberately:
--   profiles  one row per player, holding the value the game reads back on
--             every launch (their best score) and what a leaderboard needs
--             to show (name, avatar).
--   scores    one row per finished game, so a player's history survives and
--             the best score can always be recomputed from the record
--             rather than trusted as a running total.

create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  avatar_url  text,
  best_score  integer not null default 0 check (best_score >= 0),
  updated_at  timestamptz not null default now()
);

create table if not exists public.scores (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  score      integer not null check (score >= 0),
  created_at timestamptz not null default now()
);

-- The leaderboard sorts by best_score; the history view filters by player.
create index if not exists profiles_best_score_idx
  on public.profiles (best_score desc);
create index if not exists scores_user_created_idx
  on public.scores (user_id, created_at desc);

alter table public.profiles enable row level security;
alter table public.scores   enable row level security;

-- Profiles are readable by any signed-in player, because that is what makes
-- a leaderboard possible, but writable only by their owner.
drop policy if exists "profiles are readable by authenticated users" on public.profiles;
create policy "profiles are readable by authenticated users"
  on public.profiles for select
  to authenticated
  using (true);

drop policy if exists "a player can insert their own profile" on public.profiles;
create policy "a player can insert their own profile"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

drop policy if exists "a player can update their own profile" on public.profiles;
create policy "a player can update their own profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Scores are private: a player sees and writes only their own games.
drop policy if exists "a player reads their own scores" on public.scores;
create policy "a player reads their own scores"
  on public.scores for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "a player records their own scores" on public.scores;
create policy "a player records their own scores"
  on public.scores for insert
  to authenticated
  with check (auth.uid() = user_id);

-- A profile row has to exist the moment a player signs in, or the very
-- first score has nothing to attach to. Creating it in a trigger rather
-- than from the client means it cannot be skipped or raced.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name',
      split_part(new.email, '@', 1)
    ),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Keep best_score in step with the recorded games. Doing it in the database
-- means a client cannot claim a best score it never played, and a lost or
-- retried request cannot lower a score that already stands.
create or replace function public.sync_best_score()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
     set best_score = greatest(best_score, new.score),
         updated_at = now()
   where id = new.user_id;
  return new;
end;
$$;

drop trigger if exists on_score_recorded on public.scores;
create trigger on_score_recorded
  after insert on public.scores
  for each row execute function public.sync_best_score();
