-- Create profiles table (if not exists)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
  username TEXT UNIQUE,
  avatar_url TEXT,
  updated_at TIMESTAMP WITH TIME ZONE
);

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create videos table
CREATE TABLE IF NOT EXISTS public.videos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  video_url TEXT NOT NULL,
  description TEXT,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  likes_count INTEGER DEFAULT 0 NOT NULL,
  comments_count INTEGER DEFAULT 0 NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on videos
ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;

-- Create video_likes table
CREATE TABLE IF NOT EXISTS public.video_likes (
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  video_id UUID REFERENCES public.videos(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (user_id, video_id)
);

-- Enable RLS on video_likes
ALTER TABLE public.video_likes ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Allow public read access to profiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Allow public read access to videos" ON public.videos FOR SELECT USING (true);
CREATE POLICY "Allow public read access to video_likes" ON public.video_likes FOR SELECT USING (true);

-- Allow authenticated users to perform actions
CREATE POLICY "Allow individual insert/update to profiles" ON public.profiles FOR ALL USING (auth.uid() = id);
CREATE POLICY "Allow authenticated users to insert videos" ON public.videos FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Allow individual delete for owned videos" ON public.videos FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Allow authenticated users to toggle likes" ON public.video_likes FOR ALL USING (auth.uid() = user_id);

-- RPC for atomic toggle video like
CREATE OR REPLACE FUNCTION public.toggle_video_like(video_id_param UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id UUID;
  liked BOOLEAN;
BEGIN
  -- Get the current authenticated user's ID
  current_user_id := auth.uid();
  
  IF current_user_id IS NULL THEN
    -- Fallback to guest UUID
    current_user_id := '00000000-0000-0000-0000-000000000000';
    -- Ensure the guest profile exists
    INSERT INTO public.profiles (id, username)
    VALUES (current_user_id, 'cold_guest')
    ON CONFLICT (id) DO NOTHING;
  END IF;

  -- Check if already liked
  SELECT EXISTS (
    SELECT 1 FROM public.video_likes
    WHERE user_id = current_user_id AND video_id = video_id_param
  ) INTO liked;

  IF liked THEN
    -- Unlike: Delete the row and decrement likes count
    DELETE FROM public.video_likes
    WHERE user_id = current_user_id AND video_id = video_id_param;

    UPDATE public.videos
    SET likes_count = GREATEST(likes_count - 1, 0)
    WHERE id = video_id_param;
    
    RETURN FALSE;
  ELSE
    -- Like: Insert the row and increment likes count
    INSERT INTO public.video_likes (user_id, video_id)
    VALUES (current_user_id, video_id_param);

    UPDATE public.videos
    SET likes_count = likes_count + 1
    WHERE id = video_id_param;
    
    RETURN TRUE;
  END IF;
END;
$$;
