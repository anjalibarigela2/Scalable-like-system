import sys
import http.client

try:
    conn = http.client.HTTPConnection("localhost", 5000, timeout=2)
    conn.request("GET", "/health")
    response = conn.getresponse()
    if response.status == 200:
        print("Health check passed.")
        sys.exit(0)
    else:
        print(f"Health check failed with status: {response.status}")
        sys.exit(1)
except Exception as e:
    print(f"Health check failed with exception: {e}")
    sys.exit(1)
finally:
    conn.close()