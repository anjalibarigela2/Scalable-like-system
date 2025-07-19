# This file is also nearly identical to the others
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
# Use CMD so it can be easily overridden by docker-compose run
CMD ["python", "load_tester.py"]