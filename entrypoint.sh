#!/bin/bash

set -e  # Exit on error

echo "Starting application setup..."

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

echo "Database is ready! Setting up database and role..."

# Create horilla role and database
echo "Creating horilla role and database..."
python3 manage.py dbshell << EOF
DO
\$do\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'horilla') THEN
      CREATE ROLE horilla LOGIN PASSWORD 'horilla';
   END IF;
END
\$do\$;

SELECT 'CREATE DATABASE horilla_main OWNER horilla'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'horilla_main')\gexec
EOF

echo "Database and role created successfully!"

# Run migrations
echo "Running migrations..."
python3 manage.py makemigrations --verbosity 2
python3 manage.py migrate --verbosity 2

# Compile translations
echo "Compiling translations..."
python3 manage.py compilemessages --verbosity 2

# Create admin user if it doesn't exist
echo "Setting up admin user..."
python3 manage.py createhorillauser --first_name admin --last_name admin --username admin --password admin --email admin@example.com --phone 1234567890

# Start Gunicorn
echo "Starting Gunicorn..."
exec gunicorn --bind 0.0.0.0:${PORT:-8000} --workers 2 --timeout 120 --log-level debug horilla.wsgi:application
