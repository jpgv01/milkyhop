-- Milky Hop shared Top 10: paste this whole script into Supabase > SQL Editor > New query, then click Run.

create table if not exists public.scores (
  id bigint generated always as identity primary key,
  name text not null check (name ~ '^[A-ZÁÉÍÓÚÜÑ]{2,10}$'),
  score integer not null check (score between 1 and 500),
  created_at timestamptz not null default now()
);

alter table public.scores enable row level security;

-- Everyone can read the scores and add a new one. Nobody can edit or delete except you (from the dashboard).
drop policy if exists "Anyone can read scores" on public.scores;
create policy "Anyone can read scores" on public.scores
  for select to anon, authenticated using (true);

drop policy if exists "Anyone can add a score" on public.scores;
create policy "Anyone can add a score" on public.scores
  for insert to anon, authenticated with check (true);

grant select, insert on public.scores to anon, authenticated;
