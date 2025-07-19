import requests
import time
import os
import sys
from concurrent.futures import ThreadPoolExecutor

# The URL will be http://web:5000 because we are inside the Docker network
URL = os.getenv("TARGET_URL", "http://web:5000/like")

# Get request count from environment variable, default to 1000
try:
    REQUEST_COUNT = int(os.getenv("REQUEST_COUNT", 1000))
except (ValueError, TypeError):
    print("Invalid number provided for REQUEST_COUNT. Defaulting to 1000.")
    REQUEST_COUNT = 1000

CONCURRENT_WORKERS = 50

def send_like(n):
    """Sends a single POST request to the /like endpoint."""
    try:
        response = requests.post(URL, timeout=10)
        if response.status_code == 202:
            print(f"Request {n+1}/{REQUEST_COUNT} sent successfully.")
        else:
            print(f"Request {n+1}/{REQUEST_COUNT} failed with status: {response.status_code}")
    except requests.exceptions.RequestException as e:
        print(f"Request {n+1}/{REQUEST_COUNT} failed: {e}")

def main():
    """Runs the load test."""
    print(f"Starting load test: {REQUEST_COUNT} requests with {CONCURRENT_WORKERS} workers.")
    print(f"Targeting URL: {URL}")
    
    # Give other services a moment to start up fully
    time.sleep(5) 
    
    start_time = time.time()
    
    with ThreadPoolExecutor(max_workers=CONCURRENT_WORKERS) as executor:
        executor.map(send_like, range(REQUEST_COUNT))
        
    end_time = time.time()
    print(f"\nLoad test finished in {end_time - start_time:.2f} seconds.")

if __name__ == "__main__":
    main()