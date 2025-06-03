#!/bin/bash

set -e  # Exit on error

# Debug logging
echo "Environment variables:"
env | sort

echo "Starting application setup..."
echo "Using PORT: ${PORT:-8000}"
echo "Using RAILWAY_TCP_PROXY_PORT: ${RAILWAY_TCP_PROXY_PORT:-8000}"

# Check if secret key is set and not using default value
if [ -z "$SECRET_KEY" ] || [ "$SECRET_KEY" = "django-insecure-j8op9)1q8$1&0^s&p*_0%d#pr@w9qj@1o=3#@d=a(^@9@zd@%j" ]; then
    echo "WARNING: SECRET_KEY is not set or using default value. This is not secure for production!"
    echo "Please set a secure SECRET_KEY in your Railway environment variables."
fi

# Check if we're using the default database URL
if [ -z "$DATABASE_URL" ]; then
    echo "WARNING: DATABASE_URL is not set. Using default SQLite database."
fi

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
echo "Starting Gunicorn..."
echo "PORT environment variable: ${PORT}"
echo "RAILWAY_TCP_PROXY_PORT: ${RAILWAY_TCP_PROXY_PORT}"

# Export the correct port for Gunicorn
export PORT=${RAILWAY_TCP_PROXY_PORT:-${PORT:-8000}}
echo "Exported PORT: ${PORT}"

exec gunicorn -c gunicorn.conf.py horilla.wsgi:application
