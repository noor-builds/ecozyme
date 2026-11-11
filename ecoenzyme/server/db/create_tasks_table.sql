-- Run in Supabase SQL Editor. Safe to re-run on the existing tasks table.

create table if not exists public.farmer_profiles (
  farmer_id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  mobile text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.farmer_crops (
  id bigint generated always as identity primary key,
  farmer_id uuid not null references auth.users(id) on delete cascade,
  crop_type text not null,
  soil_type text not null,
  location text not null,
  season text not null,
  farmer_experience text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (farmer_id, crop_type, location)
);

create table if not exists public.chat_history (
  id bigint generated always as identity primary key,
  farmer_id uuid not null references auth.users(id) on delete cascade,
  user_message text not null,
  assistant_message text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.tasks (
  id bigint generated always as identity primary key,
  farmer_id uuid references auth.users(id) on delete cascade,
  title text not null,
  description text,
  frequency text,
  crop_stage text,
  bioenzyme_ratio text,
  application_method text,
  benefits jsonb,
  precautions jsonb,
  meta jsonb not null default '{}'::jsonb,
  is_completed boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.farmer_profiles
  add column if not exists full_name text,
  add column if not exists email text,
  add column if not exists mobile text,
  add column if not exists updated_at timestamptz not null default now();

alter table public.farmer_crops
  add column if not exists soil_type text not null default '',
  add column if not exists location text not null default '',
  add column if not exists season text not null default '',
  add column if not exists farmer_experience text not null default '',
  add column if not exists updated_at timestamptz not null default now();

alter table public.tasks
  add column if not exists is_completed boolean not null default false,
  add column if not exists completed_at timestamptz,
  add column if not exists meta jsonb not null default '{}'::jsonb,
  add column if not exists created_at timestamptz not null default now();

create index if not exists idx_tasks_farmer_created
  on public.tasks (farmer_id, created_at desc);

create index if not exists idx_farmer_crops_farmer
  on public.farmer_crops (farmer_id, updated_at desc);

create index if not exists idx_chat_history_farmer_created
  on public.chat_history (farmer_id, created_at desc);

create or replace function public.sync_farmer_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.farmer_profiles (farmer_id, full_name, email, mobile)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', new.raw_user_meta_data ->> 'full_name'),
    new.email,
    new.raw_user_meta_data ->> 'mobile'
  )
  on conflict (farmer_id) do update set
    full_name = excluded.full_name,
    email = excluded.email,
    mobile = excluded.mobile,
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_profile_sync on auth.users;
create trigger on_auth_user_profile_sync
  after insert or update of email, raw_user_meta_data on auth.users
  for each row execute function public.sync_farmer_profile();

insert into public.farmer_profiles (farmer_id, full_name, email, mobile)
select
  id,
  coalesce(raw_user_meta_data ->> 'name', raw_user_meta_data ->> 'full_name'),
  email,
  raw_user_meta_data ->> 'mobile'
from auth.users
on conflict (farmer_id) do update set
  full_name = excluded.full_name,
  email = excluded.email,
  mobile = excluded.mobile,
  updated_at = now();

alter table public.farmer_profiles enable row level security;
alter table public.farmer_crops enable row level security;
alter table public.chat_history enable row level security;
alter table public.tasks enable row level security;

grant select, insert, update on public.farmer_profiles to authenticated;
grant select, insert, update, delete on public.farmer_crops to authenticated;
grant select, insert on public.chat_history to authenticated;
grant select, insert, update, delete on public.tasks to authenticated;
grant usage, select on sequence
  public.farmer_crops_id_seq,
  public.chat_history_id_seq,
  public.tasks_id_seq
to authenticated;

drop policy if exists "Users can view their own profile" on public.farmer_profiles;
create policy "Users can view their own profile"
  on public.farmer_profiles for select to authenticated
  using (farmer_id = auth.uid());

drop policy if exists "Users can update their own profile" on public.farmer_profiles;
create policy "Users can update their own profile"
  on public.farmer_profiles for update to authenticated
  using (farmer_id = auth.uid())
  with check (farmer_id = auth.uid());

drop policy if exists "Users can view their own crop profiles" on public.farmer_crops;
create policy "Users can view their own crop profiles"
  on public.farmer_crops for select to authenticated
  using (farmer_id = auth.uid());

drop policy if exists "Users can create their own crop profiles" on public.farmer_crops;
create policy "Users can create their own crop profiles"
  on public.farmer_crops for insert to authenticated
  with check (farmer_id = auth.uid());

drop policy if exists "Users can update their own crop profiles" on public.farmer_crops;
create policy "Users can update their own crop profiles"
  on public.farmer_crops for update to authenticated
  using (farmer_id = auth.uid())
  with check (farmer_id = auth.uid());

drop policy if exists "Users can delete their own crop profiles" on public.farmer_crops;
create policy "Users can delete their own crop profiles"
  on public.farmer_crops for delete to authenticated
  using (farmer_id = auth.uid());

drop policy if exists "Users can view their own chat history" on public.chat_history;
create policy "Users can view their own chat history"
  on public.chat_history for select to authenticated
  using (farmer_id = auth.uid());

drop policy if exists "Users can create their own chat history" on public.chat_history;
create policy "Users can create their own chat history"
  on public.chat_history for insert to authenticated
  with check (farmer_id = auth.uid());

drop policy if exists "Users can view their own tasks" on public.tasks;
create policy "Users can view their own tasks"
  on public.tasks for select to authenticated
  using (farmer_id = auth.uid());

drop policy if exists "Users can create their own tasks" on public.tasks;
create policy "Users can create their own tasks"
  on public.tasks for insert to authenticated
  with check (farmer_id = auth.uid());

drop policy if exists "Users can update their own tasks" on public.tasks;
create policy "Users can update their own tasks"
  on public.tasks for update to authenticated
  using (farmer_id = auth.uid())
  with check (farmer_id = auth.uid());

drop policy if exists "Users can delete their own tasks" on public.tasks;
create policy "Users can delete their own tasks"
  on public.tasks for delete to authenticated
  using (farmer_id = auth.uid());
