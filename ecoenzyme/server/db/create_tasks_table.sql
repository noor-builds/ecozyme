-- Run in Supabase SQL Editor. Safe to re-run on the existing tasks table.

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

alter table public.tasks
  add column if not exists is_completed boolean not null default false,
  add column if not exists completed_at timestamptz,
  add column if not exists meta jsonb not null default '{}'::jsonb,
  add column if not exists created_at timestamptz not null default now();

create index if not exists idx_tasks_farmer_created
  on public.tasks (farmer_id, created_at desc);

alter table public.tasks enable row level security;

grant select, insert, update, delete on public.tasks to authenticated;
grant usage, select on sequence public.tasks_id_seq to authenticated;

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
