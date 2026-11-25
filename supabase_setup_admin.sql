-- Run this in Supabase Dashboard -> SQL Editor to enable Admin User Tracking, Blue Tick Verification, Blocking & Message Moderation

-- 1. Users & Login/Logout Activity Table
create table if not exists public.snapgram_users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  phone text default '',
  username text not null,
  full_name text default '',
  avatar_url text default '',
  is_verified boolean not null default false,
  is_blocked boolean not null default false,
  is_online boolean not null default false,
  last_login_at timestamptz,
  last_logout_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.snapgram_users enable row level security;

create policy "Anyone can read basic user flags"
on public.snapgram_users for select
using (true);

create policy "Users insert own profile"
on public.snapgram_users for insert
to authenticated
with check (auth.uid() = id);

create policy "Users update own login status"
on public.snapgram_users for update
to authenticated
using (auth.uid() = id or (auth.jwt() ->> 'email') = 's4967408@gmail.com');

-- Prevent non-admins from changing is_verified or is_blocked
create or replace function public.protect_admin_user_flags()
returns trigger as $$
begin
  if (auth.jwt() ->> 'email') is distinct from 's4967408@gmail.com' then
    new.is_verified := old.is_verified;
    new.is_blocked := old.is_blocked;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_protect_admin_user_flags on public.snapgram_users;
create trigger trg_protect_admin_user_flags
before update on public.snapgram_users
for each row execute function public.protect_admin_user_flags();

-- 2. Platform Messages Table (for DMs & Admin Safety Moderation)
create table if not exists public.snapgram_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid references auth.users(id) on delete cascade not null,
  sender_username text not null,
  recipient_username text not null,
  text text not null,
  created_at timestamptz not null default now()
);

alter table public.snapgram_messages enable row level security;

create policy "Users read own messages or admin reads all"
on public.snapgram_messages for select
to authenticated
using (
  auth.uid() = sender_id
  or recipient_username = (select username from public.snapgram_users where id = auth.uid() limit 1)
  or (auth.jwt() ->> 'email') = 's4967408@gmail.com'
);

create policy "Authenticated users send messages"
on public.snapgram_messages for insert
to authenticated
with check (auth.uid() = sender_id);

notify pgrst, 'reload schema';
