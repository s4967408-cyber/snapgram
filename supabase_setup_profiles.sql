-- Run once in Supabase -> SQL Editor to enable User Profiles, Private Accounts & Real Follow/Followers

-- 1. Add bio, category, website, and is_private to snapgram_users
alter table public.snapgram_users
  add column if not exists category text default '',
  add column if not exists bio text default '',
  add column if not exists website text default '',
  add column if not exists is_private boolean not null default false;

-- 2. Create snapgram_follows table
create table if not exists public.snapgram_follows (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid references auth.users(id) on delete cascade not null,
  follower_username text not null,
  following_id uuid references auth.users(id) on delete cascade not null,
  following_username text not null,
  status text not null default 'accepted' check (status in ('pending', 'accepted')),
  created_at timestamptz not null default now(),
  unique(follower_id, following_id)
);

alter table public.snapgram_follows enable row level security;

create policy "Anyone can read follows"
on public.snapgram_follows for select
using (true);

create policy "Authenticated users can follow"
on public.snapgram_follows for insert
to authenticated
with check (auth.uid() = follower_id);

create policy "Target user can accept follow requests"
on public.snapgram_follows for update
to authenticated
using (auth.uid() = following_id or auth.uid() = follower_id);

create policy "Users can unfollow or decline"
on public.snapgram_follows for delete
to authenticated
using (auth.uid() = follower_id or auth.uid() = following_id);

notify pgrst, 'reload schema';
