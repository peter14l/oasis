-- Enable necessary extensions
create extension if not exists "uuid-ossp" with schema extensions;
create extension if not exists "pgcrypto" with schema extensions;

-- Set up custom types
create type user_role as enum ('user', 'moderator', 'admin');
create type post_type as enum ('text', 'image', 'video', 'link', 'poll');
create type reaction_type as enum ('like', 'love', 'laugh', 'sad', 'angry');
create type notification_type as enum (
  'new_follower',
  'post_like',
  'post_comment',
  'comment_reply',
  'post_mention',
  'comment_mention',
  'community_invite',
  'moderation_action'
);

-- Create tables
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  username text unique not null,
  full_name text,
  bio text,
  avatar_url text,
  website text,
  location text,
  is_private boolean default false,
  role user_role default 'user'::user_role,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  constraint username_length check (char_length(username) >= 3 and char_length(username) <= 30),
  constraint username_format check (username ~* '^[a-zA-Z0-9_]+$')
);

create table if not exists public.communities (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  slug text unique not null,
  description text,
  avatar_url text,
  banner_url text,
  is_private boolean default false,
  is_restricted boolean default false,
  creator_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  constraint name_length check (char_length(name) >= 3 and char_length(name) <= 100),
  constraint slug_format check (slug ~* '^[a-z0-9-]+$')
);

create table if not exists public.community_members (
  id uuid default uuid_generate_v4() primary key,
  community_id uuid references public.communities(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  role user_role default 'user'::user_role,
  joined_at timestamptz default now() not null,
  unique(community_id, user_id)
);

create table if not exists public.posts (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  community_id uuid references public.communities(id) on delete set null,
  parent_id uuid references public.posts(id) on delete cascade,
  title text,
  content text,
  post_type post_type not null default 'text',
  media_urls text[],
  poll_options jsonb,
  poll_ends_at timestamptz,
  is_nsfw boolean default false,
  is_locked boolean default false,
  is_archived boolean default false,
  is_pinned boolean default false,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  constraint content_or_media_or_poll check (
    (content is not null and content != '') or
    (array_length(media_urls, 1) > 0) or
    (poll_options is not null)
  )
);

create table if not exists public.comments (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  post_id uuid references public.posts(id) on delete cascade not null,
  parent_id uuid references public.comments(id) on delete cascade,
  content text not null,
  is_deleted boolean default false,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create table if not exists public.reactions (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  post_id uuid references public.posts(id) on delete cascade,
  comment_id uuid references public.comments(id) on delete cascade,
  reaction_type reaction_type not null,
  created_at timestamptz default now() not null,
  unique(user_id, post_id, comment_id, reaction_type),
  constraint reaction_target check (
    (post_id is not null)::integer + (comment_id is not null)::integer = 1
  )
);

create table if not exists public.conversations (
  id uuid default uuid_generate_v4() primary key,
  is_group boolean default false,
  name text,
  avatar_url text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  constraint group_name_check check (
    (is_group = true and name is not null) or 
    (is_group = false and name is null)
  )
);

create table if not exists public.conversation_participants (
  id uuid default uuid_generate_v4() primary key,
  conversation_id uuid references public.conversations(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  is_admin boolean default false,
  joined_at timestamptz default now() not null,
  left_at timestamptz,
  unique(conversation_id, user_id)
);

create table if not exists public.messages (
  id uuid default uuid_generate_v4() primary key,
  conversation_id uuid references public.conversations(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete set null,
  content text not null,
  media_urls text[],
  is_edited boolean default false,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  constraint message_content check (
    (content is not null and content != '') or
    (array_length(media_urls, 1) > 0)
  )
);

create table if not exists public.message_reads (
  id uuid default uuid_generate_v4() primary key,
  message_id uuid references public.messages(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  read_at timestamptz default now() not null,
  unique(message_id, user_id)
);

create table if not exists public.notifications (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  from_user_id uuid references public.profiles(id) on delete cascade,
  notification_type notification_type not null,
  post_id uuid references public.posts(id) on delete cascade,
  comment_id uuid references public.comments(id) on delete cascade,
  community_id uuid references public.communities(id) on delete cascade,
  is_read boolean default false,
  created_at timestamptz default now() not null
);

-- Create indexes for better query performance
create index if not exists idx_posts_user_id on public.posts(user_id);
create index if not exists idx_posts_community_id on public.posts(community_id);
create index if not exists idx_comments_post_id on public.comments(post_id);
create index if not exists idx_comments_user_id on public.comments(user_id);
create index if not exists idx_reactions_user_id on public.reactions(user_id);
create index if not exists idx_reactions_post_id on public.reactions(post_id);
create index if not exists idx_reactions_comment_id on public.reactions(comment_id);
create index if not exists idx_messages_conversation_id on public.messages(conversation_id);
create index if not exists idx_notifications_user_id on public.notifications(user_id);

-- Set up Row Level Security (RLS)
alter table public.profiles enable row level security;
alter table public.communities enable row level security;
alter table public.community_members enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;
alter table public.reactions enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;
alter table public.message_reads enable row level security;
alter table public.notifications enable row level security;

-- Create RLS policies
-- Profiles policies
create policy "Public profiles are viewable by everyone."
  on public.profiles for select
  using ( true );

create policy "Users can update their own profile."
  on public.profiles for update
  using ( auth.uid() = id );

-- Communities policies
create policy "Communities are viewable by everyone."
  on public.communities for select
  using ( true );

create policy "Authenticated users can create communities"
  on public.communities for insert
  with check ( auth.role() = 'authenticated' );

create policy "Community creators can update their communities"
  on public.communities for update
  using ( auth.uid() = creator_id );

-- Posts policies
create policy "Public posts are viewable by everyone."
  on public.posts for select
  using ( true );

create policy "Users can create posts"
  on public.posts for insert
  with check ( auth.uid() = user_id );

create policy "Users can update their own posts"
  on public.posts for update
  using ( auth.uid() = user_id );

create policy "Users can delete their own posts"
  on public.posts for delete
  using ( auth.uid() = user_id );

-- Comments policies (similar structure to posts)
-- Reactions policies (users can create/delete their own reactions)
-- Messages policies (users can only read messages from conversations they're in)
-- Notifications policies (users can only read their own notifications)

-- Create storage buckets
insert into storage.buckets (id, name, public) 
values 
  ('profile_pictures', 'profile-pictures', true),
  ('post_media', 'post-media', true),
  ('community_media', 'community-media', true)
on conflict (id) do nothing;

-- Set up storage policies
create policy "Profile pictures are publicly accessible"
  on storage.objects for select
  using ( bucket_id = 'profile_pictures' );

create policy "Users can upload their own profile picture"
  on storage.objects for insert
  with check (
    bucket_id = 'profile_pictures' and
    auth.role() = 'authenticated' and
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Create triggers for updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger handle_profiles_updated_at before update on public.profiles
  for each row execute procedure public.handle_updated_at();

create trigger handle_communities_updated_at before update on public.communities
  for each row execute procedure public.handle_updated_at();

create trigger handle_posts_updated_at before update on public.posts
  for each row execute procedure public.handle_updated_at();

create trigger handle_comments_updated_at before update on public.comments
  for each row execute procedure public.handle_updated_at();

create trigger handle_messages_updated_at before update on public.messages
  for each row execute procedure public.handle_updated_at();

-- Create a function to handle new user signups
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, full_name, avatar_url)
  values (
    new.id,
    new.raw_user_meta_data->>'username',
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do update set
    username = excluded.username,
    full_name = excluded.full_name,
    avatar_url = excluded.avatar_url;
  return new;
end;
$$ language plpgsql security definer;

-- Trigger the function every time a user is created
create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Create a function to delete user data when a user is deleted
create or replace function public.handle_user_deleted()
returns trigger as $$
begin
  -- Delete user's data from all tables
  delete from public.profiles where id = old.id;
  -- Note: Other tables with foreign keys will be handled by on delete cascade
  return old;
end;
$$ language plpgsql security definer;

-- Trigger the function before a user is deleted
create or replace trigger before_user_deleted
  before delete on auth.users
  for each row execute procedure public.handle_user_deleted();

-- Create a function to get user feed
create or replace function public.get_user_feed(p_user_id uuid, page int default 1, page_size int default 20)
returns table (
  id uuid,
  user_id uuid,
  community_id uuid,
  title text,
  content text,
  post_type post_type,
  media_urls text[],
  created_at timestamptz,
  username text,
  full_name text,
  avatar_url text,
  community_name text,
  community_avatar_url text,
  like_count bigint,
  comment_count bigint,
  has_liked boolean,
  has_saved boolean
) as $$
begin
  return query
  with user_communities as (
    select community_id 
    from public.community_members 
    where user_id = p_user_id
  )
  select 
    p.id,
    p.user_id,
    p.community_id,
    p.title,
    p.content,
    p.post_type,
    p.media_urls,
    p.created_at,
    pr.username,
    pr.full_name,
    pr.avatar_url,
    c.name as community_name,
    c.avatar_url as community_avatar_url,
    (select count(*) from public.reactions r where r.post_id = p.id) as like_count,
    (select count(*) from public.comments co where co.post_id = p.id) as comment_count,
    exists (select 1 from public.reactions r where r.post_id = p.id and r.user_id = p_user_id) as has_liked,
    false as has_saved -- Implement saved posts logic separately
  from public.posts p
  join public.profiles pr on p.user_id = pr.id
  left join public.communities c on p.community_id = c.id
  where 
    p.community_id is null or
    p.community_id in (select community_id from user_communities) or
    p.user_id = p_user_id
  order by p.created_at desc
  limit $3 offset (($2 - 1) * $3);
end;
$$ language plpgsql stable security definer;

-- Create a function to get user notifications
create or replace function public.get_user_notifications(p_user_id uuid, p_limit int default 20, p_offset int default 0)
returns table (
  id uuid,
  notification_type notification_type,
  is_read boolean,
  created_at timestamptz,
  from_user_id uuid,
  from_username text,
  from_avatar_url text,
  post_id uuid,
  comment_id uuid,
  community_id uuid,
  content_preview text
) as $$
begin
  return query
  select 
    n.id,
    n.notification_type,
    n.is_read,
    n.created_at,
    n.from_user_id,
    fu.username as from_username,
    fu.avatar_url as from_avatar_url,
    n.post_id,
    n.comment_id,
    n.community_id,
    case 
      when n.post_id is not null then (select left(p.content, 100) from public.posts p where p.id = n.post_id)
      when n.comment_id is not null then (select left(c.content, 100) from public.comments c where c.id = n.comment_id)
      else null
    end as content_preview
  from public.notifications n
  left join public.profiles fu on n.from_user_id = fu.id
  where n.user_id = p_user_id
  order by n.created_at desc
  limit p_limit offset p_offset;
end;
$$ language plpgsql stable security definer;
