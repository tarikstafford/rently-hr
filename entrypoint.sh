#!/bin/bash

set -e  # Exit on error

# Debug logging
echo "Environment variables:"
env | sort

echo "Starting application setup..."
echo "Using PORT: ${PORT:-8000}"
echo "Using RAILWAY_TCP_PROXY_PORT: ${RAILWAY_TCP_PROXY_PORT:-not set}"

# Check for required environment variables
if [ -z "$SECRET_KEY" ]; then
    echo "WARNING: SECRET_KEY is not set!"
fi

if [ -z "$DATABASE_URL" ]; then
    echo "WARNING: DATABASE_URL is not set!"
fi

# Function to check database connectivity
check_db() {
    python << END
import sys
import psycopg2
from urllib.parse import urlparse
import time

def wait_for_db():
    max_retries = 30
    retry_interval = 2
    
    for i in range(max_retries):
        try:
            db_url = "${DATABASE_URL}"
            if not db_url:
                print("DATABASE_URL is not set")
                sys.exit(1)
                
            result = urlparse(db_url)
            conn = psycopg2.connect(
                dbname=result.path[1:],
                user=result.username,
                password=result.password,
                host=result.hostname,
                port=result.port
            )
            conn.close()
            print("Database is ready!")
            return True
        except Exception as e:
            print(f"Database not ready... attempt {i+1}/{max_retries}")
            print(f"Error: {str(e)}")
            if i < max_retries - 1:
                time.sleep(retry_interval)
    return False

if not wait_for_db():
    print("Could not connect to database after maximum retries")
    sys.exit(1)
END
}

# Wait for database
check_db

# Run migrations
echo "Running migrations..."
python manage.py migrate

# Create admin user if it doesn't exist
echo "Setting up admin user..."
python << END
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'horilla.settings')
django.setup()

from django.contrib.auth import get_user_model
User = get_user_model()

username = os.getenv('DJANGO_SUPERUSER_USERNAME', 'admin')
email = os.getenv('DJANGO_SUPERUSER_EMAIL', 'admin@example.com')
password = os.getenv('DJANGO_SUPERUSER_PASSWORD', 'admin')

if not User.objects.filter(username=username).exists():
    print(f"Creating superuser {username}...")
    User.objects.create_superuser(username, email, password)
    print("Superuser created successfully!")
else:
    print(f"Superuser {username} already exists.")
END

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Set the correct port for Gunicorn
# Railway sets PORT=8080, but we need to use that port
export PORT=${PORT:-8000}
echo "Starting Gunicorn on port $PORT..."

# Start Gunicorn
exec gunicorn -c gunicorn.conf.py horilla.wsgi:application
