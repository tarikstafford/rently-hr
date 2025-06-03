FROM python:3.10-slim-bullseye

ENV PYTHONUNBUFFERED=1
ENV PORT=8000
ENV PYTHONDONTWRITEBYTECODE=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcairo2-dev \
    gcc \
    gettext \
    procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app/

# Copy requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

# Make entrypoint executable
RUN chmod +x /app/entrypoint.sh

EXPOSE ${PORT}

# Use entrypoint script instead of direct gunicorn command
ENTRYPOINT ["/app/entrypoint.sh"]
