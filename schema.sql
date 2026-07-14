-- ============================================================
--  Counselors for Change — Strategic Planning Feedback
--  Supabase schema. Paste this whole file into:
--    Supabase dashboard -> SQL Editor -> New query -> Run
--  Safe to re-run: uses "if not exists" / "drop policy if exists".
-- ============================================================

-- ---------- tables ----------

-- one row per logged free-text response (a person can log many per question)
create table if not exists public.responses (
  id          bigserial primary key,
  question_id text        not null,
  respondent  text        not null,
  body        text        not null,
  created_at  timestamptz not null default now()
);

-- one row per person per scale question (upsert on conflict)
create table if not exists public.scale_picks (
  question_id text        not null,
  respondent  text        not null,
  choice      text        not null,
  updated_at  timestamptz not null default now(),
  primary key (question_id, respondent)
);

-- one row per person (their priority ranking)
create table if not exists public.rankings (
  respondent  text        primary key,
  order_json  jsonb       not null,
  updated_at  timestamptz not null default now()
);

-- ---------- row level security ----------
alter table public.responses   enable row level security;
alter table public.scale_picks enable row level security;
alter table public.rankings    enable row level security;

-- Everyone (anon) may READ everything — the whole point is that the
-- board sees all responses together.
drop policy if exists "responses_read"   on public.responses;
drop policy if exists "scale_read"        on public.scale_picks;
drop policy if exists "rankings_read"     on public.rankings;
create policy "responses_read" on public.responses   for select using (true);
create policy "scale_read"     on public.scale_picks for select using (true);
create policy "rankings_read"  on public.rankings    for select using (true);

-- Anyone past the passphrase gate may INSERT.
drop policy if exists "responses_insert" on public.responses;
drop policy if exists "scale_insert"      on public.scale_picks;
drop policy if exists "rankings_insert"   on public.rankings;
create policy "responses_insert" on public.responses   for insert with check (true);
create policy "scale_insert"     on public.scale_picks for insert with check (true);
create policy "rankings_insert"  on public.rankings    for insert with check (true);

-- UPDATE is needed for the upserts on scale_picks and rankings.
-- (responses are append-only, so no update policy for them.)
drop policy if exists "scale_update"    on public.scale_picks;
drop policy if exists "rankings_update" on public.rankings;
create policy "scale_update"    on public.scale_picks for update using (true) with check (true);
create policy "rankings_update" on public.rankings    for update using (true) with check (true);

-- NOTE: no DELETE policy on any table, so the anon key CANNOT delete
-- rows directly through the table API. That blocks arbitrary/bulk
-- deletes from a stray client. Self-delete of a free-text response
-- goes through the tightly-scoped function below instead.

-- ---------- scoped self-delete ----------
-- Deletes a single response only when BOTH the id and the respondent
-- name match. A person removing their own card supplies their selected
-- name, so they can't remove someone else's row through the UI.
create or replace function public.delete_own_response(p_id bigint, p_respondent text)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.responses
  where id = p_id and respondent = p_respondent;
$$;

grant execute on function public.delete_own_response(bigint, text) to anon;

-- ---------- realtime ----------
-- Push live updates during the session so the screen-shared view
-- refreshes as people submit. Ignore "already member" errors on re-run.
do $$
begin
  begin execute 'alter publication supabase_realtime add table public.responses';   exception when others then null; end;
  begin execute 'alter publication supabase_realtime add table public.scale_picks';  exception when others then null; end;
  begin execute 'alter publication supabase_realtime add table public.rankings';     exception when others then null; end;
end $$;

-- ============================================================
--  To WIPE everything and reuse next year, run:
--    truncate public.responses, public.scale_picks, public.rankings;
-- ============================================================
