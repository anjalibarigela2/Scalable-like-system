CREATE TABLE IF NOT EXISTS likes (
    --id SERIAL PRIMARY KEY,
    post_id TEXT PRIMARY KEY,
    like_count  INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Optional: create a table for posts
CREATE TABLE IF NOT EXISTS posts (
    id SERIAL PRIMARY KEY,
    title TEXT
);

-- Insert demo posts (if not already present)
INSERT INTO posts (id, title) VALUES (1, 'First Post'), (2, 'Second Post'), (3, 'Third Post');
