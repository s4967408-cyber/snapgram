-- Run once in Supabase -> SQL Editor to save Music tracks on Posts, Reels & Stories
alter table public.snapgram_media
  add column if not exists music_title text default '',
  add column if not exists music_artist text default '',
  add column if not exists music_url text default '',
  add column if not exists music_source text default '';

notify pgrst, 'reload schema';
