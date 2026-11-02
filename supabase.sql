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

create or replace function public.merge_railway_app_state(incoming_state jsonb)
returns void
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
    section_name text;
begin
    if incoming_state is null or jsonb_typeof(incoming_state) <> 'object' then
        raise exception 'incoming_state must be a JSON object';
    end if;

    foreach section_name in array array['plans', 'preparations', 'engineerEvals', 'managerApprovals']
    loop
        if incoming_state ? section_name
            and jsonb_typeof(incoming_state -> section_name) <> 'object' then
            raise exception 'incoming_state.% must be a JSON object', section_name;
        end if;
    end loop;

    insert into public.railway_app_state (id, state, updated_at)
    values (
        1,
        jsonb_build_object(
            'plans', coalesce(incoming_state -> 'plans', '{}'::jsonb),
            'preparations', coalesce(incoming_state -> 'preparations', '{}'::jsonb),
            'engineerEvals', coalesce(incoming_state -> 'engineerEvals', '{}'::jsonb),
            'managerApprovals', coalesce(incoming_state -> 'managerApprovals', '{}'::jsonb)
        ),
        now()
    )
    on conflict (id) do update
    set state = jsonb_build_object(
            'plans',
                coalesce(public.railway_app_state.state -> 'plans', '{}'::jsonb)
                || coalesce(excluded.state -> 'plans', '{}'::jsonb),
            'preparations',
                coalesce(public.railway_app_state.state -> 'preparations', '{}'::jsonb)
                || coalesce(excluded.state -> 'preparations', '{}'::jsonb),
            'engineerEvals',
                coalesce(public.railway_app_state.state -> 'engineerEvals', '{}'::jsonb)
                || coalesce(excluded.state -> 'engineerEvals', '{}'::jsonb),
            'managerApprovals',
                coalesce(public.railway_app_state.state -> 'managerApprovals', '{}'::jsonb)
                || coalesce(excluded.state -> 'managerApprovals', '{}'::jsonb)
        ),
        updated_at = now();
end;
$$;

revoke all on function public.merge_railway_app_state(jsonb) from public;
grant execute on function public.merge_railway_app_state(jsonb) to anon;
