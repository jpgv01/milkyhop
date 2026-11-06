-- Milky Hop: leaderboard protection upgrade (run once in Supabase > SQL Editor > New query > Run)
-- Safe to run more than once.

-- 1) Store how long each run lasted, so impossible scores can be rejected.
alter table public.scores add column if not exists run_seconds numeric;

-- 2) Reject scores that are too high for the run length.
--    A perfect player earns about 1.5 points per second; this allows 2.5 per second plus 5.
--    NOT VALID keeps the scores already on the board.
alter table public.scores drop constraint if exists scores_plausible;
alter table public.scores add constraint scores_plausible
  check (run_seconds is not null and run_seconds between 1 and 7200 and score <= run_seconds * 2.5 + 5) not valid;

-- 3) Slow down spam: at most 20 new scores per minute across everyone.
create or replace function public.scores_rate_limit() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from public.scores where created_at > now() - interval '1 minute') >= 20 then
    raise exception 'too many scores, try again in a minute';
  end if;
  return new;
end $$;
drop trigger if exists scores_rate_limit on public.scores;
create trigger scores_rate_limit before insert on public.scores
  for each row execute function public.scores_rate_limit();

-- 4) Faster weekly board.
create index if not exists scores_created_at_idx on public.scores (created_at);

-- To remove a bad entry: Table Editor > scores > select the row > Delete.
