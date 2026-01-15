-- QuoteVault Database Setup Script
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Quotes table
CREATE TABLE IF NOT EXISTS quotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    text TEXT NOT NULL,
    author TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('Motivation', 'Love', 'Success', 'Wisdom', 'Humor')),
    "isDailyQuote" BOOLEAN DEFAULT FALSE,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User favorites table
CREATE TABLE IF NOT EXISTS user_favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "userId" UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    "quoteId" UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE("userId", "quoteId")
);

-- Collections table
CREATE TABLE IF NOT EXISTS collections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "userId" UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Collection quotes junction table
CREATE TABLE IF NOT EXISTS collection_quotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "collectionId" UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    "quoteId" UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
    "addedAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE("collectionId", "quoteId")
);

-- User profiles table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "userId" UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    name TEXT,
    "avatarUrl" TEXT,
    theme TEXT DEFAULT 'default',
    "fontSize" DOUBLE PRECISION DEFAULT 16.0,
    "notificationTime" TEXT,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_quotes_category ON quotes(category);
CREATE INDEX IF NOT EXISTS idx_quotes_created_at ON quotes("createdAt");
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id ON user_favorites("userId");
CREATE INDEX IF NOT EXISTS idx_user_favorites_quote_id ON user_favorites("quoteId");
CREATE INDEX IF NOT EXISTS idx_collections_user_id ON collections("userId");
CREATE INDEX IF NOT EXISTS idx_collection_quotes_collection_id ON collection_quotes("collectionId");
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles("userId");

-- Enable Row Level Security (RLS)
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE collection_quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for quotes (public read, authenticated write)
CREATE POLICY "Quotes are viewable by everyone" ON quotes
    FOR SELECT USING (true);

CREATE POLICY "Quotes are insertable by authenticated users" ON quotes
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- RLS Policies for user_favorites
CREATE POLICY "Users can view their own favorites" ON user_favorites
    FOR SELECT USING (auth.uid() = "userId");

CREATE POLICY "Users can insert their own favorites" ON user_favorites
    FOR INSERT WITH CHECK (auth.uid() = "userId");

CREATE POLICY "Users can delete their own favorites" ON user_favorites
    FOR DELETE USING (auth.uid() = "userId");

-- RLS Policies for collections
CREATE POLICY "Users can view their own collections" ON collections
    FOR SELECT USING (auth.uid() = "userId");

CREATE POLICY "Users can insert their own collections" ON collections
    FOR INSERT WITH CHECK (auth.uid() = "userId");

CREATE POLICY "Users can update their own collections" ON collections
    FOR UPDATE USING (auth.uid() = "userId");

CREATE POLICY "Users can delete their own collections" ON collections
    FOR DELETE USING (auth.uid() = "userId");

-- RLS Policies for collection_quotes
CREATE POLICY "Users can view quotes in their collections" ON collection_quotes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM collections
            WHERE collections.id = collection_quotes."collectionId"
            AND collections."userId" = auth.uid()
        )
    );

CREATE POLICY "Users can add quotes to their collections" ON collection_quotes
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM collections
            WHERE collections.id = collection_quotes."collectionId"
            AND collections."userId" = auth.uid()
        )
    );

CREATE POLICY "Users can remove quotes from their collections" ON collection_quotes
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM collections
            WHERE collections.id = collection_quotes."collectionId"
            AND collections."userId" = auth.uid()
        )
    );

-- RLS Policies for profiles
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = "userId");

CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = "userId");

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = "userId");

-- Sample quotes data (100+ quotes across 5 categories)
-- You can expand this with more quotes from public APIs or datasets

INSERT INTO quotes (text, author, category) VALUES
-- Motivation (20 quotes)
('The only way to do great work is to love what you do.', 'Steve Jobs', 'Motivation'),
('Innovation distinguishes between a leader and a follower.', 'Steve Jobs', 'Motivation'),
('Life is what happens to you while you''re busy making other plans.', 'John Lennon', 'Motivation'),
('The future belongs to those who believe in the beauty of their dreams.', 'Eleanor Roosevelt', 'Motivation'),
('It is during our darkest moments that we must focus to see the light.', 'Aristotle', 'Motivation'),
('The only impossible journey is the one you never begin.', 'Tony Robbins', 'Motivation'),
('In the middle of difficulty lies opportunity.', 'Albert Einstein', 'Motivation'),
('Believe you can and you''re halfway there.', 'Theodore Roosevelt', 'Motivation'),
('You are never too old to set another goal or to dream a new dream.', 'C.S. Lewis', 'Motivation'),
('The way to get started is to quit talking and begin doing.', 'Walt Disney', 'Motivation'),
('Don''t let yesterday take up too much of today.', 'Will Rogers', 'Motivation'),
('You learn more from failure than from success.', 'Unknown', 'Motivation'),
('If you are working on something exciting that you really care about, you don''t have to be pushed. The vision pulls you.', 'Steve Jobs', 'Motivation'),
('People who are crazy enough to think they can change the world, are the ones who do.', 'Rob Siltanen', 'Motivation'),
('We may encounter many defeats but we must not be defeated.', 'Maya Angelou', 'Motivation'),
('Knowing is not enough; we must apply. Wishing is not enough; we must do.', 'Johann Wolfgang von Goethe', 'Motivation'),
('Imagine your life is perfect in every respect; what would it look like?', 'Brian Tracy', 'Motivation'),
('We generate fears while we sit. We overcome them by action.', 'Dr. Henry Link', 'Motivation'),
('Whether you think you can or you think you can''t, you''re right.', 'Henry Ford', 'Motivation'),
('Security is mostly a superstition. Life is either a daring adventure or nothing.', 'Helen Keller', 'Motivation'),

-- Love (20 quotes)
('Love is composed of a single soul inhabiting two bodies.', 'Aristotle', 'Love'),
('Being deeply loved by someone gives you strength, while loving someone deeply gives you courage.', 'Lao Tzu', 'Love'),
('Love is not about how much you say "I love you", but how much you prove that it''s true.', 'Unknown', 'Love'),
('The best thing to hold onto in life is each other.', 'Audrey Hepburn', 'Love'),
('Love recognizes no barriers. It jumps hurdles, leaps fences, penetrates walls to arrive at its destination full of hope.', 'Maya Angelou', 'Love'),
('A successful marriage requires falling in love many times, always with the same person.', 'Mignon McLaughlin', 'Love'),
('Love is when the other person''s happiness is more important than your own.', 'H. Jackson Brown Jr.', 'Love'),
('The greatest thing you''ll ever learn is just to love and be loved in return.', 'Eden Ahbez', 'Love'),
('Love is friendship that has caught fire.', 'Ann Landers', 'Love'),
('In the end, we will remember not the words of our enemies, but the silence of our friends.', 'Martin Luther King Jr.', 'Love'),
('Love is patient, love is kind. It does not envy, it does not boast, it is not proud.', '1 Corinthians 13:4', 'Love'),
('The best and most beautiful things in this world cannot be seen or even heard, but must be felt with the heart.', 'Helen Keller', 'Love'),
('Love is like the wind, you can''t see it but you can feel it.', 'Nicholas Sparks', 'Love'),
('To love and be loved is to feel the sun from both sides.', 'David Viscott', 'Love'),
('Love is not finding someone to live with. It''s finding someone you can''t live without.', 'Rafael Ortiz', 'Love'),
('The first to apologize is the bravest. The first to forgive is the strongest. The first to forget is the happiest.', 'Unknown', 'Love'),
('Love is an untamed force. When we try to control it, it destroys us. When we try to imprison it, it enslaves us.', 'Paulo Coelho', 'Love'),
('Love is the only force capable of transforming an enemy into a friend.', 'Martin Luther King Jr.', 'Love'),
('The heart wants what it wants. There''s no logic to these things.', 'Woody Allen', 'Love'),
('Love is the greatest refreshment in life.', 'Pablo Picasso', 'Love'),

-- Success (20 quotes)
('Success is not final, failure is not fatal: it is the courage to continue that counts.', 'Winston Churchill', 'Success'),
('Don''t be afraid to give up the good to go for the great.', 'John D. Rockefeller', 'Success'),
('I find that the harder I work, the more luck I seem to have.', 'Thomas Jefferson', 'Success'),
('Success is walking from failure to failure with no loss of enthusiasm.', 'Winston Churchill', 'Success'),
('The way to get started is to quit talking and begin doing.', 'Walt Disney', 'Success'),
('Don''t let the fear of losing be greater than the excitement of winning.', 'Robert Kiyosaki', 'Success'),
('If you really look closely, most overnight successes took a long time.', 'Steve Jobs', 'Success'),
('The only place where success comes before work is in the dictionary.', 'Vidal Sassoon', 'Success'),
('Success usually comes to those who are too busy to be looking for it.', 'Henry David Thoreau', 'Success'),
('The secret of success is to do the common thing uncommonly well.', 'John D. Rockefeller', 'Success'),
('I don''t know the key to success, but the key to failure is trying to please everybody.', 'Bill Cosby', 'Success'),
('Success is the sum of small efforts repeated day in and day out.', 'Robert Collier', 'Success'),
('The successful warrior is the average man with laser-like focus.', 'Bruce Lee', 'Success'),
('Try not to become a person of success, but rather try to become a person of value.', 'Albert Einstein', 'Success'),
('Success is not how high you have climbed, but how you make a positive difference to the world.', 'Roy T. Bennett', 'Success'),
('The road to success and the road to failure are almost exactly the same.', 'Colin R. Davis', 'Success'),
('Success is getting what you want, happiness is wanting what you get.', 'W.P. Kinsella', 'Success'),
('The only way to do great work is to love what you do.', 'Steve Jobs', 'Success'),
('Success is not the key to happiness. Happiness is the key to success.', 'Albert Schweitzer', 'Success'),
('I''ve failed over and over and over again in my life and that is why I succeed.', 'Michael Jordan', 'Success'),

-- Wisdom (20 quotes)
('The only true wisdom is in knowing you know nothing.', 'Socrates', 'Wisdom'),
('Wisdom is not a product of schooling but of the lifelong attempt to acquire it.', 'Albert Einstein', 'Wisdom'),
('The fool doth think he is wise, but the wise man knows himself to be a fool.', 'William Shakespeare', 'Wisdom'),
('It is not that I''m so smart, it''s just that I stay with problems longer.', 'Albert Einstein', 'Wisdom'),
('The unexamined life is not worth living.', 'Socrates', 'Wisdom'),
('Wisdom begins in wonder.', 'Socrates', 'Wisdom'),
('The only way to deal with an unfree world is to become so absolutely free that your very existence is an act of rebellion.', 'Albert Camus', 'Wisdom'),
('The journey of a thousand miles begins with one step.', 'Lao Tzu', 'Wisdom'),
('He who knows others is wise; he who knows himself is enlightened.', 'Lao Tzu', 'Wisdom'),
('The wise find pleasure in water; the virtuous find pleasure in hills.', 'Confucius', 'Wisdom'),
('A wise man can learn more from a foolish question than a fool can learn from a wise answer.', 'Bruce Lee', 'Wisdom'),
('The older I get, the more I realize the value of privacy, of cultivating your circle and only letting certain people in.', 'Unknown', 'Wisdom'),
('Wisdom is the reward you get for a lifetime of listening when you''d have preferred to talk.', 'Doug Larson', 'Wisdom'),
('The wise man does at once what the fool does finally.', 'Niccolo Machiavelli', 'Wisdom'),
('Knowledge speaks, but wisdom listens.', 'Jimi Hendrix', 'Wisdom'),
('The invariable mark of wisdom is to see the miraculous in the common.', 'Ralph Waldo Emerson', 'Wisdom'),
('Wisdom is not wisdom when it is derived from books alone.', 'Horace', 'Wisdom'),
('The beginning of wisdom is the definition of terms.', 'Socrates', 'Wisdom'),
('Wisdom is the right use of knowledge.', 'Charles Spurgeon', 'Wisdom'),
('A wise man will make more opportunities than he finds.', 'Francis Bacon', 'Wisdom'),

-- Humor (20 quotes)
('I''m not arguing, I''m just explaining why I''m right.', 'Unknown', 'Humor'),
('I told my wife she was drawing her eyebrows too high. She looked surprised.', 'Unknown', 'Humor'),
('I''m not lazy, I''m just on energy-saving mode.', 'Unknown', 'Humor'),
('I don''t need a hairstylist, my pillow gives me a new hairstyle every morning.', 'Unknown', 'Humor'),
('I''m not procrastinating, I''m prioritizing my tasks in order of importance.', 'Unknown', 'Humor'),
('I told my computer I needed a break, and now it won''t stop sending me Kit-Kat ads.', 'Unknown', 'Humor'),
('I''m not short, I''m just concentrated awesome.', 'Unknown', 'Humor'),
('I don''t have a problem with authority. I have a problem with you telling me what to do.', 'Unknown', 'Humor'),
('I''m not arguing, I''m just passionately expressing my point of view while completely dismissing yours.', 'Unknown', 'Humor'),
('I don''t need anger management. I need people to stop making me angry.', 'Unknown', 'Humor'),
('I''m not saying I''m Wonder Woman, I''m just saying no one has ever seen me and Wonder Woman in the same room together.', 'Unknown', 'Humor'),
('I don''t need a personal trainer. My dog already makes me run around the block every morning.', 'Unknown', 'Humor'),
('I''m not a complete idiot. Some parts are missing.', 'Unknown', 'Humor'),
('I don''t need therapy. I just need everyone to do what I say.', 'Unknown', 'Humor'),
('I''m not weird, I''m limited edition.', 'Unknown', 'Humor'),
('I don''t need a GPS. My sense of direction is fine. It''s the roads that keep moving.', 'Unknown', 'Humor'),
('I''m not lazy, I''m just in energy-saving mode.', 'Unknown', 'Humor'),
('I don''t need a watch. My phone tells me what time it is, and my stomach tells me when to eat.', 'Unknown', 'Humor'),
('I''m not saying I''m Batman, but have you ever seen me and Batman in the same room?', 'Unknown', 'Humor'),
('I don''t need a personal assistant. I need a personal clone.', 'Unknown', 'Humor');

-- Create a function to update updatedAt timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updatedAt" = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updatedAt
CREATE TRIGGER update_quotes_updated_at BEFORE UPDATE ON quotes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_collections_updated_at BEFORE UPDATE ON collections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
