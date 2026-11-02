-- Run this script in Supabase Dashboard > SQL Editor.
-- This simple shared-access setup lets anyone with the public anon key read and
-- change the shared application data. Do not use it for confidential data.

create table if not exists public.railway_app_state (
    id integer primary key check (id = 1),
    state jsonb not null default jsonb_build_object(
        'plans', '{}'::jsonb,
        'preparations', '{}'::jsonb,
        'engineerEvals', '{}'::jsonb,
        'managerApprovals', '{}'::jsonb
    ),
    updated_at timestamptz not null default now()
);

alter table public.railway_app_state enable row level security;

grant select, insert, update on table public.railway_app_state to anon;

drop policy if exists "Public can read railway app state" on public.railway_app_state;
create policy "Public can read railway app state"
    on public.railway_app_state
    for select
    to anon
    using (id = 1);

drop policy if exists "Public can insert railway app state" on public.railway_app_state;
create policy "Public can insert railway app state"
    on public.railway_app_state
    for insert
    to anon
    with check (id = 1);

drop policy if exists "Public can update railway app state" on public.railway_app_state;
create policy "Public can update railway app state"
    on public.railway_app_state
    for update
    to anon
    using (id = 1)
    with check (id = 1);
