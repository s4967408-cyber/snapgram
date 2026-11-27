-- Run this once in your Supabase Dashboard -> SQL Editor

-- 1. Create public storage bucket for Snapgram photos, videos, reels & stories
insert into storage.buckets (id, name, public)
values ('snapgram-media', 'snapgram-media', true)
on conflict (id) do nothing;

-- Storage Policies
create policy "Public read snapgram media"
on storage.objects for select
using (bucket_id = 'snapgram-media');

create policy "Authenticated users upload snapgram media"
on storage.objects for insert
to authenticated
with check (bucket_id = 'snapgram-media');

create policy "Users delete own snapgram media"
on storage.objects for delete
to authenticated
using (bucket_id = 'snapgram-media' and auth.uid()::text = (storage.foldername(name))[1]);

-- 2. Create snapgram_media table
create table if not exists public.snapgram_media (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  username text not null,
  kind text not null check (kind in ('post', 'reel', 'story')),
  media_urls jsonb not null default '[]'::jsonb,
  media_types jsonb not null default '[]'::jsonb,
  storage_paths jsonb not null default '[]'::jsonb,
  thumbnail_url text default '',
  caption text default '',
  hashtags jsonb default '[]'::jsonb,
  tagged_users jsonb default '[]'::jsonb,
  location text default '',
  privacy text not null default 'public' check (privacy in ('public', 'private', 'followers')),
  is_featured boolean not null default false,
  likes_count integer not null default 0,
  views_count integer not null default 0,
  comments jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  expires_at timestamptz
);

alter table public.snapgram_media enable row level security;

create policy "Read public or own media"
on public.snapgram_media for select
using (privacy = 'public' or auth.uid() = user_id);

create policy "Insert own media"
on public.snapgram_media for insert
to authenticated
with check (auth.uid() = user_id);

create policy "Update own media"
on public.snapgram_media for update
to authenticated
using (auth.uid() = user_id);

create policy "Delete own media"
on public.snapgram_media for delete
to authenticated
using (auth.uid() = user_id);
