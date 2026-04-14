# ─────────────────────────────────────────────────────────────
# SalamaRecover Backend — Dockerfile
#
# Build:  docker build -t salamarecover-api ./backend
# Run:    docker run -p 8000:8000 --env-file backend/.env salamarecover-api
# ─────────────────────────────────────────────────────────────

FROM python:3.11-slim

# Prevents Python from writing .pyc files and buffers stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies needed by some Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies first (cached layer — only rebuilds when requirements change)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose the port uvicorn will listen on
EXPOSE 8000

# Start the server
# $PORT is set by Render automatically; falls back to 8000 locally
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
