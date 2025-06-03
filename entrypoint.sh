#!/bin/bash

set -e  # Exit on error

echo "Starting application setup..."

# Wait for database to be ready
echo "Waiting for database to be ready..."
max_retries=30
retry_count=0
while ! python3 manage.py check --database default 2>/dev/null; do
    retry_count=$((retry_count + 1))
    if [ $retry_count -gt $max_retries ]; then
        echo "Database connection failed after $max_retries attempts"
        exit 1
    fi
    echo "Database not ready yet... waiting (attempt $retry_count/$max_retries)"
    sleep 2
done

echo "Database is ready!"

# Run migrations
echo "Running migrations..."
python3 manage.py makemigrations
python3 manage.py migrate

# Collect static files
echo "Collecting static files..."
python3 manage.py collectstatic --noinput

# Compile translations
echo "Compiling translations..."
python3 manage.py compilemessages

# Initialize database with demo data
echo "Initializing database with demo data..."
python3 manage.py load_demo_database

# Create admin user if it doesn't exist
echo "Setting up admin user..."
python3 manage.py createhorillauser --first_name admin --last_name admin --username admin --password admin --email admin@example.com --phone 1234567890

# Start Gunicorn
echo "Starting Gunicorn..."
exec gunicorn --bind 0.0.0.0:${PORT:-8000} --workers 2 --timeout 120 horilla.wsgi:application
