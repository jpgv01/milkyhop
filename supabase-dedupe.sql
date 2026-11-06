-- Milky Hop: one entry per name (run once in Supabase > SQL Editor > New query > Run). Safe to run again.

-- 1) Delete repeated names now, keeping each name's best score (ANA and Ana count as the same name).
delete from public.scores s
using (
  select id, row_number() over (partition by upper(name) order by score desc, id asc) as rn
  from public.scores
) d
where s.id = d.id and d.rn > 1;

-- 2) From now on, a name only keeps its best score:
--    a lower or equal score for an existing name is not saved, and a higher one replaces the old entry.
create or replace function public.scores_one_per_name() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from public.scores where upper(name) = upper(new.name) and score >= new.score) then
    return null;   -- keep the existing, better score
  end if;
  delete from public.scores where upper(name) = upper(new.name);
  return new;
end $$;
drop trigger if exists scores_one_per_name on public.scores;
create trigger scores_one_per_name before insert on public.scores
  for each row execute function public.scores_one_per_name();

-- Check: this should return no rows.
select upper(name) as name, count(*) from public.scores group by 1 having count(*) > 1;
