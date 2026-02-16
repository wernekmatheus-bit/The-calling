
-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ==========================================
-- 1. WHITELIST TABLE (Controle de Acesso)
-- ==========================================

create table if not exists public.whitelist_customers (
  email text primary key,
  products_owned text[] not null default '{}',
  transaction_id text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- GARANTIR que a coluna transaction_id existe (caso a tabela já exista)
do $$ 
begin
  if not exists (select 1 from information_schema.columns where table_name='whitelist_customers' and column_name='transaction_id') then
    alter table public.whitelist_customers add column transaction_id text;
  end if;
end $$;

-- ENABLE RLS (Segurança)
alter table public.whitelist_customers enable row level security;

-- PERMISSÕES DE ACESSO (CRÍTICO PARA O LOGIN FUNCIONAR)
drop policy if exists "Service role only" on public.whitelist_customers;
drop policy if exists "Allow public read" on public.whitelist_customers;
drop policy if exists "Enable read access for all users" on public.whitelist_customers;

create policy "Enable read access for all users" on public.whitelist_customers
  for select
  using (true);

create index if not exists idx_whitelist_email on public.whitelist_customers(email);


-- ==========================================
-- 2. WHITELIST TRIGGER (Checagem de Segurança)
-- ==========================================

create or replace function public.check_whitelist()
returns trigger 
security definer set search_path = public
as $$
declare
  is_whitelisted boolean;
begin
  select exists(select 1 from public.whitelist_customers where lower(email) = lower(new.email))
  into is_whitelisted;

  if not is_whitelisted then
    raise exception 'Acesso Negado: Email não encontrado na Whitelist.';
  end if;

  return new;
end;
$$ language plpgsql;

drop trigger if exists on_auth_user_created_check_whitelist on auth.users;
create trigger on_auth_user_created_check_whitelist
  before insert on auth.users
  for each row execute procedure public.check_whitelist();


-- ==========================================
-- 3. PROFILES TABLE (CRITICAL FIX HERE)
-- ==========================================

create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  xp integer default 0,
  level integer default 1,
  current_streak integer default 0,
  intercessions_count integer default 0, -- Fixes Error 42703
  last_access timestamp with time zone,
  preferred_language varchar default 'en',
  updated_at timestamp with time zone,
  name text,
  avatar_url text
);

-- ADD COLUMNS IF MISSING (Run this block to fix existing tables)
do $$ 
begin
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='bible_state') then
    alter table public.profiles add column bible_state jsonb default '{}'::jsonb;
  end if;
  -- CRITICAL FIX FOR MEDALS ERROR
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='intercessions_count') then
    alter table public.profiles add column intercessions_count integer default 0;
  end if;
end $$;

alter table public.profiles enable row level security;

drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);
  
drop policy if exists "Users can view all profiles" on public.profiles;
create policy "Users can view all profiles" on public.profiles for select using (true);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);


-- ==========================================
-- 4. PROFILE CREATION TRIGGER
-- ==========================================

create or replace function public.handle_new_user()
returns trigger 
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, preferred_language, name)
  values (new.id, 'en', split_part(new.email, '@', 1));
  return new;
end;
$$ language plpgsql;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- ==========================================
-- 5. CONTENT TABLES
-- ==========================================

create table if not exists public.daily_checklist_logs (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) not null,
  log_date date default current_date,
  tasks_completed jsonb array default array[]::jsonb[],
  created_at timestamp with time zone default now()
);
alter table public.daily_checklist_logs enable row level security;

drop policy if exists "Users manage own logs" on public.daily_checklist_logs;
create policy "Users manage own logs" on public.daily_checklist_logs for all using (auth.uid() = user_id);


create table if not exists public.prayer_requests (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) not null,
  content text not null,
  intercessors_count integer default 0,
  is_anonymous boolean default false,
  created_at timestamp with time zone default now()
);

do $$ 
begin
  if not exists (select 1 from information_schema.columns where table_name='prayer_requests' and column_name='is_anonymous') then
    alter table public.prayer_requests add column is_anonymous boolean default false;
  end if;
end $$;

alter table public.prayer_requests enable row level security;

drop policy if exists "Users view prayers" on public.prayer_requests;
create policy "Users view prayers" on public.prayer_requests for select using (true);

drop policy if exists "Users create prayers" on public.prayer_requests;
create policy "Users create prayers" on public.prayer_requests for insert with check (auth.uid() = user_id);


create table if not exists public.prayer_intercessions (
  prayer_id uuid references public.prayer_requests(id) not null,
  intercessor_id uuid references public.profiles(id) not null,
  created_at timestamp with time zone default now(),
  primary key (prayer_id, intercessor_id)
);
alter table public.prayer_intercessions enable row level security;

drop policy if exists "Users view intercessions" on public.prayer_intercessions;
create policy "Users view intercessions" on public.prayer_intercessions for select using (true);

drop policy if exists "Users create intercessions" on public.prayer_intercessions;
create policy "Users create intercessions" on public.prayer_intercessions for insert with check (auth.uid() = intercessor_id);

-- ==========================================
-- 5a. TRIGGER: Update Intercessions Count
-- ==========================================

create or replace function public.update_intercessions_count()
returns trigger 
security definer set search_path = public
as $$
begin
  if (TG_OP = 'INSERT') then
    update public.profiles 
    set intercessions_count = intercessions_count + 1 
    where id = new.intercessor_id;
    
    update public.prayer_requests
    set intercessors_count = intercessors_count + 1
    where id = new.prayer_id;
  elsif (TG_OP = 'DELETE') then
    update public.profiles 
    set intercessions_count = intercessions_count - 1 
    where id = old.intercessor_id;
    
    update public.prayer_requests
    set intercessors_count = intercessors_count - 1
    where id = old.prayer_id;
  end if;
  return null;
end;
$$ language plpgsql;

drop trigger if exists on_intercession_change on public.prayer_intercessions;
create trigger on_intercession_change
  after insert or delete on public.prayer_intercessions
  for each row execute procedure public.update_intercessions_count();


-- ==========================================
-- 6. FRIENDSHIPS & SOCIAL
-- ==========================================

create table if not exists public.friendships (
  id uuid default uuid_generate_v4() primary key,
  user_id_1 uuid references public.profiles(id) not null,
  user_id_2 uuid references public.profiles(id) not null,
  status text check (status in ('pending', 'accepted', 'rejected')) default 'pending',
  created_at timestamp with time zone default now(),
  constraint unique_friendship unique (user_id_1, user_id_2)
);

alter table public.friendships enable row level security;

drop policy if exists "View own friendships" on public.friendships;
create policy "View own friendships" on public.friendships 
  for select using (auth.uid() = user_id_1 OR auth.uid() = user_id_2);

drop policy if exists "Create friend request" on public.friendships;
create policy "Create friend request" on public.friendships 
  for insert with check (auth.uid() = user_id_1);

drop policy if exists "Update friendship" on public.friendships;
create policy "Update friendship" on public.friendships 
  for update using (auth.uid() = user_id_2);

-- ==========================================
-- 7. RPC: Leaderboard
-- ==========================================

-- FIX: Drop function first to allow return type change (Fixes Error 42P13)
drop function if exists public.get_top_intercessors(int);

create or replace function public.get_top_intercessors(limit_count int)
returns table (
  intercessor_id uuid,
  count integer, -- Changed to integer to match column type
  name text,
  avatar_url text
) 
language plpgsql security definer
as $$
begin
  -- Optimized to use the new counter column
  return query
  select 
    id as intercessor_id,
    intercessions_count as count,
    profiles.name,
    profiles.avatar_url
  from public.profiles
  order by intercessions_count desc
  limit limit_count;
end;
$$;

-- ==========================================
-- 8. DADOS DE TESTE (Seed)
-- ==========================================

insert into public.whitelist_customers (email, transaction_id, products_owned)
values 
  ('test@example.com', 'trans_12345_demo', '{"angel_mastery"}'),
  ('angel@example.com', 'trans_99999_founder', '{"founder_access"}')
on conflict (email) do update 
set transaction_id = excluded.transaction_id;
