import redis
import os
import time
import psycopg2

def connect_to_db():
    """Connects to the PostgreSQL database, retrying if necessary."""
    while True:
        try:
            conn = psycopg2.connect(
                host=os.getenv("POSTGRES_HOST"),
                database=os.getenv("POSTGRES_DB"),
                user=os.getenv("POSTGRES_USER"),
                password=os.getenv("POSTGRES_PASSWORD")
            )
            print("Processor connected to PostgreSQL.")
            return conn
        except psycopg2.OperationalError as e:
            print(f"Could not connect to PostgreSQL: {e}. Retrying in 5 seconds...")
            time.sleep(5)

def main():
    """Main processing loop."""
    r = redis.Redis(host=os.getenv('REDIS_HOST', 'redis'), port=6379, decode_responses=True)
    conn = connect_to_db()
    
    print("Processor is listening for likes...")
    while True:
        try:
            # brpop is a blocking command that waits for an item to appear
            # It pops from the right, making our list a FIFO queue
            _, post_id = r.brpop('like_queue')
            
            print(f"Processing like for post: {post_id}")
            
            with conn.cursor() as cur:
                # This SQL command is IDEMPOTENT.
                # It safely inserts or updates the like count.
                cur.execute(
                    """
                    INSERT INTO likes (post_id, like_count) VALUES (%s, 1)
                    ON CONFLICT (post_id) DO UPDATE SET like_count = likes.like_count + 1;
                    """,
                    (post_id,)
                )
                conn.commit()
            
            print(f"Finished processing like for post: {post_id}")

        except Exception as e:
            print(f"Error processing: {e}")
            # In a real app, you might want to handle the error,
            # e.g., by putting the message in a "dead-letter queue".
            time.sleep(5)

if __name__ == "__main__":
    main()