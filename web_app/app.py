from flask import Flask
import redis
import os
import random

app = Flask(__name__)
# Connect to our Redis container using the hostname 'redis'
# Docker Compose will handle the networking.
r = redis.Redis(host=os.getenv('REDIS_HOST', 'redis'), port=6379, decode_responses=True)

@app.route('/like', methods=['POST'])
def like():
    """Receives a like and pushes it to a Redis queue."""
    try:
        # For the load test, we'll just use a few post IDs
        post_id = random.choice(['post:1', 'post:2', 'post:3'])
        
        # lpush adds the item to the left of the list (making it a queue)
        r.lpush('like_queue', post_id)
        
        return f"Queued like for {post_id}!", 202
    except Exception as e:
        return str(e), 500

# Add a health check endpoint
@app.route('/health', methods=['GET'])
def health_check():
    return "OK", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)