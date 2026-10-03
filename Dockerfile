# ==========================================================
# AeroSense Multi-Service Container Dockerfile
# ==========================================================

FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /app

# Install system runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy and install python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code
COPY . .

# Ensure data and models directories exist
RUN mkdir -p data/raw data/interim data/processed data/external models logs reports

# Expose port: 8000 for FastAPI REST backend
EXPOSE 8000

# Default launch command: starts FastAPI REST API
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
