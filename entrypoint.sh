#!/bin/bash

set -e  # Exit on error

echo "Starting application setup..."
echo "Using PORT: ${PORT:-8000}"

# Function to check if database is accepting connections
check_db() {
    echo "Checking database connection..."
    # Try to connect to the database using DATABASE_URL
    python3 manage.py check --database default
    return $?
}

# Wait for database to be ready
echo "Waiting for database to be ready..."
max_retries=30
retry_count=0
while ! check_db; do
    retry_count=$((retry_count + 1))
    if [ $retry_count -gt $max_retries ]; then
        echo "Database connection failed after $max_retries attempts"
        echo "Current DATABASE_URL: ${DATABASE_URL}"
        exit 1
    fi
    echo "Database not ready yet... waiting (attempt $retry_count/$max_retries)"
    sleep 2
done

echo "Database is ready! Running migrations..."

# Run migrations with error handling
echo "Running migrations..."
if ! python3 manage.py makemigrations --verbosity 2; then
    echo "Error: Failed to make migrations"
    exit 1
fi

if ! python3 manage.py migrate --verbosity 2; then
    echo "Error: Failed to apply migrations"
    exit 1
fi

# Compile translations with error handling
echo "Compiling translations..."
if ! python3 manage.py compilemessages --verbosity 2; then
    echo "Warning: Failed to compile messages, continuing anyway..."
fi

# Create admin user if it doesn't exist
echo "Setting up admin user..."
if ! python3 manage.py createhorillauser --first_name admin --last_name admin --username admin --password admin --email admin@example.com --phone 1234567890; then
    echo "Warning: Failed to create admin user, continuing anyway..."
fi

# Start Gunicorn with error handling
echo "Starting Gunicorn on port ${PORT:-8000}..."
exec gunicorn \
    --bind 0.0.0.0:${PORT:-8000} \
    --workers 2 \
    --timeout 120 \
    --log-level debug \
    --access-logfile - \
    --error-logfile - \
    --capture-output \
    --forwarded-allow-ips "*" \
    horilla.wsgi:application
